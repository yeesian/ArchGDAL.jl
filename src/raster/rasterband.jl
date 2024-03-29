
function destroy(band::AbstractRasterBand)::Nothing
    band.ptr = C_NULL
    return nothing
end

function destroy(band::IRasterBand)::Nothing
    band.ptr = C_NULL
    band.ownedby = Dataset()
    return nothing
end

"""
    blocksize(band::AbstractRasterBand)

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
function blocksize(band::AbstractRasterBand)::Vector{Cint}
    xy = Vector{Cint}(undef, 2)
    x = pointer(xy)
    y = x + sizeof(Cint)
    GDAL.gdalgetblocksize(band, x, y)
    return xy
end

"""
    pixeltype(band::AbstractRasterBand)

Fetch the pixel data type for this band.
"""
function pixeltype(band::AbstractRasterBand{T})::DataType where {T<:Any}
    return T
end

"""
    width(band::AbstractRasterBand)

Fetch the width in pixels of this band.
"""
width(band::AbstractRasterBand)::Integer = GDAL.gdalgetrasterbandxsize(band)

"""
    height(band::AbstractRasterBand)

Fetch the height in pixels of this band.
"""
height(band::AbstractRasterBand)::Integer = GDAL.gdalgetrasterbandysize(band)

"""
    accessflag(band::AbstractRasterBand)

Return the access flag (e.g. `OF_READONLY` or `OF_UPDATE`) for this band.
"""
accessflag(band::AbstractRasterBand)::GDALAccess =
    GDAL.gdalgetrasteraccess(band)

"""
    indexof(band::AbstractRasterBand)

Fetch the band number (1+) within its dataset, or 0 if unknown.

This method may return a value of 0 to indicate overviews, or free-standing
`RasterBand` objects without a relationship to a dataset.
"""
indexof(band::AbstractRasterBand)::Integer = GDAL.gdalgetbandnumber(band)

"""
    getdataset(band::AbstractRasterBand)

Fetch the handle to its dataset handle, or `NULL` if this cannot be determined.

Note that some `RasterBand`s are not considered to be a part of a dataset,
such as overviews or other "freestanding" bands.
"""
getdataset(band::AbstractRasterBand)::Dataset =
    Dataset(GDAL.gdalgetbanddataset(band))
# ↑ GDAL wrapper checks null by default, but it is a valid result in this case

"""
    getunittype(band::AbstractRasterBand)

Return a name for the units of this raster's values. For instance, it might be
"m" for an elevation model in meters, or "ft" for feet.
"""
getunittype(band::AbstractRasterBand)::String = GDAL.gdalgetrasterunittype(band)

"""
    setunittype!(band::AbstractRasterBand, unitstring::AbstractString)

Set unit type of `band` to `unittype`.

Values should be one of \"\" (the default indicating it is unknown), \"m\"
indicating meters, or \"ft\" indicating feet, though other nonstandard values
are allowed.
"""
function setunittype!(
    band::T,
    unitstring::AbstractString,
)::T where {T<:AbstractRasterBand}
    result = GDAL.gdalsetrasterunittype(band, unitstring)
    @cplerr result "Failed to set unit type"
    return band
end

"""
    getoffset(band::AbstractRasterBand)

Fetch the raster value offset.

This (in combination with `GetScale()`) is used to transform raw pixel values
into the units returned by `GetUnits()`. For e.g. this might be used to store
elevations in `GUInt16` bands with a precision of 0.1, starting from -100.

    Units value = (raw value * scale) + offset

For file formats that don't know this intrinsically, a value of 0 is returned.
"""
getoffset(band::AbstractRasterBand)::Real =
    GDAL.gdalgetrasteroffset(band, C_NULL)

"""
    setoffset!(band::AbstractRasterBand, value::Real)

Set scaling offset.
"""
function setoffset!(band::T, value::Real)::T where {T<:AbstractRasterBand}
    result = GDAL.gdalsetrasteroffset(band, value)
    @cplerr result "Failed to set scaling offset."
    return band
end

"""
    getscale(band::AbstractRasterBand)

