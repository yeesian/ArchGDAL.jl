
function destroy(band::AbstractRasterBand)
    band.ptr = GDALRasterBand(C_NULL)
    return band
end

function destroy(band::IRasterBand)
    band.ptr = GDALRasterBand(C_NULL)
    band.ownedby = Dataset()
    return band
end

"""
Fetch the "natural" block size of this band.

GDAL contains a concept of the natural block size of rasters so that
applications can organized data access efficiently for some file formats.
The natural block size is the block size that is most efficient for accessing
the format. For many formats this is simple a whole scanline in which case
`*pnXSize` is set to `GetXSize()`, and *pnYSize is set to 1.

However, for tiled images this will typically be the tile size.

Note that the X and Y block sizes don't have to divide the image size evenly,
meaning that right and bottom edge blocks may be incomplete. See `ReadBlock()`
for an example of code dealing with these issues.
"""
function blocksize(band::AbstractRasterBand)
    xy = Array{Cint}(undef, 2); x = pointer(xy); y = x + sizeof(Cint)
    GDAL.gdalgetblocksize(band.ptr, x, y)
    return xy
end

"Fetch the pixel data type for this band."
pixeltype(band::AbstractRasterBand) =
    _JLTYPE[GDAL.gdalgetrasterdatatype(band.ptr)]

"Fetch the width in pixels of this band."
width(band::AbstractRasterBand) = GDAL.gdalgetrasterbandxsize(band.ptr)

"Fetch the height in pixels of this band."
height(band::AbstractRasterBand) = GDAL.gdalgetrasterbandysize(band.ptr)

"Return the access flag (e.g. `OF_ReadOnly` or `OF_Update`) for this band."
accessflag(band::AbstractRasterBand) = GDAL.gdalgetrasteraccess(band.ptr)

"""
Fetch the band number (1+) within its dataset, or 0 if unknown.

This method may return a value of 0 to indicate overviews, or free-standing
`GDALRasterBand` objects without a relationship to a dataset.
"""
indexof(band::AbstractRasterBand) = GDAL.gdalgetbandnumber(band.ptr)

"""
Fetch the handle to its dataset handle, or `NULL` if this cannot be determined.

Note that some `RasterBand`s are not considered to be a part of a dataset,
such as overviews or other "freestanding" bands.
"""
getdataset(band::AbstractRasterBand) =
    Dataset(GDAL.gdalgetbanddataset(band.ptr))
# ↑ GDAL wrapper checks null by default, but it is a valid result in this case

"""
Return a name for the units of this raster's values. For instance, it might be
"m" for an elevation model in meters, or "ft" for feet.
"""
getunittype(band::AbstractRasterBand) = GDAL.gdalgetrasterunittype(band.ptr)

"""
Set unit type of `band` to `unittype`.

Values should be one of \"\" (the default indicating it is unknown), \"m\"
indicating meters, or \"ft\" indicating feet, though other nonstandard values
are allowed.
"""
function setunittype!(band::AbstractRasterBand, unitstring::AbstractString)
    result = GDAL.gdalsetrasterunittype(band.ptr, unitstring)
    @cplerr result "Failed to set unit type"
    return band
end

"""
Fetch the raster value offset.

This (in combination with `GetScale()`) is used to transform raw pixel values
into the units returned by `GetUnits()`. For e.g. this might be used to store
elevations in `GUInt16` bands with a precision of 0.1, starting from -100.

    Units value = (raw value * scale) + offset

For file formats that don't know this intrinsically, a value of 0 is returned.
"""
getoffset(band::AbstractRasterBand) = GDAL.gdalgetrasteroffset(band.ptr, C_NULL)

"Set scaling offset."
function setoffset!(band::AbstractRasterBand, value::Real)
    result = GDAL.gdalsetrasteroffset(band.ptr, value)
    @cplerr result "Failed to set scaling offset."
    return band
end

"""
Fetch the raster value scale.

This value (in combination with the `GetOffset()` value) is used to transform
raw pixel values into the units returned by `GetUnits()`. For example this
might be used to store elevations in GUInt16 bands with a precision of 0.1,
and starting from -100.

    Units value = (raw value * scale) + offset

For file formats that don't know this intrinsically a value of one is returned.
"""
getscale(band::AbstractRasterBand) = GDAL.gdalgetrasterscale(band.ptr, C_NULL)

"Set scaling ratio."
function setscale!(band::AbstractRasterBand, ratio::Real)
    result = GDAL.gdalsetrasterscale(band.ptr, ratio)
    @cplerr result "Failed to set scaling ratio"
    return band
end

