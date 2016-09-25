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
        source::Dataset,
        dest::Dataset,
        options                 = StringList(C_NULL);
        progressfunc::Function  = GDAL.C.GDALDummyProgress,
        progressdata::Any       = C_NULL
    )
    result = @gdal(GDALDatasetCopyWholeRaster::GDAL.CPLErr,
        source.ptr::GDALDataset,
        dest.ptr::GDALDataset,
        options::StringList,
        @cplprogress(progressfunc)::GDALProgressFunc,
        progressdata::Ptr{Void}
    )
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
* `filename`      the name for the new dataset. UTF-8 encoded.
* `strict`        `TRUE` if the copy must be strictly equivelent, or more
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
        dataset::Dataset,
        filename::AbstractString,
        driver::Driver;
        strict::Bool            = false,
        options                 = StringList(C_NULL),
        progressfunc::Function  = GDAL.C.GDALDummyProgress,
        progressdata            = C_NULL
    )
    GDAL.checknull(dataset.ptr)
    result = GDAL.checknull(@gdal(GDALCreateCopy::GDALDataset,
        driver.ptr::GDALDriver,
        filename::Cstring,
        dataset.ptr::GDALDataset,
        strict::Cint,
        options::StringList,
        @cplprogress(progressfunc)::GDALProgressFunc,
        progressdata::Ptr{Void}
    ))
    Dataset(result)
end

function unsafe_createcopy(
        dataset::Dataset,
        filename::AbstractString,
        drivername::AbstractString;
        kwargs...
    )
    unsafe_createcopy(
        dataset,
        filename,
        getdriver(drivername);
        kwargs...
    )
end

function unsafe_createcopy(
        dataset::Dataset,
        filename::AbstractString;
        kwargs...
    )
    unsafe_createcopy(
        dataset,
        filename,
        getdriver(dataset);
        kwargs...
    )
end

function write(args...; kwargs...)
    destroy(unsafe_createcopy(args...; kwargs...))
end

"""
Create a new dataset with this driver.

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
        filename::AbstractString,
        driver::Driver;
        width::Integer  = 0,
        height::Integer = 0,
        nbands::Integer = 0,
        dtype::DataType = Any,
        options = StringList(C_NULL)
    )
    result = GDAL.checknull(@gdal(GDALCreate::GDALDataset,
        driver.ptr::GDALDriver,
        filename::Cstring,
        width::Cint,
        height::Cint,
        nbands::Cint,
        _GDALTYPE[dtype]::GDAL.GDALDataType,
        options::StringList
    ))
    Dataset(result)
end

function unsafe_create(
        filename::AbstractString,
        drivername::AbstractString;
        kwargs...
    )
    unsafe_create(
        filename,
        getdriver(drivername);
        kwargs...
    )
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
* # In order to reduce the need for searches through the operating system file
# system machinery, it is possible to give an optional list of files with the
# papszSiblingFiles parameter. This is the list of all files at the same level in
# the file system as the target file, including the target file. The filenames
# must not include any path components, are essentially just the output of
# VSIReadDir() on the parent directory. If the target object does not have
# filesystem semantics then the file list should be NULL.

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
    result = GDAL.checknull(@gdal(GDALOpenEx::GDALDataset,
        filename::Cstring,
        flags::UInt32,
        alloweddrivers::StringList,
        options::StringList,
        siblingfiles::StringList
    ))
    Dataset(result)
end

unsafe_update(filename::AbstractString; flags = OF_Update, kwargs...) =
    unsafe_read(filename; flags = OF_Update | flags, kwargs...)

"Fetch raster width in pixels."
width(dataset::Dataset) = GDAL.getrasterxsize(dataset.ptr)

"Fetch raster height in pixels."
height(dataset::Dataset) = GDAL.getrasterysize(dataset.ptr)

"Fetch the number of raster bands on this dataset."
nraster(dataset::Dataset) = GDAL.getrastercount(dataset.ptr)

"Fetch the number of feature layers on this dataset."
nlayer(dataset::Dataset) = GDAL.datasetgetlayercount(dataset.ptr)

"Fetch the driver that the dataset was created with"
getdriver(dataset::Dataset) = Driver(GDAL.getdatasetdriver(dataset.ptr))

"""
Fetch files forming dataset.

