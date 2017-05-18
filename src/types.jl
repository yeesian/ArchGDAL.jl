typealias GDALColorTable      Ptr{GDAL.GDALColorTableH}
typealias GDALCoordTransform  Ptr{GDAL.OGRCoordinateTransformationH}
typealias GDALDataset         Ptr{GDAL.GDALDatasetH}
typealias GDALDriver          Ptr{GDAL.GDALDriverH}
typealias GDALFeature         Ptr{GDAL.OGRFeatureH}
typealias GDALFeatureDefn     Ptr{GDAL.OGRFeatureDefnH}
typealias GDALFeatureLayer    Ptr{GDAL.OGRLayerH}
typealias GDALField           Ptr{GDAL.OGRField}
typealias GDALFieldDefn       Ptr{GDAL.OGRFieldDefnH}
typealias GDALGeometry        Ptr{GDAL.OGRGeometryH}
typealias GDALGeomFieldDefn   GDAL.OGRGeomFieldDefnH
typealias GDALProgressFunc    Ptr{GDAL.GDALProgressFunc}
typealias GDALRasterAttrTable Ptr{GDAL.GDALRasterAttributeTableH}
typealias GDALRasterBand      Ptr{GDAL.GDALRasterBandH}
typealias GDALSpatialRef      Ptr{GDAL.OGRSpatialReferenceH}
typealias GDALStyleManager    Ptr{GDAL.OGRStyleMgrH}
typealias GDALStyleTable      Ptr{GDAL.OGRStyleTableH}
typealias GDALStyleTool       Ptr{GDAL.OGRStyleToolH}

typealias StringList          Ptr{Ptr{UInt8}}

abstract AbstractGeometry # needs to have a `ptr::GDALGeometry` attribute
type ColorTable;                    ptr::GDALColorTable         end
type CoordTransform;                ptr::GDALCoordTransform     end
type Dataset;                       ptr::GDALDataset            end
type Driver;                        ptr::GDALDriver             end
type Feature;                       ptr::GDALFeature            end
type FeatureDefn;                   ptr::GDALFeatureDefn        end
type FeatureLayer;                  ptr::GDALFeatureLayer       end
type Field;                         ptr::GDALField              end
type FieldDefn;                     ptr::GDALFieldDefn          end
type Geometry <: AbstractGeometry;  ptr::GDALGeometry           end
type GeomFieldDefn;                 ptr::GDALGeomFieldDefn      end
type RasterAttrTable;               ptr::GDALRasterAttrTable    end
type RasterBand;                    ptr::GDALRasterBand         end
type SpatialRef;                    ptr::GDALSpatialRef         end
type StyleManager;                  ptr::GDALStyleManager       end
type StyleTable;                    ptr::GDALStyleTable         end
type StyleTool;                     ptr::GDALStyleTool          end

@enum(CPLErr,
      CE_None       = (UInt32)(0),
      CE_Debug      = (UInt32)(1),
      CE_Warning    = (UInt32)(2),
      CE_Failure    = (UInt32)(3),
      CE_Fatal      = (UInt32)(4))

@enum(CPLXMLNodeType,
      CXT_Element   = (UInt32)(0),
      CXT_Text      = (UInt32)(1),
      CXT_Attribute = (UInt32)(2),
      CXT_Comment   = (UInt32)(3),
      CXT_Literal   = (UInt32)(4))

"return the corresponding `GDALDataType`"
@enum(GDALDataType,
      GDT_Unknown   = GDAL.GDT_Unknown,
      GDT_Byte      = GDAL.GDT_Byte,
      GDT_UInt16    = GDAL.GDT_UInt16,
      GDT_Int16     = GDAL.GDT_Int16,
      GDT_UInt32    = GDAL.GDT_UInt32,
      GDT_Int32     = GDAL.GDT_Int32,
      GDT_Float32   = GDAL.GDT_Float32,
      GDT_Float64   = GDAL.GDT_Float64)

