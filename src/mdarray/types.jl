abstract type AbstractExtendedDataType end
# needs to have a `ptr::GDALExtendedDataTypeH` attribute

abstract type AbstractEDTComponent end
# needs to have a `ptr::GDALEDTComponentH` attribute

# TODO: <: AbstractDict
abstract type AbstractGroup end
# needs to have a `ptr::GDAL.GDALGroupH` attribute

abstract type AbstractMDArray{T,D} <: AbstractDiskArray{T,D} end
# needs to have a `ptr::GDAL.GDALMDArrayH` attribute

# TODO: <: DenseArray{T,D}
abstract type AbstractAttribute end
# needs to have a `ptr::GDAL.GDALAttributeH` attribute

abstract type AbstractDimension end
# needs to have a `ptr::GDAL.GDALDimensionH` attribute

################################################################################

# In the multidim API, objects obtained from a dataset (groups, arrays,
# attributes, dimensions) keep the underlying file open and can be used
# after the dataset has been closed; see "Objects lifetime" in
# <https://gdal.org/en/stable/user/multidim_raster_data_model.html>.
# A file being written is therefore only complete once all of these
# objects have been released.
#
# Interactive objects are released by the garbage collector, i.e. at an
# unpredictable time. To be able to close a dataset at a well-defined
# time, multidim datasets (`dataset.children !== nothing`) keep weak
# references to their interactive children, and
# `force_close_mdarray_dataset!` destroys them before closing the
# dataset. Scoped objects (`unsafe_*`, do-blocks) are released
# explicitly and are not tracked.
function _add_mdarray_child!(dataset::WeakRef, obj::Any)::Nothing
    isnull(obj) && return nothing
    dataset = dataset.value
    # It is fine if the dataset does not exist any more
    isnothing(dataset) && return nothing
    dataset::AbstractDataset
    @assert !isnull(dataset)
    isnothing(dataset.children) && return nothing
    push!(dataset.children, WeakRef(obj))
    return nothing
end

################################################################################

mutable struct ExtendedDataType <: AbstractExtendedDataType
    ptr::GDAL.GDALExtendedDataTypeH

    ExtendedDataType(ptr::GDAL.GDALExtendedDataTypeH) = new(ptr)
end

mutable struct IExtendedDataType <: AbstractExtendedDataType
    ptr::GDAL.GDALExtendedDataTypeH

    function IExtendedDataType(ptr::GDAL.GDALExtendedDataTypeH)
        extendeddatatype = new(ptr)
        ptr != C_NULL && finalizer(destroy, extendeddatatype)
        return extendeddatatype
    end
end

mutable struct EDTComponent <: AbstractEDTComponent
    ptr::GDAL.GDALEDTComponentH

    EDTComponent(ptr::GDAL.GDALEDTComponentH) = new(ptr)
end

mutable struct IEDTComponent <: AbstractEDTComponent
    ptr::GDAL.GDALEDTComponentH

    function IEDTComponent(ptr::GDAL.GDALEDTComponentH)
        edtcomponent = new(ptr)
        ptr != C_NULL && finalizer(destroy, edtcomponent)
        return edtcomponent
    end
end

mutable struct Group <: AbstractGroup
    ptr::GDAL.GDALGroupH
    dataset::WeakRef            # AbstractDataset

    function Group(ptr::GDAL.GDALGroupH, dataset::WeakRef)
        group = new(ptr, dataset)
        return group
    end
end

mutable struct IGroup <: AbstractGroup
    ptr::GDAL.GDALGroupH
    dataset::WeakRef            # AbstractDataset

    function IGroup(ptr::GDAL.GDALGroupH, dataset::WeakRef)
        group = new(ptr, dataset)
        _add_mdarray_child!(dataset, group)
        ptr != C_NULL && finalizer(destroy, group)
        return group
    end
end

mutable struct MDArray{T,D} <: AbstractMDArray{T,D}
    ptr::GDAL.GDALMDArrayH
    dataset::WeakRef            # AbstractDataset

    function MDArray{T,D}(ptr::GDAL.GDALMDArrayH, dataset::WeakRef) where {T,D}
        T::Type
        D::Int
        mdarray = new{T,D}(ptr, dataset)
        return mdarray
    end
end

