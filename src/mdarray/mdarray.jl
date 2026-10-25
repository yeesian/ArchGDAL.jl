# GDALMDArray

function MDArray(ptr::GDAL.GDALMDArrayH, dataset::WeakRef)
    @assert ptr != C_NULL
    datatype = IExtendedDataType(GDAL.gdalmdarraygetdatatype(ptr))
    class = getclass(datatype)
    @assert class == GDAL.GEDTC_NUMERIC
    T = convert(DataType, getnumericdatatype(datatype))
    D = Int(GDAL.gdalmdarraygetdimensioncount(ptr))
    return MDArray{T,D}(ptr, dataset)
end

function IMDArray(ptr::GDAL.GDALMDArrayH, dataset::WeakRef)
    @assert ptr != C_NULL
    datatype = IExtendedDataType(GDAL.gdalmdarraygetdatatype(ptr))
    class = getclass(datatype)
    @assert class == GDAL.GEDTC_NUMERIC
    T = convert(DataType, getnumericdatatype(datatype))
    D = Int(GDAL.gdalmdarraygetdimensioncount(ptr))
    return IMDArray{T,D}(ptr, dataset)
end

# function iswritable(mdarray::AbstractMDArray)::Bool
#     return GDAL.gdalmdarrayiswritable(mdarray)
# end
# 
# Base.iswritable(mdarray::AbstractMDArray)::Bool = iswritable(mdarray)
# Base.isreadonly(mdarray::AbstractMDArray)::Bool = !iswritable(mdarray)

# getfilename: not available in the C API

"""
    getstructuralinfo(mdarray::AbstractMDArray)

Return structural information about the array as `"NAME=VALUE"` strings,
e.g. its compression method.
"""
function getstructuralinfo(
    mdarray::AbstractMDArray,
)::AbstractVector{<:AbstractString}
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraygetstructuralinfo(mdarray)
end

"""
    getunit(mdarray::AbstractMDArray)

Return the unit of the array's values, or `""` if unknown.
"""
function getunit(mdarray::AbstractMDArray)::AbstractString
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraygetunit(mdarray)
end

"""
    setunit!(mdarray::AbstractMDArray, unit::AbstractString)

Set the unit of the array's values, preferably a UCUM or UDUNITS-2 string.

### Returns
`true` on success.
"""
function setunit!(mdarray::AbstractMDArray, unit::AbstractString)::Bool
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraysetunit(mdarray, unit)
end

"""
    setspatialref!(mdarray::AbstractMDArray, srs::AbstractSpatialRef)

Set the spatial reference system of the array.

### Returns
`true` on success.
"""
function setspatialref!(mdarray::AbstractMDArray, srs::AbstractSpatialRef)::Bool
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraysetspatialref(mdarray, srs)
end

function unsafe_getspatialref(mdarray::AbstractMDArray)::AbstractSpatialRef
    @assert !isnull(mdarray)
    return SpatialRef(GDAL.gdalmdarraygetspatialref(mdarray))
end

"""
    getspatialref(mdarray::AbstractMDArray)

Return the spatial reference system of the array.
"""
function getspatialref(mdarray::AbstractMDArray)::AbstractSpatialRef
    @assert !isnull(mdarray)
    return ISpatialRef(GDAL.gdalmdarraygetspatialref(mdarray))
end

"""
    getrawnodatavalue(mdarray::AbstractMDArray)

Return a pointer to the raw nodata value, stored in the array's data type,
or `C_NULL` if there is none. The pointer is only valid while the array is
alive and its nodata value is not changed.
"""
function getrawnodatavalue(mdarray::AbstractMDArray)::Ptr{Cvoid}
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraygetrawnodatavalue(mdarray)
end

"""
    getrawnodatavalueasdouble(mdarray::AbstractMDArray)

Return the nodata value as `Float64`, or `nothing` if there is none.
"""
function getrawnodatavalueasdouble(
    mdarray::AbstractMDArray,
)::Union{Nothing,Float64}
    @assert !isnull(mdarray)
    hasnodata = Ref{Cint}()
    nodatavalue = GDAL.gdalmdarraygetnodatavalueasdouble(mdarray, hasnodata)
    return hasnodata[] != 0 ? nodatavalue : nothing
end

"""
    getrawnodatavalueasint64(mdarray::AbstractMDArray)

Return the nodata value as `Int64`, or `nothing` if there is none.
"""
function getrawnodatavalueasint64(
    mdarray::AbstractMDArray,
)::Union{Nothing,Int64}
    @assert !isnull(mdarray)
    hasnodata = Ref{Cint}()
    nodatavalue = GDAL.gdalmdarraygetnodatavalueasint64(mdarray, hasnodata)
    return hasnodata[] != 0 ? nodatavalue : nothing
end

"""
    getrawnodatavalueasuint64(mdarray::AbstractMDArray)

Return the nodata value as `UInt64`, or `nothing` if there is none.
"""
function getrawnodatavalueasuint64(
    mdarray::AbstractMDArray,
)::Union{Nothing,UInt64}
    @assert !isnull(mdarray)
    hasnodata = Ref{Cint}()
    nodatavalue = GDAL.gdalmdarraygetnodatavalueasuint64(mdarray, hasnodata)
    return hasnodata[] != 0 ? nodatavalue : nothing
end

"""
    getnodatavalue(T::Type, mdarray::AbstractMDArray)

Return the nodata value converted to `T` (`Float64`, `Int64` or `UInt64`),
or `nothing` if there is none.
"""
function getnodatavalue(::Type{Float64}, mdarray::AbstractMDArray)
    @assert !isnull(mdarray)
    return getrawnodatavalueasdouble(mdarray)
end
function getnodatavalue(::Type{Int64}, mdarray::AbstractMDArray)
    @assert !isnull(mdarray)
    return getrawnodatavalueasint64(mdarray)
end
function getnodatavalue(::Type{UInt64}, mdarray::AbstractMDArray)
    @assert !isnull(mdarray)
    return getrawnodatavalueasuint64(mdarray)
