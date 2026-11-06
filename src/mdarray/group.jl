# GDALGroup

"""
    getname(group::AbstractGroup)

Return the name of the group (`"/"` for the root group).
"""
function getname(group::AbstractGroup)::AbstractString
    @assert !isnull(group)
    return GDAL.gdalgroupgetname(group)
end

"""
    getfullname(group::AbstractGroup)

Return the full name of the group, i.e. its path from the root group,
e.g. `"/subgroup"`.
"""
function getfullname(group::AbstractGroup)::AbstractString
    @assert !isnull(group)
    return GDAL.gdalgroupgetfullname(group)
end

"""
    getmdarraynames(group::AbstractGroup, options=nothing)

Return the names of the multidimensional arrays directly contained in the
group. `options` are driver-specific (`"NAME=VALUE"` strings), or `nothing`.
"""
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
    ptr = GDAL.gdalgroupopenmdarray(group, name, CSLConstListWrapper(options))
    ptr == C_NULL && error("Could not open mdarray \"$name\"")
    return MDArray(ptr, group.dataset)
end

"""
    openmdarray(group::AbstractGroup, name::AbstractString, options=nothing)

Open the multidimensional array `name` of the group. Throws an error if it
does not exist.
"""
function openmdarray(
    group::AbstractGroup,
    name::AbstractString,
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(group)
    ptr = GDAL.gdalgroupopenmdarray(group, name, CSLConstListWrapper(options))
    ptr == C_NULL && error("Could not open mdarray \"$name\"")
    return IMDArray(ptr, group.dataset)
end

"""
    getgroupnames(group::AbstractGroup, options=nothing)

Return the names of the subgroups of the group.
"""
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
    ptr = GDAL.gdalgroupopengroup(group, name, CSLConstListWrapper(options))
    ptr == C_NULL && error("Could no open group \"$name\"")
    return Group(ptr, group.dataset)
end

"""
    opengroup(group::AbstractGroup, name::AbstractString, options=nothing)

Open the subgroup `name` of the group. Throws an error if it does not exist.
"""
function opengroup(
    group::AbstractGroup,
    name::AbstractString,
    options::OptionList = nothing,
)::AbstractGroup
    @assert !isnull(group)
    ptr = GDAL.gdalgroupopengroup(group, name, CSLConstListWrapper(options))
    ptr == C_NULL && error("Could no open group \"$name\"")
    return IGroup(ptr, group.dataset)
end

"""
    getvectorlayernames(group::AbstractGroup, options=nothing)

Return the names of the vector layers contained in the group.
"""
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

# openvectorlayer: not wrapped yet. The layer's lifetime is tied to the
# group, which `FeatureLayer` (owned by a dataset) cannot express.

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
    dimensions = AbstractDimension[
        Dimension(unsafe_load(dimensionshptr, n), group.dataset) for
        n in 1:dimensionscountref[]
    ]
    GDAL.vsifree(dimensionshptr)
    return dimensions
end

"""
    getdimensions(group::AbstractGroup, options=nothing)

Return the dimensions defined in the group.
"""
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
    dimensions = AbstractDimension[
        IDimension(unsafe_load(dimensionshptr, n), group.dataset) for
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
    ptr = GDAL.gdalgroupcreategroup(group, name, CSLConstListWrapper(options))
    ptr == C_NULL && error("Could not create group \"$name\"")
    return Group(ptr, group.dataset)
end

"""
    creategroup(group::AbstractGroup, name::AbstractString, options=nothing)

Create a subgroup `name` of the group.
"""
function creategroup(
    group::AbstractGroup,
    name::AbstractString,
    options::OptionList = nothing,
)::AbstractGroup
    @assert !isnull(group)
    ptr = GDAL.gdalgroupcreategroup(group, name, CSLConstListWrapper(options))
    ptr == C_NULL && error("Could not create group \"$name\"")
    return IGroup(ptr, group.dataset)
end

"""
    deletegroup(group::AbstractGroup, name::AbstractString, options=nothing)

Delete the subgroup `name` of the group.

Objects obtained from the deleted group must not be used any more. Not all
drivers support deletion.

### Returns
`true` on success.
"""
function deletegroup(
    group::AbstractGroup,
    name::AbstractString,
    options::OptionList = nothing,
)::Bool
    @assert !isnull(group)
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
    ptr = GDAL.gdalgroupcreatedimension(
        group,
        name,
        type,
        direction,
        size,
        CSLConstListWrapper(options),
    )
    ptr == C_NULL && error("Could not create dimension \"$name\"")
    return Dimension(ptr, group.dataset)
end

"""
    createdimension(group::AbstractGroup, name::AbstractString,
                    type::AbstractString, direction::AbstractString,
                    size::Integer, options=nothing)

Create a dimension in the group.

### Parameters
* `name`: the name of the dimension.
* `type`: the type of the dimension, e.g. `"HORIZONTAL_X"`,
  `"HORIZONTAL_Y"`, `"VERTICAL"`, `"TEMPORAL"`, `"PARAMETRIC"`, or `""`.
* `direction`: the direction of the dimension, e.g. `"EAST"`, `"WEST"`,
  `"SOUTH"`, `"NORTH"`, `"UP"`, `"DOWN"`, `"FUTURE"`, `"PAST"`, or `""`.
* `size`: the number of elements along the dimension.
* `options`: driver-specific options, or `nothing`.
"""
function createdimension(
    group::AbstractGroup,
    name::AbstractString,
    type::AbstractString,
    direction::AbstractString,
    size::Integer,
    options::OptionList = nothing,
)::AbstractDimension
    @assert !isnull(group)
    ptr = GDAL.gdalgroupcreatedimension(
        group,
        name,
        type,
        direction,
        size,
        CSLConstListWrapper(options),
    )
    ptr == C_NULL && error("Could not create dimension \"$name\"")
    return IDimension(ptr, group.dataset)
end

function unsafe_createmdarray(
    group::AbstractGroup,
    name::AbstractString,
    dimensions::VectorLike{<:AbstractDimension},
    datatype::AbstractExtendedDataType,
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(group)
    @assert all(!isnull(dim) for dim in dimensions)
    @assert !isnull(datatype)
    ptr = GDAL.gdalgroupcreatemdarray(
        group,
        name,
        length(dimensions),
        DimensionHList(reverse(dimensions)),
        datatype,
        CSLConstListWrapper(options),
    )
    ptr == C_NULL && error("Could not create mdarray \"$name\"")
    return MDArray(ptr, group.dataset)
end

"""
    createmdarray(group::AbstractGroup, name::AbstractString, dimensions,
                  datatype::AbstractExtendedDataType, options=nothing)

Create a multidimensional array in the group.

### Parameters
* `name`: the name of the array.
* `dimensions`: the dimensions of the array, in Julia order, i.e. the first
  dimension varies fastest.
* `datatype`: the element type, e.g. `extendeddatatypecreate(Float32)`.
* `options`: driver-specific creation options (e.g. compression), or
  `nothing`.
"""
function createmdarray(
    group::AbstractGroup,
    name::AbstractString,
    dimensions::VectorLike{<:AbstractDimension},
    datatype::AbstractExtendedDataType,
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(group)
    @assert all(!isnull(dim) for dim in dimensions)
    @assert !isnull(datatype)
    ptr = GDAL.gdalgroupcreatemdarray(
        group,
        name,
        length(dimensions),
        DimensionHList(reverse(dimensions)),
        datatype,
        CSLConstListWrapper(options),
    )
    ptr == C_NULL && error("Could not create mdarray \"$name\"")
    return IMDArray(ptr, group.dataset)
end

"""
    deletemdarray(group::AbstractGroup, name::AbstractString, options=nothing)

Delete the multidimensional array `name` of the group.

Objects obtained from the deleted array must not be used any more. Not all
drivers support deletion.

### Returns
`true` on success.
"""
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

"""
    getstructuralinfo(group::AbstractGroup)

Return structural information about the group as `"NAME=VALUE"` strings,
e.g. about the file format.
"""
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
    ptr = GDAL.gdalgroupopenmdarrayfromfullname(
        group,
        fullname,
        CSLConstListWrapper(options),
    )
    ptr == C_NULL && error("Could not open mdarray \"$fullname\"")
    return MDArray(ptr, group.dataset)
end

"""
    openmdarrayfromfullname(group::AbstractGroup, fullname::AbstractString,
                            options=nothing)

Open a multidimensional array from its full name, e.g. `"/group/array"`.
"""
function openmdarrayfromfullname(
    group::AbstractGroup,
    fullname::AbstractString,
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(group)
    ptr = GDAL.gdalgroupopenmdarrayfromfullname(
        group,
        fullname,
        CSLConstListWrapper(options),
    )
    ptr == C_NULL && error("Could not open mdarray \"$fullname\"")
    return IMDArray(ptr, group.dataset)
end

function unsafe_resolvemdarray(
    group::AbstractGroup,
    name::AbstractString,
    startingpath::AbstractString,
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(group)
    ptr = GDAL.gdalgroupresolvemdarray(
        group,
        name,
        startingpath,
        CSLConstListWrapper(options),
    )
    ptr == C_NULL && error("Could not resolve mdarray \"$name\"")
    return MDArray(ptr, group.dataset)
end

"""
    resolvemdarray(group::AbstractGroup, name::AbstractString,
                   startingpath::AbstractString, options=nothing)

Locate the multidimensional array `name`.

A fully qualified `name` is opened directly. Otherwise, the search starts in
the group with the full name `startingpath` (the group itself if
`startingpath` is `""` or `"/"`), continues recursively in its subgroups, and
then restarts from the parent group.
"""
function resolvemdarray(
    group::AbstractGroup,
    name::AbstractString,
    startingpath::AbstractString,
    options::OptionList = nothing,
)::AbstractMDArray
    @assert !isnull(group)
    ptr = GDAL.gdalgroupresolvemdarray(
        group,
        name,
        startingpath,
        CSLConstListWrapper(options),
    )
    ptr == C_NULL && error("Could not resolve mdarray \"$name\"")
    return IMDArray(ptr, group.dataset)
end

function unsafe_opengroupfromfullname(
    group::AbstractGroup,
    fullname::AbstractString,
    options::OptionList = nothing,
)::AbstractGroup
    @assert !isnull(group)
    ptr = GDAL.gdalgroupopengroupfromfullname(
        group,
        fullname,
        CSLConstListWrapper(options),
    )
    ptr == C_NULL && error("Could not open group \"$fullname\"")
    return Group(ptr, group.dataset)
end

"""
    opengroupfromfullname(group::AbstractGroup, fullname::AbstractString,
                          options=nothing)

Open a group from its full name, e.g. `"/group/subgroup"`.
"""
function opengroupfromfullname(
    group::AbstractGroup,
    fullname::AbstractString,
    options::OptionList = nothing,
)::AbstractGroup
    @assert !isnull(group)
    ptr = GDAL.gdalgroupopengroupfromfullname(
        group,
        fullname,
        CSLConstListWrapper(options),
    )
    ptr == C_NULL && error("Could not open group \"$fullname\"")
    return IGroup(ptr, group.dataset)
end

# function unsafe_opendimensionfromfullname(
#     group::AbstractGroup,
#     fullname::AbstractString,
#     options::OptionList=nothing,
# )::AbstractDimension
#     @assert !isnull(group)
#     return Dimension(
#         GDAL.gdalgroupopendimensionfromfullname(group, fullname, CSLConstListWrapper(options)), group.dataset
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
#         GDAL.gdalgroupopendimensionfromfullname(group, fullname, CSLConstListWrapper(options)), group.dataset
#     )
# end

# clearstatistics

"""
    rename!(group::AbstractGroup, newname::AbstractString)

Rename the group. Not all drivers support renaming.

### Returns
`true` on success.
"""
function rename!(group::AbstractGroup, newname::AbstractString)::Bool
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
        group.dataset,
    )
end

"""
    subsetdimensionfromselection(group::AbstractGroup,
                                 selection::AbstractString, options=nothing)

Return a virtual group in which one dimension has been subset according to
a selection on its indexing variable.

The selection has the form `"/path/to/indexing_variable=value"`, e.g.
`"/x=1"`; the arrays in the result only contain the entries of that
dimension whose indexing variable has the given value.
"""
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
        group.dataset,
    )
end

################################################################################

function unsafe_getattribute(
    group::AbstractGroup,
    name::AbstractString,
)::AbstractAttribute
    @assert !isnull(group)
    ptr = GDAL.gdalgroupgetattribute(group, name)
    ptr == C_NULL && error("Could not open attribute \"$name\"")
    return Attribute(ptr, group.dataset)
end

"""
    getattribute(group::AbstractGroup, name::AbstractString)

Return the attribute `name` of the group. Throws an error if it does not
exist. See also `readattribute`.
"""
function getattribute(
    group::AbstractGroup,
    name::AbstractString,
)::AbstractAttribute
    @assert !isnull(group)
    ptr = GDAL.gdalgroupgetattribute(group, name)
    ptr == C_NULL && error("Could not open attribute \"$name\"")
    return IAttribute(ptr, group.dataset)
end

function unsafe_getattributes(
    group::AbstractGroup,
    options::OptionList = nothing,
)::AbstractVector{<:AbstractAttribute}
    @assert !isnull(group)
    count = Ref{Csize_t}()
    ptr =
        GDAL.gdalgroupgetattributes(group, count, CSLConstListWrapper(options))
    attributes = AbstractAttribute[
        Attribute(unsafe_load(ptr, n), group.dataset) for n in 1:count[]
    ]
    GDAL.vsifree(ptr)
    return attributes
end

"""
    getattributes(group::AbstractGroup, options=nothing)

Return all attributes of the group.
"""
function getattributes(
    group::AbstractGroup,
    options::OptionList = nothing,
)::AbstractVector{<:AbstractAttribute}
    @assert !isnull(group)
    count = Ref{Csize_t}()
    ptr =
        GDAL.gdalgroupgetattributes(group, count, CSLConstListWrapper(options))
    attributes = AbstractAttribute[
        IAttribute(unsafe_load(ptr, n), group.dataset) for n in 1:count[]
    ]
    GDAL.vsifree(ptr)
    return attributes
end

function unsafe_createattribute(
    group::AbstractGroup,
    name::AbstractString,
    dimensions::VectorLike{<:Integer},
    datatype::AbstractExtendedDataType,
    options::OptionList = nothing,
)::AbstractAttribute
    @assert !isnull(group)
    @assert !isnull(datatype)
    ptr = GDAL.gdalgroupcreateattribute(
        group,
        name,
        length(dimensions),
        reverse(dimensions),
        datatype,
        CSLConstListWrapper(options),
    )
    ptr == C_NULL && error("Could not create attribute \"$name\"")
    return Attribute(ptr, group.dataset)
end

"""
    createattribute(group::AbstractGroup, name::AbstractString, dimensions,
                    datatype::AbstractExtendedDataType, options=nothing)

Create an attribute of the group.

### Parameters
* `name`: the name of the attribute.
* `dimensions`: the size of the attribute along each dimension, in Julia
  order; empty for a scalar attribute.
* `datatype`: the element type of the attribute.
* `options`: driver-specific options, or `nothing`.

See also `writeattribute`.
"""
function createattribute(
    group::AbstractGroup,
    name::AbstractString,
    dimensions::VectorLike{<:Integer},
    datatype::AbstractExtendedDataType,
    options::OptionList = nothing,
)::AbstractAttribute
    @assert !isnull(group)
    @assert !isnull(datatype)
    ptr = GDAL.gdalgroupcreateattribute(
        group,
        name,
        length(dimensions),
        reverse(dimensions),
        datatype,
        CSLConstListWrapper(options),
    )
    ptr == C_NULL && error("Could not create attribute \"$name\"")
    return IAttribute(ptr, group.dataset)
end

"""
    deleteattribute(group::AbstractGroup, name::AbstractString, options=nothing)

Delete the attribute `name` of the group.

### Returns
`true` on success.
"""
function deleteattribute(
    group::AbstractGroup,
    name::AbstractString,
    options::OptionList = nothing,
)::Bool
    @assert !isnull(group)
    return GDAL.gdalgroupdeleteattribute(
        group,
        name,
        CSLConstListWrapper(options),
    )
end