mutable struct IMDArray{T,D} <: AbstractMDArray{T,D}
    ptr::GDAL.GDALMDArrayH
    dataset::WeakRef            # AbstractDataset

    function IMDArray{T,D}(ptr::GDAL.GDALMDArrayH, dataset::WeakRef) where {T,D}
        T::Type
        D::Int
        mdarray = new{T,D}(ptr, dataset)
        _add_mdarray_child!(dataset, mdarray)
        ptr != C_NULL && finalizer(destroy, mdarray)
        return mdarray
    end
end

mutable struct Attribute <: AbstractAttribute
    ptr::GDAL.GDALAttributeH
    dataset::WeakRef            # AbstractDataset

    function Attribute(ptr::GDAL.GDALAttributeH, dataset::WeakRef)
        attribute = new(ptr, dataset)
        return attribute
    end
end

mutable struct IAttribute <: AbstractAttribute
    ptr::GDAL.GDALAttributeH
    dataset::WeakRef            # AbstractDataset

    function IAttribute(ptr::GDAL.GDALAttributeH, dataset::WeakRef)
        attribute = new(ptr, dataset)
        _add_mdarray_child!(dataset, attribute)
        ptr != C_NULL && finalizer(destroy, attribute)
        return attribute
    end
end

mutable struct Dimension <: AbstractDimension
    ptr::GDAL.GDALDimensionH
    dataset::WeakRef            # AbstractDataset

    function Dimension(ptr::GDAL.GDALDimensionH, dataset::WeakRef)
        dimension = new(ptr, dataset)
        return dimension
    end
end

mutable struct IDimension <: AbstractDimension
    ptr::GDAL.GDALDimensionH
    dataset::WeakRef            # AbstractDataset

    function IDimension(ptr::GDAL.GDALDimensionH, dataset::WeakRef)
        dimension = new(ptr, dataset)
        _add_mdarray_child!(dataset, dimension)
        ptr != C_NULL && finalizer(destroy, dimension)
        return dimension
    end
end

################################################################################

isnull(x::AbstractAttribute) = x.ptr == C_NULL
isnull(x::AbstractDataset) = x.ptr == C_NULL
isnull(x::AbstractDimension) = x.ptr == C_NULL
isnull(x::AbstractEDTComponent) = x.ptr == C_NULL
isnull(x::AbstractExtendedDataType) = x.ptr == C_NULL
isnull(x::AbstractFeature) = x.ptr == C_NULL
isnull(x::AbstractFeatureDefn) = x.ptr == C_NULL
isnull(x::AbstractFeatureLayer) = x.ptr == C_NULL
isnull(x::AbstractFieldDefn) = x.ptr == C_NULL
isnull(x::AbstractGeomFieldDefn) = x.ptr == C_NULL
isnull(x::AbstractGeometry) = x.ptr == C_NULL
isnull(x::AbstractGroup) = x.ptr == C_NULL
isnull(x::AbstractMDArray) = x.ptr == C_NULL
isnull(x::AbstractRasterBand) = x.ptr == C_NULL
isnull(x::AbstractSpatialRef) = x.ptr == C_NULL
isnull(x::ColorTable) = x.ptr == C_NULL
isnull(x::CoordTransform) = x.ptr == C_NULL
isnull(x::Driver) = x.ptr == C_NULL
isnull(x::Field) = x.ptr == C_NULL
isnull(x::RasterAttrTable) = x.ptr == C_NULL
isnull(x::StyleManager) = x.ptr == C_NULL
isnull(x::StyleTable) = x.ptr == C_NULL
isnull(x::StyleTool) = x.ptr == C_NULL

################################################################################

const VectorLike{T} = Union{AbstractVector{<:T},NTuple{<:Any,X where X<:T}}

const IndexLike{D} = Union{
    AbstractVector{<:Integer},
    CartesianIndex{D},
    NTuple{D,I where I<:Integer},
}
const RangeLike{D} = Union{
    AbstractVector{<:AbstractRange{<:Integer}},
    NTuple{D,R where R<:AbstractRange{<:Integer}},
}

################################################################################

