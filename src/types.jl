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

const StringList          = Ptr{Cstring}

abstract type AbstractGeometry <: GeoInterface.AbstractGeometry end
    # needs to have a `ptr::GDALGeometry` attribute

abstract type AbstractSpatialRef end
    # needs to have a `ptr::GDALSpatialRef` attribute

abstract type AbstractDataset end
    # needs to have a `ptr::GDALDataset` attribute

mutable struct CoordTransform
    ptr::GDALCoordTransform
end

mutable struct Dataset <: AbstractDataset
    ptr::GDALDataset

    Dataset(ptr::GDALDataset = GDALDataset(C_NULL)) = new(ptr)
end

mutable struct IDataset <: AbstractDataset
    ptr::GDALDataset

    function IDataset(ptr::GDALDataset = GDALDataset(C_NULL))
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

mutable struct FieldDefn
    ptr::GDALFieldDefn
end

mutable struct GeomFieldDefn
    ptr::GDALGeomFieldDefn
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

mutable struct FeatureLayer
    ptr::GDALFeatureLayer
    ownedby::AbstractDataset

    function FeatureLayer(
            ptr::GDALFeatureLayer = GDALFeatureLayer(C_NULL);
            ownedby::AbstractDataset = Dataset()
        )
        new(ptr, ownedby)
    end
end

mutable struct Feature
    ptr::GDALFeature
end

mutable struct FeatureDefn
    ptr::GDALFeatureDefn
end

mutable struct RasterBand
    ptr::GDALRasterBand
    ownedby::AbstractDataset

    function RasterBand(
            ptr::GDALRasterBand = GDALRasterBand(C_NULL);
            ownedby::AbstractDataset = Dataset()
        )
        new(ptr, ownedby)
    end
end

mutable struct SpatialRef <: AbstractSpatialRef
    ptr::GDALSpatialRef

    SpatialRef(ptr::GDALSpatialRef = GDALSpatialRef(C_NULL)) = new(ptr)
end

mutable struct ISpatialRef <: AbstractSpatialRef
    ptr::GDALSpatialRef

    function ISpatialRef(ptr::GDALSpatialRef = GDALSpatialRef(C_NULL))
        spref = new(ptr)
        finalizer(destroy, spref)
        spref
    end
end

mutable struct Geometry <: AbstractGeometry
    ptr::GDALGeometry

    Geometry(ptr::GDALGeometry = GDALGeometry(C_NULL)) = new(ptr)
end

mutable struct IGeometry <: AbstractGeometry
    ptr::GDALGeometry

    function IGeometry(ptr::GDALGeometry = GDALGeometry(C_NULL))
        geom = new(ptr)
        finalizer(destroy, geom)
        geom
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
    GDAL.OFTIntegerList     => Nothing,
    GDAL.OFTReal            => Float64,
    GDAL.OFTRealList        => Nothing,
    GDAL.OFTString          => String,
    GDAL.OFTStringList      => Nothing,
    GDAL.OFTWideString      => Nothing, # deprecated
    GDAL.OFTWideStringList  => Nothing, # deprecated
    GDAL.OFTBinary          => Nothing,
    GDAL.OFTDate            => Date,
    GDAL.OFTTime            => Nothing,
    GDAL.OFTDateTime        => DateTime,
    GDAL.OFTInteger64       => Int64,
    GDAL.OFTInteger64List   => Nothing)

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

"Get data type size in bits."
typesize(dt::GDALDataType) = GDAL.getdatatypesize(dt)

"name (string) corresponding to GDAL data type"
typename(dt::GDALDataType) = GDAL.getdatatypename(dt)

"Returns GDAL data type by symbolic name."
gettype(name::AbstractString) = GDAL.getdatatypebyname(name)

"Return the smallest data type that can fully express both input data types."
typeunion(dt1::GDALDataType, dt2::GDALDataType) = GDAL.datatypeunion(dt1, dt2)

"""
`true` if `dtype` is one of `GDT_{CInt16|CInt32|CFloat32|CFloat64}`
"""
iscomplex(dtype::GDALDataType) = Bool(GDAL.datatypeiscomplex(dtype))

"Get name of AsyncStatus data type."
getname(dtype::GDALAsyncStatusType) = GDAL.getasyncstatustypename(dtype)

"Get AsyncStatusType by symbolic name."
asyncstatustype(name::AbstractString) = GDAL.getasyncstatustypebyname(name)

"Return name (string) corresponding to color interpretation"
getname(obj::GDALColorInterp) = GDAL.getcolorinterpretationname(obj)

"Get color interpretation corresponding to the given symbolic name."
colorinterp(name::AbstractString) = GDAL.getcolorinterpretationbyname(name)

"Get name of palette interpretation."
getname(obj::GDALPaletteInterp) = GDAL.getpaletteinterpretationname(obj)

"Fetch human readable name for a field type."
getname(obj::OGRFieldType) = GDAL.getfieldtypename(obj)

"Fetch human readable name for a field subtype."
getname(obj::OGRFieldSubType) = GDAL.getfieldsubtypename(obj)

"Return if type and subtype are compatible."
arecompatible(dtype::OGRFieldType, subtype::OGRFieldSubType) =
    Bool(GDAL.aretypesubtypecompatible(dtype, subtype))
