import DiskArrays: AbstractDiskArray
import Base.convert
const GDALColorTable      = GDAL.GDALColorTableH
const GDALCoordTransform  = GDAL.OGRCoordinateTransformationH
const GDALDataset         = GDAL.GDALDatasetH
const GDALDriver          = GDAL.GDALDriverH
const GDALFeature         = GDAL.OGRFeatureH
const GDALFeatureDefn     = GDAL.OGRFeatureDefnH
const GDALFeatureLayer    = GDAL.OGRLayerH
const GDALField           = GDAL.OGRField
const GDALFieldDefn       = GDAL.OGRFieldDefnH
const GDALGeometry        = GDAL.OGRGeometryH
const GDALGeomFieldDefn   = GDAL.OGRGeomFieldDefnH
const GDALProgressFunc    = GDAL.GDALProgressFunc
const GDALRasterAttrTable = GDAL.GDALRasterAttributeTableH
const GDALRasterBand      = GDAL.GDALRasterBandH
const GDALSpatialRef      = GDAL.OGRSpatialReferenceH
const GDALStyleManager    = GDAL.OGRStyleMgrH
const GDALStyleTable      = GDAL.OGRStyleTableH
const GDALStyleTool       = GDAL.OGRStyleToolH

const StringList          = Ptr{Cstring}

abstract type AbstractGeometry <: GeoInterface.AbstractGeometry end
    # needs to have a `ptr::GDALGeometry` attribute

abstract type AbstractSpatialRef end
    # needs to have a `ptr::GDALSpatialRef` attribute

abstract type AbstractDataset end
    # needs to have a `ptr::GDALDataset` attribute

abstract type AbstractFeatureDefn end
    # needs to have a `ptr::GDALFeatureDefn` attribute

abstract type AbstractFeatureLayer end
    # needs to have a `ptr::GDALDataset` attribute

abstract type AbstractFieldDefn end
    # needs to have a `ptr::GDALFieldDefn` attribute

abstract type AbstractGeomFieldDefn end
    # needs to have a `ptr::GDALGeomFieldDefn` attribute

abstract type AbstractRasterBand{T} <: AbstractDiskArray{T,2} end
    # needs to have a `ptr::GDALDataset` attribute

mutable struct CoordTransform
    ptr::GDALCoordTransform
end

mutable struct Dataset <: AbstractDataset
    ptr::GDALDataset

    Dataset(ptr::GDALDataset = C_NULL) = new(ptr)
end

mutable struct IDataset <: AbstractDataset
    ptr::GDALDataset

    function IDataset(ptr::GDALDataset = C_NULL)
        dataset = new(ptr)
        finalizer(destroy, dataset)
        return dataset
    end
end

mutable struct Driver
    ptr::GDALDriver
end

mutable struct Field
    ptr::GDALField
end

mutable struct FieldDefn <: AbstractFieldDefn
    ptr::GDALFieldDefn
end

mutable struct IFieldDefnView <: AbstractFieldDefn
    ptr::GDALFieldDefn

    function IFieldDefnView(ptr::GDALFieldDefn = C_NULL)
        fielddefn = new(ptr)
        finalizer(destroy, fielddefn)
        return fielddefn
    end
end

mutable struct GeomFieldDefn <: AbstractGeomFieldDefn
    ptr::GDALGeomFieldDefn
    spatialref::AbstractSpatialRef

    function GeomFieldDefn(
            ptr::GDALGeomFieldDefn = C_NULL;
            spatialref::AbstractSpatialRef = SpatialRef()
        )
        return new(ptr, spatialref)
    end
end

mutable struct IGeomFieldDefnView <: AbstractGeomFieldDefn
    ptr::GDALGeomFieldDefn

    function IGeomFieldDefnView(ptr::GDALGeomFieldDefn = C_NULL)
        geomdefn = new(ptr)
        finalizer(destroy, geomdefn)
        return geomdefn
    end
end

mutable struct RasterAttrTable
    ptr::GDALRasterAttrTable
end

mutable struct StyleManager
    ptr::GDALStyleManager
end

mutable struct StyleTable
    ptr::GDALStyleTable
end

