# GDALMDArray

# function iswritable(mdarray::AbstractMDArray)::Bool
#     return GDAL.gdalmdarrayiswritable(mdarray)
# end
# 
# Base.iswritable(mdarray::AbstractMDArray)::Bool = iswritable(mdarray)
# Base.isreadonly(mdarray::AbstractMDArray)::Bool = !iswritable(mdarray)

function getfilename(mdarray::AbstractMDArray)::AbstractString
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraygetfilename(mdarray)
end

function getstructuralinfo(
    mdarray::AbstractMDArray,
)::AbstractVector{<:AbstractString}
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraygetstructuralinfo(mdarray)
end

function getunit(mdarray::AbstractMDArray)::AbstractString
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraygetunit(mdarray)
end

function setunit!(mdarray::AbstractMDArray, unit::AbstractString)::Bool
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraysetunit(mdarray, unit)
end

function setspatialref!(mdarray::AbstractMDArray, srs::AbstractSpatialRef)::Bool
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraysetspatialref(mdarray, srs)
end

function unsafe_getspatialref(mdarray::AbstractMDArray)::AbstractSpatialRef
    @assert !isnull(mdarray)
    return SpatialRef(GDAL.gdalmdarraygetspatialref(mdarray))
end

function getspatialref(mdarray::AbstractMDArray)::AbstractSpatialRef
    @assert !isnull(mdarray)
    return ISpatialRef(GDAL.gdalmdarraygetspatialref(mdarray))
end

function getrawnodatavalue(mdarray::AbstractMDArray)::Ptr{Cvoid}
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraygetrawnodatavalue(mdarray)
end

function getrawnodatavalueasdouble(
    mdarray::AbstractMDArray,
)::Union{Nothing,Float64}
    @assert !isnull(mdarray)
    hasnodata = Ref{Cbool}()
    nodatavalue = GDAL.gdalmdarraygetnodatavalueasdouble(mdarray, hasnodata)
    return hasnodata[] ? nodatavalue : nothing
end

function getrawnodatavalueasint64(
    mdarray::AbstractMDArray,
)::Union{Nothing,Int64}
    @assert !isnull(mdarray)
    hasnodata = Ref{Cbool}()
    nodatavalue = GDAL.gdalmdarraygetnodatavalueasint64(mdarray, hasnodata)
    return hasnodata[] ? nodatavalue : nothing
end

function getrawnodatavalueasuint64(
    mdarray::AbstractMDArray,
)::Union{Nothing,UInt64}
    @assert !isnull(mdarray)
    hasnodata = Ref{Cbool}()
    nodatavalue = GDAL.gdalmdarraygetnodatavalueasuint64(mdarray, hasnodata)
    return hasnodata[] ? nodatavalue : nothing
end

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

function setrawnodatavalue!(
    mdarray::AbstractMDArray,
    rawnodata::Ptr{Cvoid},
)::Bool
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraysetrawnodatavalue(mdarray, rawnodata)
end

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

function resize!(
    mdarray::AbstractMDArray,
    newdimsizes::AbstractVector{<:Integer},
    options::OptionList = nothing,
)::Bool
    @assert !isnull(mdarray)
    return GDAL.gdalmdarrayresize(
        mdarray,
        newdimsizes,
        CSLConstListWrapper(options),
    )
end

function getoffset(mdarray::AbstractMDArray)::Union{Nothing,Float64}
    @assert !isnull(mdarray)
    hasoffset = Ref{Cbool}()
    offset = GDAL.gdalmdarraygetoffset(mdarray, hasoffset)
    return hasoffset[] ? offset : nothing
end

function getoffsetex(
    mdarray::AbstractMDArray,
)::Union{Nothing,Tuple{Float64,Type}}
    @assert !isnull(mdarray)
    hasoffset = Ref{Cbool}()
    storagetyperef = Ref{GDAL.GDALDataType}()
    offset = GDAL.gdalmdarraygetoffsetex(mdarray, hasoffset, storagetyperef)
    !hasoffset[] && return nothing
    storagetype = convert(Type, storagetyperef[])
    return offset, storagetype