@enum(GDALAsyncStatusType,
      GARIO_PENDING     = GDAL.GARIO_PENDING,
      GARIO_UPDATE      = GDAL.GARIO_UPDATE,
      GARIO_ERROR       = GDAL.GARIO_ERROR,
      GARIO_COMPLETE    = GDAL.GARIO_COMPLETE,
      GARIO_TypeCount   = GDAL.GARIO_TypeCount)

@enum(GDALAccess,
      GA_ReadOnly   = GDAL.GA_ReadOnly,
      GA_Update     = GDAL.GA_Update)

@enum(GDALRWFlag,
      GF_Read       = GDAL.GF_Read,
      GF_Write      = GDAL.GF_Write)

@enum(GDALRIOResampleAlg,
      GRIORA_NearestNeighbour   = (UInt32)(0),
      GRIORA_Bilinear           = (UInt32)(1),
      GRIORA_Cubic              = (UInt32)(2),
      GRIORA_CubicSpline        = (UInt32)(3),
      GRIORA_Lanczos            = (UInt32)(4),
      GRIORA_Average            = (UInt32)(5),
      GRIORA_Mode               = (UInt32)(6),
      GRIORA_Gauss              = (UInt32)(7))

@enum(GDALColorInterp,
      GCI_Undefined         = (UInt32)(0),
      GCI_GrayIndex         = (UInt32)(1),
      GCI_PaletteIndex      = (UInt32)(2),
      GCI_RedBand           = (UInt32)(3),
      GCI_GreenBand         = (UInt32)(4),
      GCI_BlueBand          = (UInt32)(5),
      GCI_AlphaBand         = (UInt32)(6),
      GCI_HueBand           = (UInt32)(7),
      GCI_SaturationBand    = (UInt32)(8),
      GCI_LightnessBand     = (UInt32)(9),
      GCI_CyanBand          = (UInt32)(10),
      GCI_MagentaBand       = (UInt32)(11),
      GCI_YellowBand        = (UInt32)(12),
      GCI_BlackBand         = (UInt32)(13),
      GCI_YCbCr_YBand       = (UInt32)(14),
      GCI_YCbCr_CbBand      = (UInt32)(15),
      GCI_YCbCr_CrBand      = (UInt32)(16))

@enum(GDALPaletteInterp,
      GPI_Gray  = (UInt32)(0),
      GPI_RGB   = (UInt32)(1),
      GPI_CMYK  = (UInt32)(2),
      GPI_HLS   = (UInt32)(3))

@enum(GDALRATFieldType,
      GFT_Integer   = (UInt32)(0),
      GFT_Real      = (UInt32)(1),
      GFT_String    = (UInt32)(2))

@enum(GDALRATFieldUsage,
      GFU_Generic       = (UInt32)(0),
      GFU_PixelCount    = (UInt32)(1),
      GFU_Name          = (UInt32)(2),
      GFU_Min           = (UInt32)(3),
      GFU_Max           = (UInt32)(4),
      GFU_MinMax        = (UInt32)(5),
      GFU_Red           = (UInt32)(6),
      GFU_Green         = (UInt32)(7),
      GFU_Blue          = (UInt32)(8),
      GFU_Alpha         = (UInt32)(9),
      GFU_RedMin        = (UInt32)(10),
      GFU_GreenMin      = (UInt32)(11),
      GFU_BlueMin       = (UInt32)(12),
      GFU_AlphaMin      = (UInt32)(13),
      GFU_RedMax        = (UInt32)(14),
      GFU_GreenMax      = (UInt32)(15),
      GFU_BlueMax       = (UInt32)(16),
      GFU_AlphaMax      = (UInt32)(17),
      GFU_MaxCount      = (UInt32)(18))

@enum(GDALTileOrganization,
      GTO_TIP = (UInt32)(0),
      GTO_BIT = (UInt32)(1),
      GTO_BSQ = (UInt32)(2))

