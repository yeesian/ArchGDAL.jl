# GDALDimension

function getname(dimension::AbstractDimension)::AbstractString
    @assert !isnull(dimension)
    return GDAL.gdaldimensiongetname(dimension)
end

function getfullname(dimension::AbstractDimension)::AbstractString
    @assert !isnull(dimension)
    return GDAL.gdaldimensiongetfullname(dimension)
end

function gettype(dimension::AbstractDimension)::AbstractString
    @assert !isnull(dimension)
    return GDAL.gdaldimensiongettype(dimension)
end

function getdirection(dimension::AbstractDimension)::AbstractString
    @assert !isnull(dimension)
    return GDAL.gdaldimensiongetdirection(dimension)
end

function getsize(dimension::AbstractDimension)::Int
    @assert !isnull(dimension)
    return Int(GDAL.gdaldimensiongetsize(dimension))
end

function unsafe_getindexingvariable(
    dimension::AbstractDimension,
)::AbstractMDArray
    @assert !isnull(dimension)
    ptr = GDAL.gdaldimensiongetindexingvariable(dimension)
    ptr == C_NULL && error("Could not get indexing variable for dimension")
    return MDArray(ptr, dimension.dataset.value)
end

function getindexingvariable(dimension::AbstractDimension)::AbstractMDArray
    @assert !isnull(dimension)
    ptr = GDAL.gdaldimensiongetindexingvariable(dimension)
    ptr == C_NULL && error("Could not get indexing variable for dimension")
    return IMDArray(ptr, dimension.dataset.value)
end

function setindexingvariable!(
    dimension::AbstractDimension,
    indexingvariable::AbstractMDArray,
)::Nothing
    @assert !isnull(dimension)
    success = GDAL.gdaldimensionsetindexingvariable(dimension, indexingvariable)
    success == 0 && error("Could not set indexing variable for dimension")
    return nothing
end

function rename!(dimension::AbstractDimension, newname::AbstractString)::Bool
    @assert !isnull(dimension)
    return GDAL.gdaldimensionrename(dimension, newname)
end