Base.unsafe_convert(::Type{Ptr{Cvoid}}, x::AbstractExtendedDataType) = x.ptr
Base.unsafe_convert(::Type{Ptr{Cvoid}}, x::AbstractEDTComponent) = x.ptr
Base.unsafe_convert(::Type{Ptr{Cvoid}}, x::AbstractGroup) = x.ptr
Base.unsafe_convert(::Type{Ptr{Cvoid}}, x::AbstractMDArray) = x.ptr
Base.unsafe_convert(::Type{Ptr{Cvoid}}, x::AbstractAttribute) = x.ptr
Base.unsafe_convert(::Type{Ptr{Cvoid}}, x::AbstractDimension) = x.ptr

################################################################################

function destroy(datatype::AbstractExtendedDataType)::Nothing
    datatype.ptr == C_NULL && return nothing
    GDAL.gdalextendeddatatyperelease(datatype)
    datatype.ptr = C_NULL
    return nothing
end

function destroy(edtcomponent::AbstractEDTComponent)::Nothing
    edtcomponent.ptr == C_NULL && return nothing
    GDAL.gdaledtcomponentrelease(edtcomponent)
    edtcomponent.ptr = C_NULL
    return nothing
end

function destroy(group::AbstractGroup)::Nothing
    group.ptr == C_NULL && return nothing
    GDAL.gdalgrouprelease(group)
    group.ptr = C_NULL
    return nothing
end

function destroy(mdarray::AbstractMDArray)::Nothing
    mdarray.ptr == C_NULL && return nothing
    GDAL.gdalmdarrayrelease(mdarray)
    mdarray.ptr = C_NULL
    return nothing
end

function destroy(attribute::AbstractAttribute)::Nothing
    attribute.ptr == C_NULL && return nothing
    GDAL.gdalattributerelease(attribute)
    attribute.ptr = C_NULL
    return nothing
end

function destroy(dimension::AbstractDimension)::Nothing
    dimension.ptr == C_NULL && return nothing
    GDAL.gdaldimensionrelease(dimension)
    dimension.ptr = C_NULL
    return nothing
end

function destroy(edtcomponents::VectorLike{<:AbstractEDTComponent})
    return destroy.(edtcomponents)
end
destroy(attributes::VectorLike{<:AbstractAttribute}) = destroy.(attributes)
destroy(dimensions::VectorLike{<:AbstractDimension}) = destroy.(dimensions)
# E.g. the dimensions of a 0-dimensional array; ambiguous otherwise
destroy(::Tuple{}) = nothing

################################################################################

# Helpers

const OptionList = Union{Nothing,AbstractVector{<:AbstractString}}

# TODO: Move to GDAL.jl, redefining `CSLConstList`
struct CSLConstListWrapper
    # Hold on to the original arguments to prevent GC from freeing
    # them while they are being used in a ccall
    cstrings::Union{Nothing,Vector{Cstring}}
    strings::Any

    function CSLConstListWrapper(strings::Nothing)
        cstrings = nothing
        return new(cstrings, strings)
    end
    function CSLConstListWrapper(
        strings::AbstractVector{<:Union{String,SubString{String}}},
    )
        cstrings = Cstring[[pointer(str) for str in strings]; C_NULL]
        return new(cstrings, strings)
    end
end
function CSLConstListWrapper(strings::AbstractVector{<:AbstractString})
    return CSLConstListWrapper(String.(strings))
end

function Base.cconvert(::Type{GDAL.CSLConstList}, wrapper::CSLConstListWrapper)
    isnothing(wrapper.cstrings) &&
        return Base.cconvert(GDAL.CSLConstList, C_NULL)
    return Base.cconvert(GDAL.CSLConstList, wrapper.cstrings)
end

struct DimensionHList
    # Hold on to the original arguments to prevent GC from freeing
    # them while they are being used in a ccall
    dimensionhs::Vector{GDAL.GDALDimensionH}
    dimensions::AbstractVector{<:AbstractDimension}

    function DimensionHList(dimensions::AbstractVector{<:AbstractDimension})
        dimensionhs = GDAL.GDALDimensionH[
            Base.unsafe_convert(Ptr{Cvoid}, dim) for dim in dimensions
        ]
        return new(dimensionhs, dimensions)
    end
end
function DimensionHList(dimensions::NTuple{<:Any,T where T<:AbstractDimension})
    return DimensionHList([dimensions...])
end

function Base.cconvert(
    ::Type{Ptr{GDAL.GDALDimensionH}},
    dimensionhlist::DimensionHList,
)
    return Base.cconvert(Ptr{Cvoid}, dimensionhlist.dimensionhs)
end