@enum(GDALGridAlgorithm,
      GGA_InverseDistanceToAPower                   = (UInt32)(1),
      GGA_MovingAverage                             = (UInt32)(2),
      GGA_NearestNeighbor                           = (UInt32)(3),
      GGA_MetricMinimum                             = (UInt32)(4),
      GGA_MetricMaximum                             = (UInt32)(5),
      GGA_MetricRange                               = (UInt32)(6),
      GGA_MetricCount                               = (UInt32)(7),
      GGA_MetricAverageDistance                     = (UInt32)(8),
      GGA_MetricAverageDistancePts                  = (UInt32)(9),
      GGA_Linear                                    = (UInt32)(10),
      GGA_InverseDistanceToAPowerNearestNeighbor    = (UInt32)(11))

@enum(OGRwkbGeometryType,
      wkbUnknown                = GDAL.wkbUnknown,
      wkbPoint                  = GDAL.wkbPoint,
      wkbLineString             = GDAL.wkbLineString,
      wkbPolygon                = GDAL.wkbPolygon,
      wkbMultiPoint             = GDAL.wkbMultiPoint,
      wkbMultiLineString        = GDAL.wkbMultiLineString,
      wkbMultiPolygon           = GDAL.wkbMultiPolygon,
      wkbGeometryCollection     = GDAL.wkbGeometryCollection,
      wkbCircularString         = GDAL.wkbCircularString,
      wkbCompoundCurve          = GDAL.wkbCompoundCurve,
      wkbCurvePolygon           = GDAL.wkbCurvePolygon,
      wkbMultiCurve             = GDAL.wkbMultiCurve,
      wkbMultiSurface           = GDAL.wkbMultiSurface,
      wkbCurve                  = GDAL.wkbCurve,
      wkbSurface                = GDAL.wkbSurface,
      wkbPolyhedralSurface      = GDAL.wkbPolyhedralSurface,
      wkbTIN                    = GDAL.wkbTIN,
      wkbTriangle               = GDAL.wkbTriangle,
      wkbNone                   = GDAL.wkbNone,
      wkbLinearRing             = GDAL.wkbLinearRing,
      wkbCircularStringZ        = GDAL.wkbCircularStringZ,
      wkbCompoundCurveZ         = GDAL.wkbCompoundCurveZ,
      wkbCurvePolygonZ          = GDAL.wkbCurvePolygonZ,
      wkbMultiCurveZ            = GDAL.wkbMultiCurveZ,
      wkbMultiSurfaceZ          = GDAL.wkbMultiSurfaceZ,
      wkbCurveZ                 = GDAL.wkbCurveZ,
      wkbSurfaceZ               = GDAL.wkbSurfaceZ,
      wkbPolyhedralSurfaceZ     = GDAL.wkbPolyhedralSurfaceZ,
      wkbTINZ                   = GDAL.wkbTINZ,
      wkbTriangleZ              = GDAL.wkbTriangleZ,
      wkbPointM                 = GDAL.wkbPointM,
      wkbLineStringM            = GDAL.wkbLineStringM,
      wkbPolygonM               = GDAL.wkbPolygonM,
      wkbMultiPointM            = GDAL.wkbMultiPointM,
      wkbMultiLineStringM       = GDAL.wkbMultiLineStringM,
      wkbMultiPolygonM          = GDAL.wkbMultiPolygonM,
      wkbGeometryCollectionM    = GDAL.wkbGeometryCollectionM,
      wkbCircularStringM        = GDAL.wkbCircularStringM,
      wkbCompoundCurveM         = GDAL.wkbCompoundCurveM,
      wkbCurvePolygonM          = GDAL.wkbCurvePolygonM,
      wkbMultiCurveM            = GDAL.wkbMultiCurveM,
      wkbMultiSurfaceM          = GDAL.wkbMultiSurfaceM,
      wkbCurveM                 = GDAL.wkbCurveM,
      wkbSurfaceM               = GDAL.wkbSurfaceM,
      wkbPolyhedralSurfaceM     = GDAL.wkbPolyhedralSurfaceM,
      wkbTINM                   = GDAL.wkbTINM,
      wkbTriangleM              = GDAL.wkbTriangleM,
      wkbPointZM                = GDAL.wkbPointZM,
      wkbLineStringZM           = GDAL.wkbLineStringZM,
      wkbPolygonZM              = GDAL.wkbPolygonZM,
      wkbMultiPointZM           = GDAL.wkbMultiPointZM,
      wkbMultiLineStringZM      = GDAL.wkbMultiLineStringZM,
      wkbMultiPolygonZM         = GDAL.wkbMultiPolygonZM,
      wkbGeometryCollectionZM   = GDAL.wkbGeometryCollectionZM,
      wkbCircularStringZM       = GDAL.wkbCircularStringZM,
      wkbCompoundCurveZM        = GDAL.wkbCompoundCurveZM,
      wkbCurvePolygonZM         = GDAL.wkbCurvePolygonZM,
      wkbMultiCurveZM           = GDAL.wkbMultiCurveZM,
      wkbMultiSurfaceZM         = GDAL.wkbMultiSurfaceZM,
      wkbCurveZM                = GDAL.wkbCurveZM,
      wkbSurfaceZM              = GDAL.wkbSurfaceZM,
      wkbPolyhedralSurfaceZM    = GDAL.wkbPolyhedralSurfaceZM,
      wkbTINZM                  = GDAL.wkbTINZM,
      wkbTriangleZM             = GDAL.wkbTriangleZM) 
    # the rest returns an Inexact Error for now
      # wkbPoint25D = GDAL.wkbPoint25D,
      # wkbLineString25D = GDAL.wkbLineString25D,
      # wkbPolygon25D = GDAL.wkbPolygon25D,
      # wkbMultiPoint25D = GDAL.wkbMultiPoint25D,
      # wkbMultiLineString25D = GDAL.wkbMultiLineString25D,
      # wkbMultiPolygon25D = GDAL.wkbMultiPolygon25D,
      # wkbGeometryCollection25D = GDAL.wkbGeometryCollection25D

