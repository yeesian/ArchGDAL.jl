module ArchGDAL

    using Compat
    import Compat.String
    import GDAL, GeoInterface
    import DataStreams: Data

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
    include("ogr/feature.jl")
    include("ogr/featurelayer.jl")
    include("ogr/featuredefn.jl")
    include("ogr/fielddefn.jl")
    include("ogr/styletable.jl")
    include("context.jl")
    include("base/iterators.jl")
    include("base/display.jl")
    include("datastreams.jl")
    include("geointerface.jl")

end # module