Returns a list of files believed to be part of this dataset. If it returns an
empty list of files it means there is believed to be no local file system files
associated with the dataset (for instance a virtual dataset). The returned file
list is owned by the caller and should be deallocated with `CSLDestroy()`.

The returned filenames will normally be relative or absolute paths depending on
the path used to originally open the dataset. The strings will be UTF-8 encoded
"""
function filelist(dataset::Dataset)
    unsafe_loadstringlist(@gdal(GDALGetFileList::Ptr{Cstring},
        dataset.ptr::GDALDataset
    ))
end

"""
Fetch the layer at index `i` (between `0` and `nlayer(dataset)-1`)

The returned layer remains owned by the GDALDataset and should not be deleted by
the application.
"""
getlayer(dataset::Dataset, i::Integer) =
    FeatureLayer(GDAL.datasetgetlayer(dataset.ptr, i))

"""
Fetch the feature layer corresponding to the given name.

The returned layer remains owned by the GDALDataset and should not be deleted by
the application.
"""
getlayer(dataset::Dataset, name::AbstractString) =
    FeatureLayer(GDAL.datasetgetlayerbyname(dataset.ptr, name))

"""
Delete the indicated layer (at index i; between `0` to `nlayer()-1`)

### Returns
`OGRERR_NONE` on success, or `OGRERR_UNSUPPORTED_OPERATION` if deleting layers
is not supported for this dataset.
"""
function deletelayer!(dataset::Dataset, i::Integer)
    result = GDAL.datasetdeletelayer(dataset.ptr, i)
    @ogrerr result "Failed to delete layer"
    dataset
end

"""
This function attempts to create a new layer on the dataset with the indicated
name, coordinate system, geometry type.

The papszOptions argument can be used to control driver specific creation
options. These options are normally documented in the format specific
documentation.

### Parameters
* `dataset`: the dataset
* `name`: the name for the new layer. This should ideally not match any
    existing layer on the datasource.

### Optional Parameters
* `spatialref`: the coordinate system to use for the new layer, or `NULL`
    (default) if no coordinate system is available.
* `geom`: the geometry type for the layer. Use wkbUnknown (default) if
    there are no constraints on the types geometry to be written.
* `options`: a StringList of name=value (driver-specific) options.
"""

function createlayer(
        dataset::Dataset,
        name::AbstractString;
        spatialref::SpatialRef      = SpatialRef(C_NULL),
        geom::OGRwkbGeometryType    = wkbUnknown,
        options                     = StringList(C_NULL)
    )
    result = GDAL.checknull(@gdal(GDALDatasetCreateLayer::GDALFeatureLayer,
        dataset.ptr::GDALDataset,
        name::Cstring,
        spatialref.ptr::GDALSpatialRef,
        geom::GDAL.OGRwkbGeometryType,
        options::StringList
    ))
    FeatureLayer(result)
end

"""
Duplicate an existing layer.

