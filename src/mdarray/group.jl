# GDALGroup

function getname(group::AbstractGroup)::AbstractString
    @assert !isnull(group)
    return GDAL.gdalgroupgetname(group)
end

function getfullname(group::AbstractGroup)::AbstractString
    @assert !isnull(group)
    return GDAL.gdalgroupgetfullname(group)
end

function getmdarraynames(
    group::AbstractGroup,
    options::OptionList = nothing,
)::AbstractVector{<:AbstractString}
    @assert !isnull(group)
    return GDAL.gdalgroupgetmdarraynames(group, CSLConstListWrapper(options))
end

function unsafe_openmdarray(
    group::AbstractGroup,
    name::AbstractString,
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(group)
    return MDArray(
        GDAL.gdalgroupopenmdarray(group, name, CSLConstListWrapper(options)),
        group.dataset.value,
    )
end

function openmdarray(
    group::AbstractGroup,
    name::AbstractString,
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(group)
    return IMDArray(
        GDAL.gdalgroupopenmdarray(group, name, CSLConstListWrapper(options)),
        group.dataset.value,
    )
end

function getgroupnames(
    group::AbstractGroup,
    options::OptionList = nothing,
)::AbstractVector{<:AbstractString}
    @assert !isnull(group)
    return GDAL.gdalgroupgetgroupnames(group, CSLConstListWrapper(options))
end

function unsafe_opengroup(
    group::AbstractGroup,
    name::AbstractString,
    options::OptionList = nothing,
)::AbstractGroup
    @assert !isnull(group)
    return Group(
        GDAL.gdalgroupopengroup(group, name, CSLConstListWrapper(options)),
        group.dataset.value,
    )
end

function opengroup(
    group::AbstractGroup,
    name::AbstractString,
    options::OptionList = nothing,
)::AbstractGroup
    @assert !isnull(group)
    return IGroup(
        GDAL.gdalgroupopengroup(group, name, CSLConstListWrapper(options)),
        group.dataset.value,
    )
end

function getvectorlayernames(
    group::AbstractGroup,
    options::OptionList = nothing,
)::AbstractVector{<:AbstractString}
    @assert !isnull(group)
    return GDAL.gdalgroupgetvectorlayernames(
        group,
        CSLConstListWrapper(options),
    )
end

function unsafe_openvectorlayer(
    group::AbstractGroup,
    options::OptionList = nothing,
)::AbstractFeatureLayer
    @assert !isnull(group)
    # TODO: Find out how to set `ownedby` and `spatialref`, probably by querying `group`
    # TODO: Store dataset
    return FeatureLayer(
        GDAL.openvectorlayer(group, CSLConstListWrapper(options)),
        ownedby,
        spatialref,
    )
end

function openvectorlayer(
    group::AbstractGroup,
    options::OptionList = nothing,
)::AbstractFeatureLayer
    @assert !isnull(group)
    # TODO: Find out how to set `ownedby` and `spatialref`, probably by querying `group`
    # TODO: Store dataset
    return IFeatureLayer(
        GDAL.openvectorlayer(group, CSLConstListWrapper(options)),
        ownedby,
        spatialref,
    )
end

function unsafe_getdimensions(
    group::AbstractGroup,
    options::OptionList = nothing,
)::AbstractVector{<:AbstractDimension}
    @assert !isnull(group)
    dimensionscountref = Ref{Csize_t}()
    dimensionshptr = GDAL.gdalgroupgetdimensions(
        group,
        dimensionscountref,
        CSLConstListWrapper(options),
    )
    dataset = group.dataset.value
    dimensions = AbstractDimension[
        Dimension(unsafe_load(dimensionshptr, n), dataset) for
        n in 1:dimensionscountref[]
    ]
    GDAL.vsifree(dimensionshptr)
    return dimensions
end

function getdimensions(
    group::AbstractGroup,
    options::OptionList = nothing,
)::AbstractVector{<:AbstractDimension}
    @assert !isnull(group)
    dimensionscountref = Ref{Csize_t}()
    dimensionshptr = GDAL.gdalgroupgetdimensions(
        group,
        dimensionscountref,
        CSLConstListWrapper(options),
    )
    dataset = group.dataset.value
    dimensions = AbstractDimension[
        IDimension(unsafe_load(dimensionshptr, n), dataset) for
        n in 1:dimensionscountref[]
    ]
    GDAL.vsifree(dimensionshptr)
    return dimensions
end

function unsafe_creategroup(
    group::AbstractGroup,
    name::AbstractString,
    options::OptionList = nothing,
)::AbstractGroup
    @assert !isnull(group)
    return Group(
        GDAL.gdalgroupcreategroup(group, name, CSLConstListWrapper(options)),
        group.dataset.value,
    )
end

function creategroup(
    group::AbstractGroup,
    name::AbstractString,
    options::OptionList = nothing,
)::AbstractGroup
    @assert !isnull(group)
    return IGroup(
        GDAL.gdalgroupcreategroup(group, name, CSLConstListWrapper(options)),
        group.dataset.value,
    )
end

function deletegroup(
    group::AbstractGroup,
    name::AbstractString,
    options::OptionList = nothing,
)::Bool
    @assert !isnull(group)
    # TODO: Do we need to set group.ptr = C_NULL?
    return GDAL.gdalgroupdeletegroup(group, name, CSLConstListWrapper(options))
end

function unsafe_createdimension(
    group::AbstractGroup,
    name::AbstractString,
    type::AbstractString,
    direction::AbstractString,
    size::Integer,
    options::OptionList = nothing,
)::AbstractDimension
    @assert !isnull(group)
    return Dimension(
        GDAL.gdalgroupcreatedimension(
            group,
            name,
            type,
            direction,
            size,
            CSLConstListWrapper(options),
        ),
        group.dataset.value,
    )
end

function createdimension(
    group::AbstractGroup,
    name::AbstractString,
    type::AbstractString,
    direction::AbstractString,
    size::Integer,
    options::OptionList = nothing,
)::AbstractDimension
    @assert !isnull(group)
    return IDimension(
        GDAL.gdalgroupcreatedimension(
            group,
            name,
            type,
            direction,
            size,
            CSLConstListWrapper(options),
        ),
        group.dataset.value,
    )
end

function unsafe_createmdarray(
    group::AbstractGroup,
    name::AbstractString,
    dimensions::AbstractVector{<:AbstractDimension},
    datatype::AbstractExtendedDataType,
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(group)
    @assert all(!isnull(dim) for dim in dimensions)
    @assert !isnull(datatype)
    return MDArray(
        GDAL.gdalgroupcreatemdarray(
            group,
            name,
            length(dimensions),
            DimensionHList(dimensions),
            datatype,
            CSLConstListWrapper(options),
        ),
        group.dataset.value,
    )
end

function createmdarray(
    group::AbstractGroup,
    name::AbstractString,
    dimensions::AbstractVector{<:AbstractDimension},
    datatype::AbstractExtendedDataType,
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(group)
    @assert all(!isnull(dim) for dim in dimensions)
    @assert !isnull(datatype)
    return IMDArray(
        GDAL.gdalgroupcreatemdarray(
            group,
            name,
            length(dimensions),
            DimensionHList(dimensions),
            datatype,
            CSLConstListWrapper(options),
        ),
        group.dataset.value,
    )
end

function deletemdarray(
    group::AbstractGroup,
    name::AbstractString,
    options::OptionList = nothing,
)::Bool
    @assert !isnull(group)
    return GDAL.gdalgroupdeletemdarray(
        group,
        name,
        CSLConstListWrapper(options),
    )
end

# gettotalcopycost
# copyfrom

function getstructuralinfo(
    group::AbstractGroup,
)::AbstractVector{<:AbstractString}
    @assert !isnull(group)
    return GDAL.gdalgroupgetstructuralinfo(group)
end

function unsafe_openmdarrayfromfullname(
    group::AbstractGroup,
    fullname::AbstractString,
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(group)
    return MDArray(
        GDAL.gdalgroupopenmdarrayfromfullname(
            group,
            fullname,
            CSLConstListWrapper(options),
        ),
        group.dataset.value,
    )
end

function openmdarrayfromfullname(
    group::AbstractGroup,
    fullname::AbstractString,
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(group)
    return IMDArray(
        GDAL.gdalgroupopenmdarrayfromfullname(
            group,
            fullname,
            CSLConstListWrapper(options),
        ),
        group.dataset.value,
    )
end

function unsafe_resolvemdarray(
    group::AbstractGroup,
    name::AbstractString,
    startingpath::AbstractString,
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(group)
    return MDArray(
        GDAL.gdalgroupresolvemdarray(
            group,
            name,
            startingpath,
            CSLConstListWrapper(options),
        ),
        group.dataset.value,
    )
end

function resolvemdarray(
    group::AbstractGroup,
    name::AbstractString,
    startingpath::AbstractString,
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(group)
    return IMDArray(
        GDAL.gdalgroupresolvemdarray(
            group,
            name,
            startingpath,
            CSLConstListWrapper(options),
        ),
        group.dataset.value,
    )
end

function unsafe_opengroupfromfullname(
    group::AbstractGroup,
    fullname::AbstractString,
    options::OptionList = nothing,
)::AbstractGroup
    @assert !isnull(group)
    return Group(
        GDAL.gdalgroupopengroupfromfullname(
            group,
            fullname,
            CSLConstListWrapper(options),
        ),
        group.dataset.value,
    )
end

function opengroupfromfullname(
    group::AbstractGroup,
    fullname::AbstractString,
    options::OptionList = nothing,
)::AbstractGroup
    @assert !isnull(group)
    return IGroup(
        GDAL.gdalgroupopengroupfromfullname(
            group,
            fullname,
            CSLConstListWrapper(options),
        ),
        group.dataset.value,
    )
end

# function unsafe_opendimensionfromfullname(
#     group::AbstractGroup,
#     fullname::AbstractString,
#     options::OptionList=nothing,
# )::AbstractDimension
#     @assert !isnull(group)
#     return Dimension(
#         GDAL.gdalgroupopendimensionfromfullname(group, fullname, CSLConstListWrapper(options)), group.dataset.value
#     )
# end
# 
# function opendimensionfromfullname(
#     group::AbstractGroup,
#     fullname::AbstractString,
#     options::OptionList=nothing,
# )::AbstractDimension
#     @assert !isnull(group)
#     return IDimension(
#         GDAL.gdalgroupopendimensionfromfullname(group, fullname, CSLConstListWrapper(options)), group.dataset.value
#     )
# end

# clearstatistics

function rename(group::AbstractGroup, newname::AbstractString)::Bool
    @assert !isnull(group)
    return GDAL.gdalgrouprename(group, newname)
end

function unsafe_subsetdimensionfromselection(
    group::AbstractGroup,
    selection::AbstractString,
    options::OptionList = nothing,
)::AbstractGroup
    @assert !isnull(group)
    return Group(
        GDAL.gdalgroupsubsetdimensionfromselection(
            group,
            selection,
            CSLConstListWrapper(options),
        ),
        group.dataset.value,
    )
end

function subsetdimensionfromselection(
    group::AbstractGroup,
    selection::AbstractString,
    options::OptionList = nothing,
)::AbstractGroup
    @assert !isnull(group)
    return IGroup(
        GDAL.gdalgroupsubsetdimensionfromselection(
            group,
            selection,
            CSLConstListWrapper(options),
        ),
        group.dataset.value,
    )
end
