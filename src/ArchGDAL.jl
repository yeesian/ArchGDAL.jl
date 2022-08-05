module ArchGDAL

using Dates
using GDAL: GDAL
using GeoFormatTypes: GeoFormatTypes
import GeoInterface
using GeoInterfaceRecipes
using Tables: Tables
using ImageCore: Normed, N0f8, N0f16, N0f32, ImageCore
using ColorTypes: ColorTypes
using CEnum

const GFT = GeoFormatTypes

const gdal_vector_drivers = ["AmigoCloud", "Arrow", "AVCBIN", "AVCE00", "CAD", "CARTO", "CSV", "CSW", "DGN", "DGNv8", "DWG", "DXF", "EDIGEO", "EEDA", "Elasticsearch", "ESRIJSON", "FileGDB", "FlatGeobuf", "Geoconcept", "GeoJSON", "GeoJSONSeq", "GeoRSS", "GML", "GMLAS", "GMT", "GPKG", "GPSBabel", "GPX", "GRASS", "HANA", "IDB", "IDRISI", "INTERLIS 1", "INTERLIS 2", "JML", "KML", "LIBKML", "LVBAG", "MapML", "Memory", "MapInfo File", "MongoDBv3", "MSSQLSpatial", "MVT", "MySQL", "NAS", "netCDF", "NGW", "UK .NTF", "OAPIF", "OCI", "ODBC", "ODS", "OGDI", "OpenFileGDB", "OSM", "Parquet", "PDF", "PDS", "PostgreSQL", "PGDump", "PGeo", "PLScenes", "S57", "SDTS", "Selafin", "ESRI Shapefile", "SOSI", "SQLite", "SVG", "SXF", "TIGER", "TopoJSON", "VDV", "VFK", "WAsP", "WFS", "XLS", "XLSX"]
const gdal_raster_drivers = ["AAIGrid", "ACE2", "ADRG", "AIG", "AIRSAR", "ARG", "BAG", "BASISU", "BLX", "BMP", "BSB", "BT", "BYN", "CAD", "CALS", "CEOS", "COASP", "COG", "COSAR", "CPG", "CTable2", "CTG", "DAAS", "DDS", "DERIVED", "DIMAP", "DIPEx", "DOQ1", "DOQ2", "DTED", "ECRGTOC", "ECW", "EEDAI", "EHdr", "EIR", "ELAS", "ENVI", "ERS", "ESAT", "ESRIC", "EXR", "FAST", "FIT", "FITS", "GenBin", "GeoRaster", "GFF", "GIF", "GPKG", "GRASS", "GRASSASCIIGrid", "GRIB", "GS7BG", "GSAG", "GSBG", "GSC", "GTA", "GTiff", "GXF", "HDF4", "HDF5", "HEIF", "HF2", "HFA", "RST", "ILWIS", "IRIS", "ISCE", "ISG", "ISIS2", "ISIS3", "JDEM", "JP2ECW", "JP2KAK", "JP2LURA", "JP2MrSID", "JP2OpenJPEG", "JPEG", "JPEGXL", "JPIPKAK", "KEA", "KMLSuperoverlay", "KRO", "KTX2", "L1B", "LAN", "LCP", "Leveller", "LOSLAS", "MAP", "MRF", "MBTiles", "MEM", "MFF", "MFF2", "MrSID", "MSG", "MSGN", "NDF", "netCDF", "NGSGEOID", "NGW", "NITF", "NTv2", "NWT_GRD", "NWT_GRC", "OGCAPI", "OZI", "JAXAPALSAR", "PAux", "PCIDSK", "PCRaster", "PDF", "PDS", "PDS4", "PLMosaic", "PNG", "PNM", "PostGISRaster", "PRF", "R", "Rasdaman", "Rasterlite", "SQLite", "RDB", "RIK", "RMF", "ROI_PAC", "RPFTOC", "RRASTER", "RS2", "SAFE", "SAR_CEOS", "SAGA", "SDTS", "SENTINEL2", "SGI", "SIGDEM", "SNODAS", "SRP", "SRTMHGT", "STACIT", "STACTA", "Terragen", "TGA", "TIL", "TileDB", "TSX", "USGSDEM", "VICAR", "VRT", "WCS", "WEBP", "WMS", "WMTS", "XPM", "XYZ", "Zarr", "ZMAP"]

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
