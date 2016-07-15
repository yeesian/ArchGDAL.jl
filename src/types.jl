typealias FeatureLayer          Ptr{GDAL.OGRLayerH}
typealias Feature               Ptr{GDAL.OGRFeatureH}
typealias FeatureDefn           Ptr{GDAL.OGRFeatureDefnH}
typealias Field                 Ptr{GDAL.OGRField}
typealias FieldDefn             Ptr{GDAL.OGRFieldDefnH}
typealias Geometry              Ptr{GDAL.OGRGeometryH}
typealias GeomFieldDefn         GDAL.OGRGeomFieldDefnH
typealias SpatialRef            Ptr{GDAL.OGRSpatialReferenceH}
typealias CoordTransform        Ptr{GDAL.OGRCoordinateTransformationH}
typealias Driver                Ptr{GDAL.GDALDriverH}
typealias RasterBand            Ptr{GDAL.GDALRasterBandH}
typealias Dataset               Ptr{GDAL.GDALDatasetH}
typealias Envelope              Ptr{GDAL.OGREnvelope}
typealias Envelope3D            Ptr{GDAL.OGREnvelope3D}
typealias ProgressFunc          Ptr{GDAL.GDALProgressFunc}
typealias RasterAttributeTable  Ptr{GDAL.GDALRasterAttributeTableH}
typealias StyleTable            Ptr{GDAL.OGRStyleTableH}
typealias ColorTable            Ptr{GDAL.GDALColorTableH}
typealias StringList            Ptr{Ptr{UInt8}}

"return the corresponding `DataType` in julia"
const _JLTYPE = Dict{GDAL.GDALDataType, DataType}(
    GDAL.GDT_Unknown    => Any,
    GDAL.GDT_Byte       => UInt8,
    GDAL.GDT_UInt16     => UInt16,
    GDAL.GDT_Int16      => Int16,
    GDAL.GDT_UInt32     => UInt32,
    GDAL.GDT_Int32      => Int32,
    GDAL.GDT_Float32    => Float32,
    GDAL.GDT_Float64    => Float64
)

"return the corresponding `GDALDataType`"
const _GDALTYPE = Dict{DataType,GDAL.GDALDataType}(
    Any         => GDAL.GDT_Unknown,
    UInt8       => GDAL.GDT_Byte,
    UInt16      => GDAL.GDT_UInt16,
    Int16       => GDAL.GDT_Int16,
    UInt32      => GDAL.GDT_UInt32,
    Int32       => GDAL.GDT_Int32,
    Float32     => GDAL.GDT_Float32,
    Float64     => GDAL.GDT_Float64
)

"return the corresponding `DataType` in julia"
const _FIELDTYPE = Dict{GDAL.OGRFieldType, DataType}(
    GDAL.OFTInteger         => Int32,
    GDAL.OFTIntegerList     => Void,
    GDAL.OFTReal            => Float64,
    GDAL.OFTRealList        => Void,
    GDAL.OFTString          => Cstring,
    GDAL.OFTStringList      => Void,
    GDAL.OFTWideString      => Void, # deprecated
    GDAL.OFTWideStringList  => Void, # deprecated
    GDAL.OFTBinary          => Void,
    GDAL.OFTDate            => Date,
    GDAL.OFTTime            => Void,
    GDAL.OFTDateTime        => DateTime,
    GDAL.OFTInteger64       => Int64,
    GDAL.OFTInteger64List   => Void,
    GDAL.OFTMaxType         => Void
)

