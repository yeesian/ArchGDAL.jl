module ArchGDAL

    import GDAL

    include("utils.jl")
    include("types.jl")
    include("driver.jl")
    include("gcp.jl")
    include("spatialref.jl")
    include("dataset.jl")
    include("raster/rasterband.jl")
    include("raster/rasterio.jl")
    include("raster/rasterattributetable.jl")
    include("raster/colortable.jl")
    include("ogr/geometry.jl")
    include("ogr/featurelayer.jl")
    include("ogr/featuredefn.jl")
    include("ogr/fielddefn.jl")
    include("context.jl")
    include("base/iterators.jl")
    include("base/display.jl")

end # module