mutable struct StyleTool
    ptr::GDALStyleTool
end

mutable struct FeatureLayer <: AbstractFeatureLayer
    ptr::GDALFeatureLayer
end

mutable struct IFeatureLayer <: AbstractFeatureLayer
    ptr::GDALFeatureLayer
    ownedby::AbstractDataset
    spatialref::AbstractSpatialRef

    function IFeatureLayer(
            ptr::GDALFeatureLayer = C_NULL;
            ownedby::AbstractDataset = Dataset(),
            spatialref::AbstractSpatialRef = SpatialRef()
        )
        layer = new(ptr, ownedby, spatialref)
        finalizer(destroy, layer)
        return layer
    end
end

mutable struct Feature
    ptr::GDALFeature
end

mutable struct FeatureDefn <: AbstractFeatureDefn
    ptr::GDALFeatureDefn
end

mutable struct IFeatureDefnView <: AbstractFeatureDefn
    ptr::GDALFeatureDefn

    function IFeatureDefnView(ptr::GDALFeatureDefn = C_NULL)
        featuredefn = new(ptr)
        finalizer(destroy, featuredefn)
        return featuredefn
    end
end

mutable struct RasterBand{T} <: AbstractRasterBand{T}
    ptr::GDALRasterBand
end
function RasterBand(ptr::GDALRasterBand)
  t = datatype(GDAL.gdalgetrasterdatatype(ptr))
  RasterBand{t}(ptr)
end

mutable struct IRasterBand{T} <: AbstractRasterBand{T}
    ptr::GDALRasterBand
    ownedby::AbstractDataset

    function IRasterBand{T}(
            ptr::GDALRasterBand = C_NULL;
            ownedby::AbstractDataset = Dataset()
        ) where T
        rasterband = new(ptr, ownedby)
        finalizer(destroy, rasterband)
        return rasterband
    end
end

function IRasterBand(ptr::GDALRasterBand; ownedby = Dataset())
    t = datatype(GDAL.gdalgetrasterdatatype(ptr))
    IRasterBand{t}(ptr, ownedby=ownedby)
end

mutable struct SpatialRef <: AbstractSpatialRef
    ptr::GDALSpatialRef

    SpatialRef(ptr::GDALSpatialRef = C_NULL) = new(ptr)
end

mutable struct ISpatialRef <: AbstractSpatialRef
    ptr::GDALSpatialRef

    function ISpatialRef(ptr::GDALSpatialRef = C_NULL)
        spref = new(ptr)
        finalizer(destroy, spref)
        return spref
    end
end

mutable struct Geometry <: AbstractGeometry
    ptr::GDALGeometry

    Geometry(ptr::GDALGeometry = C_NULL) = new(ptr)
end

mutable struct IGeometry <: AbstractGeometry
    ptr::GDALGeometry

    function IGeometry(ptr::GDALGeometry = C_NULL)
        geom = new(ptr)
        finalizer(destroy, geom)
        return geom
    end
end

mutable struct ColorTable
    ptr::GDALColorTable
end

CPLErr = GDAL.CPLErr
CPLXMLNodeType = GDAL.CPLXMLNodeType
GDALDataType = GDAL.GDALDataType
GDALAsyncStatusType = GDAL.GDALAsyncStatusType
GDALAccess = GDAL.GDALAccess
GDALRWFlag = GDAL.GDALRWFlag
GDALRIOResampleAlg = GDAL.GDALRIOResampleAlg
GDALColorInterp = GDAL.GDALColorInterp
GDALPaletteInterp = GDAL.GDALPaletteInterp
GDALRATFieldType = GDAL.GDALRATFieldType
GDALRATFieldUsage = GDAL.GDALRATFieldUsage
GDALTileOrganization = GDAL.GDALTileOrganization
GDALGridAlgorithm = GDAL.GDALGridAlgorithm
OGRwkbGeometryType = GDAL.OGRwkbGeometryType
OGRwkbVariant = GDAL.OGRwkbVariant
OGRwkbByteOrder = GDAL.OGRwkbByteOrder
OGRFieldSubType = GDAL.OGRFieldSubType
OGRJustification = GDAL.OGRJustification
OGRSTClassId = GDAL.OGRSTClassId
OGRSTUnitId = GDAL.OGRSTUnitId
OGRSTPenParam = GDAL.OGRSTPenParam
OGRSTBrushParam = GDAL.OGRSTBrushParam
OGRSTSymbolParam = GDAL.OGRSTSymbolParam
OGRSTLabelParam = GDAL.OGRSTLabelParam
GDALResampleAlg = GDAL.GDALResampleAlg
GWKAverageOrModeAlg = GDAL.GWKAverageOrModeAlg
OGRAxisOrientation = GDAL.OGRAxisOrientation

