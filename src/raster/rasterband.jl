
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
function getblocksize(rb::RasterBand)
    xy = Array{Cint}(undef, 2); x = pointer(xy); y = x + sizeof(Cint)
    GDAL.getblocksize(rb.ptr, x, y)
    xy
end

"Fetch the pixel data type for this band."
getdatatype(rb::RasterBand) = _JLTYPE[GDAL.getrasterdatatype(rb.ptr)]

"Fetch the width in pixels of this band."
width(rb::RasterBand) = GDAL.getrasterbandxsize(rb.ptr)

"Fetch the height in pixels of this band."
height(rb::RasterBand) = GDAL.getrasterbandysize(rb.ptr)

"Find out if we have update permission for this band."
getaccess(rb::RasterBand) = GDAL.getrasteraccess(rb.ptr)

"""Fetch the band number (1+) within its dataset, or 0 if unknown.

This method may return a value of 0 to indicate overviews, or free-standing
`GDALRasterBand` objects without a relationship to a dataset.
"""
getnumber(rb::RasterBand) = GDAL.getbandnumber(rb.ptr)

"""
Fetch the handle to its dataset handle, or `NULL` if this cannot be determined.

Note that some `GDALRasterBands` are not considered to be a part of a dataset,
such as overviews or other "freestanding" bands.
"""
getdataset(rb::RasterBand) = Dataset(GDAL.getbanddataset(rb.ptr))
# ↑ GDAL wrapper checks null by default, but it is a valid result in this case

"""
Return a name for the units of this raster's values. For instance, it might be
"m" for an elevation model in meters, or "ft" for feet.
"""
getunittype(rb::RasterBand) = GDAL.getrasterunittype(rb.ptr)

"""
Set unit type of `rb` to `unittype`.

Values should be one of \"\" (the default indicating it is unknown), \"m\"
indicating meters, or \"ft\" indicating feet, though other nonstandard values
are allowed.
"""
function setunittype!(rb::RasterBand, unitstring::AbstractString)
    result = GDAL.setrasterunittype(rb.ptr, unitstring)
    @cplerr result "Failed to set unit type"
    rb
end

"""
Fetch the raster value offset.

This (in combination with `GetScale()`) is used to transform raw pixel values
into the units returned by `GetUnits()`. For e.g. this might be used to store
elevations in `GUInt16` bands with a precision of 0.1, starting from -100.

    Units value = (raw value * scale) + offset

For file formats that don't know this intrinsically, a value of 0 is returned.
"""
getoffset(rb::RasterBand) = GDAL.getrasteroffset(rb.ptr, C_NULL)

"Set scaling offset."
function setoffset!(rb::RasterBand, value::Real)
    result = GDAL.setrasteroffset(rb.ptr, value)
    @cplerr result "Failed to set scaling offset."
    rb
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
getscale(rb::RasterBand) = GDAL.getrasterscale(rb.ptr, C_NULL)

"Set scaling ratio."
function setscale!(rb::RasterBand, ratio::Real)
    result = GDAL.setrasterscale(rb.ptr, ratio)
    @cplerr result "Failed to set scaling ratio"
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
getnodatavalue(rb::RasterBand) = GDAL.getrasternodatavalue(rb.ptr, C_NULL)
# ↑ ### Parameters
# * `pbSuccess`   pointer to a boolean to use to indicate if a value is actually
# associated with this layer. May be `NULL` (default).

"Set the no data value for this band."
function setnodatavalue!(rb::RasterBand, value::Real)
    result = GDAL.setrasternodatavalue(rb.ptr, value)
    @cplerr result "Could not set nodatavalue"
    value
end

function deletenodatavalue!(rb::RasterBand)
    result = GDAL.deleterasternodatavalue(rb.ptr)
    @cplerr result "Could not delete nodatavalue"
end

"Set the category names for this band."
function setcategorynames!(rb::RasterBand, names)
    result = GDAL.setrastercategorynames(rb.ptr, names)
    @cplerr result "Failed to set category names"
end

"Fetch the minimum value for this band."
getminimum(rb::RasterBand) = GDAL.getrasterminimum(rb.ptr, C_NULL)

"Fetch the maximum value for this band."
getmaximum(rb::RasterBand) = GDAL.getrastermaximum(rb.ptr, C_NULL)

"Fetch default Raster Attribute Table."
getdefaultRAT(rb::RasterBand) = GDAL.getdefaultrat(rb.ptr)

"""
Set default Raster Attribute Table.

Associates a default RAT with the band. If not implemented for the format a
CPLE_NotSupported error will be issued. If successful a copy of the RAT is made,
the original remains owned by the caller.
"""
function setdefaultRAT!(rb::RasterBand, rat::RasterAttrTable)
    result = GDAL.setdefaultrat(rb.ptr, rat.ptr)
    @cplerr result "Failed to set default raster attribute table"
    rat
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
        source::RasterBand,
        dest::RasterBand;
        options                 = StringList(C_NULL),
        progressdata            = C_NULL,
        progressfunc::Function  = GDAL.C.GDALDummyProgress
    )
    result = GDAL.rasterbandcopywholeraster(source.ptr, dest.ptr, options,
        @cplprogress(progressfunc), progressdata)
    @cplerr result "Failed to copy whole raster"
