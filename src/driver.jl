"Fetch driver by index"
getdriver(i::Integer) = GDAL.getdriver(i)

"Fetch a driver based on the short name (such as `GTiff`)."
getdriver(name::AbstractString) = GDAL.getdriverbyname(name)

"""
Destroy a `GDALDriver`.

This is roughly equivelent to deleting the driver, but is guaranteed to take
place in the GDAL heap. It is important this that function not be called on a
driver that is registered with the `GDALDriverManager`.
"""
destroy(drv::Driver) = GDAL.destroydriver(drv)

"Register a driver for use."
register(drv::Driver) = GDAL.registerdriver(drv)

"Deregister the passed drv."
deregister(drv::Driver) = GDAL.deregisterdriver(drv)

"Return the list of creation options of the driver [an XML string]"
options(drv::Driver) = GDAL.getdrivercreationoptionlist(drv)
options(name::AbstractString) = options(getdriver(name))

"Return the short name of a driver (e.g. `GTiff`)"
shortname(drv::Driver) = GDAL.getdrivershortname(drv)

"Return the long name of a driver (e.g. `GeoTIFF`), or empty string."
longname(drv::Driver) = GDAL.getdriverlongname(drv)

"Fetch the number of registered drivers."
ndriver() = GDAL.getdrivercount()

"Returns a listing of all registered drivers"
function drivers()
    dlist = Dict{ASCIIString,ASCIIString}()
    for i in 0:(ndriver()-1)
        dlist[shortname(getdriver(i))] = longname(getdriver(i))
    end
    dlist
end

"""
Identify the driver that can open a raster file.

This function will try to identify the driver that can open the passed filename
by invoking the Identify method of each registered `GDALDriver` in turn. The
first driver that successful identifies the file name will be returned. If all
drivers fail then `NULL` is returned.
"""
identifydriver(filename::AbstractString) = GDAL.identifydriver(filename, C_NULL)

"""
Validate the list of creation options that are handled by a drv.

This is a helper method primarily used by `create()` and `createcopy()` to
validate that the passed in list of creation options is compatible with the
`GDAL_DMD_CREATIONOPTIONLIST` metadata item defined by some drivers.

### Parameters
* `drv`     the handle of the driver with whom the lists of creation option
            must be validated
* `options` the list of creation options. An array of strings, whose last
            element is a `NULL` pointer

### Returns
`TRUE` if the list of creation options is compatible with the `create()` and
`createCopy()` method of the driver, `FALSE` otherwise.

### Additional Remarks
See also: `options(drv::Driver)`

If the `GDAL_DMD_CREATIONOPTIONLIST` metadata item is not defined, this
function will return `TRUE`. Otherwise it will check that the keys and values
in the list of creation options are compatible with the capabilities declared
by the `GDAL_DMD_CREATIONOPTIONLIST` metadata item. In case of incompatibility
a (non fatal) warning will be emited and `FALSE` will be returned.
"""
validate{T <: AbstractString}(drv::Driver, options::Vector{T}) = 
    Bool(ccall((:GDALValidateCreationOptions,GDAL.libgdal),Cint,
               (Driver,StringList),drv,options))

"Copy all the files associated with a dataset."
function copyfiles(drv::Driver,
                   newname::AbstractString,
                   oldname::AbstractString)
    result = GDAL.copydatasetfiles(drv, newname, oldname)
    @cplerr result "Failed to copy dataset files"
end

"Copy all the files associated with a dataset."
function copyfiles(drvname::AbstractString,
                   newname::AbstractString,
                   oldname::AbstractString)
    result = GDAL.copydatasetfiles(getdriver(drvname), newname, oldname)
    @cplerr result "Failed to copy dataset files"
end
