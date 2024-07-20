abstract type AbstractExtendedDataType end
# needs to have a `ptr::GDALExtendedDataTypeH` attribute

abstract type AbstractEDTComponent end
# needs to have a `ptr::GDALEDTComponentH` attribute

abstract type AbstractGroup end
# needs to have a `ptr::GDAL.GDALGroupH` attribute

abstract type AbstractMDArray end
# needs to have a `ptr::GDAL.GDALMDArrayH` attribute

abstract type AbstractAttribute end
# needs to have a `ptr::GDAL.GDALAttributeH` attribute

abstract type AbstractDimension end
# needs to have a `ptr::GDAL.GDALDimensionH` attribute

################################################################################

# Question: Why do the `I...` types exist? The only difference seems
# to be that they call a finalizer. This could instead be an option to
# the constructor, simplifying the type hierarchy.

mutable struct ExtendedDataType <: AbstractExtendedDataType
    ptr::GDAL.GDALExtendedDataTypeH
end

mutable struct EDTComponent <: AbstractEDTComponent
    ptr::GDAL.GDALEDTComponentH
end

mutable struct Group <: AbstractGroup
    ptr::GDAL.GDALGroupH

    Group(ptr::GDAL.GDALGroupH = C_NULL) = new(ptr)
end

mutable struct IGroup <: AbstractGroup
    ptr::GDAL.GDALGroupH

    function IGroup(ptr::GDAL.GDALGroupH = C_NULL)
        group = new(ptr)
        finalizer(destroy, group)
        return group
    end
end

mutable struct MDArray <: AbstractMDArray
    ptr::GDAL.GDALMDArrayH

    MDArray(ptr::GDAL.GDALMDArrayH = C_NULL) = new(ptr)
end

mutable struct IMDArray <: AbstractMDArray
    ptr::GDAL.GDALMDArrayH

    function IMDArray(ptr::GDAL.GDALMDArrayH = C_NULL)
        mdarray = new(ptr)
        finalizer(destroy, mdarray)
        return mdarray
    end
end

mutable struct Attribute <: AbstractAttribute
    ptr::GDAL.GDALAttributeH

    Attribute(ptr::GDAL.GDALAttributeH = C_NULL) = new(ptr)
end

mutable struct IAttribute <: AbstractAttribute
    ptr::GDAL.GDALAttributeH

    function IAttribute(ptr::GDAL.GDALAttributeH = C_NULL)
        attribute = new(ptr)
        finalizer(destroy, attribute)
        return attribute
    end
end

mutable struct Dimension <: AbstractDimension
    ptr::GDAL.GDALDimensionH

    Dimension(ptr::GDAL.GDALDimensionH = C_NULL) = new(ptr)
end

mutable struct IDimension <: AbstractDimension
    ptr::GDAL.GDALDimensionH

    function IDimension(ptr::GDAL.GDALDimensionH = C_NULL)
        dimension = new(ptr)
        finalizer(destroy, dimension)
        return dimension
    end
end

################################################################################

Base.unsafe_convert(::Type{Ptr{Cvoid}}, x::AbstractExtendedDataType) = x.ptr
Base.unsafe_convert(::Type{Ptr{Cvoid}}, x::AbstractEDTComponent) = x.ptr
Base.unsafe_convert(::Type{Ptr{Cvoid}}, x::AbstractGroup) = x.ptr
Base.unsafe_convert(::Type{Ptr{Cvoid}}, x::AbstractMDArray) = x.ptr
Base.unsafe_convert(::Type{Ptr{Cvoid}}, x::AbstractAttribute) = x.ptr
Base.unsafe_convert(::Type{Ptr{Cvoid}}, x::AbstractDimension) = x.ptr

################################################################################

function destroy(datatype::AbstractExtendedDataType)::Nothing
    GDAL.gdalextendeddatatyperelease(datatype)
    datatype.ptr = C_NULL
    return nothing
end

function destroy(edtcomponent::AbstractEDTComponent)::Nothing
    GDAL.gdaledtcomponentrelease(edtcomponent)
    edtcomponent.ptr = C_NULL
    return nothing
end

function destroy(group::AbstractGroup)::Nothing
    GDAL.gdalgrouprelease(group)
    group.ptr = C_NULL
    return nothing
end

function destroy(mdarray::AbstractMDArray)::Nothing
    GDAL.gdalmdarrayrelease(mdarray)
    mdarray.ptr = C_NULL
    return nothing
end

function destroy(attribute::AbstractAttribute)::Nothing
    GDAL.gdalattributerelease(attribute)
    attribute.ptr = C_NULL
    return nothing
end

function destroy(dimension::AbstractDimension)::Nothing
    GDAL.gdaldimensionrelease(dimension)
    dimension.ptr = C_NULL
    return nothing
end

################################################################################

# GDALGroup

function getname(group::AbstractGroup)::AbstractString
    return GDAL.gdalgroupgetname(group)
end

function getfullname(group::AbstractGroup)::AbstractString
    return GDAL.gdalgroupgetfullname(group)
end

function getmdarraynames(
    group::AbstractGroup,
    options = nothing,
)::AbstractVector{<:AbstractString}
    # TODO: allow options
    @assert options === nothing
    return GDAL.gdalgroupgetmdarraynames(group, C_NULL)
end

