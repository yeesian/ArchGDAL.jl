"""
    getdriver(i::Integer)

Fetch driver by index.
"""
getdriver(i::Integer)::Driver = Driver(GDAL.gdalgetdriver(i))

"""
    getdriver(name::AbstractString)

Fetch a driver based on the short name (such as `GTiff`).
"""
getdriver(name::AbstractString)::Driver = Driver(GDAL.gdalgetdriverbyname(name))

"""
    register(drv::Driver)

Register a driver for use.
"""
function register(drv::Driver)::Nothing
    GDAL.gdalregisterdriver(drv.ptr)
    return nothing
end

"""
    deregister(drv::Driver)

Deregister the passed driver.
"""
function deregister(drv::Driver)::Nothing
    GDAL.gdalderegisterdriver(drv.ptr)
    return nothing
end

"""
    options(drv::Driver)

Return the list of creation options of the driver [an XML string].
"""
options(drv::Driver)::String = GDAL.gdalgetdrivercreationoptionlist(drv.ptr)

driveroptions(name::AbstractString)::String = options(getdriver(name))

"""
    shortname(drv::Driver)

Return the short name of a driver (e.g. `GTiff`).
"""
shortname(drv::Driver)::String = GDAL.gdalgetdrivershortname(drv.ptr)

"""
    longname(drv::Driver)

Return the long name of a driver (e.g. `GeoTIFF`), or empty string.
"""
longname(drv::Driver)::String = GDAL.gdalgetdriverlongname(drv.ptr)

"""
    ndriver()

Fetch the number of registered drivers.
"""
ndriver()::Integer = GDAL.gdalgetdrivercount()

"""
    listdrivers()

Returns a listing of all registered drivers.
"""
listdrivers()::Dict{String,String} = Dict{String,String}([
    shortname(getdriver(i)) => longname(getdriver(i)) for i in 0:(ndriver()-1)
])

"""
    identifydriver(filename::AbstractString)

Identify the driver that can open a raster file.

This function will try to identify the driver that can open the passed filename
by invoking the Identify method of each registered `Driver` in turn. The
first driver that successful identifies the file name will be returned. If all
drivers fail then `NULL` is returned.
"""
identifydriver(filename::AbstractString)::Driver =
    Driver(GDAL.gdalidentifydriver(filename, C_NULL))

"""
    validate(drv::Driver, options::Vector{<:AbstractString})

Validate the list of creation options that are handled by a drv.

This is a helper method primarily used by `create()` and `copy()` to
validate that the passed in list of creation options is compatible with the
`GDAL_DMD_CREATIONOPTIONLIST` metadata item defined by some drivers.

### Parameters
* `drv`     the handle of the driver with whom the lists of creation option
            must be validated
* `options` the list of creation options. An array of strings, whose last
            element is a `NULL` pointer

### Returns
`true` if the list of creation options is compatible with the `create()` and
`createcopy()` method of the driver, `false` otherwise.

### Additional Remarks
See also: `options(drv::Driver)`

If the `GDAL_DMD_CREATIONOPTIONLIST` metadata item is not defined, this
function will return ``true``. Otherwise it will check that the keys and values
in the list of creation options are compatible with the capabilities declared
by the `GDAL_DMD_CREATIONOPTIONLIST` metadata item. In case of incompatibility
a (non fatal) warning will be emited and ``false`` will be returned.
"""
function validate(
        drv::Driver,
        options::Vector{T}
    )::Bool where {T <: AbstractString}
    return Bool(GDAL.gdalvalidatecreationoptions(drv.ptr, options))
end

"""
    copyfiles(drv::Driver, new::AbstractString, old::AbstractString)
    copyfiles(drvname::AbstractString, new::AbstractString, old::AbstractString)

Copy all the files associated with a dataset.
"""
function copyfiles end

function copyfiles(
        drv::Driver,
        new::AbstractString,
        old::AbstractString
    )::Nothing
    result = GDAL.gdalcopydatasetfiles(drv.ptr, new, old)
    @cplerr result "Failed to copy dataset files"
    return nothing
end

function copyfiles(
        drvname::AbstractString,
        new::AbstractString,
        old::AbstractString
    )::Nothing
    copyfiles(getdriver(drvname), new, old)
    return nothing
end

"""
    extensions()

Returns a `Dict{String,String}` of all of the file extensions that can be read
by GDAL,  with their respective drivers' `shortname`s.
"""
function extensions()::Dict{String, String}
    extdict = Dict{String, String}()
    for i in 1:ndriver()
        driver = getdriver(i)
        if !(driver.ptr == C_NULL)
            # exts is a space-delimited list in a String, so split it
            for ext in split(metadataitem(driver, "DMD_EXTENSIONS"))
                extdict[".$ext"] = shortname(driver)
            end
        end
    end
    return extdict
end

"""
    extensiondriver(filename::AbstractString)
 
Returns a driver shortname that matches the filename extension.

So `extensiondriver("/my/file.tif") == "GTiff"`.
"""
function extensiondriver(filename::AbstractString)::String
    split = splitext(filename)
    extensiondict = extensions()
    ext = split[2] == "" ? split[1] : split[2]
    if !haskey(extensiondict, ext)
        throw(ArgumentError("There are no GDAL drivers for the $ext extension"))
    end
    return extensiondict[ext]
end