"""
Fetch the no data value for this band.

If there is no out of data value, an out of range value will generally be
returned. The no data value for a band is generally a special marker value
used to mark pixels that are not valid data. Such pixels should generally
not be displayed, nor contribute to analysis operations.

### Returns
the nodata value for this band.
"""
function getnodatavalue(band::AbstractRasterBand)
    # ### Parameters
    # * `pbSuccess`   pointer to a boolean to use to indicate if a value is
    #     actually associated with this layer. May be `NULL` (default).
    return GDAL.gdalgetrasternodatavalue(band.ptr, C_NULL)
end

"Set the no data value for this band."
function setnodatavalue!(band::AbstractRasterBand, value::Real)
    result = GDAL.gdalsetrasternodatavalue(band.ptr, value)
    @cplerr result "Could not set nodatavalue"
    return band
end

function deletenodatavalue!(band::AbstractRasterBand)
    result = GDAL.gdaldeleterasternodatavalue(band.ptr)
    @cplerr result "Could not delete nodatavalue"
    return band
end

"Set the category names for this band."
function setcategorynames!(band::AbstractRasterBand, names)
    result = GDAL.gdalsetrastercategorynames(band.ptr, names)
    @cplerr result "Failed to set category names"
    return band
end

"Fetch the minimum value for this band."
minimum(band::AbstractRasterBand) = GDAL.gdalgetrasterminimum(band.ptr, C_NULL)

"Fetch the maximum value for this band."
maximum(band::AbstractRasterBand) = GDAL.gdalgetrastermaximum(band.ptr, C_NULL)

"Fetch default Raster Attribute Table."
getdefaultRAT(band::AbstractRasterBand) = GDAL.gdalgetdefaultrat(band.ptr)

"""
Set default Raster Attribute Table.

Associates a default RAT with the band. If not implemented for the format a
CPLE_NotSupported error will be issued. If successful a copy of the RAT is made,
the original remains owned by the caller.
"""
function setdefaultRAT!(band::AbstractRasterBand, rat::RasterAttrTable)
    result = GDAL.gdalsetdefaultrat(band.ptr, rat.ptr)
    @cplerr result "Failed to set default raster attribute table"
    return band
end

"""
Copy all raster band raster data.

This function copies the complete raster contents of one band to another
similarly configured band. The source and destination bands must have the same
width and height. The bands do not have to have the same data type.

It implements efficient copying, in particular "chunking" the copy in
substantial blocks.

Currently the only `options` value supported is : "COMPRESSED=YES" to
force alignment on target dataset block sizes to achieve best compression.
More options may be supported in the future.

### Parameters
* `source`        the source band
* `dest`          the destination band
* `options`       transfer hints in "StringList" Name=Value format.
* `progressfunc`  progress reporting function.
* `progressdata`  callback data for progress function.
"""
function copywholeraster!(
        source::AbstractRasterBand,
        dest::AbstractRasterBand;
        options                 = StringList(C_NULL),
        progressdata            = C_NULL,
        progressfunc::Function  = GDAL.gdaldummyprogress
    )
    result = GDAL.gdalrasterbandcopywholeraster(source.ptr, dest.ptr, options,
        @cplprogress(progressfunc), progressdata)
    @cplerr result "Failed to copy whole raster"
    return source
end

"Return the number of overview layers available, zero if none."
noverview(band::AbstractRasterBand) = GDAL.gdalgetoverviewcount(band.ptr)

"Fetch overview raster band object."
getoverview(band::IRasterBand, i::Integer) =
    IRasterBand(GDAL.gdalgetoverview(band.ptr, i), ownedby = band.ownedby)

unsafe_getoverview(band::AbstractRasterBand, i::Integer) =
    RasterBand(GDAL.gdalgetoverview(band.ptr, i))

"""
Fetch best overview satisfying `nsamples` number of samples.

Returns the most reduced overview of the given band that still satisfies the
desired number of samples `nsamples`. This function can be used with zero as the
number of desired samples to fetch the most reduced overview. The same band as
was passed in will be returned if it has not overviews, or if none of the
overviews have enough samples.
"""
function sampleoverview(band::IRasterBand, nsamples::Integer)
    return IRasterBand(
        GDAL.gdalgetrastersampleoverviewex(band.ptr, UInt64(nsamples)),
        ownedby = band.ownedby
    )
end

unsafe_sampleoverview(band::AbstractRasterBand, nsamples::Integer) =
    RasterBand(GDAL.gdalgetrastersampleoverviewex(band.ptr, UInt64(nsamples)))

"Color Interpretation value for band"
getcolorinterp(band::AbstractRasterBand) =
    GDAL.gdalgetrastercolorinterpretation(band.ptr)

"Set color interpretation of a band."
function setcolorinterp!(band::AbstractRasterBand, color::GDALColorInterp)
    result = GDAL.gdalsetrastercolorinterpretation(band.ptr, color)
    @cplerr result "Failed to set color interpretation"
    return band