function openmdarray(
    group::AbstractGroup,
    name::AbstractString,
    options,
)::AbstractMDArray
    # TODO: allow options
    @assert options === nothing
    return IMDArray(GDAL.gdalgroupopenmdarray(group, name, C_NULL))
end

function getgroupnames(
    group::AbstractGroup,
    options = nothing,
)::AbstractVector{<:AbstractString}
    # TODO: allow options
    @assert options === nothing
    return GDAL.gdalgroupgetgroupnames(group, C_NULL)
end

function opengroup(
    group::AbstractGroup,
    name::AbstractString,
    options,
)::AbstractGroup
    # TODO: allow options
    @assert options === nothing
    return IGroup(GDAL.gdalgroupopengroup(group, name, C_NULL))
end

function getvectorlayernames(
    group::AbstractGroup,
    options,
)::AbstractVector{<:AbstractString}
    # TODO: allow options
    @assert options === nothing
    return GDAL.gdalgroupgetvectorlayernames(group, C_NULL)
end

function openvectorlayer(group::AbstractGroup, options)::AbstractFeatureLayer
    # TODO: allow options
    @assert options === nothing
    # TODO: Find out how to set `ownedby` and `spatialref`, probably by querying `group`
    return IFeatureLayer(
        GDAL.openvectorlayer(group, C_NULL),
        ownedby,
        spatialref,
    )
end

function getdimensions(
    group::AbstractGroup,
    options,
)::AbstractVector{<:AbstractDimension}
    # TODO: allow options
    @assert options === nothing
    dimensioncountref = Ref{Csize_t}()
    dimensionshptr = GDAL.gdalgroupgetdimensions(group, ndimensions, C_NULL)
    dimensions = AbstractDimension[
        IDimension(unsafe_load(dimensionhptr, n)) for
        n in 1:dimensionscountref[]
    ]
    GDAL.vsifree(dimensionshptr)
    return dimensions
end

function creategroup(
    group::AbstractGroup,
    name::AbstractString,
    options,
)::AbstractGroup
    # TODO: allow options
    @assert options === nothing
    return IGroup(GDAL.gdalgroupcreategroup(group, name, C_NULL))
end

function deletegroup(group::AbstractGroup, name::AbstractString, options)::Bool
    # TODO: allow options
    @assert options === nothing
    return GDAL.gdalgroupdeletegroup(group, name, C_NULL)
end

function createdimension(
    group::AbstractGroup,
    name::AbstractString,
    type::AbstractString,
    direction::AbstractString,
    size::Integer,
    options,
)::AbstractDimension
    # TODO: allow options
    @assert options === nothing
    return IDimension(
        GDAL.gdalgroupcreatedimension(
            group,
            name,
            type,
            direction,
            size,
            C_NULL,
        ),
    )
end

function createmdarray(
    group::AbstractGroup,
    name::AbstractString,
    dimensions::AbstractVector{<:AbstractDimension},
    datatype::AbstractExtendedDataType,
    options,
)::AbstractMDArray
    # TODO: allow options
    @assert options === nothing
    dimensionhptrs = Ptr{Cvoid}[convert(Ptr{Cvoid}, dim) for dim in dimensions]
    return IMDArray(
        GDAL.gdalgroupcreatemdarray(
            group,
            name,
            length(dimensionhptrs),
            dimensionhptrs,
            datatype,
            C_NULL,
        ),
    )
end

function deletemdarray(
    group::AbstractGroup,
    name::AbstractString,
    options,
)::Bool
    # TODO: allow options
    @assert options === nothing
    return GDAL.gdalgroupdeletemdarray(group, name, C_NULL)
end

# gettotalcopycost
# copyfrom

function getstructuralinfo(
    group::AbstractGroup,
)::AbstractVector{<:AbstractString}
    return GDAL.gdalgroupgetstructuralinfo(group)
end

function openmdarrayfromfullname(
    group::AbstractGroup,
    fullname::AbstractString,
    options,
)::AbstractMDArray
    # TODO: allow options
    @assert options === nothing
    return IMDArray(
        GDAL.gdalgroupopenmdarrayfromfullname(group, fullname, C_NULL),
    )
end

function resolvemdarray(
    group::AbstractGroup,
    name::AbstractString,
    startingpath::AbstractString,
    options,
)::AbstractMDArray
    # TODO: allow options
    @assert options === nothing
    return IMDArray(
        GDAL.gdalgroupresolvemdarray(group, name, startingpath, C_NULL),
    )
end

function opengroupfromfullname(
    group::AbstractGroup,
    fullname::AbstractString,
    options,
)::AbstractGroup
    # TODO: allow options
    @assert options === nothing
    return IGroup(GDAL.gdalgroupopengroupfromfullname(group, fullname, C_NULL))
end

function opendimensionfromfullname(
    group::AbstractGroup,
    fullname::AbstractString,
    options,
)::AbstractDimension
    # TODO: allow options
    @assert options === nothing
    return IDimension(
        GDAL.gdalgroupopendimensionfromfullname(group, fullname, C_NULL),
    )
end

# clearstatistics

function rename(group::AbstractGroup, newname::AbstractString)::Bool
    return GDAL.gdalgrouprename(group, newname)
end

function subsetdimensionfromselection(
    group::AbstractGroup,
    selection::AbstractString,
    options,
)::AbstractGroup
    # TODO: allow options
    @assert options === nothing
    return IGroup(
        GDAL.gdalgroupsubsetdimensionfromselection(group, selection, C_NULL),
    )
end