end

"Return the number of overview layers available, zero if none."
noverview(rb::RasterBand) = GDAL.getoverviewcount(rb.ptr)

"Fetch overview raster band object."
getoverview(rb::RasterBand, i::Integer) =
    RasterBand(GDAL.getoverview(rb.ptr, i))

"""
Fetch best overview satisfying `nsamples` number of samples.

Returns the most reduced overview of the given band that still satisfies the
desired number of samples `nsamples`. This function can be used with zero as the
number of desired samples to fetch the most reduced overview. The same band as
was passed in will be returned if it has not overviews, or if none of the
overviews have enough samples.
"""
getsampleoverview(rb::RasterBand, nsamples::Integer) =
    RasterBand(GDAL.getrastersampleoverviewex(rb.ptr, UInt64(nsamples)))

"Color Interpretation value for band"
getcolorinterp(rb::RasterBand) = GDAL.getrastercolorinterpretation(rb.ptr)

"Set color interpretation of a band."
function setcolorinterp!(rb::RasterBand, color::GDALColorInterp)
    result = GDAL.setrastercolorinterpretation(rb.ptr, color)
    @cplerr result "Failed to set color interpretation"
    color
end

"""
Returns a clone of the color table associated with the band.

(If there is no associated color table, the original result is `NULL`. The
original color table remains owned by the `GDALRasterBand`, and can't be
depended on for long, nor should it ever be modified by the caller.)
"""
function unsafe_getcolortable(rb::RasterBand)
    result = ColorTable(GDALColorTable(GDAL.getrastercolortable(rb.ptr)))
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
function setcolortable!(rb::RasterBand, colortable::ColorTable)
    result = GDAL.setrastercolortable(rb.ptr, colortable.ptr)
    @cplwarn result "CPLError $(result): action is unsupported by the driver"
    colortable
end

function clearcolortable!(rb::RasterBand)
    result = GDAL.setrastercolortable(rb.ptr, GDALColorTable(C_NULL))
    @cplwarn result "CPLError $(result): action is unsupported by the driver"
end

"""
Generate downsampled overviews.

This function will generate one or more overview images from a base image using
the requested downsampling algorithm. Its primary use is for generating
overviews via BuildOverviews(), but it can also be used to generate downsampled
images in one file from another outside the overview architecture.

### Parameters
* `rb`              the source (base level) band.
* `overviewbands`   the list of downsampled bands to be generated.
* `resampling`      (optional) Resampling algorithm (eg. "AVERAGE").
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
        rb::RasterBand,
        overviewbands::Vector{RasterBand},
        resampling::AbstractString  = "NEAREST",
        progressfunc::Function      = GDAL.C.GDALDummyProgress,
        progressdata                = C_NULL
    )
    result = GDAL.regenerateoverviews(rb.ptr, length(overviewbands),
        GDALRasterBand[band.ptr for band in overviewbands], resampling,
        @cplprogress(progressfunc), progressdata)
    @cplerr result "Failed to regenerate overviews"
    result
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
getcategorynames(band::RasterBand) = GDAL.getrastercategorynames(band.ptr)

"Set the category names for this band."
function setcategorynames!(band::RasterBand, names::Vector{String})
    result = GDAL.setrastercategorynames(band.ptr, names)
    @cplerr result "Failed to set category names for this band"
    result
end

"""
Flush raster data cache.

This call will recover memory used to cache data blocks for this raster band,
and ensure that new requests are referred to the underlying driver.
"""
function flushcache!(band::RasterBand)
    result = GDAL.flushrastercache(band.ptr)
    @cplerr result "Failed to flush raster data cache"
    result
end

"""
Fill this band with a constant value.

GDAL makes no guarantees about what values pixels in newly created files are
set to, so this method can be used to clear a band to a specified "default"
value. The fill value is passed in as a double but this will be converted to
the underlying type before writing to the file. An optional second argument
allows the imaginary component of a complex constant value to be specified.

### Parameters
* `realvalue`         Real component of fill value
* `imagvalue`    Imaginary component of fill value, defaults to zero
"""
function fillraster!(band::RasterBand, realvalue::Real, imagvalue::Real = 0)
    result = GDAL.fillraster(band.ptr, realvalue, imagvalue)
    @cplerr result "Failed to fill raster band"
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
getmaskband(band::RasterBand) = RasterBand(GDAL.getmaskband(band.ptr))

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
getmaskflags(band::RasterBand) = GDAL.getmaskflags(band.ptr)

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
function createmaskband!(band::RasterBand, nflags::Integer)
    result = GDAL.createmaskband(band.ptr, nflags)
    @cplerr result "Failed to create mask band"
end
