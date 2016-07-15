module ArchGDAL
    __precompile__(true)

    import GDAL

    include("utils.jl")
    include("types.jl")
    include("metadata.jl")
    include("driver.jl")
    include("gcp.jl")
    include("spatialref.jl")
    include("dataset.jl") # depends: types.jl, driver.jl
    include("raster/rasterband.jl") # depends: dataset.jl
    include("raster/rasterio.jl") # depends: dataset.jl
    include("ogr/geometry.jl")
    include("ogr/featurelayer.jl")
    include("ogr/featuredefn.jl")
    include("ogr/fielddefn.jl")
    include("context.jl")
    include("base/iterators.jl")
    include("base/display.jl")

end # module
