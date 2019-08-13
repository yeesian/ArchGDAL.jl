"Throw an error if the pointer to int variable indicates an error."
function _failsafe(usage_error::Ref{Cint})
    # follows https://github.com/JuliaGeo/GDAL.jl/blob/017bf6b8492dcd2186ced297076b283c3591d798/src/error.jl#L31-L37
    if usage_error[] != 0 && GDAL.cplgetlasterrortype() in GDAL.throw_class
        throw(GDAL.GDALError())
    end
end

"""
List various information about a GDAL supported raster dataset.

### Parameters
* **dataset**: The source dataset.
* **options**: List of options (potentially including filename and open
    options). The accepted options are the ones of the gdalinfo utility.

### Returns
String corresponding to the information about the raster dataset.
"""
function gdalinfo(dataset::Dataset, options = String[])
    options = GDAL.gdalinfooptionsnew(options, C_NULL)
    result = GDAL.gdalinfo(dataset.ptr, options)
    GDAL.gdalinfooptionsfree(options)
    return result
end

"""
Convert raster data between different formats.

### Parameters
* **dataset**: The dataset to be translated.
* **options**: List of options (potentially including filename and open
    options). The accepted options are the ones of the gdal_translate utility.

### Returns
The output dataset.
"""
function unsafe_gdaltranslate(
        dataset::Dataset,
        options = String[];
        dest = "/vsimem/tmp"
    )
    options = GDAL.gdaltranslateoptionsnew(options, C_NULL)
    usage_error = Ref{Cint}()
    result = GDAL.gdaltranslate(dest, dataset.ptr, options, usage_error)
    GDAL.gdaltranslateoptionsfree(options)
    _failsafe(usage_error)
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
        options = String[];
        dest = "/vsimem/tmp"
    )
    options = GDAL.gdalwarpappoptionsnew(options, C_NULL)
    usage_error = Ref{Cint}()
    result = GDAL.gdalwarp(dest, Ptr{GDAL.GDALDatasetH}(C_NULL),
        length(datasets), [ds.ptr for ds in datasets], options, usage_error)
    GDAL.gdalwarpappoptionsfree(options)
    _failsafe(usage_error)
    return Dataset(result)
end

"""
Convert vector data between file formats.

### Parameters
* **datasets**: The list of input datasets (only 1 supported currently).
* **options**: List of options (potentially including filename and open
    options). The accepted options are the ones of the ogr2ogr utility.

### Returns
The output dataset.
"""
function unsafe_gdalvectortranslate(
        datasets::Vector{Dataset},
        options = String[];
        dest = "/vsimem/tmp"
    )
    options = GDAL.gdalvectortranslateoptionsnew(options, C_NULL)
    usage_error = Ref{Cint}()
    result = GDAL.gdalvectortranslate(dest, Ptr{GDAL.GDALDatasetH}(C_NULL),
        length(datasets), [ds.ptr for ds in datasets], options, usage_error)
    GDAL.gdalvectortranslateoptionsfree(options)
    _failsafe(usage_error)
    return Dataset(result)
end

"""
Tools to analyze and visualize DEMs.

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
        options = String[];
        dest = "/vsimem/tmp",
        colorfile = C_NULL
    )
    if processing == "color-relief"
        @assert colorfile != C_NULL
    end
    options = GDAL.gdaldemprocessingoptionsnew(options, C_NULL)
    usage_error = Ref{Cint}()
    result = GDAL.gdaldemprocessing(dest, dataset.ptr, processing, colorfile,
        options, usage_error)
    GDAL.gdaldemprocessingoptionsfree(options)
    _failsafe(usage_error)
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
        options = String[];
        dest = "/vsimem/tmp"
    )
    options = GDAL.gdalnearblackoptionsnew(options, C_NULL)
    usage_error = Ref{Cint}()
    result = GDAL.gdalnearblack(dest, Ptr{GDAL.GDALDatasetH}(C_NULL),
        dataset.ptr, options, usage_error)
    GDAL.gdalnearblackoptionsfree(options)
    _failsafe(usage_error)
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
        options = String[];
        dest = "/vsimem/tmp"
    )
    options = GDAL.gdalgridoptionsnew(options, C_NULL)
    usage_error = Ref{Cint}()
    result = GDAL.gdalgrid(dest, dataset.ptr, options, usage_error)
    GDAL.gdalgridoptionsfree(options)
    _failsafe(usage_error)
    return Dataset(result)
end

"""
Burn vector geometries into a raster.

### Parameters
* **dataset**: The source dataset.
* **options**: List of options (potentially including filename and open
    options). The accepted options are the ones of the gdal_rasterize utility.

### Returns
The output dataset.
"""
function unsafe_gdalrasterize(
        dataset::Dataset,
        options = String[];
        dest = "/vsimem/tmp"
    )
    options = GDAL.gdalrasterizeoptionsnew(options, C_NULL)
    usage_error = Ref{Cint}()
    result = GDAL.gdalrasterize(dest, C_NULL, dataset.ptr, options, usage_error)
    GDAL.gdalrasterizeoptionsfree(options)
    _failsafe(usage_error)
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
        options = String[];
        dest = "/vsimem/tmp"
    )
    options = GDAL.gdalbuildvrtoptionsnew(options, C_NULL)
    usage_error = Ref{Cint}()
    result = GDAL.gdalbuildvrt(dest, length(datasets),
        [ds.ptr for ds in datasets], C_NULL, options, usage_error)
    GDAL.gdalbuildvrtoptionsfree(options)
    _failsafe(usage_error)
    return Dataset(result)
end
