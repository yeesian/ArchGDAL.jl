abstract type AbstractExtendedDataType end
# needs to have a `ptr::GDALExtendedDataTypeH` attribute

abstract type AbstractEDTComponent end
# needs to have a `ptr::GDALEDTComponentH` attribute

abstract type AbstractGroup end
# needs to have a `ptr::GDAL.GDALGroupH` attribute

# TODO: Add `<: AbstractDiskArray`
# TODO: Put `{T,D}` into the type signature?
abstract type AbstractMDArray end
# needs to have a `ptr::GDAL.GDALMDArrayH` attribute

abstract type AbstractAttribute end
# needs to have a `ptr::GDAL.GDALAttributeH` attribute

abstract type AbstractDimension end
# needs to have a `ptr::GDAL.GDALDimensionH` attribute

################################################################################

mutable struct ExtendedDataType <: AbstractExtendedDataType
    ptr::GDAL.GDALExtendedDataTypeH

    ExtendedDataType(ptr::GDAL.GDALExtendedDataTypeH = C_NULL) = new(ptr)
end

mutable struct IExtendedDataType <: AbstractExtendedDataType
    ptr::GDAL.GDALExtendedDataTypeH

    function IExtendedDataType(ptr::GDAL.GDALExtendedDataTypeH = C_NULL)
        extendeddatatype = new(ptr)
        finalizer(destroy, extendeddatatype)
        return extendeddatatype
    end
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

# Helpers

# TODO: Move to GDAL.jl, redefining `CSLConstList`
struct CSLConstListWrapper
    # Hold on to the original arguments to prevent GC from freeing
    # them while they are being used in a ccall
    cstrings::Vector{Cstring}
    strings::AbstractVector{<:AbstractString}

    function CSLConstListWrapper(
        strings::AbstractVector{<:Union{String,SubString{String}}},
    )
        cstrings = Cstring[[pointer(str) for str in strings]; C_NULL]
        return new(cstrings, strings)
    end
end
function CSLConstListWrapper(strings::AbstractVector{<:AbstractString})
    return String.(strings)
end

function Base.cconvert(::Type{GDAL.CSLConstList}, wrapper::CSLConstListWrapper)
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

function Base.cconvert(
    ::Type{Ptr{GDAL.GDALDimensionH}},
    dimensionhlist::DimensionHList,
)
    return Base.cconvert(Ptr{Cvoid}, dimensionhlist.dimensionhs)
end

################################################################################

# Global functions

function unsafe_createmultidimensional(
    driver::Driver,
    name::AbstractString,
    rootgroupoptions::AbstractVector{<:AbstractString} = String[],
    options::AbstractVector{<:AbstractString} = String[],
)::AbstractDataset
    return Dataset(
        GDAL.gdalcreatemultidimensional(
            driver,
            name,
            CSLConstListWrapper(rootgroupoptions),
            CSLConstListWrapper(options),
        ),
    )
end

function createmultidimensional(
    driver::Driver,
    name::AbstractString,
    rootgroupoptions::AbstractVector{<:AbstractString} = String[],
    options::AbstractVector{<:AbstractString} = String[],
)::AbstractDataset
    return IDataset(
        GDAL.gdalcreatemultidimensional(
            driver,
            name,
            CSLConstListWrapper(rootgroupoptions),
            CSLConstListWrapper(options),
        ),
    )
end

function getrootgroup(dataset::AbstractDataset)::AbstractGroup
    return Group(GDAL.gdaldatasetgetrootgroup(dataset))
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
    options::AbstractVector{<:AbstractString} = String[],
)::AbstractVector{<:AbstractString}
    return GDAL.gdalgroupgetmdarraynames(group, options)
end

function unsafe_openmdarray(
    group::AbstractGroup,
    name::AbstractString,
    options,
)::AbstractMDArray
    return MDArray(GDAL.gdalgroupopenmdarray(group, name, options))
end

function openmdarray(
    group::AbstractGroup,
    name::AbstractString,
    options,
)::AbstractMDArray
    return IMDArray(GDAL.gdalgroupopenmdarray(group, name, options))
end

function getgroupnames(
    group::AbstractGroup,
    options::AbstractVector{<:AbstractString} = String[],
)::AbstractVector{<:AbstractString}
    return GDAL.gdalgroupgetgroupnames(group, options)
