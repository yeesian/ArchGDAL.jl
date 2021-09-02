# An ImmutableDict constructor based on a list of Pair arguments has been introduced in Julia 1.6.0 and backported to Julia 1.5
if VERSION < v"1.5"
    function Base.ImmutableDict(KV::Pair, rest::Pair...)
        return Base.ImmutableDict(Base.ImmutableDict(KV), rest...)
    end
end

"""
    @convert(<T1>::<T2>, 
        <conversions>
    )

Generate `convert` functions both ways between ArchGDAL Enum of typeids (e.g. `ArchGDAL.OGRFieldType`) 
and other types or typeids.

ArchGDAL uses Enum types, listing typeids of various data container used in GDAL/OGR object model. 
Some of these types are used to implement concrete types in julia through parametric composite types 
based on those Enum of typeids (e.g. `Geometry` and `IGeometry` types with `OGRwkbGeometryType`)

Other types or typeids can be:
- GDAL CEnum.Cenum typeids (e.g. `GDAL.OGRFieldType`), 
- Base primitive DataType types (e.g. `Bool`), 
- other parametric composite types (e.g. `ImageCore.Normed`)

# Arguments
- `(<T1>::<T2>)::Expr`: source and target supertypes, where `T1<:Enum`  and `T2<:CEnum.Cenum || T2::Type{DataType} || T2::UnionAll}``
- `(<stype1>::<stype2>)::Expr`: source and target subtypes or type ids with `stype1::T1` and 
    - `stype2::T2 where T2<:CEnum.Cenum` or 
    - `stype2::T2 where T2::Type{DataType}` or 
    - `stype2<:T2`where T2<:UnionAll
- ...

**Note:** In the case where the mapping is not bijective, the last declared typeid of subtype is used. 
Example: 
```
@convert(
    OGRFieldType::DataType,
    OFTInteger::Bool,
    OFTInteger::Int16,
    OFTInteger::Int32,
)
```
will generate a `convert` functions giving:
- `Int32` type for `OFTInteger` and not `Ìnt16`
- `OFTInteger` OGRFieldType typeid for both `Int16` and `Int32`

# Usage
### General case:
```
@convert(GDALRWFlag::GDAL.GDALRWFlag,
    GF_Read::GDAL.GF_Read,
    GF_Write::GDAL.GF_Write,
)
```
does the equivalent of 
```
const GDALRWFlag_to_GDALRWFlag_map = ImmutableDict(
    GF_Read => GDAL.GF_Read,
    GF_Write => GDAL.GF_Write
)
Base.convert(::Type{GDAL.GDALRWFlag}, ft::GDALRWFlag) =
    GDALRWFlag_to_GDALRWFlag_map[ft]

const GDALRWFlag_to_GDALRWFlag_map = ImmutableDict(
    GDAL.GF_Read => GF_Read, 
    GDAL.GF_Write => GF_Write
)
Base.convert(::Type{GDALRWFlag}, ft::GDAL.GDALRWFlag) =
    GDALRWFlag_to_GDALRWFlag_map[ft]
```
### Case where 1st type `<: Enum` and 2nd type `== DataType` or `ìsa UnionAll`:
```
@convert(OGRFieldType::DataType,
    OFTInteger::Bool,
    OFTInteger::Int16,
)
```
does the equivalent of
```
const OGRFieldType_to_DataType_map = ImmutableDict(
    OFTInteger => Bool, 
    OFTInteger => Int16,
)
Base.convert(::Type{DataType}, ft::OGRFieldType) =
    OGRFieldType_to_DataType_map[ft]

Base.convert(::Type{OGRFieldType}, ft::Type{Bool}) = OFTInteger
Base.convert(::Type{OGRFieldType}, ft::Type{Int16}) = OFTInteger
```

"""
macro convert(args...)
    @assert length(args) > 1
    @assert args[1].head == :(::)
    (T1, T2) = args[1].args

    # Types and type ids / subtypes checks
    stypes1, stypes2 = zip((eval.(a.args) for a in args[2:end])...)
    @assert(eval(T1) <: Enum && all(isa.(stypes1, eval(T1))))
    @assert(
        ((eval(T2) <: CEnum.Cenum) && all(isa.(stypes2, eval(T2)))) ||
        ((eval(T2) isa Type{DataType}) && all(isa.(stypes2, eval(T2)))) ||
        ((eval(T2) isa UnionAll) && all((<:).(stypes2, eval(T2))))
    )

    # Types other representations
    (T1_string, T2_string) = replace.(string.((T1, T2)), "." => "_")
    (type1, type2) = esc.((T1, T2))

    # Subtypes forward and backward mapping
    fwd_map = [Expr(:call, esc(:Pair), esc.(a.args)...) for a in args[2:end]]
    rev_map =
        [Expr(:call, esc(:Pair), esc.(reverse(a.args))...) for a in args[2:end]]

    #! Convert functions generation
    result_expr = Expr(:block)

    #* Forward conversions from ArchGDAL typeids
    T1_to_T2_map_name = esc(Symbol(T1_string * "_to_" * T2_string * "_map"))
    push!(
        result_expr.args,
        :(const $T1_to_T2_map_name = Base.ImmutableDict([$(fwd_map...)]...)),
    )
    push!(
        result_expr.args,
        :(function Base.convert(::Type{$type2}, ft::$type1)
            return $T1_to_T2_map_name[ft]
        end),
    )

    #* Reverse conversions to ArchGDAL typeids
    # Optimization for conversion from types
    if !(eval(T2) <: CEnum.Cenum)
        for stypes in [Tuple(esc.(reverse(a.args))) for a in args[2:end]]
            push!(
                result_expr.args,
                :(
                    function Base.convert(
                        ::Type{$type1},
                        ft::Type{$(stypes[1])},
                    )
                        return $(stypes[2])
                    end
                ),
            )
        end
        # Conversion from typeids
    else
        T2_to_T1_map_name = esc(Symbol(T2_string * "_to_" * T1_string * "_map"))
        push!(
            result_expr.args,
            :(
                const $T2_to_T1_map_name =
                    Base.ImmutableDict([$(rev_map...)]...)
            ),
        )
        push!(
            result_expr.args,
            :(function Base.convert(::Type{$type1}, ft::$type2)
                return $T2_to_T1_map_name[ft]
            end),
        )
    end

    return result_expr
