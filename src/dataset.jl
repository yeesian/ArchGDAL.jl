"""
Copy all dataset raster data.

This function copies the complete raster contents of one dataset to another
similarly configured dataset. The source and destination dataset must have the
same number of bands, and the same width and height. The bands do not have to
have the same data type.

Currently the only `options` supported are : `\"INTERLEAVE=PIXEL\"` to
force pixel interleaved operation and `\"COMPRESSED=YES\"` to force alignment on
target dataset block sizes to achieve best compression. More options may be
supported in the future.

### Additional Remarks
This function is primarily intended to support implementation of driver
specific `createcopy()` functions. It implements efficient copying, in
particular \"chunking\" the copy in substantial blocks and, if appropriate,
performing the transfer in a pixel interleaved fashion.
"""
function copywholeraster(
        source::AbstractDataset,
        dest::AbstractDataset;
        options                 = StringList(C_NULL),
        progressfunc::Function  = GDAL.C.GDALDummyProgress,
        progressdata::Any       = C_NULL
    )
    result = GDAL.datasetcopywholeraster(source.ptr, dest.ptr, options,
        @cplprogress(progressfunc), progressdata)
    @cplerr result "Failed to copy whole raster"
end

"""
Create a copy of a dataset.

This method will attempt to create a copy of a raster dataset with the
indicated filename, and in this drivers format. Band number, size, type,
projection, geotransform and so forth are all to be copied from the
provided template dataset.

### Parameters
* `dataset`       the dataset being duplicated.

### Keyword Arguments
* `filename`      the filename for the new dataset. UTF-8 encoded.
* `driver`        the driver to use for creating the new dataset
* `strict`        `TRUE` if the copy must be strictly equivalent, or more
normally `FALSE` if the copy may adapt as needed for the output format.
* `options`       additional format dependent options controlling creation
of the output file. `The APPEND_SUBDATASET=YES` option can be specified to
avoid prior destruction of existing dataset.

### Returns
a pointer to the newly created dataset (may be read-only access).

### Additional Remarks
Note: many sequential write once formats (such as JPEG and PNG) don't implement
the `Create()` method but do implement this `CreateCopy()` method. If the
driver doesn't implement `CreateCopy()`, but does implement `Create()` then the
default `CreateCopy()` mechanism built on calling `Create()` will be used.

It is intended that `CreateCopy()` will often be used with a source dataset
which is a virtual dataset allowing configuration of band types, and other
information without actually duplicating raster data (see the VRT driver). This
is what is done by the gdal_translate utility for example.

This function will validate the creation option list passed to the driver
with the `GDALValidateCreationOptions()` method. This check can be disabled by
defining the configuration option `GDAL_VALIDATE_CREATION_OPTIONS=NO`.

After you have finished working with the returned dataset, it is required to
close it with `GDALClose()`. This does not only close the file handle, but also
ensures that all the data and metadata has been written to the dataset
(`GDALFlushCache()` is not sufficient for that purpose).

In some situations, the new dataset can be created in another process through
the GDAL API Proxy mechanism.
"""
function unsafe_createcopy(
        dataset::AbstractDataset;
        filename::AbstractString    = string("/vsimem/$(gensym())"),
        driver::Driver              = getdriver(dataset),
        strict::Bool                = false,
        options                     = StringList(C_NULL),
        progressfunc::Function      = GDAL.C.GDALDummyProgress,
        progressdata                = C_NULL
    )
    Dataset(GDAL.createcopy(driver.ptr, filename, GDAL.failsafe(dataset.ptr),
        strict, options, @cplprogress(progressfunc), progressdata))
end