"return the corresponding `DataType` in julia"
const _JLTYPE = Dict{GDALDataType, DataType}(
    GDAL.GDT_Unknown    => Any,
    GDAL.GDT_Byte       => UInt8,
    GDAL.GDT_UInt16     => UInt16,
    GDAL.GDT_Int16      => Int16,
    GDAL.GDT_UInt32     => UInt32,
    GDAL.GDT_Int32      => Int32,
    GDAL.GDT_Float32    => Float32,
    GDAL.GDT_Float64    => Float64)

"return the corresponding `DataType` in julia"
datatype(gt::GDALDataType) = get(_JLTYPE, gt) do
    error("Unknown GDALDataType: $gt")
end

const _GDALTYPE = Dict{DataType,GDALDataType}(
    Any         => GDAL.GDT_Unknown,
    UInt8       => GDAL.GDT_Byte,
    UInt16      => GDAL.GDT_UInt16,
    Int16       => GDAL.GDT_Int16,
    UInt32      => GDAL.GDT_UInt32,
    Int32       => GDAL.GDT_Int32,
    Float32     => GDAL.GDT_Float32,
    Float64     => GDAL.GDT_Float64)

"return the corresponding `GDAL.GDALDataType`"
gdaltype(dt::DataType) = get(_GDALTYPE, dt) do
    error("Unknown DataType: $dt")
end

@enum(OGRFieldType,
    OFTInteger          = Int32(GDAL.OFTInteger),
    OFTIntegerList      = Int32(GDAL.OFTIntegerList),
    OFTReal             = Int32(GDAL.OFTReal),
    OFTRealList         = Int32(GDAL.OFTRealList),
    OFTString           = Int32(GDAL.OFTString),
    OFTStringList       = Int32(GDAL.OFTStringList),
    OFTWideString       = Int32(GDAL.OFTWideString),
    OFTWideStringList   = Int32(GDAL.OFTWideStringList),
    OFTBinary           = Int32(GDAL.OFTBinary),
    OFTDate             = Int32(GDAL.OFTDate),
    OFTTime             = Int32(GDAL.OFTTime),
    OFTDateTime         = Int32(GDAL.OFTDateTime),
    OFTInteger64        = Int32(GDAL.OFTInteger64),
    OFTInteger64List    = Int32(GDAL.OFTInteger64List),
    # OFTMaxType          = Int32(GDAL.OFTMaxType), # unsupported
)

"return the corresponding `DataType` in julia"
const _FIELDTYPE = Dict{OGRFieldType, DataType}(
    OFTInteger         => Int32,
    OFTIntegerList     => Vector{Int32},
    OFTReal            => Float64,
    OFTRealList        => Vector{Float64},
    OFTString          => String,
    OFTStringList      => Vector{String},
    OFTWideString      => Nothing, # deprecated
    OFTWideStringList  => Nothing, # deprecated
    OFTBinary          => Vector{UInt8},
    OFTDate            => Dates.Date,
    OFTTime            => Dates.Time,
    OFTDateTime        => Dates.DateTime,
    OFTInteger64       => Int64,
    OFTInteger64List   => Vector{Int64},
    # OFTMaxType         => Nothing # unsupported
)