@enum(OGRwkbVariant,
      wkbVariantOldOgc      = (UInt32)(0),
      wkbVariantIso         = (UInt32)(1),
      wkbVariantPostGIS1    = (UInt32)(2))

@enum(OGRwkbByteOrder,
      wkbXDR = (UInt32)(0),
      wkbNDR = (UInt32)(1))

@enum(OGRFieldType,
      OFTInteger        = GDAL.OFTInteger,
      OFTIntegerList    = GDAL.OFTIntegerList,
      OFTReal           = GDAL.OFTReal,
      OFTRealList       = GDAL.OFTRealList,
      OFTString         = GDAL.OFTString,
      OFTStringList     = GDAL.OFTStringList,
      OFTWideString     = GDAL.OFTWideString,
      OFTWideStringList = GDAL.OFTWideStringList,
      OFTBinary         = GDAL.OFTBinary,
      OFTDate           = GDAL.OFTDate,
      OFTTime           = GDAL.OFTTime,
      OFTDateTime       = GDAL.OFTDateTime,
      OFTInteger64      = GDAL.OFTInteger64,
      OFTInteger64List  = GDAL.OFTInteger64List)

@enum(OGRFieldSubType,
      OFSTNone      = (UInt32)(0),
      OFSTBoolean   = (UInt32)(1),
      OFSTInt16     = (UInt32)(2),
      OFSTFloat32   = (UInt32)(3))

@enum(OGRJustification,
      OJUndefined   = (UInt32)(0),
      OJLeft        = (UInt32)(1),
      OJRight       = (UInt32)(2))

@enum(OGRSTClassId,
      OGRSTCNone    = (UInt32)(0),
      OGRSTCPen     = (UInt32)(1),
      OGRSTCBrush   = (UInt32)(2),
      OGRSTCSymbol  = (UInt32)(3),
      OGRSTCLabel   = (UInt32)(4),
      OGRSTCVector  = (UInt32)(5))

@enum(OGRSTUnitId,
      OGRSTUGround  = (UInt32)(0),
      OGRSTUPixel   = (UInt32)(1),
      OGRSTUPoints  = (UInt32)(2),
      OGRSTUMM      = (UInt32)(3),
      OGRSTUCM      = (UInt32)(4),
      OGRSTUInches  = (UInt32)(5))