"""
Create a copy of a dataset.

This method will attempt to create a copy of a raster dataset with the
indicated filename, and in this drivers format. Band number, size, type,
projection, geotransform and so forth are all to be copied from the
provided template dataset.

### Parameters
* `dataset`       the dataset being duplicated.

### Keyword Arguments
* `filename`      the filename for the new dataset. UTF-8 encoded.
* `driver`        the driver to use for creating the new dataset
* `strict`        `TRUE` if the copy must be strictly equivalent, or more
    normally `FALSE` if the copy may adapt as needed for the output format.
* `options`       additional format dependent options controlling creation
of the output file. `The APPEND_SUBDATASET=YES` option can be specified to
avoid prior destruction of existing dataset.

### Example
```
dataset = ArchGDAL.createcopy(originaldataset)
# work with dataset from here
```
or
```
ArchGDAL.createcopy(originaldataset) do dataset
    # work with dataset from here
end
```

### Returns
The newly created dataset.
"""
function createcopy(
        dataset::AbstractDataset;
        filename::AbstractString    = string("/vsimem/$(gensym())"),
        driver::Driver              = getdriver(dataset),
        strict::Bool                = false,
        options                     = StringList(C_NULL),
        progressfunc::Function      = GDAL.C.GDALDummyProgress,
        progressdata                = C_NULL
    )
    IDataset(GDAL.createcopy(driver.ptr, filename, GDAL.failsafe(dataset.ptr),
        strict, options, @cplprogress(progressfunc), progressdata))
end

"""
Writes the dataset to the designated filename.
"""
function write(dataset::AbstractDataset, filename::AbstractString; kwargs...)
    destroy(unsafe_createcopy(dataset, filename = filename; kwargs...))
end

"""
Create a new dataset.

What argument values are legal for particular drivers is driver specific, and
there is no way to query in advance to establish legal values.

That function will try to validate the creation option list passed to the driver
with the GDALValidateCreationOptions() method. This check can be disabled by
defining the configuration option GDAL_VALIDATE_CREATION_OPTIONS=NO.

After you have finished working with the returned dataset, it is required to
close it with GDALClose(). This does not only close the file handle, but also
ensures that all the data and metadata has been written to the dataset
(GDALFlushCache() is not sufficient for that purpose).

In some situations, the new dataset can be created in another process through
the GDAL API Proxy mechanism.

In GDAL 2, the arguments nXSize, nYSize and nBands can be passed to 0 when
creating a vector-only dataset for a compatible driver.
"""
function unsafe_create(
        filename::AbstractString;
        driver::Driver              = identifydriver(filename),
        width::Integer              = 0,
        height::Integer             = 0,
        nbands::Integer             = 0,
        dtype::DataType             = Any,
        options                     = StringList(C_NULL)
    )
    result = GDAL.create(driver.ptr, filename, width, height, nbands,
        _GDALTYPE[dtype], options)
    Dataset(result)
end

function unsafe_create(
        driver::Driver;
        filename::AbstractString    = string("/vsimem/$(gensym())"),
        width::Integer              = 0,
        height::Integer             = 0,
        nbands::Integer             = 0,
        dtype::DataType             = Any,
        options                     = StringList(C_NULL)
    )
    result = GDAL.create(driver.ptr, filename, width, height, nbands,
        _GDALTYPE[dtype], options)
    Dataset(result)
end

"""
Create a new dataset.

### Parameters
* `filename`       the filename for the dataset being created.

### Keyword Arguments
* `driver`        the driver to use for creating the new dataset
* `options`       additional format dependent options controlling creation
of the output file. `The APPEND_SUBDATASET=YES` option can be specified to
avoid prior destruction of existing dataset.
* `width`, `height`, `nbands`, `dtype`: only for raster datasets.

### Example
```
dataset = ArchGDAL.create(AG.getdriver("MEM"))
# work with raster dataset from here
```
or
```
ArchGDAL.create(AG.getdriver("Memory")) do dataset
    # work with vector dataset from here
end
```

### Returns
The newly created dataset.
"""
function create(
        filename::AbstractString;
        driver::Driver              = identifydriver(filename),
        width::Integer              = 0,
        height::Integer             = 0,
        nbands::Integer             = 0,
        dtype::DataType             = Any,
        options                     = StringList(C_NULL)
    )
    result = GDAL.create(driver.ptr, filename, width, height, nbands,
        _GDALTYPE[dtype], options)
    IDataset(result)
end

function create(
        driver::Driver;
        filename::AbstractString    = string("/vsimem/$(gensym())"),
        width::Integer              = 0,
        height::Integer             = 0,
        nbands::Integer             = 0,
        dtype::DataType             = Any,
        options                     = StringList(C_NULL)
    )
    result = GDAL.create(driver.ptr, filename, width, height, nbands,
        _GDALTYPE[dtype], options)
    IDataset(result)