end

"""
    setrawnodatavalue!(mdarray::AbstractMDArray, rawnodata::Ptr{Cvoid})

Set the nodata value from a pointer to a value in the array's data type,
or remove it if `rawnodata` is `C_NULL`.

### Returns
`true` on success.
"""
function setrawnodatavalue!(
    mdarray::AbstractMDArray,
    rawnodata::Ptr{Cvoid},
)::Bool
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraysetrawnodatavalue(mdarray, rawnodata)
end

"""
    setnodatavalue!(mdarray::AbstractMDArray, nodata::Union{Float64,Int64,UInt64})

Set the nodata value.

### Returns
`true` on success.
"""
function setnodatavalue!(mdarray::AbstractMDArray, nodata::Float64)::Bool
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraysetnodatavalueasdouble(mdarray, nodata)
end

function setnodatavalue!(mdarray::AbstractMDArray, nodata::Int64)::Bool
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraysetnodatavalueasint64(mdarray, nodata)
end

function setnodatavalue!(mdarray::AbstractMDArray, nodata::UInt64)::Bool
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraysetnodatavalueasuint64(mdarray, nodata)
end

"""
    resize!(mdarray::AbstractMDArray, newdimsizes, options=nothing)

Resize the array to `newdimsizes`, given in Julia order.

The dimensions of the array are resized as well, which also affects other
arrays using them. Not all drivers support resizing.

### Returns
`true` on success.
"""
function resize!(
    mdarray::AbstractMDArray{<:Any,D},
    newdimsizes::VectorLike{<:Integer},
    options::OptionList = nothing,
)::Bool where {D}
    @assert !isnull(mdarray)
    @assert length(newdimsizes) == D
    gdal_newdimsizes = UInt64[newdimsizes[d] for d in D:-1:1]
    return GDAL.gdalmdarrayresize(
        mdarray,
        gdal_newdimsizes,
        CSLConstListWrapper(options),
    )
end

"""
    getoffset(mdarray::AbstractMDArray)

Return the offset `o` used to unscale the stored values `v` as
`v * scale + o`, or `nothing` if there is none. See also `getunscaled`.
"""
function getoffset(mdarray::AbstractMDArray)::Union{Nothing,Float64}
    @assert !isnull(mdarray)
    hasoffset = Ref{Cint}()
    offset = GDAL.gdalmdarraygetoffset(mdarray, hasoffset)
    return hasoffset[] != 0 ? offset : nothing
end

"""
    getoffsetex(mdarray::AbstractMDArray)

Return the offset (see `getoffset`) together with the Julia type in which
it is stored, or `nothing` if there is none.
"""
function getoffsetex(
    mdarray::AbstractMDArray,
)::Union{Nothing,Tuple{Float64,Type}}
    @assert !isnull(mdarray)
    hasoffset = Ref{Cint}()
    storagetyperef = Ref{GDAL.GDALDataType}()
    offset = GDAL.gdalmdarraygetoffsetex(mdarray, hasoffset, storagetyperef)
    hasoffset[] == 0 && return nothing
    storagetype = convert(DataType, convert(GDALDataType, storagetyperef[]))
    return offset, storagetype
end

"""
    getscale(mdarray::AbstractMDArray)

Return the scale `s` used to unscale the stored values `v` as
`v * s + offset`, or `nothing` if there is none. See also `getunscaled`.
"""
function getscale(mdarray::AbstractMDArray)::Union{Nothing,Float64}
    @assert !isnull(mdarray)
    hasscale = Ref{Cint}()
    scale = GDAL.gdalmdarraygetscale(mdarray, hasscale)
    return hasscale[] != 0 ? scale : nothing
end

"""
    getscaleex(mdarray::AbstractMDArray)

Return the scale (see `getscale`) together with the Julia type in which it
is stored, or `nothing` if there is none.
"""
function getscaleex(
    mdarray::AbstractMDArray,
)::Union{Nothing,Tuple{Float64,Type}}
    @assert !isnull(mdarray)
    hasscale = Ref{Cint}()
    storagetyperef = Ref{GDAL.GDALDataType}()
    scale = GDAL.gdalmdarraygetscaleex(mdarray, hasscale, storagetyperef)
    hasscale[] == 0 && return nothing
    storagetype = convert(DataType, convert(GDALDataType, storagetyperef[]))
    return scale, storagetype
end

"""
    setoffset!(mdarray::AbstractMDArray, offset::Float64, storagetype=nothing)

Set the offset used to unscale the stored values (see `getoffset`).
`storagetype` is the Julia type in which the offset is stored, or `nothing`
for the default.

### Returns
`true` on success.
"""
function setoffset!(
    mdarray::AbstractMDArray,
    offset::Float64,
    storagetype::Union{Type,Nothing} = nothing,
)::Bool
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraysetoffsetex(
        mdarray,
        offset,
        isnothing(storagetype) ? GDAL.GDT_Unknown :
        convert(GDAL.GDALDataType, convert(GDALDataType, storagetype)),
    )
end

"""
    setscale!(mdarray::AbstractMDArray, scale::Float64, storagetype=nothing)

Set the scale used to unscale the stored values (see `getscale`).
`storagetype` is the Julia type in which the scale is stored, or `nothing`
for the default.

### Returns
`true` on success.
"""
function setscale!(
    mdarray::AbstractMDArray,
    scale::Float64,
    storagetype::Union{Type,Nothing} = nothing,
)::Bool
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraysetscaleex(
        mdarray,
        scale,
        isnothing(storagetype) ? GDAL.GDT_Unknown :
        convert(GDAL.GDALDataType, convert(GDALDataType, storagetype)),
    )
end

function unsafe_getview(
    mdarray::AbstractMDArray,
    viewexpr::AbstractString,
)::AbstractMDArray
    @assert !isnull(mdarray)
    ptr = GDAL.gdalmdarraygetview(mdarray, viewexpr)
    ptr == C_NULL && error("Could not get view \"$viewexpr\"")
    return MDArray(ptr, mdarray.dataset)