end

"""
Returns a clone of the color table associated with the band.

(If there is no associated color table, the original result is `NULL`. The
original color table remains owned by the `GDALRasterBand`, and can't be
depended on for long, nor should it ever be modified by the caller.)
"""
function unsafe_getcolortable(band::AbstractRasterBand)
    result = ColorTable(GDALColorTable(GDAL.gdalgetrastercolortable(band.ptr)))
    if result.ptr == C_NULL
        return result
    else
        return unsafe_clone(result)
    end
end

"""
Set the raster color table.

The driver will make a copy of all desired data in the colortable. It remains
owned by the caller after the call.

### Parameters
* `colortable` color table to apply (where supported).
"""
function setcolortable!(band::AbstractRasterBand, colortable::ColorTable)
    result = GDAL.gdalsetrastercolortable(band.ptr, colortable.ptr)
    @cplwarn result "CPLError $(result): action is unsupported by the driver"
    return band
end

function clearcolortable!(band::AbstractRasterBand)
    result = GDAL.gdalsetrastercolortable(band.ptr, GDALColorTable(C_NULL))
    @cplwarn result "CPLError $(result): action is unsupported by the driver"
    return band
end

"""
Generate downsampled overviews.

This function will generate one or more overview images from a base image using
the requested downsampling algorithm. Its primary use is for generating
overviews via BuildOverviews(), but it can also be used to generate downsampled
images in one file from another outside the overview architecture.

### Parameters
* `band`              the source (base level) band.
* `overviewbands`   the list of downsampled bands to be generated.

### Keyword Arguments
* `resampling`      (optional) Resampling algorithm (eg. "AVERAGE"). default to
                    "NEAREST".
* `progressfunc`    (optional) progress report function.
* `progressdata`    (optional) progress function callback data.

### Additional Remarks
The output bands need to exist in advance.

This function will honour properly `NODATA_VALUES` tuples (special dataset
metadata) so that only a given RGB triplet (in case of a RGB image) will be
considered as the nodata value and not each value of the triplet independantly
per band.
"""
function regenerateoverviews!(
        band::AbstractRasterBand,
        overviewbands::Vector{<:AbstractRasterBand},
        resampling::AbstractString  = "NEAREST",
        # progressfunc::Function      = GDAL.gdaldummyprogress,
        progressdata                = C_NULL
    )
    cfunc = @cfunction(GDAL.gdaldummyprogress, Cint,
        (Cdouble, Cstring, Ptr{Cvoid}))
    result = GDAL.gdalregenerateoverviews(
        band.ptr,
        length(overviewbands),
        GDALRasterBand[band.ptr for band in overviewbands],
        resampling,
        cfunc,
        progressdata
    )
    @cplerr result "Failed to regenerate overviews"
    return band
end

# "Advise driver of upcoming read requests."
# _rasteradviseread(hRB::GDALRasterBandH,
#                   nDSXOff::Integer,
#                   nDSYOff::Integer,
#                   nDSXSize::Integer,
#                   nDSYSize::Integer,
#                   nBXSize::Integer,
#                   nBYSize::Integer,
#                   eBDataType::GDALDataType,
#                   papszOptions::Ptr{Cstring}) =
#     GDALRasterAdviseRead(hRB, nDSXOff, nDSYOff, nDSXSize, nDSYSize, nBXSize,
#                          nBYSize, eBDataType, papszOptions)::CPLErr

"""
Fetch the list of category names for this raster.

The return list is a "StringList" in the sense of the CPL functions. That is a
NULL terminated array of strings. Raster values without associated names will
have an empty string in the returned list. The first entry in the list is for
raster values of zero, and so on.
"""
getcategorynames(band::AbstractRasterBand) =
    GDAL.gdalgetrastercategorynames(band.ptr)

"Set the category names for this band."
function setcategorynames!(band::AbstractRasterBand, names::Vector{String})
    result = GDAL.gdalsetrastercategorynames(band.ptr, names)
    @cplerr result "Failed to set category names for this band"
    return band
end

# """
# Flush raster data cache.

# This call will recover memory used to cache data blocks for this raster band,
# and ensure that new requests are referred to the underlying driver.
# """
# function flushcache!(band::AbstractRasterBand)
#     result = GDAL.flushrastercache(band.ptr)
#     @cplerr result "Failed to flush raster data cache"
#     result
# end

"""
Fill this band with a constant value.

GDAL makes no guarantees about what values pixels in newly created files are
set to, so this method can be used to clear a band to a specified "default"
value. The fill value is passed in as a double but this will be converted to
the underlying type before writing to the file. An optional second argument
allows the imaginary component of a complex constant value to be specified.

### Parameters
* `realvalue`: Real component of fill value
* `imagvalue`: Imaginary component of fill value, defaults to zero
"""
function fillraster!(
        band::AbstractRasterBand,
        realvalue::Real,
        imagvalue::Real = 0
    )
    result = GDAL.gdalfillraster(band.ptr, realvalue, imagvalue)
    @cplerr result "Failed to fill raster band"
    return band