end

"""
Open a raster file as a GDALDataset.

This function will try to open the passed file, or virtual dataset name by
invoking the Open method of each registered `GDALDriver` in turn. The first
successful open will result in a returned dataset. If all drivers fail then
`NULL` is returned and an error is issued.

### Parameters
* `filename`  the name of the file to access. In the case of exotic drivers
this may not refer to a physical file, but instead contain information for the
driver on how to access a dataset. It should be in UTF-8 encoding.
* `flags`     a combination of `GDAL_OF_*` flags (listed below) that may be
              combined through the logical `|` operator.

    - Driver kind: GDAL_OF_RASTER for raster drivers, GDAL_OF_VECTOR for vector
                   drivers. If none of the value is specified, both are implied.
    - Access mode: `GDAL_OF_READONLY` (exclusive) or `GDAL_OF_UPDATE`.
    - Shared mode: `GDAL_OF_SHARED`. If set, it allows the sharing of
                   GDALDataset handles for a dataset with other callers that
                   have set GDAL_OF_SHARED. In particular, GDALOpenEx() will
                   consult its list of currently open and shared GDALDataset's,
                   and if the GetDescription() name for one exactly matches the
                   pszFilename passed to GDALOpenEx() it will be referenced and
                   returned, if GDALOpenEx() is called from the same thread.
    - Verbose error: GDAL_OF_VERBOSE_ERROR. If set, a failed attempt to open the
                   file will lead to an error message to be reported.

### Additional Remarks
Several recommendations:

* If you open a dataset object with `GA_Update` access, it is not recommended
to open a new dataset on the same underlying file.
* The returned dataset should only be accessed by one thread at a time. To use
it from different threads, you must add all necessary code (mutexes, etc.) to
avoid concurrent use of the object. (Some drivers, such as GeoTIFF, maintain
internal state variables that are updated each time a new block is read,
preventing concurrent use.)
* In order to reduce the need for searches through the operating system file
system machinery, it is possible to give an optional list of files with the
papszSiblingFiles parameter. This is the list of all files at the same level in
the file system as the target file, including the target file. The filenames
must not include any path components, are essentially just the output of
VSIReadDir() on the parent directory. If the target object does not have
filesystem semantics then the file list should be NULL.

In some situations (dealing with unverified data), the datasets can be opened
in another process through the GDAL API Proxy mechanism.

For drivers supporting the VSI virtual file API, it is possible to open a file
in a `.zip` archive (see `VSIInstallZipFileHandler()`), a `.tar/.tar.gz/.tgz`
archive (see `VSIInstallTarFileHandler()`), or a HTTP / FTP server
(see `VSIInstallCurlFileHandler()`)
"""
function unsafe_read(
        filename::AbstractString;
        flags           = OF_ReadOnly,
        alloweddrivers  = StringList(C_NULL),
        options         = StringList(C_NULL),
        siblingfiles    = StringList(C_NULL)
    )
    result = GDAL.openex(filename, Int(flags), alloweddrivers, options,
        siblingfiles)
    Dataset(result)
end

"""
Open a raster file

### Parameters
* `filename`: the filename of the dataset to be read.

### Keyword Arguments
* `flags`: a combination of `OF_*` flags (listed below) that may be
    combined through the logical `|` operator. It defaults to `OF_ReadOnly`.
    - Driver kind: `OF_Raster` for raster drivers, `OF_Vector` for vector
        drivers. If none of the value is specified, both are implied.
    - Access mode: `OF_ReadOnly` (exclusive) or `OF_Update`.
    - Shared mode: `OF_Shared`. If set, it allows the sharing of handles for a
        dataset with other callers that have set `OF_Shared`.
    - Verbose error: `OF_Verbose_Error`. If set, a failed attempt to open the
        file will lead to an error message to be reported.
* `options`: additional format dependent options.

### Example
```
dataset = ArchGDAL.read("point.shp")
# work with dataset from here
```
or
```
ArchGDAL.read("point.shp") do dataset
    # work with dataset from here
end
```

### Returns
The corresponding dataset.
"""
function read(
        filename::AbstractString;
        flags           = OF_ReadOnly | OF_Verbose_Error,
        alloweddrivers  = StringList(C_NULL),
        options         = StringList(C_NULL),
        siblingfiles    = StringList(C_NULL)
    )
    result = GDAL.openex(filename, Int(flags), alloweddrivers, options,
        siblingfiles)
    IDataset(result)
