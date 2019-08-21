"Fetch driver by index"
getdriver(i::Integer) = Driver(GDAL.gdalgetdriver(i))

"Fetch a driver based on the short name (such as `GTiff`)."
getdriver(name::AbstractString) = Driver(GDAL.gdalgetdriverbyname(name))

"""
Destroy a `GDALDriver`.

This is roughly equivalent to deleting the driver, but is guaranteed to take
place in the GDAL heap. It is important this that function not be called on a
driver that is registered with the `GDALDriverManager`.
"""
function destroy(drv::Driver)
    GDAL.gdaldestroydriver(drv.ptr)
    drv.ptr = C_NULL
end

"Register a driver for use."
register(drv::Driver) = GDAL.gdalregisterdriver(drv.ptr)

"Deregister the passed drv."
deregister(drv::Driver) = GDAL.gdalderegisterdriver(drv.ptr)

"Return the list of creation options of the driver [an XML string]"
options(drv::Driver) = GDAL.gdalgetdrivercreationoptionlist(drv.ptr)

driveroptions(name::AbstractString) = options(getdriver(name))

"Return the short name of a driver (e.g. `GTiff`)"
shortname(drv::Driver) = GDAL.gdalgetdrivershortname(drv.ptr)

"Return the long name of a driver (e.g. `GeoTIFF`), or empty string."
longname(drv::Driver) = GDAL.gdalgetdriverlongname(drv.ptr)

"Fetch the number of registered drivers."
ndriver() = GDAL.gdalgetdrivercount()

"Returns a listing of all registered drivers"
listdrivers() = Dict{String,String}([
    shortname(getdriver(i)) => longname(getdriver(i)) for i in 0:(ndriver()-1)
])

"""
Identify the driver that can open a raster file.

This function will try to identify the driver that can open the passed filename
by invoking the Identify method of each registered `GDALDriver` in turn. The
first driver that successful identifies the file name will be returned. If all
drivers fail then `NULL` is returned.
"""
identifydriver(filename::AbstractString) =
    Driver(GDAL.gdalidentifydriver(filename, C_NULL))

"""
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
validate(drv::Driver, options::Vector{T}) where {T <: AbstractString} = 
    Bool(GDAL.gdalvalidatecreationoptions(drv.ptr, options))

"Copy all the files associated with a dataset."
function copyfiles(drv::Driver, new::AbstractString, old::AbstractString)
    result = GDAL.gdalcopydatasetfiles(drv.ptr, new, old)
    @cplerr result "Failed to copy dataset files"
end

"Copy all the files associated with a dataset."
copyfiles(drvname::AbstractString, new::AbstractString, old::AbstractString) =
    copyfiles(getdriver(drvname), new, old)
