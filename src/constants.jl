const StringList = Ptr{Cstring}

@enum(GDALDataType,
    GDT_Unknown = 0,
    GDT_Byte = 1,
    GDT_UInt16 = 2,
    GDT_Int16 = 3,
    GDT_UInt32 = 4,
    GDT_Int32 = 5,
    GDT_Float32 = 6,
    GDT_Float64 = 7,
    GDT_CInt16 = 8,
    GDT_CInt32 = 9,
    GDT_CFloat32 = 10,
    GDT_CFloat64 = 11,
    GDT_TypeCount = 12,
)

@enum(OGRFieldType,
    OFTInteger          = 0,
    OFTIntegerList      = 1,
    OFTReal             = 2,
    OFTRealList         = 3,
    OFTString           = 4,
    OFTStringList       = 5,
    OFTWideString       = 6,
    OFTWideStringList   = 7,
    OFTBinary           = 8,
    OFTDate             = 9,
    OFTTime             = 10,
    OFTDateTime         = 11,
    OFTInteger64        = 12,
    OFTInteger64List    = 13,
    OFTMaxType          = 14, # 13
)

@enum(OGRFieldSubType,
    OFSTNone = 0,
    OFSTBoolean = 1,
    OFSTInt16 = 2,
    OFSTFloat32 = 3,
    OFSTJSON = 4,
    OFSTMaxSubType = 5, # 4
)

@enum(OGRJustification,
    OJUndefined = 0,
    OJLeft = 1,
    OJRight = 2,
)

@enum(GDALRATFieldType,
    GFT_Integer = 0,
    GFT_Real = 1,
    GFT_String = 2,
)

@enum(GDALRATFieldUsage,
    GFU_Generic = 0,
    GFU_PixelCount = 1,
    GFU_Name = 2,
    GFU_Min = 3,
    GFU_Max = 4,
    GFU_MinMax = 5,
    GFU_Red = 6,
    GFU_Green = 7,
    GFU_Blue = 8,
    GFU_Alpha = 9,
    GFU_RedMin = 10,
    GFU_GreenMin = 11,
    GFU_BlueMin = 12,
    GFU_AlphaMin = 13,
    GFU_RedMax = 14,
    GFU_GreenMax = 15,
    GFU_BlueMax = 16,
    GFU_AlphaMax = 17,
    GFU_MaxCount = 18,
)

@enum(GDALAccess,
    GA_ReadOnly = 0,
    GA_Update = 1,
)

@enum(GDALRWFlag,
    GF_Read = 0,
    GF_Write = 1,
)

@enum(GDALPaletteInterp,
    GPI_Gray = 0,
    GPI_RGB = 1,
    GPI_CMYK = 2,
    GPI_HLS = 3,
)

@enum(GDALColorInterp,
    GCI_Undefined = 0,
    GCI_GrayIndex = 1,
    GCI_PaletteIndex = 2,
    GCI_RedBand = 3,
    GCI_GreenBand = 4,
    GCI_BlueBand = 5,
    GCI_AlphaBand = 6,
    GCI_HueBand = 7,
    GCI_SaturationBand = 8,
    GCI_LightnessBand = 9,
    GCI_CyanBand = 10,
    GCI_MagentaBand = 11,
    GCI_YellowBand = 12,
    GCI_BlackBand = 13,
    GCI_YCbCr_YBand = 14,
    GCI_YCbCr_CbBand = 15,
    GCI_YCbCr_CrBand = 16,
    GCI_Max = 17, # 16
)

@enum(GDALAsyncStatusType,
    GARIO_PENDING = 0,
    GARIO_UPDATE = 1,
    GARIO_ERROR = 2,
    GARIO_COMPLETE = 3,
    GARIO_TypeCount = 4,
)

@enum(OGRSTClassId,
    OGRSTCNone = 0,
    OGRSTCPen = 1,
    OGRSTCBrush = 2,
    OGRSTCSymbol = 3,
    OGRSTCLabel = 4,
    OGRSTCVector = 5,
)

@enum(OGRSTUnitId,
    OGRSTUGround = 0,
    OGRSTUPixel = 1,
    OGRSTUPoints = 2,
    OGRSTUMM = 3,
    OGRSTUCM = 4,
    OGRSTUInches = 5,
)

@enum(OGRwkbGeometryType,
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

@enum(OGRwkbByteOrder,
    wkbXDR = 0,
    wkbNDR = 1,
)

@enum(GDALOpenFlag,
    OF_READONLY             = GDAL.GDAL_OF_READONLY,                # 0x00
    OF_UPDATE               = GDAL.GDAL_OF_UPDATE,                  # 0x01
    # OF_All                  = GDAL.GDAL_OF_ALL,                   # 0x00
    OF_RASTER               = GDAL.GDAL_OF_RASTER,                  # 0x02
    OF_VECTOR               = GDAL.GDAL_OF_VECTOR,                  # 0x04
    OF_GNM                  = GDAL.GDAL_OF_GNM,                     # 0x08
    OF_KIND_MASK            = GDAL.GDAL_OF_KIND_MASK,               # 0x1e
    OF_SHARED               = GDAL.GDAL_OF_SHARED,                  # 0x20
    OF_VERBOSE_ERROR        = GDAL.GDAL_OF_VERBOSE_ERROR,           # 0x40
    OF_INTERNAL             = GDAL.GDAL_OF_INTERNAL,                # 0x80
    # OF_DEFAULT_BLOCK_ACCESS = GDAL.GDAL_OF_DEFAULT_BLOCK_ACCESS,  # 0
    OF_ARRAY_BLOCK_ACCESS   = GDAL.GDAL_OF_ARRAY_BLOCK_ACCESS,      # 0x0100
    OF_HASHSET_BLOCK_ACCESS = GDAL.GDAL_OF_HASHSET_BLOCK_ACCESS,    # 0x0200
    # OF_RESERVED_1           = GDAL.GDAL_OF_RESERVED_1,            # 0x0300
    OF_BLOCK_ACCESS_MASK    = GDAL.GDAL_OF_BLOCK_ACCESS_MASK,       # 0x0300
)

@enum(FieldValidation,
    F_VAL_NULL                      = GDAL.OGR_F_VAL_NULL,                      # 0x0001
    F_VAL_GEOM_TYPE                 = GDAL.OGR_F_VAL_GEOM_TYPE,                 # 0x0002
    F_VAL_WIDTH                     = GDAL.OGR_F_VAL_WIDTH,                     # 0x0004
    F_VAL_ALLOW_NULL_WHEN_DEFAULT   = GDAL.OGR_F_VAL_ALLOW_NULL_WHEN_DEFAULT,   # 0x0008
    F_VAL_ALLOW_DIFFERENT_GEOM_DIM  = GDAL.OGR_F_VAL_ALLOW_DIFFERENT_GEOM_DIM,  # 0x0010
)