end

unsafe_update(filename::AbstractString; flags = OF_Update, kwargs...) =
    unsafe_read(filename; flags = OF_Update | flags, kwargs...)

"Fetch raster width in pixels."
width(dataset::AbstractDataset) = GDAL.getrasterxsize(dataset.ptr)

"Fetch raster height in pixels."
height(dataset::AbstractDataset) = GDAL.getrasterysize(dataset.ptr)

"Fetch the number of raster bands on this dataset."
nraster(dataset::AbstractDataset) = GDAL.getrastercount(dataset.ptr)

"Fetch the number of feature layers on this dataset."
nlayer(dataset::AbstractDataset) = GDAL.datasetgetlayercount(dataset.ptr)

"Fetch the driver that the dataset was created with"
getdriver(dataset::AbstractDataset) = Driver(GDAL.getdatasetdriver(dataset.ptr))

"""
Fetch files forming dataset.

Returns a list of files believed to be part of this dataset. If it returns an
empty list of files it means there is believed to be no local file system files
associated with the dataset (for instance a virtual dataset). The returned file
list is owned by the caller and should be deallocated with `CSLDestroy()`.

The returned filenames will normally be relative or absolute paths depending on
the path used to originally open the dataset. The strings will be UTF-8 encoded
"""
filelist(dataset::AbstractDataset) = GDAL.getfilelist(dataset.ptr)

"""
Fetch the layer at index `i` (between `0` and `nlayer(dataset)-1`)

The returned layer remains owned by the GDALDataset and should not be deleted by
the application.
"""
getlayer(dataset::AbstractDataset, i::Integer) =
    FeatureLayer(GDAL.datasetgetlayer(dataset.ptr, i), ownedby = dataset)

"""
Fetch the feature layer corresponding to the given name.

The returned layer remains owned by the GDALDataset and should not be deleted by
the application.
"""
function getlayer(dataset::AbstractDataset, name::AbstractString)
    FeatureLayer(
        GDAL.datasetgetlayerbyname(dataset.ptr, name),
        ownedby = dataset
    )
end

"""
Delete the indicated layer (at index i; between `0` to `nlayer()-1`)

### Returns
`OGRERR_NONE` on success, or `OGRERR_UNSUPPORTED_OPERATION` if deleting layers
is not supported for this dataset.
"""
function deletelayer!(dataset::AbstractDataset, i::Integer)
    result = GDAL.datasetdeletelayer(dataset.ptr, i)
    @ogrerr result "Failed to delete layer"
    dataset
end

"""
This function attempts to create a new layer on the dataset with the indicated
name, coordinate system, geometry type.

The `options` argument can be used to control driver specific creation
options. These options are normally documented in the format specific
documentation.

### Parameters
* `dataset`: the dataset
* `name`: the name for the new layer. This should ideally not match any
    existing layer on the datasource.
* `spatialref`: the coordinate system to use for the new layer, or `NULL`
    (default) if no coordinate system is available.

### Optional Parameters
* `geom`: the geometry type for the layer. Use wkbUnknown (default) if
    there are no constraints on the types geometry to be written.
* `options`: a StringList of name=value (driver-specific) options.
"""
function createlayer(
        dataset::AbstractDataset,
        name::AbstractString;
        geom::OGRwkbGeometryType        = GDAL.wkbUnknown,
        options                         = StringList(C_NULL)
    )
    FeatureLayer(GDAL.datasetcreatelayer(dataset.ptr, name,
        GDALSpatialRef(C_NULL), geom, options), ownedby = dataset)
end

function createlayer(
        f::Function,
        dataset::AbstractDataset,
        name::AbstractString,
        spatialref::AbstractSpatialRef;
        geom::OGRwkbGeometryType        = GDAL.wkbUnknown,
        options                         = StringList(C_NULL)
    )
    # NOTE(yeesian): The driver might only increase the reference counter of
    # the spatialref to take ownership, and not make a full copy. Therefore,
    # we need to enclose it within a do-block to be safe.
    f(FeatureLayer(GDAL.datasetcreatelayer(dataset.ptr, name,
        spref.ptr, geom, options), ownedby = dataset))
