"""
Lists various information about a GDAL supported raster dataset.

### Parameters
* **dataset**: The source dataset.
* **options**: List of options (potentially including filename and open
    options). The accepted options are the ones of the gdalinfo utility.

### Returns
String corresponding to the information about the raster dataset.
"""
function gdalinfo(dataset::Dataset, options = [])
    options = GDAL.infooptionsnew(options, C_NULL)
    result = GDAL.info(dataset.ptr, options)
    GDAL.infooptionsfree(options)
    return result
end

"""
Converts raster data between different formats.

### Parameters
* **dataset**: The dataset to be translated.
* **options**: List of options (potentially including filename and open
    options). The accepted options are the ones of the gdal_translate utility.

### Returns
The output dataset.
"""
function unsafe_gdaltranslate(
        dataset::Dataset,
        options = [];
        dest = "/vsimem/tmp"
    )
    options = GDAL.translateoptionsnew(options, C_NULL)
    usage_error = Ref{Cint}()
    result = GDAL.translate(dest, dataset.ptr, options, usage_error)
    # TODO: check usage_error
    GDAL.translateoptionsfree(options)
    return Dataset(result)
end

"""
Image reprojection and warping function.

### Parameters
* **datasets**: The list of input datasets.
* **options**: List of options (potentially including filename and open
    options). The accepted options are the ones of the gdalwarp utility.

### Returns
The output dataset.
"""
function unsafe_gdalwarp(
        datasets::Vector{Dataset},
        options = [];
        dest = "/vsimem/tmp"
    )
    options = GDAL.warpappoptionsnew(options, C_NULL)
    usage_error = Ref{Cint}()
    result = GDAL.warp(dest, Ptr{GDAL.GDALDatasetH}(C_NULL), length(datasets),
        [ds.ptr for ds in datasets], options, usage_error)
    # TODO: check usage_error
    GDAL.warpappoptionsfree(options)
    return Dataset(result)
end

"""
Converts vector data between file formats.

### Parameters
* **datasets**: The list of input datasets (only 1 supported currently).
* **options**: List of options (potentially including filename and open
    options). The accepted options are the ones of the ogr2ogr utility.

### Returns
The output dataset.
"""
function unsafe_gdalvectortranslate(
        datasets::Vector{Dataset},
        options = [];
        dest = "/vsimem/tmp"
    )
    options = GDAL.vectortranslateoptionsnew(options, C_NULL)
    usage_error = Ref{Cint}()
    result = GDAL.vectortranslate(dest, Ptr{GDAL.GDALDatasetH}(C_NULL),
        length(datasets), [ds.ptr for ds in datasets], options, usage_error)
    # TODO: check usage_error
    GDAL.vectortranslateoptionsfree(options)
    return Dataset(result)
end

"""
Converts vector data between file formats.

### Parameters
* **dataset**: The source dataset.
* **pszProcessing**: the processing to apply (one of "hillshade", "slope",
    "aspect", "color-relief", "TRI", "TPI", "Roughness").
* **options**: List of options (potentially including filename and open
    options). The accepted options are the ones of the gdaldem utility.

# Keyword Arguments
* **colorfile**: color file (mandatory for "color-relief" processing,
    should be empty otherwise).

### Returns
The output dataset.
"""
function unsafe_gdaldem(
        dataset::Dataset,
        processing::String,
        options = [];
        dest = "/vsimem/tmp",
        colorfile = C_NULL
    )
    options = GDAL.demprocessingoptionsnew(options, C_NULL)
    usage_error = Ref{Cint}()
    if processing == "color-relief"
        @assert colorfile != C_NULL
    end
    result = GDAL.demprocessing(dest, dataset.ptr, processing, colorfile,
        options, usage_error)
    # TODO: check usage_error
    GDAL.demprocessingoptionsfree(options)
    return Dataset(result)
end

"""
Convert nearly black/white borders to exact value.

### Parameters
* **dataset**: The source dataset.
* **options**: List of options (potentially including filename and open
    options). The accepted options are the ones of the nearblack utility.

### Returns
The output dataset.
"""
function unsafe_gdalnearblack(
        dataset::Dataset,
        options = [];
        dest = "/vsimem/tmp"
    )
    options = GDAL.nearblackoptionsnew(options, C_NULL)
    usage_error = Ref{Cint}()
    result = GDAL.nearblack(dest, Ptr{GDAL.GDALDatasetH}(C_NULL), dataset.ptr,
        options, usage_error)
    # TODO: check usage_error
    GDAL.nearblackoptionsfree(options)
    return Dataset(result)
end

"""
Create a raster from the scattered data.

### Parameters
* **dataset**: The source dataset.
* **options**: List of options (potentially including filename and open
    options). The accepted options are the ones of the gdal_grid utility.

### Returns
The output dataset.
"""
function unsafe_gdalgrid(
        dataset::Dataset,
        options = [];
        dest = "/vsimem/tmp"
    )
    options = GDAL.gridoptionsnew(options, C_NULL)
    usage_error = Ref{Cint}()
    result = GDAL.grid(dest, dataset.ptr, options, usage_error)
    # TODO: check usage_error
    GDAL.gridoptionsfree(options)
    return Dataset(result)
end

"""
Burns vector geometries into a raster.

### Parameters
* **dataset**: The source dataset.
* **options**: List of options (potentially including filename and open
    options). The accepted options are the ones of the gdal_rasterize utility.

### Returns
The output dataset.
"""
function unsafe_gdalrasterize(
        dataset::Dataset,
        options = [];
        dest = "/vsimem/tmp"
    )
    options = GDAL.rasterizeoptionsnew(options, C_NULL)
    usage_error = Ref{Cint}()
    result = GDAL.rasterize(dest, Ptr{GDAL.GDALDatasetH}(C_NULL), dataset.ptr,
        options, usage_error)
    # TODO: check usage_error
    GDAL.rasterizeoptionsfree(options)
    return Dataset(result)
end

"""
Build a VRT from a list of datasets.

### Parameters
* **datasets**: The list of input datasets.
* **options**: List of options (potentially including filename and open
    options). The accepted options are the ones of the gdalbuildvrt utility.

### Returns
The output dataset.
"""
function unsafe_gdalbuildvrt(
        datasets::Vector{Dataset},
        options = [];
        dest = "/vsimem/tmp"
    )
    options = GDAL.buildvrtoptionsnew(options, C_NULL)
    usage_error = Ref{Cint}()
    result = GDAL.buildvrt(dest, length(datasets), [ds.ptr for ds in datasets],
        C_NULL, options, usage_error)
    # TODO: check usage_error
    GDAL.buildvrtoptionsfree(options)
    return Dataset(result)
end