"return the corresponding `GDALDataType`"
const _WKBGEOMTYPE = Dict{GDAL.OGRwkbGeometryType, Symbol}(
    GDAL.wkbUnknown                 => :Unknown,
    GDAL.wkbPoint                   => :Point,
    GDAL.wkbLineString              => :LineString,
    GDAL.wkbPolygon                 => :Polygon,
    GDAL.wkbMultiPoint              => :MultiPoint,
    GDAL.wkbMultiLineString         => :MultiLineString,
    GDAL.wkbMultiPolygon            => :MultiPolygon,
    GDAL.wkbGeometryCollection      => :GeometryCollection,
    GDAL.wkbCircularString          => :CircularString,
    GDAL.wkbCompoundCurve           => :CompoundCurve,
    GDAL.wkbCurvePolygon            => :CurvePolygon,
    GDAL.wkbMultiCurve              => :MultiCurve,
    GDAL.wkbMultiSurface            => :MultiSurface,
    GDAL.wkbNone                    => :None,
    GDAL.wkbLinearRing              => :LinearRing,
    GDAL.wkbCircularStringZ         => :CircularStringZ,
    GDAL.wkbCompoundCurveZ          => :CompoundCurveZ,
    GDAL.wkbCurvePolygonZ           => :CurvePolygonZ,
    GDAL.wkbMultiCurveZ             => :MultiCurveZ,
    GDAL.wkbMultiSurfaceZ           => :MultiSurfaceZ,
    GDAL.wkbPoint25D                => :Point25D,
    GDAL.wkbLineString25D           => :LineString25D,
    GDAL.wkbPolygon25D              => :Polygon25D,
    GDAL.wkbMultiPoint25D           => :MultiPoint25D,
    GDAL.wkbMultiLineString25D      => :MultiLineString25D,
    GDAL.wkbMultiPolygon25D         => :MultiPolygon25D,
    GDAL.wkbGeometryCollection25D   => :GeometryCollection25D
)

const _OPENFLAG = Dict{UInt8, Symbol}(
    GDAL.GDAL_OF_READONLY => :ReadOnly,
    GDAL.GDAL_OF_UPDATE => :Update,
    GDAL.GDAL_OF_ALL => :All,
    GDAL.GDAL_OF_RASTER => :Raster,
    GDAL.GDAL_OF_VECTOR => :Vector,
    GDAL.GDAL_OF_GNM => :GNM
)

const _ACCESSFLAG = Dict{UInt32, Symbol}(0 => :ReadOnly, 1 => :Update)

"Get data type size in bits."
typesize(dt::GDAL.GDALDataType) = GDAL.getdatatypesize(dt)

"name (string) corresponding to GDAL data type"
typename(dt::GDAL.GDALDataType) = GDAL.getdatatypename(dt)

"Returns GDAL data type by symbolic name."
gettype(name::AbstractString) = GDAL.getdatatypebyname(name)

"Return the smallest data type that can fully express both input data types."
typeunion(dt1::GDAL.GDALDataType,dt2::GDAL.GDALDataType) =
    GDAL.datatypeunion(dt1, dt2)

"""
Adjust a value to the output data type.

### Parameters
* **dt**: target data type
* **value**: value to adjust

### Returns
adjusted value
"""
# * **pbClamped**: pointer to a integer(boolean) to indicate if clamping has been made, or NULL
# * **pbRounded**: pointer to a integer(boolean) to indicate if rounding has been made, or NULL
adjustvaluetotype(dt::Integer, value::Cdouble) =
    GDAL.adjustvaluetodatatype(dt, value, C_NULL, C_NULL)

"""
`TRUE` if `dtype` is one of `GDT_{CInt16|CInt32|CFloat32|CFloat64}`
"""
iscomplex(dtype::GDAL.GDALDataType) = GDAL.datatypeiscomplex(dtype)

"Get name of AsyncStatus data type."
asyncstatusname(dtype::GDAL.GDALAsyncStatusType) =
    GDAL.getasyncstatustypename(dtype)

"Get AsyncStatusType by symbolic name."
asyncstatustype(name::AbstractString) = GDAL.getasyncstatustypebyname(name)

"Return name (string) corresponding to color interpretation"
colorname(obj::GDAL.GDALColorInterp) = GDAL.getcolorinterpretationname(obj)

"Get color interpretation corresponding to the given symbolic name."
colorinterp(name::AbstractString) = GDAL.getcolorinterpretationbyname(name)

"Get name of palette interpretation."
palettename(obj::GDAL.GDALPaletteInterp)=GDAL.getpaletteinterpretationname(obj)

"Fetch human readable name for a field type."
fieldtypename(obj::GDAL.OGRFieldType) = GDAL.getfieldtypename(obj)

"Fetch human readable name for a field subtype."
fieldsubtypename(obj::GDAL.OGRFieldSubType) = GDAL.getfieldsubtypename(obj)

"Return if type and subtype are compatible."
arecompatible(dtype::GDAL.OGRFieldType, subtype::GDAL.OGRFieldSubType) =
    GDAL.aretypesubtypecompatible(dtype, subtype)