end

"""
Duplicate an existing layer.

This method creates a new layer, duplicate the field definitions of the source
layer and then duplicate each features of the source layer. The papszOptions
argument can be used to control driver specific creation options. These options
are normally documented in the format specific documentation. The source layer
may come from another dataset.

### Parameters
* `dataset`: the dataset handle.
* `layer`: source layer.
* `name`: the name of the layer to create.
* `papszOptions`: a StringList of name=value (driver-specific) options.
"""
function copylayer(
        dataset::AbstractDataset,
        layer::FeatureLayer,
        name::AbstractString;
        options = StringList(C_NULL)
    )
    FeatureLayer(
        GDAL.datasetcopylayer(dataset.ptr, layer.ptr, name, options),
        ownedby = dataset
    )
end

"""
Test if capability is available. TRUE if capability available otherwise FALSE.

One of the following dataset capability names can be passed into this function,
and a TRUE or FALSE value will be returned indicating whether or not the
capability is available for this object.

* `ODsCCreateLayer`: True if this datasource can create new layers.
* `ODsCDeleteLayer`: True if this datasource can delete existing layers.
* `ODsCCreateGeomFieldAfterCreateLayer`: True if the layers of this datasource
        support CreateGeomField() just after layer creation.
* `ODsCCurveGeometries`: True if this datasource supports curve geometries.
* `ODsCTransactions`: True if this datasource supports (efficient) transactions.
* `ODsCEmulatedTransactions`: True if this datasource supports transactions
        through emulation.

The #define macro forms of the capability names should be used in preference to
the strings themselves to avoid misspelling.

### Parameters
* `dataset`: the dataset handle.
* `capability`: the capability to test.
"""
testcapability(dataset::AbstractDataset, capability::AbstractString) =
    Bool(GDAL.datasettestcapability(dataset.ptr, capability))

function listcapability(
        dataset::AbstractDataset,
        capabilities = (GDAL.ODsCCreateLayer,
                        GDAL.ODsCDeleteLayer,
                        GDAL.ODsCCreateGeomFieldAfterCreateLayer, 
                        GDAL.ODsCCurveGeometries,
                        GDAL.ODsCTransactions,
                        GDAL.ODsCEmulatedTransactions)
    )
    Dict{String, Bool}(c => testcapability(dataset, c) for c in capabilities)
end

"""
Execute an SQL statement against the data store.

The result of an SQL query is either NULL for statements that are in error, or
that have no results set, or an OGRLayer pointer representing a results set from
the query. Note that this OGRLayer is in addition to the layers in the data
store and must be destroyed with ReleaseResultSet() before the dataset is closed
(destroyed).

For more information on the SQL dialect supported internally by OGR review the
OGR SQL document. Some drivers (i.e. Oracle and PostGIS) pass the SQL directly
through to the underlying RDBMS.

Starting with OGR 1.10, the SQLITE dialect can also be used.

### Parameters
* `dataset`: the dataset handle.
* `query`: the SQL statement to execute.
* `spatialfilter`: geometry which represents a spatial filter. Can be NULL.
* `dialect`: allows control of the statement dialect. If set to NULL, the
    OGR SQL engine will be used, except for RDBMS drivers that will use their
    dedicated SQL engine, unless OGRSQL is explicitly passed as the dialect.
    Starting with OGR 1.10, the SQLITE dialect can also be used.

### Returns
an OGRLayer containing the results of the query.
Deallocate with ReleaseResultSet().
"""
function unsafe_executesql(
        dataset::AbstractDataset,
        query::AbstractString;
        dialect::AbstractString = "",
        spatialfilter::Geometry = Geometry(GDALGeometry(C_NULL))
    )
    FeatureLayer(
        GDALFeatureLayer(GDAL.datasetexecutesql(
            dataset.ptr,
            query,
            spatialfilter.ptr,
            dialect
        )),
        ownedby = dataset
    )
end

