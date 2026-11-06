# GDALDimension

"""
    getname(dimension::AbstractDimension)

Return the name of the dimension.
"""
function getname(dimension::AbstractDimension)::AbstractString
    @assert !isnull(dimension)
    return GDAL.gdaldimensiongetname(dimension)
end

"""
    getfullname(dimension::AbstractDimension)

Return the full name of the dimension, including the path of its group,
e.g. `"/group/x"`.
"""
function getfullname(dimension::AbstractDimension)::AbstractString
    @assert !isnull(dimension)
    return GDAL.gdaldimensiongetfullname(dimension)
end

"""
    gettype(dimension::AbstractDimension)

Return the type of the dimension, e.g. `"HORIZONTAL_X"`, or `""` if unknown.
See `createdimension`.
"""
function gettype(dimension::AbstractDimension)::AbstractString
    @assert !isnull(dimension)
    return GDAL.gdaldimensiongettype(dimension)
end

"""
    getdirection(dimension::AbstractDimension)

Return the direction of the dimension, e.g. `"EAST"`, or `""` if unknown.
See `createdimension`.
"""
function getdirection(dimension::AbstractDimension)::AbstractString
    @assert !isnull(dimension)
    return GDAL.gdaldimensiongetdirection(dimension)
end

"""
    getsize(dimension::AbstractDimension)

Return the number of elements along the dimension.
"""
function getsize(dimension::AbstractDimension)::Int
    @assert !isnull(dimension)
    return Int(GDAL.gdaldimensiongetsize(dimension))
end

# These return `nothing` if the dimension has no indexing variable
function unsafe_getindexingvariable(
    dimension::AbstractDimension,
)::Union{Nothing,AbstractMDArray}
    @assert !isnull(dimension)
    ptr = GDAL.gdaldimensiongetindexingvariable(dimension)
    ptr == C_NULL && return nothing
    return MDArray(ptr, dimension.dataset)
end

"""
    getindexingvariable(dimension::AbstractDimension)

Return the variable that indexes the dimension, i.e. the (typically
1-dimensional) array holding the coordinate values along it.

### Returns
The indexing variable, or `nothing` if the dimension has none.
"""
function getindexingvariable(
    dimension::AbstractDimension,
)::Union{Nothing,AbstractMDArray}
    @assert !isnull(dimension)
    ptr = GDAL.gdaldimensiongetindexingvariable(dimension)
    ptr == C_NULL && return nothing
    return IMDArray(ptr, dimension.dataset)
end

# Not generated in context.jl, since there may be nothing to destroy
function getindexingvariable(f::Function, dimension::AbstractDimension)
    indexingvariable = unsafe_getindexingvariable(dimension)
    try
        return f(indexingvariable)
    finally
        isnothing(indexingvariable) || destroy(indexingvariable)
    end
end

"""
    setindexingvariable!(dimension::AbstractDimension,
                         indexingvariable::AbstractMDArray)

Set the variable that indexes the dimension. Throws an error on failure.
"""
function setindexingvariable!(
    dimension::AbstractDimension,
    indexingvariable::AbstractMDArray,
)::Nothing
    @assert !isnull(dimension)
    success = GDAL.gdaldimensionsetindexingvariable(dimension, indexingvariable)
    success == 0 && error("Could not set indexing variable for dimension")
    return nothing
end

"""
    rename!(dimension::AbstractDimension, newname::AbstractString)

Rename the dimension. Not all drivers support renaming.

### Returns
`true` on success.
"""
function rename!(dimension::AbstractDimension, newname::AbstractString)::Bool
    @assert !isnull(dimension)
    return GDAL.gdaldimensionrename(dimension, newname)
end