@enum(OGRSTPenParam,
      OGRSTPenColor     = (UInt32)(0),
      OGRSTPenWidth     = (UInt32)(1),
      OGRSTPenPattern   = (UInt32)(2),
      OGRSTPenId        = (UInt32)(3),
      OGRSTPenPerOffset = (UInt32)(4),
      OGRSTPenCap       = (UInt32)(5),
      OGRSTPenJoin      = (UInt32)(6),
      OGRSTPenPriority  = (UInt32)(7),
      OGRSTPenLast      = (UInt32)(8))

@enum(OGRSTBrushParam,
      OGRSTBrushFColor      = (UInt32)(0),
      OGRSTBrushBColor      = (UInt32)(1),
      OGRSTBrushId          = (UInt32)(2),
      OGRSTBrushAngle       = (UInt32)(3),
      OGRSTBrushSize        = (UInt32)(4),
      OGRSTBrushDx          = (UInt32)(5),
      OGRSTBrushDy          = (UInt32)(6),
      OGRSTBrushPriority    = (UInt32)(7),
      OGRSTBrushLast        = (UInt32)(8))

@enum(OGRSTSymbolParam,
      OGRSTSymbolId         = (UInt32)(0),
      OGRSTSymbolAngle      = (UInt32)(1),
      OGRSTSymbolColor      = (UInt32)(2),
      OGRSTSymbolSize       = (UInt32)(3),
      OGRSTSymbolDx         = (UInt32)(4),
      OGRSTSymbolDy         = (UInt32)(5),
      OGRSTSymbolStep       = (UInt32)(6),
      OGRSTSymbolPerp       = (UInt32)(7),
      OGRSTSymbolOffset     = (UInt32)(8),
      OGRSTSymbolPriority   = (UInt32)(9),
      OGRSTSymbolFontName   = (UInt32)(10),
      OGRSTSymbolOColor     = (UInt32)(11),
      OGRSTSymbolLast       = (UInt32)(12))

@enum(OGRSTLabelParam,
      OGRSTLabelFontName    = (UInt32)(0),
      OGRSTLabelSize        = (UInt32)(1),
      OGRSTLabelTextString  = (UInt32)(2),
      OGRSTLabelAngle       = (UInt32)(3),
      OGRSTLabelFColor      = (UInt32)(4),
      OGRSTLabelBColor      = (UInt32)(5),
      OGRSTLabelPlacement   = (UInt32)(6),
      OGRSTLabelAnchor      = (UInt32)(7),
      OGRSTLabelDx          = (UInt32)(8),
      OGRSTLabelDy          = (UInt32)(9),
      OGRSTLabelPerp        = (UInt32)(10),
      OGRSTLabelBold        = (UInt32)(11),
      OGRSTLabelItalic      = (UInt32)(12),
      OGRSTLabelUnderline   = (UInt32)(13),
      OGRSTLabelPriority    = (UInt32)(14),
      OGRSTLabelStrikeout   = (UInt32)(15),
      OGRSTLabelStretch     = (UInt32)(16),
      OGRSTLabelAdjHor      = (UInt32)(17),
      OGRSTLabelAdjVert     = (UInt32)(18),
      OGRSTLabelHColor      = (UInt32)(19),
      OGRSTLabelOColor      = (UInt32)(20),
      OGRSTLabelLast        = (UInt32)(21))

@enum(GDALResampleAlg,
      GRA_NearestNeighbour  = (UInt32)(0),
      GRA_Bilinear          = (UInt32)(1),
      GRA_Cubic             = (UInt32)(2),
      GRA_CubicSpline       = (UInt32)(3),
      GRA_Lanczos           = (UInt32)(4),
      GRA_Average           = (UInt32)(5),
      GRA_Mode              = (UInt32)(6),
      GRA_Max               = (UInt32)(8),
      GRA_Min               = (UInt32)(9),
      GRA_Med               = (UInt32)(10),
      GRA_Q1                = (UInt32)(11),
      GRA_Q3                = (UInt32)(12))