"""
Release results of ExecuteSQL().

This function should only be used to deallocate OGRLayers resulting from an
ExecuteSQL() call on the same GDALDataset. Failure to deallocate a results set
before destroying the GDALDataset may cause errors.

### Parameters
* `dataset`: the dataset handle.
* `layer`: the result of a previous ExecuteSQL() call.
"""
function releaseresultset(dataset::AbstractDataset, layer::FeatureLayer)
    GDAL.datasetreleaseresultset(dataset.ptr, layer.ptr)
    layer.ptr = GDALFeatureLayer(C_NULL)
    layer.ownedby = Dataset()
end

"Fetch a band object for a dataset from its index"
getband(dataset::AbstractDataset, i::Integer) =
    RasterBand(GDAL.getrasterband(dataset.ptr, i), ownedby = dataset)

"""
Fetch the affine transformation coefficients.

Fetches the coefficients for transforming between pixel/line (P,L) raster
space, and projection coordinates (Xp,Yp) space.

```julia
   Xp = padfTransform[0] + P*padfTransform[1] + L*padfTransform[2];
   Yp = padfTransform[3] + P*padfTransform[4] + L*padfTransform[5];
```

In a north up image, `padfTransform[1]` is the pixel width, and
`padfTransform[5]` is the pixel height. The upper left corner of the upper left
pixel is at position `(padfTransform[0],padfTransform[3])`.

The default transform is `(0,1,0,0,0,1)` and should be returned even when a
`CE_Failure` error is returned, such as for formats that don't support
transformation to projection coordinates.

### Parameters
* `buffer`   a six double buffer into which the transformation will be placed.

### Returns
`CE_None` on success, or `CE_Failure` if no transform can be fetched.
"""
function getgeotransform!(dataset::AbstractDataset, transform::Vector{Cdouble})
    @assert length(transform) == 6
    result = GDAL.getgeotransform(dataset.ptr, pointer(transform))
    @cplerr result "Failed to get geotransform"
    transform
end

getgeotransform(dataset::AbstractDataset) =
    getgeotransform!(dataset, Array{Cdouble}(undef, 6))

"Set the affine transformation coefficients."
function setgeotransform!(dataset::AbstractDataset, transform::Vector{Cdouble})
    @assert length(transform) == 6
    result = GDAL.setgeotransform(dataset.ptr, pointer(transform))
    @cplerr result "Failed to transform raster dataset"
    dataset
end

"Get number of GCPs for this dataset. Zero if there are none."
ngcp(dataset::AbstractDataset) = GDAL.getgcpcount(dataset.ptr)

"""
Fetch the projection definition string for this dataset in OpenGIS WKT format.

It should be suitable for use with the OGRSpatialReference class. When a
projection definition is not available an empty (but not `NULL`) string is
returned.
"""
getproj(dataset::AbstractDataset) = GDAL.getprojectionref(dataset.ptr)

"Set the projection reference string for this dataset."
function setproj!(dataset::AbstractDataset, projstring::AbstractString)
    result = GDAL.setprojection(dataset.ptr, projstring)
    @cplerr result "Could not set projection"
    dataset
end

"""
Build raster overview(s).

If the operation is unsupported for the indicated dataset, then CE_Failure is
returned, and CPLGetLastErrorNo() will return CPLE_NotSupported.

### Parameters
* `overviewlist` overview decimation factors to build.

### Keyword Parameters
* `panBandList`  list of band numbers. Must be in Cint (default = all)
* `sampling`     one of "NEAREST" (default), "GAUSS","CUBIC","AVERAGE","MODE",
                 "AVERAGE_MAGPHASE" or "NONE" controlling the downsampling
                 method applied.
* `progressfunc` a function to call to report progress, or `NULL`.
* `progressdata` application data to pass to the progress function.
"""
function buildoverviews!(
        dataset::AbstractDataset,
        overviewlist::Vector{Cint};
        bandlist::Vector{Cint}     = Cint[],
        resampling::AbstractString = "NEAREST",
        progressfunc::Function     = GDAL.C.GDALDummyProgress,
        progressdata               = C_NULL
    )
    result = GDAL.buildoverviews(dataset.ptr, resampling, length(overviewlist),
        overviewlist, length(bandlist), bandlist, @cplprogress(progressfunc),
        progressdata)
    @cplerr result "Failed to build overviews"
    dataset
end

function destroy(dataset::AbstractDataset)
    GDAL.close(dataset.ptr)
    dataset.ptr = C_NULL
end