Fetch the raster value scale.

This value (in combination with the `GetOffset()` value) is used to transform
raw pixel values into the units returned by `GetUnits()`. For example this
might be used to store elevations in GUInt16 bands with a precision of 0.1,
and starting from -100.

    Units value = (raw value * scale) + offset

For file formats that don't know this intrinsically a value of one is returned.
"""
getscale(band::AbstractRasterBand)::Real = GDAL.gdalgetrasterscale(band, C_NULL)

"""
    setscale!(band::AbstractRasterBand, ratio::Real)

Set scaling ratio.
"""
function setscale!(band::T, ratio::Real)::T where {T<:AbstractRasterBand}
    result = GDAL.gdalsetrasterscale(band, ratio)
    @cplerr result "Failed to set scaling ratio"
    return band
end

"""
    getnodatavalue(band::AbstractRasterBand)

Fetch the no data value for this band.

If there is no out of data value, `nothing` will be returned instead. The no
data value for a band is generally a special marker value used to mark pixels
that are not valid data. Such pixels should generally not be displayed, nor
contribute to analysis operations.

### Returns
the nodata value for this band or `nothing`.
"""
function getnodatavalue(band::AbstractRasterBand)::Union{Float64,Nothing}
    # ### Parameters
    # * `pbSuccess`   pointer to a boolean to use to indicate if a value is
    #     actually associated with this layer. May be `NULL` (default).
    hasnodatavalue = Ref(Cint(0))
    nodatavalue = GDAL.gdalgetrasternodatavalue(band, hasnodatavalue)
    return if Bool(hasnodatavalue[])
        nodatavalue
    else
        nothing
    end
end

"""
    setnodatavalue!(band::AbstractRasterBand, value::Real)

Set the no data value for this band.
"""
function setnodatavalue!(band::T, value::Real)::T where {T<:AbstractRasterBand}
    result = GDAL.gdalsetrasternodatavalue(band, value)
    @cplerr result "Could not set nodatavalue"
    return band
end

function deletenodatavalue!(band::T)::T where {T<:AbstractRasterBand}
    result = GDAL.gdaldeleterasternodatavalue(band)
    @cplerr result "Could not delete nodatavalue"
    return band
end

"""
    minimum(band::AbstractRasterBand)

Fetch the minimum value for this band.
"""
minimum(band::AbstractRasterBand)::Real =
    GDAL.gdalgetrasterminimum(band, C_NULL)

"""
    maximum(band::AbstractRasterBand)

Fetch the maximum value for this band.
"""
maximum(band::AbstractRasterBand)::Real =
    GDAL.gdalgetrastermaximum(band, C_NULL)

"""
    getdefaultRAT(band::AbstractRasterBand)

A RAT will be returned if there is a default one associated with the band,
otherwise NULL is returned. The returned RAT is owned by the band and should not
be deleted by the application.
"""
getdefaultRAT(band::AbstractRasterBand)::RasterAttrTable =
    RasterAttrTable(GDAL.gdalgetdefaultrat(band))

"""
    setdefaultRAT!(band::AbstractRasterBand, rat::RasterAttrTable)

Set default Raster Attribute Table.

Associates a default RAT with the band. If not implemented for the format a
CPLE_NotSupported error will be issued. If successful a copy of the RAT is made,
the original remains owned by the caller.
"""
function setdefaultRAT!(
    band::T,
    rat::RasterAttrTable,
)::T where {T<:AbstractRasterBand}
    result = GDAL.gdalsetdefaultrat(band, rat)
    @cplerr result "Failed to set default raster attribute table"
    return band
end

"""
    copywholeraster!( source::AbstractRasterBand, dest::AbstractRasterBand;
        [options, [progressfunc]])

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
* `progressfunc`  a function(::Float64, ::String)::Bool to call to report progress
"""
function copywholeraster!(
    source::T,
    dest::AbstractRasterBand;
    options = StringList(C_NULL),
    progressfunc::Function = _dummyprogress,
)::T where {T<:AbstractRasterBand}
    result = GDAL.gdalrasterbandcopywholeraster(
        source,
        dest,
        options,
        @cfunction(_progresscallback, Cint, (Cdouble, Cstring, Ptr{Cvoid})),
        progressfunc,
    )
    @cplerr result "Failed to copy whole raster"
    return source
end

"""
    noverview(band::AbstractRasterBand)