@enum(GWKAverageOrModeAlg,
      GWKAOM_Average    = (UInt32)(1),
      GWKAOM_Fmode      = (UInt32)(2),
      GWKAOM_Imode      = (UInt32)(3),
      GWKAOM_Max        = (UInt32)(4),
      GWKAOM_Min        = (UInt32)(5),
      GWKAOM_Quant      = (UInt32)(6))

@enum(OGRAxisOrientation,
      OAO_Other     = (UInt32)(0),
      OAO_North     = (UInt32)(1),
      OAO_South     = (UInt32)(2),
      OAO_East      = (UInt32)(3),
      OAO_West      = (UInt32)(4),
      OAO_Up        = (UInt32)(5),
      OAO_Down      = (UInt32)(6))

@enum(OGRDatumType,
      # ODT_HD_Min                = (UInt32)(1000),
      ODT_HD_Other              = (UInt32)(1000),
      ODT_HD_Classic            = (UInt32)(1001),
      ODT_HD_Geocentric         = (UInt32)(1002),
      ODT_HD_Max                = (UInt32)(1999),
      # ODT_VD_Min                = (UInt32)(2000),
      ODT_VD_Other              = (UInt32)(2000),
      ODT_VD_Orthometric        = (UInt32)(2001),
      ODT_VD_Ellipsoidal        = (UInt32)(2002),
      ODT_VD_AltitudeBarometric = (UInt32)(2003),
      ODT_VD_Normal             = (UInt32)(2004),
      ODT_VD_GeoidModelDerived  = (UInt32)(2005),
      ODT_VD_Depth              = (UInt32)(2006),
      ODT_VD_Max                = (UInt32)(2999),
      ODT_LD_Min                = (UInt32)(10000),
      ODT_LD_Max                = (UInt32)(32767))

"return the corresponding `DataType` in julia"
const _JLTYPE = Dict{GDAL.GDALDataType, DataType}(
    GDAL.GDT_Unknown    => Any,
    GDAL.GDT_Byte       => UInt8,
    GDAL.GDT_UInt16     => UInt16,
    GDAL.GDT_Int16      => Int16,
    GDAL.GDT_UInt32     => UInt32,
    GDAL.GDT_Int32      => Int32,
    GDAL.GDT_Float32    => Float32,
    GDAL.GDT_Float64    => Float64)

const _GDALTYPE = Dict{DataType,GDAL.GDALDataType}(
    Any         => GDAL.GDT_Unknown,
    UInt8       => GDAL.GDT_Byte,
    UInt16      => GDAL.GDT_UInt16,
    Int16       => GDAL.GDT_Int16,
    UInt32      => GDAL.GDT_UInt32,
    Int32       => GDAL.GDT_Int32,
    Float32     => GDAL.GDT_Float32,
    Float64     => GDAL.GDT_Float64)

"return the corresponding `DataType` in julia"
const _FIELDTYPE = Dict{OGRFieldType, DataType}(
    OFTInteger         => Int32,
    OFTIntegerList     => Void,
    OFTReal            => Float64,
    OFTRealList        => Void,
    OFTString          => String,
    OFTStringList      => Void,
    OFTWideString      => Void, # deprecated
    OFTWideStringList  => Void, # deprecated
    OFTBinary          => Void,
    OFTDate            => Date,
    OFTTime            => Void,
    OFTDateTime        => DateTime,
    OFTInteger64       => Int64,
    OFTInteger64List   => Void)