end

function getscale(mdarray::AbstractMDArray)::Union{Nothing,Float64}
    @assert !isnull(mdarray)
    hasscale = Ref{Cbool}()
    scale = GDAL.gdalmdarraygetscale(mdarray, hasscale)
    return hasscale[] ? scale : nothing
end

function getscaleex(
    mdarray::AbstractMDArray,
)::Union{Nothing,Tuple{Float64,Type}}
    @assert !isnull(mdarray)
    hasscale = Ref{Cbool}()
    storagetyperef = Ref{GDAL.GDALDataType}()
    scale = GDAL.gdalmdarraygetscaleex(mdarray, hasscale, storagetyperef)
    !hasscale[] && return nothing
    storagetype = convert(Type, storagetyperef[])
    return scale, storagetype
end

function setoffset!(
    mdarray::AbstractMDArray,
    offset::Float64,
    storagetype::Union{Type,Nothing},
)::Bool
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraysetoffset(
        mdarray,
        offset,
        storagetype === nothing ? GDAL.GDT_Unknown :
        convert(GDAL.GDALDataType, storagetype),
    )
end

function setscale!(
    mdarray::AbstractMDArray,
    offset::Float64,
    storagetype::Union{Type,Nothing},
)::Bool
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraysetscale(
        mdarray,
        offset,
        storagetype === nothing ? GDAL.GDT_Unknown :
        convert(GDAL.GDALDataType, storagetype),
    )
end

function unsafe_getview(
    mdarray::AbstractMDArray,
    viewexpr::AbstractString,
)::AbstractMDArray
    @assert !isnull(mdarray)
    return MDArray(
        GDAL.gdalmdarraygetview(mdarray, viewexpr),
        mdarray.dataset.value,
    )
end

function getview(
    mdarray::AbstractMDArray,
    viewexpr::AbstractString,
)::AbstractMDArray
    @assert !isnull(mdarray)
    return IMDArray(
        GDAL.gdalmdarraygetview(mdarray, viewexpr),
        mdarray.dataset.value,
    )
end

function unsafe_getindex(
    mdarray::AbstractMDArray,
    fieldname::AbstractString,
)::AbstractMDArray
    @assert !isnull(mdarray)
    viewexpr = "['" * replace(fieldname, '\\' => "\\\\", '\'' => "\\\'") * "']"
    return unsafe_getview(mdarray, viewexpr)
end

function getindex(
    mdarray::AbstractMDArray,
    fieldname::AbstractString,
)::AbstractMDArray
    @assert !isnull(mdarray)
    viewexpr = "['" * replace(fieldname, '\\' => "\\\\", '\'' => "\\\'") * "']"
    return getview(mdarray, viewexpr)
end

function unsafe_getindex(
    mdarray::AbstractMDArray,
    indices::Integer...,
)::AbstractMDArray
    @assert !isnull(mdarray)
    viewexpr = "[" * join(indices, ",") * "]"
    return unsafe_getview(mdarray, viewexpr)
end

function getindex(
    mdarray::AbstractMDArray,
    indices::Integer...,
)::AbstractMDArray
    @assert !isnull(mdarray)
    viewexpr = "[" * join(indices, ",") * "]"
    return getview(mdarray, viewexpr)
end

# TODO: Return a `LinearAlgebra.Adjoint` instead?
function unsafe_transpose(mdarray::AbstractMDArray)::AbstractMDArray
    @assert !isnull(mdarray)
    return MDArray(GDAL.gdalmdarraytranspose(mdarray), mdarray.dataset.value)
end

function transpose(mdarray::AbstractMDArray)::AbstractMDArray
    @assert !isnull(mdarray)
    return IMDArray(GDAL.gdalmdarraytranspose(mdarray), mdarray.dataset.value)
end

function unsafe_getunscaled(
    mdarray::AbstractMDArray,
    overriddenscale = Float64(NaN),
    overriddenoffset = Float64(NaN),
    overriddendstnodata = Float64(NaN),
)::AbstractMDArray
    @assert !isnull(mdarray)
    return MDArray(
        GDAL.gdalmdarraygetunscaled(
            mdarray,
            overriddenscale,
            overriddenoffset,
            overriddendstnodata,
        ),
        mdarray.dataset.value,
    )
