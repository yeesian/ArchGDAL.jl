module ArchGDAL

    import GDAL, GeoInterface
    using Tables: Tables
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
    include("tables.jl")
    include("geointerface.jl")

    mutable struct DriverManager
        function DriverManager()
            drivermanager = new()
            GDAL.gdalallregister()
            finalizer((dm,) -> GDAL.gdaldestroydrivermanager(), drivermanager)
            return drivermanager
        end
    end

    const DRIVER_MANAGER = Ref{DriverManager}()

    function __init__()
        DRIVER_MANAGER[] = DriverManager()
    end

end # module