end

macro gdal(args...)
    @assert length(args) > 0
    @assert args[1].head == :(::)
    fhead = (args[1].args[1], GDAL.libgdal)
    returntype = args[1].args[2]
    argtypes = Expr(:tuple, [esc(a.args[2]) for a in args[2:end]]...)
    args = [esc(a.args[1]) for a in args[2:end]]
    return quote
        ccall($fhead, $returntype, $argtypes, $(args...))
    end
end

macro ogrerr(code, message)
    return quote
        if $(esc(code)) != GDAL.OGRERR_NONE
            error($message)
        end
    end
end

macro cplerr(code, message)
    return quote
        if $(esc(code)) != GDAL.CE_None
            error($message)
        end
    end
end

macro cplwarn(code, message)
    return quote
        if $(esc(code)) != GDAL.CE_None
            @warn $message
        end
    end
end

macro cplprogress(progressfunc)
    @cfunction($(esc(progressfunc)), Cint, (Cdouble, Cstring, Ptr{Cvoid}))
end

# """
# Load a `NULL`-terminated list of strings

# That is it expects a "StringList", in the sense of the CPL functions, as a
# NULL terminated array of strings.
# """
# function unsafe_loadstringlist(pstringlist::Ptr{Cstring})
#     stringlist = Vector{String}()
#     (pstringlist == C_NULL) && return stringlist
#     i = 1
#     item = unsafe_load(pstringlist, i)
#     while item != C_NULL
#         push!(stringlist, unsafe_string(item))
#         i += 1
#         item = unsafe_load(pstringlist, i)
#     end
#     stringlist
# end