@enum(GDALOpenFlag,
      OF_ReadOnly = GDAL.GDAL_OF_READONLY, # 0x00
      OF_Update   = GDAL.GDAL_OF_UPDATE,   # 0x01
#     OF_All      = GDAL.GDAL_OF_ALL,      # 0x00
      OF_Raster   = GDAL.GDAL_OF_RASTER,   # 0x02
      OF_Vector   = GDAL.GDAL_OF_VECTOR,   # 0x04
      OF_GNM      = GDAL.GDAL_OF_GNM)      # 0x08
                 # const GDAL_OF_KIND_MASK = 0x1e
                 # const GDAL_OF_SHARED = 0x20
                 # const GDAL_OF_VERBOSE_ERROR = 0x40
                 # const GDAL_OF_INTERNAL = 0x80
                 # const GDAL_OF_DEFAULT_BLOCK_ACCESS = 0
                 # const GDAL_OF_ARRAY_BLOCK_ACCESS = 0x0100
                 # const GDAL_OF_HASHSET_BLOCK_ACCESS = 0x0200
                 # const GDAL_OF_RESERVED_1 = 0x0300
                 # const GDAL_OF_BLOCK_ACCESS_MASK = 0x0300

import Base.|

|(x::GDALOpenFlag,y::UInt8) = UInt8(x) | y
|(x::UInt8,y::GDALOpenFlag) = x | UInt8(y)
|(x::GDALOpenFlag,y::GDALOpenFlag) = UInt8(x) | UInt8(y)

"Get data type size in bits."
typesize(dt::GDALDataType) =
    @gdal(GDALGetDataTypeSize::Cint,
        dt::GDAL.GDALDataType
    )

"name (string) corresponding to GDAL data type"
typename(dt::GDALDataType) =
    unsafe_string(@gdal(GDALGetDataTypeName::Cstring,
        dt::GDAL.GDALDataType
    ))

"Returns GDAL data type by symbolic name."
gettype(name::AbstractString) = GDALDataType(GDAL.getdatatypebyname(name))

"Return the smallest data type that can fully express both input data types."
typeunion(dt1::GDALDataType,dt2::GDALDataType) =
    GDALDataType(@gdal(GDALDataTypeUnion::GDAL.GDALDataType,
        dt1::GDAL.GDALDataType,
        dt2::GDAL.GDALDataType
    ))

"""
`true` if `dtype` is one of `GDT_{CInt16|CInt32|CFloat32|CFloat64}`
"""
iscomplex(dtype::GDALDataType) =
    Bool(@gdal(GDALDataTypeIsComplex::Cint,
        dtype::GDAL.GDALDataType
    ))

"Get name of AsyncStatus data type."
getname(dtype::GDALAsyncStatusType) =
    unsafe_string(@gdal(GDALGetAsyncStatusTypeName::Cstring,
        dtype::GDAL.GDALAsyncStatusType
    ))

"Get AsyncStatusType by symbolic name."
asyncstatustype(name::AbstractString) =
    GDALAsyncStatusType(GDAL.getasyncstatustypebyname(name))

"Return name (string) corresponding to color interpretation"
getname(obj::GDALColorInterp) =
    unsafe_string(@gdal(GDALGetColorInterpretationName::Cstring,
        obj::GDAL.GDALColorInterp
    ))

"Get color interpretation corresponding to the given symbolic name."
colorinterp(name::AbstractString) =
    GDALColorInterp(GDAL.getcolorinterpretationbyname(name))

"Get name of palette interpretation."
getname(obj::GDALPaletteInterp) =
    unsafe_string(@gdal(GDALGetPaletteInterpretationName::Cstring,
        obj::GDAL.GDALPaletteInterp
    ))

"Fetch human readable name for a field type."
getname(obj::OGRFieldType) = 
    unsafe_string(@gdal(OGR_GetFieldTypeName::Cstring,
        obj::GDAL.OGRFieldType
    ))

"Fetch human readable name for a field subtype."
getname(obj::OGRFieldSubType) =
    unsafe_string(@gdal(OGR_GetFieldSubTypeName::Cstring,
        obj::GDAL.OGRFieldSubType
    ))

"Return if type and subtype are compatible."
arecompatible(dtype::OGRFieldType, subtype::OGRFieldSubType) =
    Bool(@gdal(OGR_AreTypeSubTypeCompatible::Cint,
        dtype::GDAL.OGRFieldType,
        subtype::GDAL.OGRFieldSubType
    ))
