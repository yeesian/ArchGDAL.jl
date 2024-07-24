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

function unsafe_open(
    filename::AbstractString,
    openflags::Integer,
    alloweddrivers::OptionList,
    openoptions::OptionList,
    siblingfiles::OptionList,
    hard_close::Union{Nothing,Bool} = nothing,
)::AbstractDataset
    if hard_close === nothing
        # We hard-close the dataset if it is a writable multidim dataset
        hard_close =
            (openflags & OF_MULTIDIM_RASTER != 0) &&
            (openflags & OF_UPDATE != 0)
    end
    return Dataset(
        GDAL.gdalopenex(
            filename,
            openflags,
            CSLConstListWrapper(alloweddrivers),
            CSLConstListWrapper(openoptions),
            CSLConstListWrapper(siblingfiles),
        ),
        hard_close = hard_close,
    )
end

function open(
    filename::AbstractString,
    openflags::Integer,
    alloweddrivers::OptionList,
    openoptions::OptionList,
    siblingfiles::OptionList,
    hard_close::Union{Nothing,Bool} = nothing,
)::AbstractDataset
    if hard_close === nothing
        # We hard-close the dataset if it is a writable multidim dataset
        hard_close =
            (openflags & OF_MULTIDIM_RASTER != 0) &&
            (openflags & OF_UPDATE != 0)
    end
    return IDataset(
        GDAL.gdalopenex(
            filename,
            openflags,
            CSLConstListWrapper(alloweddrivers),
            CSLConstListWrapper(openoptions),
            CSLConstListWrapper(siblingfiles),
        ),
        hard_close = hard_close,
    )
end

# TODO: Wrap `GDAL.CPLErr`
function flushcache!(dataset::AbstractDataset)::GDAL.CPLErr
    @assert !isnull(dataset)
    return GDAL.gdalflushcache(dataset)
end

function unsafe_getrootgroup(dataset::AbstractDataset)::AbstractGroup
    @assert !isnull(dataset)
    return Group(GDAL.gdaldatasetgetrootgroup(dataset), dataset)
end

function getrootgroup(dataset::AbstractDataset)::AbstractGroup
    @assert !isnull(dataset)
    return Group(GDAL.gdaldatasetgetrootgroup(dataset), dataset)
end
