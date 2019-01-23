module ArchGDAL

    import GDAL, GeoInterface
    import DataStreams: Data
    import GeoInterface: coordinates, geotype
    using Dates

    include("utils.jl")
    include("types.jl")
    include("driver.jl")
    include("gcp.jl")
    include("spatialref.jl")
    include("dataset.jl")
    include("raster/rasterband.jl")
    include("raster/rasterio.jl")
    include("raster/array.jl")
    include("raster/rasterattributetable.jl")
    include("raster/colortable.jl")
    include("ogr/geometry.jl")
    include("ogr/feature.jl")
    include("ogr/featurelayer.jl")
    include("ogr/featuredefn.jl")
    include("ogr/fielddefn.jl")
    include("ogr/styletable.jl")
    include("utilities.jl")
    include("context.jl")
    include("base/iterators.jl")
    include("base/display.jl")
    include("datastreams.jl")
    include("geointerface.jl")

    function __init__()
        GDAL.allregister()
    end

end # module