end

"""
Return the mask band associated with the band.

The `GDALRasterBand` class includes a default implementation of `GetMaskBand()`
that returns one of four default implementations:

- If a corresponding .msk file exists it will be used for the mask band.
- If the dataset has a `NODATA_VALUES` metadata item, an instance of the new
GDALNoDataValuesMaskBand class will be returned. `GetMaskFlags()` will return
`GMF_NODATA | GMF_PER_DATASET`.
- If the band has a nodata value set, an instance of the new
`GDALNodataMaskRasterBand` class will be returned. `GetMaskFlags()` will
return `GMF_NODATA`.
- If there is no nodata value, but the dataset has an alpha band that seems to
apply to this band (specific rules yet to be determined) and that is of type
`GDT_Byte` then that alpha band will be returned, and the flags
`GMF_PER_DATASET` and `GMF_ALPHA` will be returned in the flags.
- If neither of the above apply, an instance of the new
`GDALAllValidRasterBand` class will be returned that has 255 values for all
pixels. The null flags will return `GMF_ALL_VALID`.

Note that the `GetMaskBand()` should always return a `GDALRasterBand` mask,
even if it is only an all 255 mask with the flags indicating `GMF_ALL_VALID`.

See also: http://trac.osgeo.org/gdal/wiki/rfc15_nodatabitmask

### Returns
a valid mask band.
"""
getmaskband(band::IRasterBand) = 
    IRasterBand(GDAL.gdalgetmaskband(band.ptr), ownedby = band.ownedby)

unsafe_getmaskband(band::AbstractRasterBand) = 
    RasterBand(GDAL.gdalgetmaskband(band.ptr))

"""
Return the status flags of the mask band associated with the band.

The GetMaskFlags() method returns an bitwise OR-ed set of status flags with the
following available definitions that may be extended in the future:

* `GMF_ALL_VALID` (`0x01`):    There are no invalid pixels, all mask values
will be 255. When used this will normally be the only flag set.
* `GMF_PER_DATASET` (`0x02`):  The mask band is shared between all bands on
the dataset.
- `GMF_ALPHA` (`0x04`):        The mask band is actually an alpha band and may
have values other than 0 and 255.
- `GMF_NODATA` (`0x08`):       Indicates the mask is actually being generated
from nodata values. (mutually exclusive of `GMF_ALPHA`)

The `GDALRasterBand` class includes a default implementation of `GetMaskBand()`
that returns one of four default implementations:

- If a corresponding .msk file exists it will be used for the mask band.
- If the dataset has a `NODATA_VALUES` metadata item, an instance of the new
`GDALNoDataValuesMaskBand` class will be returned. `GetMaskFlags()` will return
`GMF_NODATA | GMF_PER_DATASET`.
- If the band has a nodata value set, an instance of the new
`GDALNodataMaskRasterBand` class will be returned. `GetMaskFlags()` will return
`GMF_NODATA`.
- If there is no nodata value, but the dataset has an alpha band that seems to
apply to this band (specific rules yet to be determined) and that is of type
`GDT_Byte` then that alpha band will be returned, and the flags
`GMF_PER_DATASET` and `GMF_ALPHA` will be returned in the flags.
- If neither of the above apply, an instance of the new `GDALAllValidRasterBand`
class will be returned that has 255 values for all pixels. The null flags will
return `GMF_ALL_VALID`.

See also: http://trac.osgeo.org/gdal/wiki/rfc15_nodatabitmask

### Returns
a valid mask band.
"""
maskflags(band::AbstractRasterBand) = GDAL.gdalgetmaskflags(band.ptr)

"""
Adds a mask band to the current band.

The default implementation of the `CreateMaskBand()` method is implemented
based on similar rules to the `.ovr` handling implemented using the
`GDALDefaultOverviews` object. A `TIFF` file with the extension `.msk` will be
created with the same basename as the original file, and it will have as many
bands as the original image (or just one for `GMF_PER_DATASET`). The mask
images will be deflate compressed tiled images with the same block size as the
original image if possible.

If you got a mask band with a previous call to `GetMaskBand()`, it might be
invalidated by `CreateMaskBand()`. So you have to call `GetMaskBand()` again.

See also: http://trac.osgeo.org/gdal/wiki/rfc15_nodatabitmask
"""
function createmaskband!(band::AbstractRasterBand, nflags::Integer)
    result = GDAL.gdalcreatemaskband(band.ptr, nflags)
    @cplerr result "Failed to create mask band"
    return band
end