const _GDALFIELDTYPE = Dict{GDAL.OGRFieldType, OGRFieldType}(
    GDAL.OFTInteger => OFTInteger,
    GDAL.OFTIntegerList => OFTIntegerList,
    GDAL.OFTReal => OFTReal,
    GDAL.OFTRealList => OFTRealList,
    GDAL.OFTString => OFTString,
    GDAL.OFTStringList => OFTStringList,
    GDAL.OFTWideString => OFTWideString,
    GDAL.OFTWideStringList => OFTWideStringList,
    GDAL.OFTBinary => OFTBinary,
    GDAL.OFTDate => OFTDate,
    GDAL.OFTTime => OFTTime,
    GDAL.OFTDateTime => OFTDateTime,
    GDAL.OFTInteger64 => OFTInteger64,
    GDAL.OFTInteger64List => OFTInteger64List,
    # GDAL.OFTMaxType => OFTMaxType, # unsupported
)

const _GDALFIELDTYPES = Dict{OGRFieldType, GDAL.OGRFieldType}(
    OFTInteger => GDAL.OFTInteger,
    OFTIntegerList => GDAL.OFTIntegerList,
    OFTReal => GDAL.OFTReal,
    OFTRealList => GDAL.OFTRealList,
    OFTString => GDAL.OFTString,
    OFTStringList => GDAL.OFTStringList,
    OFTWideString => GDAL.OFTWideString,
    OFTWideStringList => GDAL.OFTWideStringList,
    OFTBinary => GDAL.OFTBinary,
    OFTDate => GDAL.OFTDate,
    OFTTime => GDAL.OFTTime,
    OFTDateTime => GDAL.OFTDateTime,
    OFTInteger64 => GDAL.OFTInteger64,
    OFTInteger64List => GDAL.OFTInteger64List,
    # OFTMaxType => GDAL.OFTMaxType, # unsupported
)

convert(::Type{GDAL.OGRFieldType}, ft::OGRFieldType) = get(_GDALFIELDTYPES, ft) do
    error("Unknown OGRFieldType: $ft")
end

"returns the `OGRFieldType` in julia"
gdaltype(ft::GDAL.OGRFieldType) = get(_GDALFIELDTYPE, ft) do
    error("Unknown GDAL.OGRFieldType: $ft")
end

"return the corresponding `DataType` in julia"
datatype(ft::OGRFieldType) = get(_FIELDTYPE, ft) do
    error("Unknown OGRFieldType: $ft")
end

@enum(WKBGeometryType,
    wkbUnknown                  = 0,
    wkbPoint                    = 1,
    wkbLineString               = 2,
    wkbPolygon                  = 3,
    wkbMultiPoint               = 4,
    wkbMultiLineString          = 5,
    wkbMultiPolygon             = 6,
    wkbGeometryCollection       = 7,
    wkbCircularString           = 8,
    wkbCompoundCurve            = 9,
    wkbCurvePolygon             = 10,
    wkbMultiCurve               = 11,
    wkbMultiSurface             = 12,
    wkbCurve                    = 13,
    wkbSurface                  = 14,
    wkbPolyhedralSurface        = 15,
    wkbTIN                      = 16,
    wkbTriangle                 = 17,
    wkbNone                     = 18,
    wkbLinearRing               = 19,
    wkbCircularStringZ          = 20,
    wkbCompoundCurveZ           = 21,
    wkbCurvePolygonZ            = 22,
    wkbMultiCurveZ              = 23,
    wkbMultiSurfaceZ            = 24,
    wkbCurveZ                   = 25,
    wkbSurfaceZ                 = 26,
    wkbPolyhedralSurfaceZ       = 27,
    wkbTINZ                     = 28,
    wkbTriangleZ                = 29,
    wkbPointM                   = 30,
    wkbLineStringM              = 31,
    wkbPolygonM                 = 32,
    wkbMultiPointM              = 33,
    wkbMultiLineStringM         = 34,
    wkbMultiPolygonM            = 35,
    wkbGeometryCollectionM      = 36,
    wkbCircularStringM          = 37,
    wkbCompoundCurveM           = 38,
    wkbCurvePolygonM            = 39,
    wkbMultiCurveM              = 40,
    wkbMultiSurfaceM            = 41,
    wkbCurveM                   = 42,
    wkbSurfaceM                 = 43,
    wkbPolyhedralSurfaceM       = 44,
    wkbTINM                     = 45,
    wkbTriangleM                = 46,
    wkbPointZM                  = 47,
    wkbLineStringZM             = 48,
    wkbPolygonZM                = 49,
    wkbMultiPointZM             = 50,
    wkbMultiLineStringZM        = 51,
    wkbMultiPolygonZM           = 52,
    wkbGeometryCollectionZM     = 53,
    wkbCircularStringZM         = 54,
    wkbCompoundCurveZM          = 55,
    wkbCurvePolygonZM           = 56,
    wkbMultiCurveZM             = 57,
    wkbMultiSurfaceZM           = 58,
    wkbCurveZM                  = 59,
    wkbSurfaceZM                = 60,
    wkbPolyhedralSurfaceZM      = 61,
    wkbTINZM                    = 62,
    wkbTriangleZM               = 63,
    wkbPoint25D                 = 64,
    wkbLineString25D            = 65,
    wkbPolygon25D               = 66,
    wkbMultiPoint25D            = 67,
    wkbMultiLineString25D       = 68,
    wkbMultiPolygon25D          = 69,
    wkbGeometryCollection25D    = 70,
)