end

function unsafe_opengroup(
    group::AbstractGroup,
    name::AbstractString,
    options::AbstractVector{<:AbstractString} = String[],
)::AbstractGroup
    return Group(GDAL.gdalgroupopengroup(group, name, options))
end

function opengroup(
    group::AbstractGroup,
    name::AbstractString,
    options::AbstractVector{<:AbstractString} = String[],
)::AbstractGroup
    return IGroup(GDAL.gdalgroupopengroup(group, name, options))
end

function getvectorlayernames(
    group::AbstractGroup,
    options::AbstractVector{<:AbstractString} = String[],
)::AbstractVector{<:AbstractString}
    return GDAL.gdalgroupgetvectorlayernames(group, options)
end

function unsafe_openvectorlayer(
    group::AbstractGroup,
    options,
)::AbstractFeatureLayer
    # TODO: Find out how to set `ownedby` and `spatialref`, probably by querying `group`
    return FeatureLayer(
        GDAL.openvectorlayer(group, options),
        ownedby,
        spatialref,
    )
end

function openvectorlayer(group::AbstractGroup, options)::AbstractFeatureLayer
    # TODO: Find out how to set `ownedby` and `spatialref`, probably by querying `group`
    return IFeatureLayer(
        GDAL.openvectorlayer(group, options),
        ownedby,
        spatialref,
    )
end

function getdimensions(
    group::AbstractGroup,
    options::AbstractVector{<:AbstractString} = String[],
)::AbstractVector{<:AbstractDimension}
    dimensionscountref = Ref{Csize_t}()
    dimensionshptr =
        GDAL.gdalgroupgetdimensions(group, dimensionscountref, options)
    dimensions = AbstractDimension[
        IDimension(unsafe_load(dimensionshptr, n)) for
        n in 1:dimensionscountref[]
    ]
    GDAL.vsifree(dimensionshptr)
    return dimensions
end

function unsafe_creategroup(
    group::AbstractGroup,
    name::AbstractString,
    options::AbstractVector{<:AbstractString} = String[],
)::AbstractGroup
    return Group(GDAL.gdalgroupcreategroup(group, name, options))
end

function creategroup(
    group::AbstractGroup,
    name::AbstractString,
    options::AbstractVector{<:AbstractString} = String[],
)::AbstractGroup
    return IGroup(GDAL.gdalgroupcreategroup(group, name, options))
end

function deletegroup(group::AbstractGroup, name::AbstractString, options)::Bool
    return GDAL.gdalgroupdeletegroup(group, name, options)
end

function unsafe_createdimension(
    group::AbstractGroup,
    name::AbstractString,
    type::AbstractString,
    direction::AbstractString,
    size::Integer,
    options::AbstractVector{<:AbstractString} = String[],
)::AbstractDimension
    return Dimension(
        GDAL.gdalgroupcreatedimension(
            group,
            name,
            type,
            direction,
            size,
            options,
        ),
    )
end

function createdimension(
    group::AbstractGroup,
    name::AbstractString,
    type::AbstractString,
    direction::AbstractString,
    size::Integer,
    options::AbstractVector{<:AbstractString} = String[],
)::AbstractDimension
    return IDimension(
        GDAL.gdalgroupcreatedimension(
            group,
            name,
            type,
            direction,
            size,
            options,
        ),
    )
end

function unsafe_createmdarray(
    group::AbstractGroup,
    name::AbstractString,
    dimensions::AbstractVector{<:AbstractDimension},
    datatype::AbstractExtendedDataType,
    options::AbstractVector{<:AbstractString} = String[],
)::AbstractMDArray
    return MDArray(
        GDAL.gdalgroupcreatemdarray(
            group,
            name,
            length(dimensions),
            DimensionHList(dimensions),
            datatype,
            options,
        ),
    )
end

function createmdarray(
    group::AbstractGroup,
    name::AbstractString,
    dimensions::AbstractVector{<:AbstractDimension},
    datatype::AbstractExtendedDataType,
    options::AbstractVector{<:AbstractString} = String[],
)::AbstractMDArray
    return IMDArray(
        GDAL.gdalgroupcreatemdarray(
            group,
            name,
            length(dimensions),
            DimensionHList(dimensions),
            datatype,
            options,
        ),
    )
end

