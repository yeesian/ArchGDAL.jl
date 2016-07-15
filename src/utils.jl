macro ogrerr(code, message)
    return quote
        if $code != GDAL.OGRERR_NONE
            error($message)
        end
    end
end

macro cplerr(code, message)
    return quote
        if $code != GDAL.CE_None
            error($message)
        end
    end
end

macro cplwarn(code, message)
    return quote
        if $code != GDAL.CE_None
            warn($message)
        end
    end
end

macro cplprogress(progressfunc)
    return quote
        cfunction($progressfunc,Cint,(Cdouble,Cstring,Ptr{Void}))
    end
end

"""
Load a `NULL`-terminated list of strings

That is it expects a "StringList", in the sense of the CPL functions, as a
NULL terminated array of strings.
"""
function unsafe_loadstringlist(pstringlist::Ptr{Cstring})
    stringlist = Vector{ASCIIString}()
    (pstringlist == C_NULL) && return stringlist
    i = 1
    item = unsafe_load(pstringlist, i)
    while Ptr{UInt8}(item) != C_NULL
        push!(stringlist, bytestring(item))
        i += 1
        item = unsafe_load(pstringlist, i)
    end
    stringlist
end