"""
    metadatadomainlist(obj)

Fetch list of (non-empty) metadata domains.
"""
metadatadomainlist(obj)::Vector{String} =
    GDAL.gdalgetmetadatadomainlist(obj.ptr)

"""
    metadata(obj; domain::AbstractString = "")

Fetch metadata. Note that relatively few formats return any metadata.
"""
metadata(obj; domain::AbstractString = "")::Vector{String} =
    GDAL.gdalgetmetadata(obj.ptr, domain)

"""
    metadataitem(obj, name::AbstractString, domain::AbstractString)

Fetch single metadata item.

### Parameters
* `name` the name of the metadata item to fetch.
* `domain` (optional) the domain to fetch for.

### Returns
The metadata item on success, or an empty string on failure.
"""
function metadataitem(
    obj,
    name::AbstractString;
    domain::AbstractString = "",
)::String
    item = GDAL.gdalgetmetadataitem(obj.ptr, name, domain)
    # Use `=== nothing` instead of isnothing() for performance.
    # See https://github.com/JuliaLang/julia/pull/36444 for context.
    return item === nothing ? "" : item
end

"""
    setconfigoption(option::AbstractString, value)

Set a configuration option for GDAL/OGR use.

Those options are defined as a (key, value) couple. The value corresponding to a
key can be got later with the `getconfigoption()` method.

### Parameters
* `option`  the key of the option
* `value`   the value of the option, or NULL to clear a setting.

This mechanism is similar to environment variables, but options set with
`setconfigoption()` overrides, for `getconfigoption()` point of view, values
defined in the environment.

If `setconfigoption()` is called several times with the same key, the value
provided during the last call will be used.
"""
function setconfigoption(option::AbstractString, value)::Nothing
    GDAL.cplsetconfigoption(option, value)
    return nothing
end

"""
    clearconfigoption(option::AbstractString)

This function can be used to clear a setting.

Note: it will not unset an existing environment variable; it will
just unset a value previously set by `setconfigoption()`.
"""
function clearconfigoption(option::AbstractString)::Nothing
    setconfigoption(option, C_NULL)
    return nothing
end

"""
    getconfigoption(option::AbstractString, default = C_NULL)

Get the value of a configuration option.

The value is the value of a (key, value) option set with `setconfigoption()`.
If the given option was not defined with `setconfigoption()`, it tries to find
it in environment variables.

### Parameters
* `option`  the key of the option to retrieve
* `default` a default value if the key does not match existing defined options

### Returns
the value associated to the key, or the default value if not found.
"""
function getconfigoption(option::AbstractString, default = C_NULL)::String
    result =
        @gdal(CPLGetConfigOption::Cstring, option::Cstring, default::Cstring)
    return (result == C_NULL) ? "" : unsafe_string(result)
end

"""
    setthreadconfigoption(option::AbstractString, value)

Set a configuration option for GDAL/OGR use.

Those options are defined as a (key, value) couple. The value corresponding to a
key can be got later with the `getconfigoption()` method.

### Parameters
* `option`  the key of the option
* `value`   the value of the option

This function sets the configuration option that only applies in the current
thread, as opposed to `setconfigoption()` which sets an option that applies on
all threads.
"""
function setthreadconfigoption(option::AbstractString, value)::Nothing
    GDAL.cplsetthreadlocalconfigoption(option, value)
    return nothing
end

"""
    clearthreadconfigoption(option::AbstractString)

This function can be used to clear a setting.

Note: it will not unset an existing environment variable; it will
just unset a value previously set by `setthreadconfigoption()`.
"""
function clearthreadconfigoption(option::AbstractString)::Nothing
    setthreadconfigoption(option, C_NULL)
    return nothing
end

"""
    getthreadconfigoption(option::AbstractString, default = C_NULL)

Same as `getconfigoption()` but with settings from `setthreadconfigoption()`.
"""
function getthreadconfigoption(option::AbstractString, default = C_NULL)::String
    result = @gdal(
        CPLGetThreadLocalConfigOption::Cstring,
        option::Cstring,
        default::Cstring
    )
    return (result == C_NULL) ? "" : unsafe_string(result)
end