function deletemdarray(
    group::AbstractGroup,
    name::AbstractString,
    options::AbstractVector{<:AbstractString} = String[],
)::Bool
    return GDAL.gdalgroupdeletemdarray(group, name, options)
end

# gettotalcopycost
# copyfrom

function getstructuralinfo(
    group::AbstractGroup,
)::AbstractVector{<:AbstractString}
    return GDAL.gdalgroupgetstructuralinfo(group)
end

function unsafe_openmdarrayfromfullname(
    group::AbstractGroup,
    fullname::AbstractString,
    options::AbstractVector{<:AbstractString} = String[],
)::AbstractMDArray
    return MDArray(
        GDAL.gdalgroupopenmdarrayfromfullname(group, fullname, options),
    )
end

function openmdarrayfromfullname(
    group::AbstractGroup,
    fullname::AbstractString,
    options::AbstractVector{<:AbstractString} = String[],
)::AbstractMDArray
    return IMDArray(
        GDAL.gdalgroupopenmdarrayfromfullname(group, fullname, options),
    )
end

function unsafe_resolvemdarray(
    group::AbstractGroup,
    name::AbstractString,
    startingpath::AbstractString,
    options::AbstractVector{<:AbstractString} = String[],
)::AbstractMDArray
    return MDArray(
        GDAL.gdalgroupresolvemdarray(group, name, startingpath, options),
    )
end

function resolvemdarray(
    group::AbstractGroup,
    name::AbstractString,
    startingpath::AbstractString,
    options::AbstractVector{<:AbstractString} = String[],
)::AbstractMDArray
    return IMDArray(
        GDAL.gdalgroupresolvemdarray(group, name, startingpath, options),
    )
end

function unsafe_opengroupfromfullname(
    group::AbstractGroup,
    fullname::AbstractString,
    options::AbstractVector{<:AbstractString} = String[],
)::AbstractGroup
    return Group(GDAL.gdalgroupopengroupfromfullname(group, fullname, options))
end

function opengroupfromfullname(
    group::AbstractGroup,
    fullname::AbstractString,
    options::AbstractVector{<:AbstractString} = String[],
)::AbstractGroup
    return IGroup(GDAL.gdalgroupopengroupfromfullname(group, fullname, options))
end

# function unsafe_opendimensionfromfullname(
#     group::AbstractGroup,
#     fullname::AbstractString,
#     options::AbstractVector{<:AbstractString} = String[],
# )::AbstractDimension
#     return Dimension(
#         GDAL.gdalgroupopendimensionfromfullname(group, fullname, options),
#     )
# end
# 
# function opendimensionfromfullname(
#     group::AbstractGroup,
#     fullname::AbstractString,
#     options::AbstractVector{<:AbstractString} = String[],
# )::AbstractDimension
#     return IDimension(
#         GDAL.gdalgroupopendimensionfromfullname(group, fullname, options),
#     )
# end

# clearstatistics

function rename(group::AbstractGroup, newname::AbstractString)::Bool
    return GDAL.gdalgrouprename(group, newname)
end

function unsafe_subsetdimensionfromselection(
    group::AbstractGroup,
    selection::AbstractString,
    options::AbstractVector{<:AbstractString} = String[],
)::AbstractGroup
    return Group(
        GDAL.gdalgroupsubsetdimensionfromselection(group, selection, options),
    )
end

function subsetdimensionfromselection(
    group::AbstractGroup,
    selection::AbstractString,
    options::AbstractVector{<:AbstractString} = String[],
)::AbstractGroup
    return IGroup(
        GDAL.gdalgroupsubsetdimensionfromselection(group, selection, options),
    )
end

################################################################################

# GDALExtendedDataType

function unsafe_extendeddatatypecreate(
    ::Type{T},
)::AbstractExtendedDataType where {T}
    type = convert(GDALDataType, T)
    return ExtendedDataType(GDAL.gdalextendeddatatypecreate(type))
end

function extendeddatatypecreate(::Type{T})::AbstractExtendedDataType where {T}
    type = convert(GDALDataType, T)
    return IExtendedDataType(GDAL.gdalextendeddatatypecreate(type))
end

################################################################################

# GDALMDArray

function getfilename(mdarray::AbstractMDArray)::AbstractString
    return GDAL.gdalmdarraygetfilename(mdarray)
end
