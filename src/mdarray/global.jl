# Global functions

function unsafe_createmultidimensional(
    driver::Driver,
    name::AbstractString,
    rootgroupoptions::OptionList = nothing,
    options::OptionList = nothing,
)::AbstractDataset
    @assert !isnull(driver)
    return Dataset(
        GDAL.gdalcreatemultidimensional(
            driver,
            name,
            CSLConstListWrapper(rootgroupoptions),
            CSLConstListWrapper(options),
        ),
        hard_close = true,
    )
end

function createmultidimensional(
    driver::Driver,
    name::AbstractString,
    rootgroupoptions::OptionList = nothing,
    options::OptionList = nothing,
)::AbstractDataset
    @assert !isnull(driver)
    return IDataset(
        GDAL.gdalcreatemultidimensional(
            driver,
            name,
            CSLConstListWrapper(rootgroupoptions),
            CSLConstListWrapper(options),
        ),
        hard_close = true,
    )
end

function unsafe_open(
    filename::AbstractString,
    openflags::Integer,
    alloweddrivers::OptionList,
    openoptions::OptionList,
    siblingfiles::OptionList,
)::AbstractDataset
    # We hard-close the dataset if it is a writable multidim dataset
    want_hard_close =
        (openflags & OF_MULTIDIM_RASTER != 0) && (openflags & OF_UPDATE != 0)
    return Dataset(
        GDAL.gdalopenex(
            filename,
            openflags,
            CSLConstListWrapper(alloweddrivers),
            CSLConstListWrapper(openoptions),
            CSLConstListWrapper(siblingfiles),
        ),
        hard_close = want_hard_close,
    )
end

function open(
    filename::AbstractString,
    openflags::Integer,
    alloweddrivers::OptionList,
    openoptions::OptionList,
    siblingfiles::OptionList,
)::AbstractDataset
    # We hard-close the dataset if it is a writable multidim dataset
    want_hard_close =
        (openflags & OF_MULTIDIM_RASTER != 0) && (openflags & OF_UPDATE != 0)
    return IDataset(
        GDAL.gdalopenex(
            filename,
            openflags,
            CSLConstListWrapper(alloweddrivers),
            CSLConstListWrapper(openoptions),
            CSLConstListWrapper(siblingfiles),
        ),
        hard_close = want_hard_close,
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