Return the number of overview layers available, zero if none.
"""
noverview(band::AbstractRasterBand)::Integer = GDAL.gdalgetoverviewcount(band)

"""
    getoverview(band::IRasterBand, i::Integer)

Fetch overview raster band object.
"""
getoverview(band::IRasterBand, i::Integer)::IRasterBand =
    IRasterBand(GDAL.gdalgetoverview(band, i), ownedby = band.ownedby)

unsafe_getoverview(band::AbstractRasterBand, i::Integer)::RasterBand =
    RasterBand(GDAL.gdalgetoverview(band, i))

"""
    sampleoverview(band::IRasterBand, nsamples::Integer)

Fetch best overview satisfying `nsamples` number of samples.

Returns the most reduced overview of the given band that still satisfies the
desired number of samples `nsamples`. This function can be used with zero as the
number of desired samples to fetch the most reduced overview. The same band as
was passed in will be returned if it has not overviews, or if none of the
overviews have enough samples.
"""
function sampleoverview(band::IRasterBand, nsamples::Integer)::IRasterBand
    return IRasterBand(
        GDAL.gdalgetrastersampleoverviewex(band, UInt64(nsamples)),
        ownedby = band.ownedby,
    )
end

unsafe_sampleoverview(band::AbstractRasterBand, nsamples::Integer)::RasterBand =
    RasterBand(GDAL.gdalgetrastersampleoverviewex(band, UInt64(nsamples)))

"""
    getcolorinterp(band::AbstractRasterBand)

Color Interpretation value for band
"""
getcolorinterp(band::AbstractRasterBand)::GDALColorInterp =
    GDAL.gdalgetrastercolorinterpretation(band)

"""
    setcolorinterp!(band::AbstractRasterBand, color::GDALColorInterp)

Set color interpretation of a band.
"""
function setcolorinterp!(
    band::T,
    color::GDALColorInterp,
)::T where {T<:AbstractRasterBand}
    result = GDAL.gdalsetrastercolorinterpretation(band, color)
    @cplerr result "Failed to set color interpretation"
    return band
end

"""
    unsafe_getcolortable(band::AbstractRasterBand)

Returns a clone of the color table associated with the band.

(If there is no associated color table, the original result is `NULL`. The
original color table remains owned by the `RasterBand`, and can't be
depended on for long, nor should it ever be modified by the caller.)
"""
unsafe_getcolortable(band::AbstractRasterBand)::ColorTable =
    unsafe_clone(ColorTable(GDAL.gdalgetrastercolortable(band)))

"""
    setcolortable!(band::AbstractRasterBand, colortable::ColorTable)

Set the raster color table.

The driver will make a copy of all desired data in the colortable. It remains
owned by the caller after the call.

### Parameters
* `colortable` color table to apply (where supported).
"""
function setcolortable!(
    band::T,
    colortable::ColorTable,
)::T where {T<:AbstractRasterBand}
    result = GDAL.gdalsetrastercolortable(band, colortable)
    @cplwarn result "CPLError $(result): action is unsupported by the driver"
    return band
end

function clearcolortable!(band::T)::T where {T<:AbstractRasterBand}
    result = GDAL.gdalsetrastercolortable(band, C_NULL)
    @cplwarn result "CPLError $(result): action is unsupported by the driver"
    return band
end

"""
    regenerateoverviews!(band::AbstractRasterBand,
        overviewbands::Vector{<:AbstractRasterBand}, resampling = "NEAREST")

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
* `progressfunc`    (optional) a function(::Float64, ::String)::Bool to call to report progress

### Additional Remarks
The output bands need to exist in advance.

