module ArchGDAL

using Dates
using GDAL: GDAL
using GeoFormatTypes: GeoFormatTypes
import GeoInterface
using GeoInterfaceRecipes
using GeoInterfaceMakie: GeoInterfaceMakie as GIM
using Tables: Tables
using ImageCore: Normed, N0f8, N0f16, N0f32, ImageCore
using ColorTypes: ColorTypes
using CEnum

const GFT = GeoFormatTypes

include("constants.jl")
include("utils.jl")
include("types.jl")
include("driver.jl")
include("geotransform.jl")
include("spatialref.jl")
include("dataset.jl")
include("raster/rasterband.jl")
include("raster/rasterio.jl")
include("raster/array.jl")
include("raster/rasterattributetable.jl")
include("raster/colortable.jl")
include("raster/images.jl")
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
include("convert.jl")

function __init__()
    return nothing
end

end # module
