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
        isnothing(storagetype) ? GDAL.GDT_Unknown :
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
        isnothing(storagetype) ? GDAL.GDT_Unknown :
        convert(GDAL.GDALDataType, storagetype),
    )
end

function unsafe_getview(
    mdarray::AbstractMDArray,
    viewexpr::AbstractString,
)::AbstractMDArray
    @assert !isnull(mdarray)
    ptr = GDAL.gdalmdarraygetview(mdarray, viewexpr)
    ptr == C_NULL && error("Could not get view \"$vierexpr\"")
    return MDArray(ptr, mdarray.dataset)
end

function getview(
    mdarray::AbstractMDArray,
    viewexpr::AbstractString,
)::AbstractMDArray
    @assert !isnull(mdarray)
    ptr = GDAL.gdalmdarraygetview(mdarray, viewexpr)
    ptr == C_NULL && error("Could not get view \"$vierexpr\"")
    return IMDArray(ptr, mdarray.dataset)
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
    ptr = GDAL.gdalmdarraytranspose(mdarray)
    ptr == C_NULL && error("Could not transpose mdarray")
    return MDArray(ptr, mdarray.dataset)
end

function transpose(mdarray::AbstractMDArray)::AbstractMDArray
    @assert !isnull(mdarray)
    ptr = GDAL.gdalmdarraytranspose(mdarray)
    ptr == C_NULL && error("Could not transpose mdarray")
    return IMDArray(ptr, mdarray.dataset)
end

function unsafe_getunscaled(
    mdarray::AbstractMDArray,
    overriddenscale = Float64(NaN),
    overriddenoffset = Float64(NaN),
    overriddendstnodata = Float64(NaN),
)::AbstractMDArray
    @assert !isnull(mdarray)
    ptr = GDAL.gdalmdarraygetunscaled(
        mdarray,
        overriddenscale,
        overriddenoffset,
        overriddendstnodata,
    )
    ptr == C_NULL && error("Could not get unscaled mdarray")
    return MDArray(ptr, mdarray.dataset)
end

function getunscaled(
    mdarray::AbstractMDArray,
    overriddenscale = Float64(NaN),
    overriddenoffset = Float64(NaN),
    overriddendstnodata = Float64(NaN),
)::AbstractMDArray
    @assert !isnull(mdarray)
    ptr = GDAL.gdalmdarraygetunscaled(
        mdarray,
        overriddenscale,
        overriddenoffset,
        overriddendstnodata,
    )
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
    mdarray::AbstractMDArray,
    newdims::Union{Nothing,AbstractVector{<:AbstractDimension}},
    resamplealg::GDAL.GDALRIOResampleAlg,
    targetsrs::Union{Nothing,AbstractSpatialRef},
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(mdarray)
    ptr = GDAL.gdalmdarraygetresampled(
        mdarray,
        isnothing(newdims) ? 0 : length(newdims),
        isnothing(newdims) ? C_NULL : DimensionHList(newdims),
        resamplealg,
        isnothing(targetsrs) ? C_NULL : targetsrs,
        CSLConstListWrapper(options),
    )
    ptr == C_NULL && error("Could not get resampled mdarray")
    return MDArray(ptr, mdarray.dataset)
end