const _WKBGEOMETRYTYPE = Dict{GDAL.OGRwkbGeometryType, WKBGeometryType}(
    GDAL.wkbUnknown => wkbUnknown,
    GDAL.wkbPoint => wkbPoint,
    GDAL.wkbLineString => wkbLineString,
    GDAL.wkbPolygon => wkbPolygon,
    GDAL.wkbMultiPoint => wkbMultiPoint,
    GDAL.wkbMultiLineString => wkbMultiLineString,
    GDAL.wkbMultiPolygon => wkbMultiPolygon,
    GDAL.wkbGeometryCollection => wkbGeometryCollection,
    GDAL.wkbCircularString => wkbCircularString,
    GDAL.wkbCompoundCurve => wkbCompoundCurve,
    GDAL.wkbCurvePolygon => wkbCurvePolygon,
    GDAL.wkbMultiCurve => wkbMultiCurve,
    GDAL.wkbMultiSurface => wkbMultiSurface,
    GDAL.wkbCurve => wkbCurve,
    GDAL.wkbSurface => wkbSurface,
    GDAL.wkbPolyhedralSurface => wkbPolyhedralSurface,
    GDAL.wkbTIN => wkbTIN,
    GDAL.wkbTriangle => wkbTriangle,
    GDAL.wkbNone => wkbNone,
    GDAL.wkbLinearRing => wkbLinearRing,
    GDAL.wkbCircularStringZ => wkbCircularStringZ,
    GDAL.wkbCompoundCurveZ => wkbCompoundCurveZ,
    GDAL.wkbCurvePolygonZ => wkbCurvePolygonZ,
    GDAL.wkbMultiCurveZ => wkbMultiCurveZ,
    GDAL.wkbMultiSurfaceZ => wkbMultiSurfaceZ,
    GDAL.wkbCurveZ => wkbCurveZ,
    GDAL.wkbSurfaceZ => wkbSurfaceZ,
    GDAL.wkbPolyhedralSurfaceZ => wkbPolyhedralSurfaceZ,
    GDAL.wkbTINZ => wkbTINZ,
    GDAL.wkbTriangleZ => wkbTriangleZ,
    GDAL.wkbPointM => wkbPointM,
    GDAL.wkbLineStringM => wkbLineStringM,
    GDAL.wkbPolygonM => wkbPolygonM,
    GDAL.wkbMultiPointM => wkbMultiPointM,
    GDAL.wkbMultiLineStringM => wkbMultiLineStringM,
    GDAL.wkbMultiPolygonM => wkbMultiPolygonM,
    GDAL.wkbGeometryCollectionM => wkbGeometryCollectionM,
    GDAL.wkbCircularStringM => wkbCircularStringM,
    GDAL.wkbCompoundCurveM => wkbCompoundCurveM,
    GDAL.wkbCurvePolygonM => wkbCurvePolygonM,
    GDAL.wkbMultiCurveM => wkbMultiCurveM,
    GDAL.wkbMultiSurfaceM => wkbMultiSurfaceM,
    GDAL.wkbCurveM => wkbCurveM,
    GDAL.wkbSurfaceM => wkbSurfaceM,
    GDAL.wkbPolyhedralSurfaceM => wkbPolyhedralSurfaceM,
    GDAL.wkbTINM => wkbTINM,
    GDAL.wkbTriangleM => wkbTriangleM,
    GDAL.wkbPointZM => wkbPointZM,
    GDAL.wkbLineStringZM => wkbLineStringZM,
    GDAL.wkbPolygonZM => wkbPolygonZM,
    GDAL.wkbMultiPointZM => wkbMultiPointZM,
    GDAL.wkbMultiLineStringZM => wkbMultiLineStringZM,
    GDAL.wkbMultiPolygonZM => wkbMultiPolygonZM,
    GDAL.wkbGeometryCollectionZM => wkbGeometryCollectionZM,
    GDAL.wkbCircularStringZM => wkbCircularStringZM,
    GDAL.wkbCompoundCurveZM => wkbCompoundCurveZM,
    GDAL.wkbCurvePolygonZM => wkbCurvePolygonZM,
    GDAL.wkbMultiCurveZM => wkbMultiCurveZM,
    GDAL.wkbMultiSurfaceZM => wkbMultiSurfaceZM,
    GDAL.wkbCurveZM => wkbCurveZM,
    GDAL.wkbSurfaceZM => wkbSurfaceZM,
    GDAL.wkbPolyhedralSurfaceZM => wkbPolyhedralSurfaceZM,
    GDAL.wkbTINZM => wkbTINZM,
    GDAL.wkbTriangleZM => wkbTriangleZM,
    GDAL.wkbPoint25D => wkbPoint25D,
    GDAL.wkbLineString25D => wkbLineString25D,
    GDAL.wkbPolygon25D => wkbPolygon25D,
    GDAL.wkbMultiPoint25D => wkbMultiPoint25D,
    GDAL.wkbMultiLineString25D => wkbMultiLineString25D,
    GDAL.wkbMultiPolygon25D => wkbMultiPolygon25D,
    GDAL.wkbGeometryCollection25D => wkbGeometryCollection25D,
)