end

"""
    getview(mdarray::AbstractMDArray, viewexpr::AbstractString)

Return a view of `mdarray` described by a GDAL view expression, e.g.
`"[1:3,...]"`.

The expression uses GDAL's syntax: indices are 0-based, ranges exclude
their end, and axes are in GDAL's order, which is the reverse of Julia's.
See `GDALMDArray::GetView` in the GDAL documentation.
"""
function getview(
    mdarray::AbstractMDArray,
    viewexpr::AbstractString,
)::AbstractMDArray
    @assert !isnull(mdarray)
    ptr = GDAL.gdalmdarraygetview(mdarray, viewexpr)
    ptr == C_NULL && error("Could not get view \"$viewexpr\"")
    return IMDArray(ptr, mdarray.dataset)
end

# Corresponds to `GDALMDArray::GetView(const std::vector<GUInt64>&)`,
# which is not available in the C API. `indices` are 1-based and in
# Julia order; they fix the trailing axes.
function _indexviewexpr(
    mdarray::AbstractMDArray{<:Any,D},
    indices::NTuple{N,Integer},
)::String where {D,N}
    @assert 1 <= N <= D
    @assert all(>=(1), indices)
    return "[" * join(reverse(indices) .- 1, ",") * "]"
end

function unsafe_getview(
    mdarray::AbstractMDArray,
    index::Integer,
    indices::Integer...,
)::AbstractMDArray
    @assert !isnull(mdarray)
    return unsafe_getview(mdarray, _indexviewexpr(mdarray, (index, indices...)))
end

"""
    getview(mdarray::AbstractMDArray, indices::Integer...)

Return a view of `mdarray` with its trailing axes fixed to `indices`.

The indices are 1-based and in Julia order. For a 3-dimensional array
`a`, `getview(a, j, k)` corresponds to `view(a, :, j, k)`, and
`getview(a, i, j, k)` to the 0-dimensional `view(a, i, j, k)`. Unlike
`view`, the result is a lazy GDAL array: it reads data only when
accessed.
"""
function getview(
    mdarray::AbstractMDArray,
    index::Integer,
    indices::Integer...,
)::AbstractMDArray
    @assert !isnull(mdarray)
    return getview(mdarray, _indexviewexpr(mdarray, (index, indices...)))
end

# Corresponds to `GDALMDArray::operator[](const std::string&)`, which
# is not available in the C API
function _fieldviewexpr(fieldname::AbstractString)::String
    return "['" * replace(fieldname, '\\' => "\\\\", '\'' => "\\\'") * "']"
end

function unsafe_getfieldview(
    mdarray::AbstractMDArray,
    fieldname::AbstractString,
)::AbstractMDArray
    @assert !isnull(mdarray)
    return unsafe_getview(mdarray, _fieldviewexpr(fieldname))
end

"""
    getfieldview(mdarray::AbstractMDArray, fieldname::AbstractString)

Return a view of the field `fieldname` of an array with a compound data
type.
"""
function getfieldview(
    mdarray::AbstractMDArray,
    fieldname::AbstractString,
)::AbstractMDArray
    @assert !isnull(mdarray)
    return getview(mdarray, _fieldviewexpr(fieldname))
end

# `perm[k]` is the (1-based, Julia order) axis of `mdarray` that becomes
# axis `k` of the result, as for `permutedims`. The default reverses
# all axes.
function unsafe_transpose(
    mdarray::AbstractMDArray{<:Any,D},
    perm::VectorLike{<:Integer} = D:-1:1,
)::AbstractMDArray where {D}
    @assert !isnull(mdarray)
    N = length(perm)
    @assert all(1 <= p <= D for p in perm)
    gdal_perm = Cint[D - perm[N-i] for i in 0:(N-1)]
    ptr = GDAL.gdalmdarraytranspose(mdarray, N, gdal_perm)
    ptr == C_NULL && error("Could not transpose mdarray")
    return MDArray(ptr, mdarray.dataset)
end

"""
    transpose(mdarray::AbstractMDArray, perm=reverse(1:ndims(mdarray)))

Return a lazy view of the array with permuted axes, like `permutedims`:
axis `k` of the result is axis `perm[k]` of `mdarray` (1-based, Julia
order). The default reverses all axes.
"""
function transpose(
    mdarray::AbstractMDArray{<:Any,D},
    perm::VectorLike{<:Integer} = D:-1:1,
)::AbstractMDArray where {D}
    @assert !isnull(mdarray)
    N = length(perm)
    @assert all(1 <= p <= D for p in perm)
    gdal_perm = Cint[D - perm[N-i] for i in 0:(N-1)]
    ptr = GDAL.gdalmdarraytranspose(mdarray, N, gdal_perm)
    ptr == C_NULL && error("Could not transpose mdarray")
    return IMDArray(ptr, mdarray.dataset)
end

function unsafe_getunscaled(mdarray::AbstractMDArray)::AbstractMDArray
    @assert !isnull(mdarray)
    ptr = GDAL.gdalmdarraygetunscaled(mdarray)
    ptr == C_NULL && error("Could not get unscaled mdarray")
    return MDArray(ptr, mdarray.dataset)
end

"""
    getunscaled(mdarray::AbstractMDArray)

Return a lazy view of the array in which the scale and offset have been
applied to the values (see `getscale` and `getoffset`).
"""
function getunscaled(mdarray::AbstractMDArray)::AbstractMDArray
    @assert !isnull(mdarray)
    ptr = GDAL.gdalmdarraygetunscaled(mdarray)
    ptr == C_NULL && error("Could not get unscaled mdarray")
    return IMDArray(ptr, mdarray.dataset)
end

