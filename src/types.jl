const GDALColorTable      = Ptr{GDAL.GDALColorTableH}
const GDALCoordTransform  = Ptr{GDAL.OGRCoordinateTransformationH}
const GDALDataset         = Ptr{GDAL.GDALDatasetH}
const GDALDriver          = Ptr{GDAL.GDALDriverH}
const GDALFeature         = Ptr{GDAL.OGRFeatureH}
const GDALFeatureDefn     = Ptr{GDAL.OGRFeatureDefnH}
const GDALFeatureLayer    = Ptr{GDAL.OGRLayerH}
const GDALField           = Ptr{GDAL.OGRField}
const GDALFieldDefn       = Ptr{GDAL.OGRFieldDefnH}
const GDALGeometry        = Ptr{GDAL.OGRGeometryH}
const GDALGeomFieldDefn   = Ptr{GDAL.OGRGeomFieldDefnH}
const GDALProgressFunc    = Ptr{GDAL.GDALProgressFunc}
const GDALRasterAttrTable = Ptr{GDAL.GDALRasterAttributeTableH}
const GDALRasterBand      = Ptr{GDAL.GDALRasterBandH}
const GDALSpatialRef      = Ptr{GDAL.OGRSpatialReferenceH}
const GDALStyleManager    = Ptr{GDAL.OGRStyleMgrH}
const GDALStyleTable      = Ptr{GDAL.OGRStyleTableH}
const GDALStyleTool       = Ptr{GDAL.OGRStyleToolH}

const StringList          = Ptr{Ptr{UInt8}}

abstract type AbstractGeometry <: GeoInterface.AbstractGeometry end
    # needs to have a `ptr::GDALGeometry` attribute

mutable struct ColorTable;                    ptr::GDALColorTable         end
mutable struct CoordTransform;                ptr::GDALCoordTransform     end
mutable struct Dataset;                       ptr::GDALDataset            end
mutable struct Driver;                        ptr::GDALDriver             end
mutable struct Feature;                       ptr::GDALFeature            end
mutable struct FeatureDefn;                   ptr::GDALFeatureDefn        end
mutable struct FeatureLayer;                  ptr::GDALFeatureLayer       end
mutable struct Field;                         ptr::GDALField              end
mutable struct FieldDefn;                     ptr::GDALFieldDefn          end
mutable struct Geometry <: AbstractGeometry;  ptr::GDALGeometry           end
mutable struct IGeometry <: AbstractGeometry
    ptr::GDALGeometry

    function IGeometry(ptr::GDALGeometry)
        geom = new(GDAL.clone(ptr))
        finalizer(geom, destroy)
        geom
    end
end
mutable struct GeomFieldDefn;                 ptr::GDALGeomFieldDefn      end
mutable struct RasterAttrTable;               ptr::GDALRasterAttrTable    end
mutable struct RasterBand;                    ptr::GDALRasterBand         end
mutable struct SpatialRef;                    ptr::GDALSpatialRef         end
mutable struct StyleManager;                  ptr::GDALStyleManager       end
mutable struct StyleTable;                    ptr::GDALStyleTable         end
mutable struct StyleTool;                     ptr::GDALStyleTool          end

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
OGRFieldType = GDAL.OGRFieldType
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
OGRDatumType = GDAL.OGRDatumType

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
    GDAL.OFTInteger         => Int32,
    GDAL.OFTIntegerList     => Void,
    GDAL.OFTReal            => Float64,
    GDAL.OFTRealList        => Void,
    GDAL.OFTString          => String,
    GDAL.OFTStringList      => Void,
    GDAL.OFTWideString      => Void, # deprecated
    GDAL.OFTWideStringList  => Void, # deprecated
    GDAL.OFTBinary          => Void,
    GDAL.OFTDate            => Date,
    GDAL.OFTTime            => Void,
    GDAL.OFTDateTime        => DateTime,
    GDAL.OFTInteger64       => Int64,
    GDAL.OFTInteger64List   => Void)

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