const _WKBGEOMETRYTYPES = Dict{WKBGeometryType, GDAL.OGRwkbGeometryType}(
    wkbUnknown => GDAL.wkbUnknown,
    wkbPoint => GDAL.wkbPoint,
    wkbLineString => GDAL.wkbLineString,
    wkbPolygon => GDAL.wkbPolygon,
    wkbMultiPoint => GDAL.wkbMultiPoint,
    wkbMultiLineString => GDAL.wkbMultiLineString,
    wkbMultiPolygon => GDAL.wkbMultiPolygon,
    wkbGeometryCollection => GDAL.wkbGeometryCollection,
    wkbCircularString => GDAL.wkbCircularString,
    wkbCompoundCurve => GDAL.wkbCompoundCurve,
    wkbCurvePolygon => GDAL.wkbCurvePolygon,
    wkbMultiCurve => GDAL.wkbMultiCurve,
    wkbMultiSurface => GDAL.wkbMultiSurface,
    wkbCurve => GDAL.wkbCurve,
    wkbSurface => GDAL.wkbSurface,
    wkbPolyhedralSurface => GDAL.wkbPolyhedralSurface,
    wkbTIN => GDAL.wkbTIN,
    wkbTriangle => GDAL.wkbTriangle,
    wkbNone => GDAL.wkbNone,
    wkbLinearRing => GDAL.wkbLinearRing,
    wkbCircularStringZ => GDAL.wkbCircularStringZ,
    wkbCompoundCurveZ => GDAL.wkbCompoundCurveZ,
    wkbCurvePolygonZ => GDAL.wkbCurvePolygonZ,
    wkbMultiCurveZ => GDAL.wkbMultiCurveZ,
    wkbMultiSurfaceZ => GDAL.wkbMultiSurfaceZ,
    wkbCurveZ => GDAL.wkbCurveZ,
    wkbSurfaceZ => GDAL.wkbSurfaceZ,
    wkbPolyhedralSurfaceZ => GDAL.wkbPolyhedralSurfaceZ,
    wkbTINZ => GDAL.wkbTINZ,
    wkbTriangleZ => GDAL.wkbTriangleZ,
    wkbPointM => GDAL.wkbPointM,
    wkbLineStringM => GDAL.wkbLineStringM,
    wkbPolygonM => GDAL.wkbPolygonM,
    wkbMultiPointM => GDAL.wkbMultiPointM,
    wkbMultiLineStringM => GDAL.wkbMultiLineStringM,
    wkbMultiPolygonM => GDAL.wkbMultiPolygonM,
    wkbGeometryCollectionM => GDAL.wkbGeometryCollectionM,
    wkbCircularStringM => GDAL.wkbCircularStringM,
    wkbCompoundCurveM => GDAL.wkbCompoundCurveM,
    wkbCurvePolygonM => GDAL.wkbCurvePolygonM,
    wkbMultiCurveM => GDAL.wkbMultiCurveM,
    wkbMultiSurfaceM => GDAL.wkbMultiSurfaceM,
    wkbCurveM => GDAL.wkbCurveM,
    wkbSurfaceM => GDAL.wkbSurfaceM,
    wkbPolyhedralSurfaceM => GDAL.wkbPolyhedralSurfaceM,
    wkbTINM => GDAL.wkbTINM,
    wkbTriangleM => GDAL.wkbTriangleM,
    wkbPointZM => GDAL.wkbPointZM,
    wkbLineStringZM => GDAL.wkbLineStringZM,
    wkbPolygonZM => GDAL.wkbPolygonZM,
    wkbMultiPointZM => GDAL.wkbMultiPointZM,
    wkbMultiLineStringZM => GDAL.wkbMultiLineStringZM,
    wkbMultiPolygonZM => GDAL.wkbMultiPolygonZM,
    wkbGeometryCollectionZM => GDAL.wkbGeometryCollectionZM,
    wkbCircularStringZM => GDAL.wkbCircularStringZM,
    wkbCompoundCurveZM => GDAL.wkbCompoundCurveZM,
    wkbCurvePolygonZM => GDAL.wkbCurvePolygonZM,
    wkbMultiCurveZM => GDAL.wkbMultiCurveZM,
    wkbMultiSurfaceZM => GDAL.wkbMultiSurfaceZM,
    wkbCurveZM => GDAL.wkbCurveZM,
    wkbSurfaceZM => GDAL.wkbSurfaceZM,
    wkbPolyhedralSurfaceZM => GDAL.wkbPolyhedralSurfaceZM,
    wkbTINZM => GDAL.wkbTINZM,
    wkbTriangleZM => GDAL.wkbTriangleZM,
    wkbPoint25D => GDAL.wkbPoint25D,
    wkbLineString25D => GDAL.wkbLineString25D,
    wkbPolygon25D => GDAL.wkbPolygon25D,
    wkbMultiPoint25D => GDAL.wkbMultiPoint25D,
    wkbMultiLineString25D => GDAL.wkbMultiLineString25D,
    wkbMultiPolygon25D => GDAL.wkbMultiPolygon25D,
    wkbGeometryCollection25D => GDAL.wkbGeometryCollection25D,
)

