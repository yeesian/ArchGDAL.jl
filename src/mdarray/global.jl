# Global functions

function unsafe_createmultidimensional(
    driver::Driver,
    name::AbstractString,
    rootgroupoptions::OptionList = nothing,
    options::OptionList = nothing,
    ;
    hard_close::Bool = true,
)::AbstractDataset
    @assert !isnull(driver)
    return Dataset(
        GDAL.gdalcreatemultidimensional(
            driver,
            name,
            CSLConstListWrapper(rootgroupoptions),
            CSLConstListWrapper(options),
        ),
        hard_close = hard_close,
    )
end

"""
    createmultidimensional(driver::Driver, name::AbstractString,
                           rootgroupoptions=nothing, options=nothing;
                           hard_close=true)

Create a new multidimensional dataset with the given driver.

Only drivers that advertise multidimensional creation support can be used,
e.g. "MEM", "netCDF" or "Zarr".

### Parameters
* `driver`: the driver used to create the dataset.
* `name`: the name of the dataset (usually a file name).
* `rootgroupoptions`: driver-specific options for the root group
  (`"NAME=VALUE"` strings), or `nothing`.
* `options`: driver-specific creation options, or `nothing`.

### Keyword Arguments
* `hard_close`: whether the dataset tracks its interactive children, so
  that `force_close_mdarray_dataset!` can release them.

### Returns
The new dataset. Its contents are accessed through `getrootgroup`.
"""
function createmultidimensional(
    driver::Driver,
    name::AbstractString,
    rootgroupoptions::OptionList = nothing,
    options::OptionList = nothing,
    ;
    hard_close::Bool = true,
)::AbstractDataset
    @assert !isnull(driver)
    return IDataset(
        GDAL.gdalcreatemultidimensional(
            driver,
            name,
            CSLConstListWrapper(rootgroupoptions),
            CSLConstListWrapper(options),
        ),
        hard_close = hard_close,
    )
end

function _openmultidimensional(
    constructor::Type{<:AbstractDataset},
    filename::AbstractString,
    update::Bool,
    flags,
    alloweddrivers::OptionList,
    options::OptionList,
    siblingfiles::OptionList,
    hard_close::Union{Nothing,Bool},
)::AbstractDataset
    openflags = UInt32(flags) | UInt32(OF_MULTIDIM_RASTER)
    update && (openflags |= UInt32(OF_UPDATE))
    # By default, track the children of writable datasets so that they
    # can be closed with `force_close_mdarray_dataset!`
    if isnothing(hard_close)
        hard_close = openflags & UInt32(OF_UPDATE) != 0
    end
    return constructor(
        GDAL.gdalopenex(
            filename,
            openflags,
            CSLConstListWrapper(alloweddrivers),
            CSLConstListWrapper(options),
            CSLConstListWrapper(siblingfiles),
        );
        hard_close = hard_close,
    )
end

function unsafe_openmultidimensional(
    filename::AbstractString;
    update::Bool = false,
    flags = OF_READONLY,
    alloweddrivers::OptionList = nothing,
    options::OptionList = nothing,
    siblingfiles::OptionList = nothing,
    hard_close::Union{Nothing,Bool} = nothing,
)::AbstractDataset
    return _openmultidimensional(
        Dataset,
        filename,
        update,
        flags,
        alloweddrivers,
        options,
        siblingfiles,
        hard_close,
    )
end

"""
    openmultidimensional(filename; update=false, flags=OF_READONLY|OF_VERBOSE_ERROR,
                         alloweddrivers, options, siblingfiles, hard_close)

Open a multidimensional dataset.

### Parameters
* `filename`: the name of the file to open.

### Keyword Arguments
* `update`: open the dataset for writing (adds `OF_UPDATE`).
* `flags`: additional `OF_*` flags, combined with `|`. `OF_MULTIDIM_RASTER`
  is always added.
* `alloweddrivers`: short names of the drivers that may be used, or
  `nothing` for all drivers.
* `options`: driver-specific open options (`"NAME=VALUE"`), or `nothing`.
* `siblingfiles`: the files next to `filename`, or `nothing` to let GDAL
  look them up.
* `hard_close`: whether the dataset tracks its interactive children, so
  that `force_close_mdarray_dataset!` can release them. Defaults to
  `true` for datasets opened for writing.

### Returns
The corresponding dataset.

### Example
```julia
openmultidimensional(filename; update = true) do dataset
    getrootgroup(dataset) do root
        writemdarray(root, "values", Float32[1, 2, 3])
    end
end
```
"""
function openmultidimensional(
    filename::AbstractString;
    update::Bool = false,
    flags = OF_READONLY | OF_VERBOSE_ERROR,
    alloweddrivers::OptionList = nothing,
    options::OptionList = nothing,
    siblingfiles::OptionList = nothing,
    hard_close::Union{Nothing,Bool} = nothing,
)::AbstractDataset
    return _openmultidimensional(
        IDataset,
        filename,
        update,
        flags,
        alloweddrivers,
        options,
        siblingfiles,
        hard_close,
    )
end

# TODO: Wrap `GDAL.CPLErr`
"""
    flushcache!(dataset::AbstractDataset)

Write all pending changes of `dataset` to disk.

### Returns
The `GDAL.CPLErr` error code (`GDAL.CE_None` on success).
"""
function flushcache!(dataset::AbstractDataset)::GDAL.CPLErr
    @assert !isnull(dataset)
    return GDAL.gdalflushcache(dataset)
end

"""
    force_close_mdarray_dataset!(dataset::AbstractDataset)

Close a multidimensional dataset, releasing all interactive objects
(groups, arrays, attributes, dimensions) that were obtained from it and
are still alive.

In GDAL's multidimensional API, these objects keep the underlying file
open, and a file being written is only complete once all of them have
been released. Interactive objects are released by the garbage
collector at an unpredictable time; this function releases them
immediately, so that the file is complete when it returns.

Afterwards, the dataset and all its interactive children are null
(`isnull` returns `true`) and must not be used any more. Scoped objects
(obtained via `unsafe_*` functions) are not tracked and must be
destroyed by the caller beforehand.

Child tracking is enabled by default for datasets returned by
`createmultidimensional`, and by `open` when both `OF_MULTIDIM_RASTER`
and `OF_UPDATE` are set. For other datasets, this function only closes
the dataset itself.
"""
function force_close_mdarray_dataset!(dataset::AbstractDataset)::Nothing
    isnull(dataset) && return nothing
    if !isnothing(dataset.children)
        for child in dataset.children
            value = child.value
            !isnothing(value) && destroy(value)
        end
        Base.empty!(dataset.children)
    end
    err = GDAL.gdalclose(dataset)
    dataset.ptr = C_NULL
    @cplerr err "Failed to close dataset"
    return nothing
end

function unsafe_getrootgroup(dataset::AbstractDataset)::AbstractGroup
    @assert !isnull(dataset)
    return Group(GDAL.gdaldatasetgetrootgroup(dataset), WeakRef(dataset))
end

"""
    getrootgroup(dataset::AbstractDataset)

Return the root group of a multidimensional dataset.
"""
function getrootgroup(dataset::AbstractDataset)::AbstractGroup
    @assert !isnull(dataset)
    return IGroup(GDAL.gdaldatasetgetrootgroup(dataset), WeakRef(dataset))
end