### Parameters
* `dataset`: the dataset handle.
* `layer`: source layer.
* `name`: the name of the layer to create.
* `papszOptions`: a StringList of name=value (driver-specific) options.
"""
function copylayer(
        dataset::Dataset,
        layer::FeatureLayer,
        name::AbstractString;
        options = StringList(C_NULL)
    )
    result = GDAL.checknull(@gdal(GDALDatasetCopyLayer::GDALFeatureLayer,
        dataset.ptr::GDALDataset,
        layer.ptr::GDALFeatureLayer,
        name::Cstring,
        options::StringList
    ))
    FeatureLayer(result)
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
testcapability(dataset::Dataset, capability::AbstractString) =
    Bool(GDAL.datasettestcapability(dataset.ptr, capability))


function listcapability(
        dataset::Dataset,
        capabilities = (GDAL.ODsCCreateLayer,
                        GDAL.ODsCDeleteLayer,
                        GDAL.ODsCCreateGeomFieldAfterCreateLayer, 
                        GDAL.ODsCCurveGeometries,
                        GDAL.ODsCTransactions,
                        GDAL.ODsCEmulatedTransactions)
    )
    Dict{String, Bool}([
        c => testcapability(dataset, c) for c in capabilities
    ])
end

# TODO use syntax below once v0.4 support is dropped (not in Compat.jl)
# listcapability(dataset::Dataset) = Dict(
#     c => testcapability(dataset,c) for c in
#     (GDAL.ODsCCreateLayer, GDAL.ODsCDeleteLayer,
#      GDAL.ODsCCreateGeomFieldAfterCreateLayer, GDAL.ODsCCurveGeometries,
#      GDAL.ODsCTransactions, GDAL.ODsCEmulatedTransactions)
# )


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
        dataset::Dataset,
        query::AbstractString;
        dialect::AbstractString = "",
        spatialfilter::Geometry = Geometry(C_NULL)
    )
    result = @gdal(GDALDatasetExecuteSQL::GDALFeatureLayer,
        dataset.ptr::GDALDataset,
        query::Cstring,
        spatialfilter.ptr::GDALGeometry,
        dialect::Cstring
    )
    FeatureLayer(result)
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
releaseresultset(dataset::Dataset, layer::FeatureLayer) =
    (GDAL.datasetreleaseresultset(dataset.ptr, layer.ptr); layer.ptr = C_NULL)

"Fetch a band object for a dataset from its index"
getband(dataset::Dataset, i::Integer) =
    RasterBand(GDAL.getrasterband(dataset.ptr, i))

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
function getgeotransform!(dataset::Dataset, transform::Vector{Cdouble})
    @assert length(transform) == 6
    result = GDAL.getgeotransform(dataset.ptr, pointer(transform))
    @cplerr result "Failed to get geotransform"
    transform
end

getgeotransform(dataset::Dataset) = getgeotransform!(dataset, Array(Cdouble, 6))

"Set the affine transformation coefficients."
function setgeotransform!(dataset::Dataset, transform::Vector{Cdouble})
    @assert length(transform) == 6
    result = GDAL.setgeotransform(dataset.ptr, pointer(transform))
    @cplerr result "Failed to transform raster dataset"
    dataset
end

"Get number of GCPs for this dataset. Zero if there are none."
ngcp(dataset::Dataset) = GDAL.getgcpcount(dataset.ptr)

"""
Fetch the projection definition string for this dataset in OpenGIS WKT format.

It should be suitable for use with the OGRSpatialReference class. When a
projection definition is not available an empty (but not `NULL`) string is
returned.
"""
getproj(dataset::Dataset) = GDAL.getprojectionref(dataset.ptr)

"Set the projection reference string for this dataset."
function setproj!(dataset::Dataset, projstring::AbstractString)
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
function buildoverviews!(dataset::Dataset,
                         overviewlist::Vector{Cint};
                         bandlist::Vector{Cint}     = Cint[],
                         resampling::AbstractString = "NEAREST",
                         progressfunc::Function     = GDAL.C.GDALDummyProgress,
                         progressdata               = C_NULL)
    result = @gdal(GDALBuildOverviews::GDAL.CPLErr,
        dataset.ptr::GDALDataset,
        resampling::Cstring,
        length(overviewlist)::Cint,
        overviewlist::Ptr{Cint},
        length(bandlist)::Cint,
        bandlist::Ptr{Cint},
        @cplprogress(progressfunc)::GDALProgressFunc,
        progressdata::Ptr{Void}
    )
    @cplerr result "Failed to build overviews"
    dataset
end

destroy(dataset::Dataset) = (GDAL.close(dataset.ptr); dataset.ptr = C_NULL)