function convert(::Type{GDAL.OGRwkbGeometryType}, wkbType::WKBGeometryType)
    return get(_WKBGEOMETRYTYPES, wkbType) do
        error("Unknown WKBGeometryType: $wkbType")
    end
end

"returns the `OGRFieldType` in julia"
function gdaltype(wkbType::GDAL.OGRwkbGeometryType)
    return get(_WKBGEOMETRYTYPE, wkbType) do
        error("Unknown GDAL.OGRwkbGeometryType: $wkbType")
    end
end

@enum(GDALOpenFlag,
    OF_ReadOnly             = GDAL.GDAL_OF_READONLY,                # 0x00
    OF_Update               = GDAL.GDAL_OF_UPDATE,                  # 0x01
    # OF_All                  = GDAL.GDAL_OF_ALL,                     # 0x00
    OF_Raster               = GDAL.GDAL_OF_RASTER,                  # 0x02
    OF_Vector               = GDAL.GDAL_OF_VECTOR,                  # 0x04
    OF_GNM                  = GDAL.GDAL_OF_GNM,                     # 0x08
    OF_Kind_Mask            = GDAL.GDAL_OF_KIND_MASK,               # 0x1e
    OF_Shared               = GDAL.GDAL_OF_SHARED,                  # 0x20
    OF_Verbose_Error        = GDAL.GDAL_OF_VERBOSE_ERROR,           # 0x40
    OF_Internal             = GDAL.GDAL_OF_INTERNAL,                # 0x80
    # OF_DEFAULT_BLOCK_ACCESS = GDAL.GDAL_OF_DEFAULT_BLOCK_ACCESS,    # 0
    OF_Array_Block_Access   = GDAL.GDAL_OF_ARRAY_BLOCK_ACCESS,      # 0x0100
    OF_Hashset_Block_Access = GDAL.GDAL_OF_HASHSET_BLOCK_ACCESS,    # 0x0200
    # OF_RESERVED_1           = GDAL.GDAL_OF_RESERVED_1,              # 0x0300
    OF_Block_Access_Mask    = GDAL.GDAL_OF_BLOCK_ACCESS_MASK)       # 0x0300