end

function getunscaled(
    mdarray::AbstractMDArray,
    overriddenscale = Float64(NaN),
    overriddenoffset = Float64(NaN),
    overriddendstnodata = Float64(NaN),
)::AbstractMDArray
    @assert !isnull(mdarray)
    return IMDArray(
        GDAL.gdalmdarraygetunscaled(
            mdarray,
            overriddenscale,
            overriddenoffset,
            overriddendstnodata,
        ),
        mdarray.dataset.value,
    )
end

function unsafe_getmask(
    mdarray::AbstractMDArray,
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(mdarray)
    return MDArray(
        GDAL.gdalmdarraygetmask(mdarray, CSLConstListWrapper(options)),
        mdarray.dataset.value,
    )
end

function getmask(
    mdarray::AbstractMDArray,
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(mdarray)
    return IMDArray(
        GDAL.gdalmdarraygetmask(mdarray, CSLConstListWrapper(options)),
        mdarray.dataset.value,
    )
end

# TODO: Wrap GDAL.GDALRIOResampleAlg
function unsafe_getresampled(
    mdarray::AbstractMDArray,
    newdims::Union{Nothing,AbstractVector{<:AbstractDimension}},
    resamplealg::GDAL.GDALRIOResampleAlg,
    targetsrs::Union{Nothing,AbstractSpatialRef},
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(mdarray)
    return MDArray(
        GDAL.gdalmdarraygetresampled(
            mdarray,
            newdims === nothing ? 0 : length(newdims),
            newdims === nothing ? C_NULL : DimensionHList(newdims),
            resamplealg,
            targetsrs == nothing ? C_NULL : targetsrs,
            CSLConstListWrapper(options),
        ),
        mdarray.dataset.value,
    )
end

function getresampled(
    mdarray::AbstractMDArray,
    newdims::Union{Nothing,AbstractVector{<:AbstractDimension}},
    resamplealg::GDAL.GDALRIOResampleAlg,
    targetsrs::Union{Nothing,AbstractSpatialRef},
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(mdarray)
    return IMDArray(
        GDAL.gdalmdarraygetresampled(
            mdarray,
            newdims === nothing ? 0 : length(newdims),
            newdims === nothing ? C_NULL : DimensionHList(newdims),
            resamplealg,
            targetsrs == nothing ? C_NULL : targetsrs,
            CSLConstListWrapper(options),
        ),
        mdarray.dataset.value,
    )
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
    return MDArray(
        GDAL.gdalmdarraygetgridded(
            mdarray,
            gridoptions,
            xarray,
            yarray,
            CSLConstListWrapper(options),
        ),
        mdarray.dataset.value,
    )
end

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
    return IMDArray(
        GDAL.gdalmdarraygetgridded(
            mdarray,
            gridoptions,
            xarray,
            yarray,
            CSLConstListWrapper(options),
        ),
        mdarray.dataset.value,
    )
end

function unsafe_asclassicdataset(
    mdarray::AbstractMDArray,
    xdim::Integer,
    ydim::Integer,
    rootgroup::Union{Nothing,AbstractGroup} = nothing,
    options::OptionList = nothing,
)::AbstractDataset
    @assert !isnull(mdarray)
    @assert rootgroup === nothing || !isnull(rootgroup)
    return Dataset(
        GDAL.gdalmdarrayasclassicdataset(
            mdarray,
            xdim,
            ydim,
            rootgroup === nothing ? C_NULL : rootgroup,
            CSLConstListWrapper(options),
        ),
    )
end

function asclassicdataset(
    mdarray::AbstractMDArray,
    xdim::Integer,
    ydim::Integer,
    rootgroup::Union{Nothing,AbstractGroup} = nothing,
    options::OptionList = nothing,
)::AbstractDataset
    @assert !isnull(mdarray)
    @assert rootgroup === nothing || !isnull(rootgroup)
    return IDataset(
        GDAL.gdalmdarrayasclassicdataset(
            mdarray,
            xdim,
            ydim,
            rootgroup === nothing ? C_NULL : rootgroup,
            CSLConstListWrapper(options),
        ),
    )
end

function unsafe_asmdarray(rasterband::AbstractRasterBand)::AbstractMDArray
    @assert !isnull(rasterband)
    # TODO: Find dataset
    return MDArray(GADL.gdalrasterbandasmdarray(rasterband))
end

function asmdarray(rasterband::AbstractRasterBand)::AbstractMDArray
    @assert !isnull(rasterband)
    # TODO: Find dataset
    return IMDArray(GADL.gdalrasterbandasmdarray(rasterband))
end

# TODO: Wrap GDAL.CPLErr
# TODO: Allow a progress function
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
    return succeess, min[], max[], mean[], stddev[], Int64(validcount[])
end

function clearstatistics(mdarray::AbstractMDArray)::Nothing
    @assert !isnull(mdarray)
    return GDAL.gdalmdarrayclearstatistics(mdarray)
end

function getcoordinatevariables(
    mdarray::AbstractMDArray,
)::AbstractVector{<:AbstractMDArray}
    @assert !isnull(mdarray)
    count = Ref{Csize_t}()
    coordinatevariablesptr =
        GDAL.gdalmdarraygetcoordinatevariables(mdarray, count)
    dataset = mdarray.dataset.value
    coordinatevariables = AbstractMDArray[
        IMDArray(unsafe_load(coordinatevariablesptr, n), dataset) for
        n in 1:count[]
    ]
    GDAL.vsifree(coordinatevariablesptr)
    return coordinatevariables
end

function adviseread(
    mdarray::AbstractMDArray,
    arraystartidx::Union{Nothing,AbstractVector{<:Integer}},
    count::Union{Nothing,AbstractVector{<:Integer}},
    options::OptionList = nothing,
)::Bool
    @assert !isnull(mdarray)
    return GDAL.gdalmdarrayadviseread(
        mdarray,
        arraystartidx === nothing ? C_NULL : arraystartidx,
        count === nothing ? C_NULL : count,
        CSLConstListWrapper(options),
    )
end

function isregularlyspaced(
    mdarray::AbstractMDArray,
)::Union{Nothing,Tuple{Float64,Float64}}
    @assert !isnull(mdarray)
    start = Ref{Float64}()
    increment = Ref{Float64}()
    res = GDAL.gdalmdarrayisregularlyspaced(mdarray, start, increment)
    !res[] && return nothing
    return start[], increment[]
end

function guessgeotransform(
    mdarray::AbstractMDArray,
    dimx::Integer,
    dimy::Integer,
    pixelispoint::Bool,
)::Union{Nothing,AbstractVector{Float64}}
    @assert !isnull(mdarray)
    geotransform = Vector{Float64}(undef, 6)
    res = GDAL.gdalmdarrayguessgeotransform(
        mdarray,
        dimx,
        dimy,
        pixelispoint,
        geotransform,
    )
    !res && return nothing
    return geotransform
end

function cache(mdarray::AbstractMDArray, options::OptionList = nothing)::Bool
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraycache(mdarray, CSLConstListWrapper(options))
end

function getrootgroup(mdarray::AbstractMDArray)::AbstractGroup
    @assert !isnull(mdarray)
    return Group(GDAL.gdalmdarraygetrootgroup(mdarray), mdarray.dataset.value)
end

################################################################################

const AbstractAttributeOrMDArray = Union{AbstractAttribute,AbstractMDArray}

function getname(mdarray::AbstractAttributeOrMDArray)::AbstractString
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraygetname(mdarray)
end

function getfullname(mdarray::AbstractAttributeOrMDArray)::AbstractString
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraygetfullname(mdarray)
end

function gettotalelementscount(mdarray::AbstractAttributeOrMDArray)::Int64
    @assert !isnull(mdarray)
    return Int64(GDAL.gdalmdarraygettotalelementscount(mdarray))
end

function Base.length(mdarray::AbstractAttributeOrMDArray)
    @assert !isnull(mdarray)
    return Int(gettotalelementscount(mdarray))
end

function getdimensioncount(mdarray::AbstractAttributeOrMDArray)::Int
    @assert !isnull(mdarray)
    return Int(GDAL.gdalmdarraygetdimensioncount(mdarray))
end

Base.ndims(mdarray::AbstractAttributeOrMDArray)::Int =
    getdimensioncount(mdarray)

function getdimensions(
    mdarray::AbstractAttributeOrMDArray,
)::AbstractVector{<:AbstractDimension}
    @assert !isnull(mdarray)
    dimensionscountref = Ref{Csize_t}()
    dimensionshptr = GDAL.gdalmdarraygetdimensions(mdarray, dimensionscountref)
    dataset = mdarray.dataset.value
    dimensions = AbstractDimension[
        IDimension(unsafe_load(dimensionshptr, n), dataset) for
        n in 1:dimensionscountref[]
    ]
    GDAL.vsifree(dimensionshptr)
    return dimensions
end

function unsafe_getdimensions(
    mdarray::AbstractAttributeOrMDArray,
)::AbstractVector{<:AbstractDimension}
    @assert !isnull(mdarray)
    dimensionscountref = Ref{Csize_t}()
    dimensionshptr = GDAL.gdalmdarraygetdimensions(mdarray, dimensionscountref)
    dataset = mdarray.dataset.value
    dimensions = AbstractDimension[
        Dimension(unsafe_load(dimensionshptr, n), dataset) for
        n in 1:dimensionscountref[]
    ]
    GDAL.vsifree(dimensionshptr)
    return dimensions
end

function unsafe_getdatatype(
    mdarray::AbstractAttributeOrMDArray,
)::AbstractExtendedDataType
    @assert !isnull(mdarray)
    return ExtendedDataType(GDAL.gdalmdarraygetdatatype(mdarray))
end

function getdatatype(
    mdarray::AbstractAttributeOrMDArray,
)::AbstractExtendedDataType
    @assert !isnull(mdarray)
    return IExtendedDataType(GDAL.gdalmdarraygetdatatype(mdarray))
end

function getblocksize(
    mdarray::AbstractAttributeOrMDArray,
    options::OptionList = nothing,
)::AbstractVector{Int64}
    @assert !isnull(mdarray)
    count = Ref{Csize_t}()
    blocksizeptr = GDAL.gdalmdarraygetblocksize(
        mdarray,
        count,
        CSLConstListWrapper(options),
    )
    blocksize = Int64[unsafe_load(blocksizeptr, n) for n in 1:count[]]
    GDAL.vsifree(blocksizeptr)
    return blocksize
end

function getprocessingchunksize(
    mdarray::AbstractAttributeOrMDArray,
    maxchunkmemory::Integer,
)::AbstractVector{Int64}
    @assert !isnull(mdarray)
    count = Ref{Csize_t}()
    chunksizeptr =
        GDAL.gdalmdarraygetprocessingchunksize(mdarray, count, maxchunkmemory)
    chunksize = Int64[unsafe_load(chunksizeptr, n) for n in 1:count[]]
    GDAL.vsifree(chunksizeptr)
    return chunksize
end

# processperchunk

const IndexLike{D} =
    Union{AbstractVector{<:Integer},CartesianIndex{D},NTuple{D,<:Integer}}
const RangeLike{D} = Union{
    AbstractVector{<:AbstractRange{<:Integer}},
    NTuple{D,<:AbstractRange{<:Integer}},
}

function read!(
    mdarray::AbstractAttributeOrMDArray,
    arraystartidx::IndexLike{D},
    count::IndexLike{D},
    arraystep::Union{Nothing,IndexLike{D}},
    buffer::StridedArray{T,D},
)::Bool where {T,D}
    @assert !isnull(mdarray)
    @assert length(arraystartidx) == D
    @assert length(count) == D
    @assert arraystep === nothing ? true : length(arraystep) == D
    gdal_arraystartidx = UInt64[arraystartidx[n] - 1 for n in D:-1:1]
    gdal_count = Csize_t[count[n] for n in D:-1:1]
    gdal_arraystep =
        arraystep === nothing ? nothing : Int64[arraystep[n] for n in D:-1:1]
    gdal_bufferstride = Cptrdiff_t[stride(buffer, n) for n in D:-1:1]
    return extendeddatatypecreate(T) do bufferdatatype
        return GDAL.gdalmdarrayread(
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
    end
end

function read!(
    mdarray::AbstractAttributeOrMDArray,
    region::RangeLike{D},
    buffer::StridedArray{T,D},
)::Bool where {T,D}
    @assert length(region) == D
    arraystartidx = first.(region)
    count = length.(region)
    arraystep = step.(region)
    return read!(mdarray, arraystartidx, count, arraystep, buffer)
end

function read!(
    mdarray::AbstractAttributeOrMDArray,
    indices::CartesianIndices{D},
    arraystep::Union{Nothing,IndexLike{D}},
    buffer::StridedArray{T,D},
)::Bool where {T,D}
    @assert length(region) == D
    arraystartidx = first.(indices)
    count = length.(indices)
    return read!(mdarray, arraystartidx, count, arraystep, buffer)
end

function read!(
    mdarray::AbstractAttributeOrMDArray,
    indices::CartesianIndices{D},
    buffer::StridedArray{T,D},
)::Bool where {T,D}
    return read!(mdarray, indices, nothing, buffer)
end

function read!(
    mdarray::AbstractAttributeOrMDArray,
    buffer::StridedArray{T,D},
)::Bool where {T,D}
    return read!(mdarray, axes(buffer), buffer)
end

function write(
    mdarray::AbstractAttributeOrMDArray,
    arraystartidx::IndexLike{D},
    count::IndexLike{D},
    arraystep::Union{Nothing,IndexLike{D}},
    buffer::StridedArray{T,D},
)::Bool where {T,D}
    @assert !isnull(mdarray)
    @assert length(arraystartidx) == D
    @assert length(count) == D
    @assert arraystep === nothing ? true : length(arraystep) == D
    gdal_arraystartidx = UInt64[arraystartidx[n] - 1 for n in D:-1:1]
    gdal_count = Csize_t[count[n] for n in D:-1:1]
    gdal_arraystep =
        arraystep === nothing ? nothing : Int64[arraystep[n] for n in D:-1:1]
    gdal_bufferstride = Cptrdiff_t[stride(buffer, n) for n in D:-1:1]
    return extendeddatatypecreate(T) do bufferdatatype
        return GDAL.gdalmdarraywrite(
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
    end
end

function write(
    mdarray::AbstractAttributeOrMDArray,
    region::RangeLike{D},
    buffer::StridedArray{T,D},
)::Bool where {T,D}
    @assert length(region) == D
    arraystartidx = first.(region)
    count = length.(region)
    arraystep = step.(region)
    return write(mdarray, arraystartidx, count, arraystep, buffer)
end

function write(
    mdarray::AbstractAttributeOrMDArray,
    indices::CartesianIndices{D},
    arraystep::Union{Nothing,IndexLike{D}},
    buffer::StridedArray{T,D},
)::Bool where {T,D}
    @assert length(region) == D
    arraystartidx = first.(indices)
    count = length.(indices)
    return write(mdarray, arraystartidx, count, arraystep, buffer)
end

function write(
    mdarray::AbstractAttributeOrMDArray,
    indices::CartesianIndices{D},
    buffer::StridedArray{T,D},
)::Bool where {T,D}
    return write(mdarray, indices, nothing, buffer)
end

function write(
    mdarray::AbstractAttributeOrMDArray,
    buffer::StridedArray{T,D},
)::Bool where {T,D}
    return write(mdarray, axes(buffer), buffer)
end

function rename!(mdarray::AbstractMDArray, newname::AbstractString)::Bool
    @assert !isnull(mdarray)
    return GDAL.gdalmdarrayrename(mdarray, newname)
end