function getresampled(
    mdarray::AbstractMDArray,
    newdims::Union{Nothing,AbstractVector{<:AbstractDimension}},
    resamplealg::GDAL.GDALRIOResampleAlg,
    targetsrs::Union{Nothing,AbstractSpatialRef},
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(mdarray)
    ptr = GDAL.gdalmdarraygetresampled(
        mdarray,
        isnothing(newdims) ? 0 : length(newdims),
        isnothing(newdims) ? C_NULL : DimensionHList(newdims),
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

function unsafe_asclassicdataset(
    mdarray::AbstractMDArray,
    xdim::Integer,
    ydim::Integer,
    rootgroup::Union{Nothing,AbstractGroup} = nothing,
    options::OptionList = nothing,
)::AbstractDataset
    @assert !isnull(mdarray)
    @assert isnothing(rootgroup) || !isnull(rootgroup)
    return Dataset(
        GDAL.gdalmdarrayasclassicdataset(
            mdarray,
            xdim,
            ydim,
            isnothing(rootgroup) ? C_NULL : rootgroup,
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
    @assert isnothing(rootgroup) || !isnull(rootgroup)
    return IDataset(
        GDAL.gdalmdarrayasclassicdataset(
            mdarray,
            xdim,
            ydim,
            isnothing(rootgroup) ? C_NULL : rootgroup,
            CSLConstListWrapper(options),
        ),
    )
end

function unsafe_asmdarray(rasterband::AbstractRasterBand)::AbstractMDArray
    @assert !isnull(rasterband)
    ptr = GADL.gdalrasterbandasmdarray(rasterband)
    ptr == C_NULL && error("Could not get view rasterband view as mdarray")
    # TODO: Find dataset
    return MDArray(ptr)
end

function asmdarray(rasterband::AbstractRasterBand)::AbstractMDArray
    @assert !isnull(rasterband)
    ptr = GADL.gdalrasterbandasmdarray(rasterband)
    ptr == C_NULL && error("Could not get view rasterband view as mdarray")
    # TODO: Find dataset
    return IMDArray(ptr)
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
    return Bool(succeess), min[], max[], mean[], stddev[], Int64(validcount[])
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
    coordinatevariables = AbstractMDArray[
        IMDArray(unsafe_load(coordinatevariablesptr, n), mdarray.dataset)
        for n in 1:count[]
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
        isnothing(arraystartidx) ? C_NULL : arraystartidx,
        isnothing(count) ? C_NULL : count,
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
    return Group(GDAL.gdalmdarraygetrootgroup(mdarray), mdarray.dataset)
end

################################################################################

function getname(mdarray::AbstractMDArray)::AbstractString
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraygetname(mdarray)
end

function getfullname(mdarray::AbstractMDArray)::AbstractString
    @assert !isnull(mdarray)
    return GDAL.gdalmdarraygetfullname(mdarray)
end

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
getdimensioncount(mdarray::AbstractMDArray{<:Any,D}) where {D} = D

Base.ndims(mdarray::AbstractMDArray)::Int = getdimensioncount(mdarray)

function getdimensions(
    mdarray::AbstractMDArray,
)::AbstractVector{<:AbstractDimension}
    @assert !isnull(mdarray)
    dimensionscountref = Ref{Csize_t}()
    dimensionshptr = GDAL.gdalmdarraygetdimensions(mdarray, dimensionscountref)
    dimensions = AbstractDimension[
        IDimension(unsafe_load(dimensionshptr, n), mdarray.dataset) for
        n in 1:dimensionscountref[]
    ]
    GDAL.vsifree(dimensionshptr)
    return dimensions
end

function unsafe_getdimensions(
    mdarray::AbstractMDArray,
)::AbstractVector{<:AbstractDimension}
    @assert !isnull(mdarray)
    dimensionscountref = Ref{Csize_t}()
    dimensionshptr = GDAL.gdalmdarraygetdimensions(mdarray, dimensionscountref)
    dimensions = AbstractDimension[
        Dimension(unsafe_load(dimensionshptr, n), mdarray.dataset) for
        n in 1:dimensionscountref[]
    ]
    GDAL.vsifree(dimensionshptr)
    return dimensions
end

function Base.size(mdarray::AbstractMDArray)
    getdimensions(mdarray) do dimensions
        D = length(dimensions)
        return ntuple(d -> getsize(dimensions[D-d+1]), D)
    end
end

function unsafe_getdatatype(mdarray::AbstractMDArray)::AbstractExtendedDataType
    @assert !isnull(mdarray)
    return ExtendedDataType(GDAL.gdalmdarraygetdatatype(mdarray))
end

function getdatatype(mdarray::AbstractMDArray)::AbstractExtendedDataType
    @assert !isnull(mdarray)
    return IExtendedDataType(GDAL.gdalmdarraygetdatatype(mdarray))
end

Base.eltype(mdarray::AbstractMDArray{T}) where {T} = T

function getblocksize(mdarray::AbstractMDArray)::AbstractVector{Int64}
    @assert !isnull(mdarray)
    count = Ref{Csize_t}()
    blocksizeptr = GDAL.gdalmdarraygetblocksize(mdarray, count)
    blocksize = Int64[unsafe_load(blocksizeptr, n) for n in count[]:-1:1]
    GDAL.vsifree(blocksizeptr)
    return blocksize
end

DiskArrays.haschunks(::AbstractMDArray) = DiskArrays.Chunked()
function DiskArrays.eachchunk(
    mdarray::AbstractMDArray{<:Any,D},
)::NTuple{D,Int} where {D}
    blocksize = getblocksize(mdarray)
    return DiskArrays.GridChunks(mdarray, Int.(blocksize))
end

function getprocessingchunksize(
    mdarray::AbstractMDArray,
    maxchunkmemory::Integer,
)::AbstractVector{Int64}
    @assert !isnull(mdarray)
    count = Ref{Csize_t}()
    chunksizeptr =
        GDAL.gdalmdarraygetprocessingchunksize(mdarray, count, maxchunkmemory)
    chunksize = Int64[unsafe_load(chunksizeptr, n) for n in count[]:-1:1]
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
    gdal_arraystartidx = UInt64[arraystartidx[n] - 1 for n in D:-1:1]
    gdal_count = Csize_t[count[n] for n in D:-1:1]
    gdal_arraystep =
        isnothing(arraystep) ? nothing : Int64[arraystep[n] for n in D:-1:1]
    gdal_bufferstride = Cptrdiff_t[stride(buffer, n) for n in D:-1:1]
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
    @assert length(region) == D
    arraystartidx = first.(indices)
    count = length.(indices)
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

function read(mdarray::AbstractMDArray)::AbstractArray
    getdimensions(mdarray) do dimensions
        D = length(dimensions)
        sz = [getsize(dimensions[d]) for d in D:-1:1]
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
    mdarray::AbstractMDArray{<:Any,D},
    aout,
    r::Vararg{AbstractUnitRange,D},
)::Nothing where {D}
    success == read!(mdarray, r, aout)
    @assert success
    return nothing
end

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
    gdal_arraystartidx = UInt64[arraystartidx[n] - 1 for n in D:-1:1]
    gdal_count = Csize_t[count[n] for n in D:-1:1]
    gdal_arraystep =
        isnothing(arraystep) ? nothing : Int64[arraystep[n] for n in D:-1:1]
    gdal_bufferstride = Cptrdiff_t[stride(buffer, n) for n in D:-1:1]
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
    @assert length(region) == D
    arraystartidx = first.(indices)
    count = length.(indices)
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
    mdarray::AbstractMDArray{<:Any,D},
    ain,
    r::Vararg{AbstractUnitRange,D},
)::Nothing where {D}
    success == write(mdarray, r, ain)
    @assert success
    return nothing
end

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
    dimensions::AbstractVector{<:Integer},
    datatype::AbstractExtendedDataType,
    options::OptionList = nothing,
)::AbstractAttribute
    @assert !isnull(mdarray)
    @assert !isnull(datatype)
    ptr = GDAL.gdalmdarraycreateattribute(
        mdarray,
        name,
        length(dimensions),
        dimensions,
        datatype,
        CSLConstListWrapper(options),
    )
    ptr == C_NULL && error("Could not create attribute \"$name\"")
    return Attribute(ptr, mdarray.dataset)
end

function createattribute(
    mdarray::AbstractMDArray,
    name::AbstractString,
    dimensions::AbstractVector{<:Integer},
    datatype::AbstractExtendedDataType,
    options::OptionList = nothing,
)::AbstractAttribute
    @assert !isnull(mdarray)
    @assert !isnull(datatype)
    ptr = GDAL.gdalmdarraycreateattribute(
        mdarray,
        name,
        length(dimensions),
        dimensions,
        datatype,
        CSLConstListWrapper(options),
    )
    ptr == C_NULL && error("Could not create attribute \"$name\"")
    return IAttribute(ptr, mdarray.dataset)
end

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
