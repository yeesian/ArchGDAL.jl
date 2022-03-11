const StringList = Ptr{Cstring}

"""
The value of `GDALDataType` could be different from `GDAL.GDALDataType`.

It maps correctly to `GDAL.GDALDataType` if you do e.g.

```jldoctest; output = false
convert(GDAL.GDALDataType, ArchGDAL.GDT_Unknown)

# output
GDT_Unknown::GDALDataType = 0x00000000
```
"""
@enum(
    GDALDataType,
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

"""
The value of `OGRFieldType` could be different from `GDAL.OGRFieldType`.

It maps correctly to `GDAL.OGRFieldType` if you do e.g.

```jldoctest; output = false
convert(GDAL.OGRFieldType, ArchGDAL.OFTInteger)

# output
OFTInteger::OGRFieldType = 0x00000000
```
"""
@enum(
    OGRFieldType,
    OFTInteger = 0,
    OFTIntegerList = 1,
    OFTReal = 2,
    OFTRealList = 3,
    OFTString = 4,
    OFTStringList = 5,
    OFTWideString = 6, # deprecated in GDAL
    OFTWideStringList = 7, # deprecated in GDAL
    OFTBinary = 8,
    OFTDate = 9,
    OFTTime = 10,
    OFTDateTime = 11,
    OFTInteger64 = 12,
    OFTInteger64List = 13,
    OFTMaxType = 14, # 13
)

"""
The value of `OGRFieldSubType` could be different from `GDAL.OGRFieldSubType`.

It maps correctly to `GDAL.OGRFieldSubType` if you do e.g.

```jldoctest; output = false
convert(GDAL.OGRFieldSubType, ArchGDAL.OFSTNone)

# output
OFSTNone::OGRFieldSubType = 0x00000000
```
"""
@enum(
    OGRFieldSubType,
    OFSTNone = 0,
    OFSTBoolean = 1,
    OFSTInt16 = 2,
    OFSTFloat32 = 3,
    OFSTJSON = 4,
    OFSTMaxSubType = 5, # 4
)

"""
The value of `OGRJustification` could be different from `GDAL.OGRJustification`.

It maps correctly to `GDAL.OGRJustification` if you do e.g.

```jldoctest; output = false
convert(GDAL.OGRJustification, ArchGDAL.OJUndefined)

# output
OJUndefined::OGRJustification = 0x00000000
```
"""
@enum(OGRJustification, OJUndefined = 0, OJLeft = 1, OJRight = 2,)

"""
The value of `GDALRATFieldType` could be different from `GDAL.GDALRATFieldType`.

It maps correctly to `GDAL.GDALRATFieldType` if you do e.g.

```jldoctest; output = false
convert(GDAL.GDALRATFieldType, ArchGDAL.GFT_Integer)

# output
GFT_Integer::GDALRATFieldType = 0x00000000
```
"""
@enum(GDALRATFieldType, GFT_Integer = 0, GFT_Real = 1, GFT_String = 2,)

"""
The value of `GDALRATFieldUsage` could be different from `GDAL.GDALRATFieldUsage`.

It maps correctly to `GDAL.GDALRATFieldUsage` if you do e.g.

```jldoctest; output = false
convert(GDAL.GDALRATFieldUsage, ArchGDAL.GFU_Generic)

# output
GFU_Generic::GDALRATFieldUsage = 0x00000000
```
"""
@enum(
    GDALRATFieldUsage,
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

"""
The value of `GDALAccess` could be different from `GDAL.GDALAccess`.

It maps correctly to `GDAL.GDALAccess` if you do e.g.

```jldoctest; output = false
convert(GDAL.GDALAccess, ArchGDAL.GA_ReadOnly)

# output
GA_ReadOnly::GDALAccess = 0x00000000
```
"""
@enum(GDALAccess, GA_ReadOnly = 0, GA_Update = 1,)

"""
The value of `GDALRWFlag` could be different from `GDAL.GDALRWFlag`.

It maps correctly to `GDAL.GDALRWFlag` if you do e.g.

```jldoctest; output = false
convert(GDAL.GDALRWFlag, ArchGDAL.GF_Read)

# output
GF_Read::GDALRWFlag = 0x00000000
```
"""
@enum(GDALRWFlag, GF_Read = 0, GF_Write = 1,)

"""
The value of `GDALPaletteInterp` could be different from `GDAL.GDALPaletteInterp`.

It maps correctly to `GDAL.GDALPaletteInterp` if you do e.g.

```jldoctest; output = false
convert(GDAL.GDALPaletteInterp, ArchGDAL.GPI_Gray)

# output
GPI_Gray::GDALPaletteInterp = 0x00000000
```
"""
@enum(GDALPaletteInterp, GPI_Gray = 0, GPI_RGB = 1, GPI_CMYK = 2, GPI_HLS = 3,)

"""
The value of `GDALColorInterp` could be different from `GDAL.GDALColorInterp`.

It maps correctly to `GDAL.GDALColorInterp` if you do e.g.

```jldoctest; output = false
convert(GDAL.GDALColorInterp, ArchGDAL.GCI_Undefined)

# output
GCI_Undefined::GDALColorInterp = 0x00000000
```
"""
@enum(
    GDALColorInterp,
    GCI_Undefined = 0,
    GCI_GrayIndex = 1,      # GreyScale
    GCI_PaletteIndex = 2,   # Paletted (see associated color table)
    GCI_RedBand = 3,        # Red band of RGBA image
    GCI_GreenBand = 4,      # Green band of RGBA image
    GCI_BlueBand = 5,       # Blue band of RGBA image
    GCI_AlphaBand = 6,      # Alpha (0=transparent, 255=opaque)
    GCI_HueBand = 7,        # Hue band of HLS image
    GCI_SaturationBand = 8, # Saturation band of HLS image
    GCI_LightnessBand = 9,  # Lightness band of HLS image
    GCI_CyanBand = 10,      # Cyan band of CMYK image
    GCI_MagentaBand = 11,   # Magenta band of CMYK image
    GCI_YellowBand = 12,    # Yellow band of CMYK image
    GCI_BlackBand = 13,     # Black band of CMYK image
    GCI_YCbCr_YBand = 14,   # Y Luminance
    GCI_YCbCr_CbBand = 15,  # Cb Chroma
    GCI_YCbCr_CrBand = 16,  # Cr Chroma
    GCI_Max = 17,           # Max current value = 16
)

"""
The value of `GDALAsyncStatusType` could be different from `GDAL.GDALAsyncStatusType`.

It maps correctly to `GDAL.GDALAsyncStatusType` if you do e.g.

```jldoctest; output = false
convert(GDAL.GDALAsyncStatusType, ArchGDAL.GARIO_PENDING)

# output
GARIO_PENDING::GDALAsyncStatusType = 0x00000000
```
"""
@enum(
    GDALAsyncStatusType,
    GARIO_PENDING = 0,
    GARIO_UPDATE = 1,
    GARIO_ERROR = 2,
    GARIO_COMPLETE = 3,
    GARIO_TypeCount = 4,
)

"""
The value of `OGRSTClassId` could be different from `GDAL.OGRSTClassId`.

It maps correctly to `GDAL.OGRSTClassId` if you do e.g.

```jldoctest; output = false
convert(GDAL.OGRSTClassId, ArchGDAL.OGRSTCNone)

# output
OGRSTCNone::ogr_style_tool_class_id = 0x00000000
```
"""
@enum(
    OGRSTClassId,
    OGRSTCNone = 0,
    OGRSTCPen = 1,
    OGRSTCBrush = 2,
    OGRSTCSymbol = 3,
    OGRSTCLabel = 4,
    OGRSTCVector = 5,
)

"""
The value of `OGRSTUnitId` could be different from `GDAL.OGRSTUnitId`.

It maps correctly to `GDAL.OGRSTUnitId` if you do e.g.

```jldoctest; output = false
convert(GDAL.OGRSTUnitId, ArchGDAL.OGRSTUGround)

# output
OGRSTUGround::ogr_style_tool_units_id = 0x00000000
```
"""
@enum(
    OGRSTUnitId,
    OGRSTUGround = 0,
    OGRSTUPixel = 1,
    OGRSTUPoints = 2,
    OGRSTUMM = 3,
    OGRSTUCM = 4,
    OGRSTUInches = 5,
)

"""
The value of `OGRwkbGeometryType` could be different from `GDAL.OGRwkbGeometryType`.

It maps correctly to `GDAL.OGRwkbGeometryType` if you do e.g.

```jldoctest; output = false
convert(GDAL.OGRwkbGeometryType, ArchGDAL.wkbUnknown)

# output
wkbUnknown::OGRwkbGeometryType = 0x00000000
```
"""
@enum OGRwkbGeometryType::UInt32 begin
    wkbUnknown = 0x00000000
    wkbPoint = 0x00000001
    wkbLineString = 0x00000002
    wkbPolygon = 0x00000003
    wkbMultiPoint = 0x00000004
    wkbMultiLineString = 0x00000005
    wkbMultiPolygon = 0x00000006
    wkbGeometryCollection = 0x00000007
    wkbCircularString = 0x00000008
    wkbCompoundCurve = 0x00000009
    wkbCurvePolygon = 0x0000000a
    wkbMultiCurve = 0x0000000b
    wkbMultiSurface = 0x0000000c
    wkbCurve = 0x0000000d
    wkbSurface = 0x0000000e
    wkbPolyhedralSurface = 0x0000000f
    wkbTIN = 0x00000010
    wkbTriangle = 0x00000011
    wkbNone = 0x00000064
    wkbLinearRing = 0x00000065
    wkbCircularStringZ = 0x000003f0
    wkbCompoundCurveZ = 0x000003f1
    wkbCurvePolygonZ = 0x000003f2
    wkbMultiCurveZ = 0x000003f3
    wkbMultiSurfaceZ = 0x000003f4
    wkbCurveZ = 0x000003f5
    wkbSurfaceZ = 0x000003f6
    wkbPolyhedralSurfaceZ = 0x000003f7
    wkbTINZ = 0x000003f8
    wkbTriangleZ = 0x000003f9
    wkbPointM = 0x000007d1
    wkbLineStringM = 0x000007d2
    wkbPolygonM = 0x000007d3
    wkbMultiPointM = 0x000007d4
    wkbMultiLineStringM = 0x000007d5
    wkbMultiPolygonM = 0x000007d6
    wkbGeometryCollectionM = 0x000007d7
    wkbCircularStringM = 0x000007d8
    wkbCompoundCurveM = 0x000007d9
    wkbCurvePolygonM = 0x000007da
    wkbMultiCurveM = 0x000007db
    wkbMultiSurfaceM = 0x000007dc
    wkbCurveM = 0x000007dd
    wkbSurfaceM = 0x000007de
    wkbPolyhedralSurfaceM = 0x000007df
    wkbTINM = 0x000007e0
    wkbTriangleM = 0x000007e1
    wkbPointZM = 0x00000bb9
    wkbLineStringZM = 0x00000bba
    wkbPolygonZM = 0x00000bbb
    wkbMultiPointZM = 0x00000bbc
    wkbMultiLineStringZM = 0x00000bbd
    wkbMultiPolygonZM = 0x00000bbe
    wkbGeometryCollectionZM = 0x00000bbf
    wkbCircularStringZM = 0x00000bc0
    wkbCompoundCurveZM = 0x00000bc1
    wkbCurvePolygonZM = 0x00000bc2
    wkbMultiCurveZM = 0x00000bc3
    wkbMultiSurfaceZM = 0x00000bc4
    wkbCurveZM = 0x00000bc5
    wkbSurfaceZM = 0x00000bc6
    wkbPolyhedralSurfaceZM = 0x00000bc7
    wkbTINZM = 0x00000bc8
    wkbTriangleZM = 0x00000bc9
    wkbPoint25D = 0x80000001
    wkbLineString25D = 0x80000002
    wkbPolygon25D = 0x80000003
    wkbMultiPoint25D = 0x80000004
    wkbMultiLineString25D = 0x80000005
    wkbMultiPolygon25D = 0x80000006
    wkbGeometryCollection25D = 0x80000007
end
@assert begin
    all(
        string.(instances(OGRwkbGeometryType)) .==
        string.(instances(GDAL.OGRwkbGeometryType)),
    ) && all(
        Integer.(instances(OGRwkbGeometryType)) .==
        Integer.(instances(GDAL.OGRwkbGeometryType)),
    )
end

"""
The value of `OGRwkbByteOrder` could be different from `GDAL.OGRwkbByteOrder`.

It maps correctly to `GDAL.OGRwkbByteOrder` if you do e.g.

```jldoctest; output = false
convert(GDAL.OGRwkbByteOrder, ArchGDAL.wkbXDR)

# output
wkbXDR::OGRwkbByteOrder = 0x00000000
```
"""
@enum(OGRwkbByteOrder, wkbXDR = 0, wkbNDR = 1,)

@enum(
    GDALOpenFlag,
    OF_READONLY = GDAL.GDAL_OF_READONLY,                # 0x00
    OF_UPDATE = GDAL.GDAL_OF_UPDATE,                  # 0x01
    # OF_All                  = GDAL.GDAL_OF_ALL,                   # 0x00
    OF_RASTER = GDAL.GDAL_OF_RASTER,                  # 0x02
    OF_VECTOR = GDAL.GDAL_OF_VECTOR,                  # 0x04
    OF_GNM = GDAL.GDAL_OF_GNM,                     # 0x08
    OF_KIND_MASK = GDAL.GDAL_OF_KIND_MASK,               # 0x1e
    OF_SHARED = GDAL.GDAL_OF_SHARED,                  # 0x20
    OF_VERBOSE_ERROR = GDAL.GDAL_OF_VERBOSE_ERROR,           # 0x40
    OF_INTERNAL = GDAL.GDAL_OF_INTERNAL,                # 0x80
    # OF_DEFAULT_BLOCK_ACCESS = GDAL.GDAL_OF_DEFAULT_BLOCK_ACCESS,  # 0
    OF_ARRAY_BLOCK_ACCESS = GDAL.GDAL_OF_ARRAY_BLOCK_ACCESS,      # 0x0100
    OF_HASHSET_BLOCK_ACCESS = GDAL.GDAL_OF_HASHSET_BLOCK_ACCESS,    # 0x0200
    # OF_RESERVED_1           = GDAL.GDAL_OF_RESERVED_1,            # 0x0300
    OF_BLOCK_ACCESS_MASK = GDAL.GDAL_OF_BLOCK_ACCESS_MASK,       # 0x0300
)

@enum(
    FieldValidation,
    F_VAL_NULL = GDAL.OGR_F_VAL_NULL,                      # 0x0001
    F_VAL_GEOM_TYPE = GDAL.OGR_F_VAL_GEOM_TYPE,                 # 0x0002
    F_VAL_WIDTH = GDAL.OGR_F_VAL_WIDTH,                     # 0x0004
    F_VAL_ALLOW_NULL_WHEN_DEFAULT = GDAL.OGR_F_VAL_ALLOW_NULL_WHEN_DEFAULT,   # 0x0008
    F_VAL_ALLOW_DIFFERENT_GEOM_DIM = GDAL.OGR_F_VAL_ALLOW_DIFFERENT_GEOM_DIM,  # 0x0010
)