function unsafe_getmask(
    mdarray::AbstractMDArray,
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(mdarray)
    ptr = GDAL.gdalmdarraygetmask(mdarray, CSLConstListWrapper(options))
    ptr == C_NULL && error("Could not get mask for mdarray")
    return MDArray(ptr, mdarray.dataset)
end

"""
    getmask(mdarray::AbstractMDArray, options=nothing)

Return a lazy `UInt8` array that is 1 where `mdarray` holds valid values and
0 where values are missing, e.g. equal to the nodata value.
"""
function getmask(
    mdarray::AbstractMDArray,
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(mdarray)
    ptr = GDAL.gdalmdarraygetmask(mdarray, CSLConstListWrapper(options))
    ptr == C_NULL && error("Could not get mask for mdarray")
    return IMDArray(ptr, mdarray.dataset)
end

# TODO: Wrap GDAL.GDALRIOResampleAlg
function unsafe_getresampled(
    mdarray::AbstractMDArray{<:Any,D},
    newdims::Union{Nothing,VectorLike{<:AbstractDimension}},
    resamplealg::GDAL.GDALRIOResampleAlg,
    targetsrs::Union{Nothing,AbstractSpatialRef},
    options::OptionList = nothing,
)::AbstractMDArray where {D}
    @assert !isnull(mdarray)
    @assert isnothing(newdims) || length(newdims) == D
    ptr = GDAL.gdalmdarraygetresampled(
        mdarray,
        D,
        # A null dimension handle keeps the corresponding dimension
        isnothing(newdims) ? GDAL.GDALDimensionH[C_NULL for d in 1:D] :
        DimensionHList(reverse(newdims)),
        resamplealg,
        isnothing(targetsrs) ? C_NULL : targetsrs,
        CSLConstListWrapper(options),
    )
    ptr == C_NULL && error("Could not get resampled mdarray")
    return MDArray(ptr, mdarray.dataset)
end

"""
    getresampled(mdarray::AbstractMDArray, newdims, resamplealg,
                 targetsrs, options=nothing)

Return a lazy view of the array resampled onto new dimensions or a new
spatial reference system.

### Parameters
* `newdims`: one dimension per axis (Julia order), or `nothing` to let GDAL
  choose.
* `resamplealg`: the resampling algorithm, e.g.
  `GDAL.GRIORA_NearestNeighbour`.
* `targetsrs`: the target spatial reference system, or `nothing` to keep
  the current one.
* `options`: driver-specific options, or `nothing`.

GDAL orients the y axis of the result north-up.
"""
function getresampled(
    mdarray::AbstractMDArray{<:Any,D},
    newdims::Union{Nothing,VectorLike{<:AbstractDimension}},
    resamplealg::GDAL.GDALRIOResampleAlg,
    targetsrs::Union{Nothing,AbstractSpatialRef},
    options::OptionList = nothing,
)::AbstractMDArray where {D}
    @assert !isnull(mdarray)
    @assert isnothing(newdims) || length(newdims) == D
    ptr = GDAL.gdalmdarraygetresampled(
        mdarray,
        D,
        # A null dimension handle keeps the corresponding dimension
        isnothing(newdims) ? GDAL.GDALDimensionH[C_NULL for d in 1:D] :
        DimensionHList(reverse(newdims)),
        resamplealg,
        isnothing(targetsrs) ? C_NULL : targetsrs,
        CSLConstListWrapper(options),
    )
    ptr == C_NULL && error("Could not get resampled mdarray")
    return IMDArray(ptr, mdarray.dataset)
end

function unsafe_getgridded(
    mdarray::AbstractMDArray,
    gridoptions::AbstractString,
    xarray::AbstractMDArray,
    yarray::AbstractMDArray,
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(mdarray)
    @assert !isnull(xarray)
    @assert !isnull(yarray)
    ptr = GDAL.gdalmdarraygetgridded(
        mdarray,
        gridoptions,
        xarray,
        yarray,
        CSLConstListWrapper(options),
    )
    ptr == C_NULL && error("Could not get gridded mdarray")
    return MDArray(ptr, mdarray.dataset)
end

"""
    getgridded(mdarray::AbstractMDArray, gridoptions::AbstractString,
               xarray::AbstractMDArray, yarray::AbstractMDArray,
               options=nothing)

Return a lazy gridded version of an array of scattered points, whose
coordinates are given by `xarray` and `yarray`. `gridoptions` uses the
syntax of the `-a` option of `gdal_grid`, e.g. `"invdist"`.
"""
function getgridded(
    mdarray::AbstractMDArray,
    gridoptions::AbstractString,
    xarray::AbstractMDArray,
    yarray::AbstractMDArray,
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(mdarray)
    @assert !isnull(xarray)
    @assert !isnull(yarray)
    ptr = GDAL.gdalmdarraygetgridded(
        mdarray,
        gridoptions,
        xarray,
        yarray,
        CSLConstListWrapper(options),
    )
    ptr == C_NULL && error("Could not get gridded mdarray")
    return IMDArray(ptr, mdarray.dataset)
end

# `xdim` and `ydim` are 1-based axes in Julia order
function unsafe_asclassicdataset(
    mdarray::AbstractMDArray{<:Any,D},
    xdim::Integer,
    ydim::Integer,
    rootgroup::Union{Nothing,AbstractGroup} = nothing,
    options::OptionList = nothing,
)::AbstractDataset where {D}
    @assert !isnull(mdarray)
    @assert 1 <= xdim <= D
    @assert 1 <= ydim <= D
    @assert isnothing(rootgroup) || !isnull(rootgroup)
    return Dataset(
        GDAL.gdalmdarrayasclassicdatasetex(
            mdarray,
            D - xdim,
            D - ydim,
            isnothing(rootgroup) ? C_NULL : rootgroup,
            CSLConstListWrapper(options),
        ),
    )
end

# `xdim` and `ydim` are 1-based axes in Julia order
"""
    asclassicdataset(mdarray::AbstractMDArray, xdim::Integer, ydim::Integer,
                     rootgroup=nothing, options=nothing)

Return a classic raster dataset view of the array, using axis `xdim` as x
and axis `ydim` as y (1-based, Julia order); the other axes become bands.
`rootgroup` is used to resolve references to other arrays, if given.
"""
function asclassicdataset(
    mdarray::AbstractMDArray{<:Any,D},
    xdim::Integer,
    ydim::Integer,
    rootgroup::Union{Nothing,AbstractGroup} = nothing,
    options::OptionList = nothing,
)::AbstractDataset where {D}
    @assert !isnull(mdarray)
    @assert 1 <= xdim <= D
    @assert 1 <= ydim <= D
    @assert isnothing(rootgroup) || !isnull(rootgroup)
    return IDataset(
        GDAL.gdalmdarrayasclassicdatasetex(
            mdarray,
            D - xdim,
            D - ydim,
            isnothing(rootgroup) ? C_NULL : rootgroup,
            CSLConstListWrapper(options),
        ),
    )
end

function unsafe_asmdarray(rasterband::AbstractRasterBand)::AbstractMDArray
    @assert !isnull(rasterband)
    ptr = GDAL.gdalrasterbandasmdarray(rasterband)
    ptr == C_NULL && error("Could not get rasterband as mdarray")
    # Classic datasets do not track their children
    return MDArray(ptr, WeakRef())
end

"""
    asmdarray(rasterband::AbstractRasterBand)

Return a 2-dimensional multidimensional array view of a classic raster
band. The array holds a reference to the band's dataset.
"""
function asmdarray(rasterband::AbstractRasterBand)::AbstractMDArray
    @assert !isnull(rasterband)
    ptr = GDAL.gdalrasterbandasmdarray(rasterband)
    ptr == C_NULL && error("Could not get rasterband as mdarray")
    # Classic datasets do not track their children
    return IMDArray(ptr, WeakRef())
end

# TODO: Wrap GDAL.CPLErr
# TODO: Allow a progress function
"""
    getstatistics(mdarray::AbstractMDArray, approxok::Bool, force::Bool)

Return statistics of the array's values, computing them if `force` is
true and they are not cached. With `approxok`, statistics may be computed
from a subset of the values.

### Returns
The tuple `(err, min, max, mean, stddev, validcount)`, where `err` is a
`GDAL.CPLErr` error code.
"""
function getstatistics(
    mdarray::AbstractMDArray,
    approxok::Bool,
    force::Bool,
)::Tuple{GDAL.CPLErr,Float64,Float64,Float64,Float64,Int64}
    @assert !isnull(mdarray)
    dataset = C_NULL            # apparently unused
    min = Ref{Float64}()
    max = Ref{Float64}()
    mean = Ref{Float64}()
    stddev = Ref{Float64}()
    validcount = Ref{UInt64}()
    err = GDAL.gdalmdarraygetstatistics(
        mdarray,
        dataset,
        approxok,
        force,
        min,
        max,
        mean,
        stddev,
        validcount,
        C_NULL,
        C_NULL,
    )
    return err, min[], max[], mean[], stddev[], Int64(validcount[])
end

# TODO: Allow a progress function
"""
    computestatistics(mdarray::AbstractMDArray, approxok::Bool,
                      options=nothing)

Compute statistics of the array's values. With `approxok`, statistics may
be computed from a subset of the values.

### Returns
The tuple `(success, min, max, mean, stddev, validcount)`.
"""
function computestatistics(
    mdarray::AbstractMDArray,
    approxok::Bool,
    options::OptionList = nothing,
)::Tuple{Bool,Float64,Float64,Float64,Float64,Int64}
    @assert !isnull(mdarray)
    dataset = C_NULL            # apparently unused
    min = Ref{Float64}()
    max = Ref{Float64}()
    mean = Ref{Float64}()
    stddev = Ref{Float64}()
    validcount = Ref{UInt64}()
    success = GDAL.gdalmdarraycomputestatisticsex(
        mdarray,
        dataset,
        approxok,
        min,
        max,
        mean,
        stddev,
        validcount,
        C_NULL,
        C_NULL,
        CSLConstListWrapper(options),
    )
    return Bool(success), min[], max[], mean[], stddev[], Int64(validcount[])
end

# clearstatistics: not available in the C API

"""
    getcoordinatevariables(mdarray::AbstractMDArray)

Return the coordinate variables of the array, e.g. the latitude and
longitude arrays referenced by a netCDF `coordinates` attribute.
"""
function getcoordinatevariables(
    mdarray::AbstractMDArray,
)::AbstractVector{<:AbstractMDArray}
    @assert !isnull(mdarray)
    count = Ref{Csize_t}()
    coordinatevariablesptr =
        GDAL.gdalmdarraygetcoordinatevariables(mdarray, count)
    coordinatevariables = AbstractMDArray[
        IMDArray(unsafe_load(coordinatevariablesptr, n), mdarray.dataset)
        for n in 1:count[]
    ]
    GDAL.vsifree(coordinatevariablesptr)
    return coordinatevariables
end

"""
    adviseread(mdarray::AbstractMDArray, arraystartidx, count, options=nothing)

Advise the driver that a region of the array will be read soon, so that it
can prefetch it.

`arraystartidx` (1-based) and `count` are given in Julia order, or
`nothing` for the whole array.

### Returns
`true` on success.
"""
function adviseread(
    mdarray::AbstractMDArray{<:Any,D},
    arraystartidx::Union{Nothing,IndexLike{D}},
    count::Union{Nothing,IndexLike{D}},
    options::OptionList = nothing,
)::Bool where {D}
    @assert !isnull(mdarray)
    @assert isnothing(arraystartidx) || length(arraystartidx) == D
    @assert isnothing(count) || length(count) == D
    gdal_arraystartidx =
        isnothing(arraystartidx) ? C_NULL :
        UInt64[arraystartidx[d] - 1 for d in D:-1:1]
    gdal_count = isnothing(count) ? C_NULL : Csize_t[count[d] for d in D:-1:1]
    return GDAL.gdalmdarrayadvisereadex(
        mdarray,
        gdal_arraystartidx,
        gdal_count,
        CSLConstListWrapper(options),
    )
end

# isregularlyspaced: not available in the C API

# guessgeotransform: not available in the C API

"""
    cache(mdarray::AbstractMDArray, options=nothing)

Cache the array's contents in a sidecar file, to speed up later reads.
Only supported for arrays stored in files.

### Returns
`true` on success.
"""
function cache(mdarray::AbstractMDArray, options::OptionList = nothing)::Bool
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraycache(mdarray, CSLConstListWrapper(options))
end

# getrootgroup: not available in the C API

################################################################################

"""
    getname(mdarray::AbstractMDArray)

Return the name of the array.
"""
function getname(mdarray::AbstractMDArray)::AbstractString
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraygetname(mdarray)
end

"""
    getfullname(mdarray::AbstractMDArray)

Return the full name of the array, including the path of its group, e.g.
`"/group/array"`.
"""
function getfullname(mdarray::AbstractMDArray)::AbstractString
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraygetfullname(mdarray)
end

"""
    gettotalelementscount(mdarray::AbstractMDArray)

Return the number of elements of the array.
"""
function gettotalelementscount(mdarray::AbstractMDArray)::Int64
    @assert !isnull(mdarray)
    return Int64(GDAL.gdalmdarraygettotalelementscount(mdarray))
end

function Base.length(mdarray::AbstractMDArray)
    @assert !isnull(mdarray)
    return Int(gettotalelementscount(mdarray))
end

# function getdimensioncount(mdarray::AbstractMDArray)::Int
#     @assert !isnull(mdarray)
#     return Int(GDAL.gdalmdarraygetdimensioncount(mdarray))
# end
"""
    getdimensioncount(mdarray::AbstractMDArray)

Return the number of dimensions of the array.
"""
getdimensioncount(mdarray::AbstractMDArray{<:Any,D}) where {D} = D

Base.ndims(mdarray::AbstractMDArray)::Int = getdimensioncount(mdarray)

"""
    getdimensions(mdarray::AbstractMDArray)

Return the dimensions of the array as a tuple, in Julia order.
"""
function getdimensions(
    mdarray::AbstractMDArray{<:Any,D},
)::NTuple{D,T where T<:AbstractDimension} where {D}
    @assert !isnull(mdarray)
    dimensionscountref = Ref{Csize_t}()
    dimensionshptr = GDAL.gdalmdarraygetdimensions(mdarray, dimensionscountref)
    dimensions = reverse(
        ntuple(
            d ->
                IDimension(unsafe_load(dimensionshptr, d), mdarray.dataset),
            dimensionscountref[],
        ),
    )
    GDAL.vsifree(dimensionshptr)
    return dimensions
end

function unsafe_getdimensions(
    mdarray::AbstractMDArray{<:Any,D},
)::NTuple{D,T where T<:AbstractDimension} where {D}
    @assert !isnull(mdarray)
    dimensionscountref = Ref{Csize_t}()
    dimensionshptr = GDAL.gdalmdarraygetdimensions(mdarray, dimensionscountref)
    dimensions = reverse(
        ntuple(
            d -> Dimension(unsafe_load(dimensionshptr, d), mdarray.dataset),
            dimensionscountref[],
        ),
    )
    GDAL.vsifree(dimensionshptr)
    return dimensions
end

function Base.size(mdarray::AbstractMDArray{<:Any,D})::NTuple{D,Int} where {D}
    getdimensions(mdarray) do dimensions
        return ntuple(d -> getsize(dimensions[d]), D)
    end
end

function unsafe_getdatatype(mdarray::AbstractMDArray)::AbstractExtendedDataType
    @assert !isnull(mdarray)
    return ExtendedDataType(GDAL.gdalmdarraygetdatatype(mdarray))
end

"""
    getdatatype(mdarray::AbstractMDArray)

Return the data type of the array.
"""
function getdatatype(mdarray::AbstractMDArray)::AbstractExtendedDataType
    @assert !isnull(mdarray)
    return IExtendedDataType(GDAL.gdalmdarraygetdatatype(mdarray))
end

Base.eltype(mdarray::AbstractMDArray{T}) where {T} = T

"""
    getblocksize(mdarray::AbstractMDArray)

Return the block (chunk) size of the array in Julia order. Entries are 0
for arrays that are not chunked.
"""
function getblocksize(
    mdarray::AbstractMDArray{<:Any,D},
)::NTuple{D,Int} where {D}
    @assert !isnull(mdarray)
    count = Ref{Csize_t}()
    blocksizeptr = GDAL.gdalmdarraygetblocksize(mdarray, count)
    blocksize = reverse(ntuple(d -> Int(unsafe_load(blocksizeptr, d)), count[]))
    GDAL.vsifree(blocksizeptr)
    return blocksize
end

# GDAL reports a block size of 0 for arrays that are not chunked
function DiskArrays.haschunks(mdarray::AbstractMDArray)
    return all(>(0), getblocksize(mdarray)) ? DiskArrays.Chunked() :
           DiskArrays.Unchunked()
end

function DiskArrays.eachchunk(mdarray::AbstractMDArray)
    blocksize = getblocksize(mdarray)
    all(>(0), blocksize) || return DiskArrays.estimate_chunksize(mdarray)
    return DiskArrays.GridChunks(mdarray, blocksize)
end

"""
    getprocessingchunksize(mdarray::AbstractMDArray, maxchunkmemory::Integer)

Return a chunk size (in Julia order) suitable for processing the array
chunk by chunk, using at most `maxchunkmemory` bytes per chunk and aligned
with the array's blocks.
"""
function getprocessingchunksize(
    mdarray::AbstractMDArray,
    maxchunkmemory::Integer,
)::AbstractVector{Int}
    @assert !isnull(mdarray)
    count = Ref{Csize_t}()
    chunksizeptr =
        GDAL.gdalmdarraygetprocessingchunksize(mdarray, count, maxchunkmemory)
    chunksize = Int[unsafe_load(chunksizeptr, n) for n in count[]:-1:1]
    GDAL.vsifree(chunksizeptr)
    return chunksize
end

# processperchunk

"""
    read!(mdarray::AbstractMDArray, arraystartidx, count, arraystep, buffer)
    read!(mdarray::AbstractMDArray, region, buffer)
    read!(mdarray::AbstractMDArray, indices::CartesianIndices, [arraystep,] buffer)
    read!(mdarray::AbstractMDArray, buffer)

Read a region of the array into `buffer`.

The region is given either as its start `arraystartidx` (1-based), `count`
and `arraystep` (or `nothing` for a step of 1), as a tuple of ranges
`region`, or as `CartesianIndices`; all in Julia order. Without a region,
the region is given by `axes(buffer)`. Values are converted to the element
type of `buffer`.
"""
function read!(
    mdarray::AbstractMDArray,
    arraystartidx::IndexLike{D},
    count::IndexLike{D},
    arraystep::Union{Nothing,IndexLike{D}},
    buffer::StridedArray{T,D},
)::Nothing where {T,D}
    @assert !isnull(mdarray)
    @assert length(arraystartidx) == D
    @assert length(count) == D
    @assert isnothing(arraystep) ? true : length(arraystep) == D
    gdal_arraystartidx = UInt64[arraystartidx[d] - 1 for d in D:-1:1]
    gdal_count = Csize_t[count[d] for d in D:-1:1]
    gdal_arraystep =
        isnothing(arraystep) ? C_NULL : Int64[arraystep[d] for d in D:-1:1]
    gdal_bufferstride = Cptrdiff_t[stride(buffer, d) for d in D:-1:1]
    return extendeddatatypecreate(T) do bufferdatatype
        success = GDAL.gdalmdarrayread(
            mdarray,
            gdal_arraystartidx,
            gdal_count,
            gdal_arraystep,
            gdal_bufferstride,
            bufferdatatype,
            buffer,
            buffer,
            sizeof(buffer),
        )
        success == 0 && error("Could not read mdarray")
        return nothing
    end
end

function read!(
    mdarray::AbstractMDArray,
    region::RangeLike{D},
    buffer::StridedArray{T,D},
)::Nothing where {T,D}
    @assert length(region) == D
    arraystartidx = first.(region)
    count = length.(region)
    arraystep = step.(region)
    return read!(mdarray, arraystartidx, count, arraystep, buffer)
end

function read!(
    mdarray::AbstractMDArray,
    indices::CartesianIndices{D},
    arraystep::Union{Nothing,IndexLike{D}},
    buffer::StridedArray{T,D},
)::Nothing where {T,D}
    arraystartidx = first.(indices.indices)
    count = length.(indices.indices)
    return read!(mdarray, arraystartidx, count, arraystep, buffer)
end

function read!(
    mdarray::AbstractMDArray,
    indices::CartesianIndices{D},
    buffer::StridedArray{T,D},
)::Nothing where {T,D}
    return read!(mdarray, indices, nothing, buffer)
end

function read!(
    mdarray::AbstractMDArray,
    buffer::StridedArray{T,D},
)::Nothing where {T,D}
    return read!(mdarray, axes(buffer), buffer)
end

"""
    read(mdarray::AbstractMDArray)

Read the whole array into a Julia array. The array can also be indexed
directly, e.g. `mdarray[2, :]`, which reads only the requested elements.
"""
function read(mdarray::AbstractMDArray)::AbstractArray
    getdimensions(mdarray) do dimensions
        D = length(dimensions)
        sz = [getsize(dimensions[d]) for d in 1:D]
        getdatatype(mdarray) do datatype
            class = getclass(datatype)
            @assert class == GDAL.GEDTC_NUMERIC
            T = convert(DataType, getnumericdatatype(datatype))
            buffer = Array{T}(undef, sz...)
            read!(mdarray, buffer)
            return buffer
        end
    end
end

function DiskArrays.readblock!(
    mdarray::AbstractMDArray{T,D},
    aout,
    r::Vararg{AbstractUnitRange,D},
)::Nothing where {T,D}
    if aout isa StridedArray{T,D}
        read!(mdarray, r, aout)
    else
        buffer = Array{T,D}(undef, length.(r))
        read!(mdarray, r, buffer)
        aout .= buffer
    end
    return nothing
end

"""
    write(mdarray::AbstractMDArray, arraystartidx, count, arraystep, buffer)
    write(mdarray::AbstractMDArray, region, buffer)
    write(mdarray::AbstractMDArray, indices::CartesianIndices, [arraystep,] buffer)
    write(mdarray::AbstractMDArray, buffer)

Write `buffer` to a region of the array. The region is specified as for
`read!`. Values are converted to the array's data type.
"""
function write(
    mdarray::AbstractMDArray,
    arraystartidx::IndexLike{D},
    count::IndexLike{D},
    arraystep::Union{Nothing,IndexLike{D}},
    buffer::StridedArray{T,D},
)::Nothing where {T,D}
    @assert !isnull(mdarray)
    @assert length(arraystartidx) == D
    @assert length(count) == D
    @assert isnothing(arraystep) ? true : length(arraystep) == D
    gdal_arraystartidx = UInt64[arraystartidx[d] - 1 for d in D:-1:1]
    gdal_count = Csize_t[count[d] for d in D:-1:1]
    gdal_arraystep =
        isnothing(arraystep) ? C_NULL : Int64[arraystep[d] for d in D:-1:1]
    gdal_bufferstride = Cptrdiff_t[stride(buffer, d) for d in D:-1:1]
    return extendeddatatypecreate(T) do bufferdatatype
        success = GDAL.gdalmdarraywrite(
            mdarray,
            gdal_arraystartidx,
            gdal_count,
            gdal_arraystep,
            gdal_bufferstride,
            bufferdatatype,
            buffer,
            buffer,
            sizeof(buffer),
        )
        success == 0 && error("Could not write mdarray")
        return nothing
    end
end

function write(
    mdarray::AbstractMDArray,
    region::RangeLike{D},
    buffer::StridedArray{T,D},
)::Nothing where {T,D}
    @assert length(region) == D
    arraystartidx = first.(region)
    count = length.(region)
    arraystep = step.(region)
    return write(mdarray, arraystartidx, count, arraystep, buffer)
end

function write(
    mdarray::AbstractMDArray,
    indices::CartesianIndices{D},
    arraystep::Union{Nothing,IndexLike{D}},
    buffer::StridedArray{T,D},
)::Nothing where {T,D}
    arraystartidx = first.(indices.indices)
    count = length.(indices.indices)
    return write(mdarray, arraystartidx, count, arraystep, buffer)
end

function write(
    mdarray::AbstractMDArray,
    indices::CartesianIndices{D},
    buffer::StridedArray{T,D},
)::Nothing where {T,D}
    return write(mdarray, indices, nothing, buffer)
end

function write(
    mdarray::AbstractMDArray,
    buffer::StridedArray{T,D},
)::Nothing where {T,D}
    return write(mdarray, axes(buffer), buffer)
end

function DiskArrays.writeblock!(
    mdarray::AbstractMDArray{T,D},
    ain,
    r::Vararg{AbstractUnitRange,D},
)::Nothing where {T,D}
    buffer = ain isa StridedArray{T,D} ? ain : Array{T,D}(ain)
    write(mdarray, r, buffer)
    return nothing
end

"""
    rename!(mdarray::AbstractMDArray, newname::AbstractString)

Rename the array. Not all drivers support renaming.

### Returns
`true` on success.
"""
function rename!(mdarray::AbstractMDArray, newname::AbstractString)::Bool
    @assert !isnull(mdarray)
    return GDAL.gdalmdarrayrename(mdarray, newname)
end

################################################################################

function unsafe_getattribute(
    mdarray::AbstractMDArray,
    name::AbstractString,
)::AbstractAttribute
    @assert !isnull(mdarray)
    ptr = GDAL.gdalmdarraygetattribute(mdarray, name)
    ptr == C_NULL && error("Could not get attribute \"$name\"")
    return Attribute(ptr, mdarray.dataset)
end

"""
    getattribute(mdarray::AbstractMDArray, name::AbstractString)

Return the attribute `name` of the array. Throws an error if it does not
exist. See also `readattribute`.
"""
function getattribute(
    mdarray::AbstractMDArray,
    name::AbstractString,
)::AbstractAttribute
    @assert !isnull(mdarray)
    ptr = GDAL.gdalmdarraygetattribute(mdarray, name)
    ptr == C_NULL && error("Could not get attribute \"$name\"")
    return IAttribute(ptr, mdarray.dataset)
end

function unsafe_getattributes(
    mdarray::AbstractMDArray,
    options::OptionList = nothing,
)::AbstractVector{<:AbstractAttribute}
    @assert !isnull(mdarray)
    count = Ref{Csize_t}()
    ptr = GDAL.gdalmdarraygetattributes(
        mdarray,
        count,
        CSLConstListWrapper(options),
    )
    attributes = AbstractAttribute[
        Attribute(unsafe_load(ptr, n), mdarray.dataset) for n in 1:count[]
    ]
    GDAL.vsifree(ptr)
    return attributes
end

"""
    getattributes(mdarray::AbstractMDArray, options=nothing)

Return all attributes of the array.
"""
function getattributes(
    mdarray::AbstractMDArray,
    options::OptionList = nothing,
)::AbstractVector{<:AbstractAttribute}
    @assert !isnull(mdarray)
    count = Ref{Csize_t}()
    ptr = GDAL.gdalmdarraygetattributes(
        mdarray,
        count,
        CSLConstListWrapper(options),
    )
    attributes = AbstractAttribute[
        IAttribute(unsafe_load(ptr, n), mdarray.dataset) for n in 1:count[]
    ]
    GDAL.vsifree(ptr)
    return attributes
end

function unsafe_createattribute(
    mdarray::AbstractMDArray,
    name::AbstractString,
    dimensions::VectorLike{<:Integer},
    datatype::AbstractExtendedDataType,
    options::OptionList = nothing,
)::AbstractAttribute
    @assert !isnull(mdarray)
    @assert !isnull(datatype)
    ptr = GDAL.gdalmdarraycreateattribute(
        mdarray,
        name,
        length(dimensions),
        reverse(dimensions),
        datatype,
        CSLConstListWrapper(options),
    )
    ptr == C_NULL && error("Could not create attribute \"$name\"")
    return Attribute(ptr, mdarray.dataset)
end

"""
    createattribute(mdarray::AbstractMDArray, name::AbstractString, dimensions,
                    datatype::AbstractExtendedDataType, options=nothing)

Create an attribute of the array. The arguments are as for
`createattribute` on a group. See also `writeattribute`.
"""
function createattribute(
    mdarray::AbstractMDArray,
    name::AbstractString,
    dimensions::VectorLike{<:Integer},
    datatype::AbstractExtendedDataType,
    options::OptionList = nothing,
)::AbstractAttribute
    @assert !isnull(mdarray)
    @assert !isnull(datatype)
    ptr = GDAL.gdalmdarraycreateattribute(
        mdarray,
        name,
        length(dimensions),
        reverse(dimensions),
        datatype,
        CSLConstListWrapper(options),
    )
    ptr == C_NULL && error("Could not create attribute \"$name\"")
    return IAttribute(ptr, mdarray.dataset)
end

"""
    deleteattribute(mdarray::AbstractMDArray, name::AbstractString,
                    options=nothing)

Delete the attribute `name` of the array.

### Returns
`true` on success.
"""
function deleteattribute(
    mdarray::AbstractMDArray,
    name::AbstractString,
    options::OptionList = nothing,
)::Bool
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraydeleteattribute(
        mdarray,
        name,
        CSLConstListWrapper(options),
    )
end
