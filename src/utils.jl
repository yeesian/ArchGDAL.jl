"""
    @convert(args...)

# General case:
```
eval(@convert(GDALRWFlag::GDAL.GDALRWFlag,
    GF_Read::GDAL.GF_Read,
    GF_Write::GDAL.GF_Write,
))
```
does the equivalent of 
```
const GDALRWFlag_to_GDALRWFlag_map = Dict(
    GF_Read => GDAL.GF_Read,
    GF_Write => GDAL.GF_Write
)
Base.convert(::Type{GDAL.GDALRWFlag}, ft::GDALRWFlag) =
    GDALRWFlag_to_GDALRWFlag_map[ft]

const GDALRWFlag_to_GDALRWFlag_map = Dict(
    GDAL.GF_Read => GF_Read, 
    GDAL.GF_Write => GF_Write
)
Base.convert(::Type{GDALRWFlag}, ft::GDAL.GDALRWFlag) =
    GDALRWFlag_to_GDALRWFlag_map[ft]
```
# Case where 1st type `<: Enum` and 2nd type `== DataType` or ìsa UnionAll`:
```
eval(@convert(OGRFieldType::DataType,
    OFTInteger::Bool,
    OFTInteger::Int16,
))
```
does the equivalent of
```
const OGRFieldType_to_DataType_map = Dict(
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
    @assert length(args) > 0
    @assert args[1].head == :(::)
    type1_symbol = args[1].args[1]
    type2_symbol = args[1].args[2]
    type1_string = replace(string(type1_symbol), "." => "_")
    type2_string = replace(string(type2_symbol), "." => "_")
    type1_isenum_and_type2_equaldatatype_or_isaunionall =
        (eval(type1_symbol) <: Enum) && (
            (eval(type2_symbol) == DataType) ||
            (eval(type2_symbol) isa UnionAll)
        )
    type1 = esc(type1_symbol)
    type2 = esc(type2_symbol)
    fwd_map = Expr[Expr(:tuple, esc.(a.args)...) for a in args[2:end]]
    if type1_isenum_and_type2_equaldatatype_or_isaunionall
        rev_to_enum_map = [Tuple(esc.(reverse(a.args))) for a in args[2:end]]
    else
        rev_map =
            Expr[Expr(:tuple, esc.(reverse(a.args))...) for a in args[2:end]]
    end

    result_expr = Expr(:block)
    # Forward conversion (no case of 1st type == DataType and 2nd type <: Enum handled)
    type1_to_type2_map_name =
        esc(Symbol(type1_string * "_to_" * type2_string * "_map"))
    push!(
        result_expr.args,
        :(const $type1_to_type2_map_name = Dict([$(fwd_map...)])),
    )
    push!(
        result_expr.args,
        :(function Base.convert(::Type{$type2}, ft::$type1)
            return get($type1_to_type2_map_name, ft) do
                return error("Unknown type: $ft")
            end
        end),
    )
    # Reverse conversion
    if type1_isenum_and_type2_equaldatatype_or_isaunionall
        for stypes in rev_to_enum_map
            eval(type2_symbol) isa UnionAll && @assert eval(stypes[1].args[1]) <: eval(type2_symbol)
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
    else
        type2_to_type1_map_name =
            esc(Symbol(type2_string * "_to_" * type1_string * "_map"))
        push!(
            result_expr.args,
            :(const $type2_to_type1_map_name = Dict([$(rev_map...)])),
        )
        push!(
            result_expr.args,
            :(function Base.convert(::Type{$type1}, ft::$type2)
                return get($type2_to_type1_map_name, ft) do
                    return error("Unknown type: $ft")
                end
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
