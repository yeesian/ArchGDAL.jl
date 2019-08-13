macro gdal(args...)
    @assert length(args) > 0
    @assert args[1].head == :(::)
    fhead = (args[1].args[1], GDAL.libgdal)
    returntype = args[1].args[2]
    argtypes = Expr(:tuple, [esc(a.args[2]) for a in args[2:end]]...)
    args = [esc(a.args[1]) for a in args[2:end]]
    return quote ccall($fhead, $returntype, $argtypes, $(args...)) end
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
    @cfunction($(esc(progressfunc)),Cint,(Cdouble,Cstring,Ptr{Cvoid}))
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

"Fetch list of (non-empty) metadata domains. (Since: GDAL 1.11)"
metadatadomainlist(obj) = GDAL.gdalgetmetadatadomainlist(obj.ptr)

"Fetch metadata. Note that relatively few formats return any metadata."
metadata(obj; domain::AbstractString = "") =
    GDAL.gdalgetmetadata(obj.ptr, domain)

"""
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
setconfigoption(option::AbstractString, value) =
    GDAL.cplsetconfigoption(option, value)

"""
This function can be used to clear a setting.

Note: it will not unset an existing environment variable; it will
just unset a value previously set by `setconfigoption()`.
"""
clearconfigoption(option::AbstractString) = setconfigoption(option, C_NULL)

"""
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
function getconfigoption(option::AbstractString, default = C_NULL)
    result = @gdal(CPLGetConfigOption::Cstring,
        option::Cstring,
        default::Cstring
    )
    return (result == C_NULL) ? "" : unsafe_string(result)
end

"""
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
setthreadconfigoption(option::AbstractString, value) =
    GDAL.cplsetthreadlocalconfigoption(option, value)

"""
This function can be used to clear a setting.

Note: it will not unset an existing environment variable; it will
just unset a value previously set by `setthreadconfigoption()`.
"""
clearthreadconfigoption(option::AbstractString) =
    setthreadconfigoption(option, C_NULL)

"Same as `getconfigoption()` but with settings from `setthreadconfigoption()`."
function getthreadconfigoption(option::AbstractString, default = C_NULL)
    result = @gdal(CPLGetThreadLocalConfigOption::Cstring,
        option::Cstring,
        default::Cstring
    )
    return (result == C_NULL) ? "" : unsafe_string(result)
end