This function will honour properly `NODATA_VALUES` tuples (special dataset
metadata) so that only a given RGB triplet (in case of a RGB image) will be
considered as the nodata value and not each value of the triplet independantly
per band.
"""
function regenerateoverviews!(
    band::T,
    overviewbands::Vector{<:AbstractRasterBand},
    resampling::AbstractString = "NEAREST",
    progressfunc::Function = _dummyprogress,
)::T where {T<:AbstractRasterBand}
    result = GDAL.gdalregenerateoverviews(
        band,
        length(overviewbands),
        overviewbands,
        resampling,
        @cfunction(_progresscallback, Cint, (Cdouble, Cstring, Ptr{Cvoid})),
        progressfunc,
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
    getcategorynames(band::AbstractRasterBand)

Fetch the list of category names for this raster.

The return list is a "StringList" in the sense of the CPL functions. That is a
NULL terminated array of strings. Raster values without associated names will
have an empty string in the returned list. The first entry in the list is for
raster values of zero, and so on.
"""
getcategorynames(band::AbstractRasterBand)::Vector{String} =
    GDAL.gdalgetrastercategorynames(band)

"""
    setcategorynames!(band::AbstractRasterBand, names::Vector{String})

Set the category names for this band.
"""
function setcategorynames!(
    band::T,
    names::Vector{String},
)::T where {T<:AbstractRasterBand}
    result = GDAL.gdalsetrastercategorynames(band, names)
    @cplerr result "Failed to set category names for this band"
    return band
end

# """
# Flush raster data cache.

# This call will recover memory used to cache data blocks for this raster band,
# and ensure that new requests are referred to the underlying driver.
# """
# function flushcache!(band::AbstractRasterBand)
#     result = GDAL.flushrastercache(band)
#     @cplerr result "Failed to flush raster data cache"
#     result
# end

"""
    fillraster!(band::AbstractRasterBand, realvalue::Real, imagvalue::Real = 0)

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
    band::T,
    realvalue::Real,
    imagvalue::Real = 0,
)::T where {T<:AbstractRasterBand}
    result = GDAL.gdalfillraster(band, realvalue, imagvalue)
    @cplerr result "Failed to fill raster band"
    return band
end

"""
    getmaskband(band::IRasterBand)

Return the mask band associated with the band.

The `RasterBand` class includes a default implementation of `GetMaskBand()`
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

Note that the `GetMaskBand()` should always return a `RasterBand` mask,
even if it is only an all 255 mask with the flags indicating `GMF_ALL_VALID`.

See also: http://trac.osgeo.org/gdal/wiki/rfc15_nodatabitmask

### Returns
a valid mask band.
"""
getmaskband(band::IRasterBand)::IRasterBand =
    IRasterBand(GDAL.gdalgetmaskband(band), ownedby = band.ownedby)

unsafe_getmaskband(band::AbstractRasterBand)::RasterBand =
    RasterBand(GDAL.gdalgetmaskband(band))

"""
    maskflags(band::AbstractRasterBand)

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

The `RasterBand` class includes a default implementation of `GetMaskBand()`
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
maskflags(band::AbstractRasterBand)::Cint = GDAL.gdalgetmaskflags(band)

"""
    maskflaginfo(band::AbstractRasterBand)

Returns the flags as in `maskflags`(@ref) but unpacks the bit values into a
named tuple with the following fields:

* `all_valid`
* `per_dataset`
* `alpha`
* `nodata`

### Returns

A named tuple with unpacked mask flags
"""
function maskflaginfo(
    band::AbstractRasterBand,
)::NamedTuple{(:all_valid, :per_dataset, :alpha, :nodata),NTuple{4,Bool}}
    flags = maskflags(band)
    return (
        all_valid = !iszero(flags & 0x01),
        per_dataset = !iszero(flags & 0x02),
        alpha = !iszero(flags & 0x04),
        nodata = !iszero(flags & 0x08),
    )
end

"""
    createmaskband!(band::AbstractRasterBand, nflags::Integer)

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
function createmaskband!(
    band::T,
    nflags::Integer,
)::T where {T<:AbstractRasterBand}
    result = GDAL.gdalcreatemaskband(band, nflags)
    @cplerr result "Failed to create mask band"
    return band
end