import Base.|

|(x::GDALOpenFlag,y::UInt8) = UInt8(x) | y
|(x::UInt8,y::GDALOpenFlag) = x | UInt8(y)
|(x::GDALOpenFlag,y::GDALOpenFlag) = UInt8(x) | UInt8(y)

"""
    typesize(dt::GDALDataType)

Get data type size in bits.
"""
typesize(dt::GDALDataType) = GDAL.gdalgetdatatypesize(dt)

"""
    typename(dt::GDALDataType)

name (string) corresponding to GDAL data type.
"""
typename(dt::GDALDataType) = GDAL.gdalgetdatatypename(dt)

"""
    gettype(name::AbstractString)

Returns GDAL data type by symbolic name.
"""
gettype(name::AbstractString) = GDAL.gdalgetdatatypebyname(name)

"""
    typeunion(dt1::GDALDataType, dt2::GDALDataType)

Return the smallest data type that can fully express both input data types.
"""
typeunion(dt1::GDALDataType, dt2::GDALDataType) = GDAL.gdaldatatypeunion(dt1, dt2)

"""
    iscomplex(dtype::GDALDataType)

`true` if `dtype` is one of `GDT_{CInt16|CInt32|CFloat32|CFloat64}.`
"""
iscomplex(dtype::GDALDataType) = Bool(GDAL.gdaldatatypeiscomplex(dtype))

"""
    getname(dtype::GDALAsyncStatusType)

Get name of AsyncStatus data type.
"""
getname(dtype::GDALAsyncStatusType) = GDAL.gdalgetasyncstatustypename(dtype)

"""
    asyncstatustype(name::AbstractString)

Get AsyncStatusType by symbolic name.
"""
asyncstatustype(name::AbstractString) = GDAL.gdalgetasyncstatustypebyname(name)

"""
    getname(obj::GDALColorInterp)

Return name (string) corresponding to color interpretation.
"""
getname(obj::GDALColorInterp) = GDAL.gdalgetcolorinterpretationname(obj)

"""
    colorinterp(name::AbstractString)

Get color interpretation corresponding to the given symbolic name.
"""
colorinterp(name::AbstractString) = GDAL.gdalgetcolorinterpretationbyname(name)

"""
    getname(obj::GDALPaletteInterp)

Get name of palette interpretation.
"""
getname(obj::GDALPaletteInterp) = GDAL.gdalgetpaletteinterpretationname(obj)

"""
    getname(obj::OGRFieldType)

Fetch human readable name for a field type.
"""
getname(obj::OGRFieldType) = GDAL.ogr_getfieldtypename(obj)

"""
    getname(obj::OGRFieldSubType)

Fetch human readable name for a field subtype.
"""
getname(obj::OGRFieldSubType) = GDAL.ogr_getfieldsubtypename(obj)

"""
    arecompatible(dtype::OGRFieldType, subtype::OGRFieldSubType)

Return if type and subtype are compatible.
"""
arecompatible(dtype::OGRFieldType, subtype::OGRFieldSubType) =
    Bool(GDAL.ogr_aretypesubtypecompatible(dtype, subtype))
