import DiskArrays: AbstractDiskArray
import Base.convert

abstract type AbstractSpatialRef end
# needs to have a `ptr::GDAL.OGRSpatialReferenceH` attribute

abstract type AbstractDataset end
# needs to have a `ptr::GDAL.GDALDatasetH` attribute

#! AbstractOFType could also be a non parameterized abstract type with
#! OFType{OGRFieldType, OGRFieldSubType} instead of 
#! OFType{T,OGRFieldSubType} <: AbstractOFType{T}
abstract type AbstractFType{OGRFieldType} end #! NEW abstract type for fields to group field types by OGRFieldType
struct FType{T,OGRFieldSubType} <: AbstractFType{T} end #! NEW type for fields
function getFType(ptr::GDAL.OGRFieldDefnH)
    return FType{
        convert(OGRFieldType, GDAL.ogr_fld_gettype(ptr)),
        convert(OGRFieldSubType, GDAL.ogr_fld_getsubtype(ptr)),
    }
end
abstract type AbstractGType end #! NEW abstract type for geometries
struct GType{OGRwkbGeometryType} <: AbstractGType end #! NEW type for geometries
function getGType(ptr::GDAL.OGRGeomFieldDefnH)
    return GType{convert(OGRwkbGeometryType, GDAL.ogr_gfld_gettype(ptr))}
end

#! NEW simple FeatureDefn type, could later maybe(?) replaced by full FeatureDefn type in the definitions below
FDType = Tuple{NTuple{NG,GType} where NG,NTuple{NF,FType} where NF} #! Type alias for FD parameter
FDType = Tuple{
    NamedTuple{NG,<:Tuple{Vararg{GType}}} where NG,
    NamedTuple{NF,<:Tuple{Vararg{FType}}} where NF,
}
@generated function _ngt(::Type{T}) where {T<:FDType}
    return :(length($T.types[1].types))
end
@generated function _gtnames(::Type{T}) where {T<:FDType}
    return :(tuple($T.types[1].names...))
end
@generated function _gttypes(::Type{T}) where {T<:FDType}
    return :(tuple($T.types[1].types...))
end
@generated function _nft(::Type{T}) where {T<:FDType}
    return :(length($T.types[2].types))
end
@generated function _ftnames(::Type{T}) where {T<:FDType}
    return :(tuple($T.types[2].names...))
end
@generated function _fttypes(::Type{T}) where {T<:FDType}
    return :(tuple($T.types[2].types...))
end
function _getFDType(ptr::GDAL.OGRFeatureDefnH) #! There no type difference between GDAL.OGRFeatureDefnH and GDAL.OGRLayerH (both Ptr{Cvoid})) and we cannot dispatch on it
    ng = GDAL.ogr_fd_getgeomfieldcount(ptr)
    gflddefn_ptrs = (GDAL.ogr_fd_getgeomfielddefn(ptr, i - 1) for i in 1:ng)
    NG = tuple(Symbol.(GDAL.ogr_gfld_getnameref.(gflddefn_ptrs))...)
    TG = Tuple{(G for G in getGType.(gflddefn_ptrs))...}
    nf = GDAL.ogr_fd_getfieldcount(ptr)
    flddefn_ptrs = (GDAL.ogr_fd_getfielddefn(ptr, i - 1) for i in 1:nf)
    NF = tuple(Symbol.(GDAL.ogr_fld_getnameref.(flddefn_ptrs))...)
    TF = Tuple{(F for F in getFType.(flddefn_ptrs))...}
    return Tuple{NamedTuple{NG,TG},NamedTuple{NF,TF}}
end

abstract type DUAL_AbstractGeometry <: GeoInterface.AbstractGeometry end #! NEW abstract type supertype of AbstractGeometry and GP_AbstractGeometry
abstract type AbstractGeometry <: DUAL_AbstractGeometry end
abstract type GP_AbstractGeometry{G<:GType} <: DUAL_AbstractGeometry end #! NEW abstract type to group GP_Geometry instances
# needs to have a `ptr::GDAL.OGRGeometryH` attribute

abstract type DUAL_AbstractFeatureDefn end #! NEW abstract type supertype of AbstractFeatureDefn and FDP_AbstractFeatureDefn
abstract type AbstractFeatureDefn <: DUAL_AbstractFeatureDefn end
abstract type FDP_AbstractFeatureDefn{FD<:FDType} <: DUAL_AbstractFeatureDefn end #! NEW abstract type to group FDP_FeatureDefn type instances
# needs to have a `ptr::GDAL.OGRFeatureDefnH` attribute

abstract type DUAL_AbstractFeatureLayer end #! NEW abstract type supertype of AbstractFeatureLayer and FDP_AbstractFeatureLayer
abstract type AbstractFeatureLayer <: DUAL_AbstractFeatureLayer end
abstract type FDP_AbstractFeatureLayer{FD<:FDType} <: DUAL_AbstractFeatureLayer end #! NEW abstract type to group FDP_FeatureLayer type instances
# needs to have a `ptr::GDAL.OGRLayerH` attribute

abstract type DUAL_AbstractFeature end #! NEW abstract type supertype of AbstractFeature and FDP_AbstractFeature
abstract type AbstractFeature <: DUAL_AbstractFeature end #! NEW abstract type to group Feature and IFeature (if created)
abstract type FDP_AbstractFeature{FD<:FDType} <: DUAL_AbstractFeature end #! NEW abstract type to group FDP_Feature type instances
# needs to have a `ptr::GDAL.OGRFeatureH attribute

abstract type DUAL_AbstractFieldDefn end #! NEW abstract type, supertype of AbstractFieldDefn and FTP_AbstractFieldDefn
abstract type AbstractFieldDefn <: DUAL_AbstractFieldDefn end
abstract type FTP_AbstractFieldDefn{FT<:FType} <: DUAL_AbstractFieldDefn end #! NEW abstract type to group FTP_FieldDefn type instances
# needs to have a `ptr::GDAL.OGRFieldDefnH` attribute

abstract type DUAL_AbstractGeomFieldDefn end #! NEW abstract type, supertype of AbstractGeomFieldDefn and GFTP_AbstractGeomFieldDefn
abstract type AbstractGeomFieldDefn <: DUAL_AbstractGeomFieldDefn end
abstract type GFTP_AbstractGeomFieldDefn{GFT<:GType} <:
              DUAL_AbstractGeomFieldDefn end #! NEW abstract type to group OGTP_FieldDefn type instances
# needs to have a `ptr::GDAL.OGRGeomFieldDefnH` attribute

abstract type AbstractRasterBand{T} <: AbstractDiskArray{T,2} end
# needs to have a `ptr::GDAL.GDALRasterBandH` attribute

mutable struct CoordTransform
    ptr::GDAL.OGRCoordinateTransformationH
end

mutable struct Dataset <: AbstractDataset
    ptr::GDAL.GDALDatasetH

    Dataset(ptr::GDAL.GDALDatasetH = C_NULL) = new(ptr)
end

mutable struct IDataset <: AbstractDataset
    ptr::GDAL.GDALDatasetH

    function IDataset(ptr::GDAL.GDALDatasetH = C_NULL)
        dataset = new(ptr)
        finalizer(destroy, dataset)
        return dataset
    end
end

mutable struct Driver
    ptr::GDAL.GDALDriverH
end

mutable struct Field
    ptr::GDAL.OGRField
end

mutable struct FieldDefn <: AbstractFieldDefn
    ptr::GDAL.OGRFieldDefnH
end

mutable struct IFieldDefnView <: AbstractFieldDefn
    ptr::GDAL.OGRFieldDefnH

    function IFieldDefnView(ptr::GDAL.OGRFieldDefnH = C_NULL)
        fielddefn = new(ptr)
        finalizer(destroy, fielddefn)
        return fielddefn
    end
end

#! NEW FTP_FieldDefn
mutable struct FTP_FieldDefn{FT} <: FTP_AbstractFieldDefn{FT}
    ptr::GDAL.OGRFieldDefnH
    ownedby::Union{Nothing,FDP_AbstractFeatureDefn}

    function FTP_FieldDefn{FT}(
        ptr::GDAL.OGRFieldDefnH = C_NULL;
        ownedby::Union{Nothing,FDP_AbstractFeatureDefn} = nothing,
    ) where {FT<:FType}
        return new(ptr, ownedby)
    end
end

#! NEW FTP_IFieldDefnView
mutable struct FTP_IFieldDefnView{FT} <: FTP_AbstractFieldDefn{FT}
    ptr::GDAL.OGRFieldDefnH
    ownedby::Union{Nothing,FDP_AbstractFeatureDefn}

    function FTP_IFieldDefnView{FT}(
        ptr::GDAL.OGRFieldDefnH = C_NULL;
        ownedby::Union{Nothing,FDP_AbstractFeatureDefn} = nothing,
    ) where {FT<:FType}
        ftp_ifielddefnview = new(ptr, ownedby)
        finalizer(destroy, ftp_ifielddefnview)
        return ftp_ifielddefnview
    end
end

mutable struct GeomFieldDefn <: AbstractGeomFieldDefn
    ptr::GDAL.OGRGeomFieldDefnH
    spatialref::AbstractSpatialRef

    function GeomFieldDefn(
        ptr::GDAL.OGRGeomFieldDefnH = C_NULL;
        spatialref::AbstractSpatialRef = SpatialRef(),
    )
        return new(ptr, spatialref)
    end
end

mutable struct IGeomFieldDefnView <: AbstractGeomFieldDefn
    ptr::GDAL.OGRGeomFieldDefnH

    function IGeomFieldDefnView(ptr::GDAL.OGRGeomFieldDefnH = C_NULL)
        geomdefn = new(ptr)
        finalizer(destroy, geomdefn)
        return geomdefn
    end
end

#! NEW GFTP_GeomFieldDefn
mutable struct GFTP_GeomFieldDefn{GFT} <: GFTP_AbstractGeomFieldDefn{GFT}
    ptr::GDAL.OGRGeomFieldDefnH
    ownedby::Union{Nothing,FDP_AbstractFeatureDefn}
    spatialref::Union{Nothing,AbstractSpatialRef}

    function GFTP_GeomFieldDefn{GFT}(
        ptr::GDAL.OGRGeomFieldDefnH = C_NULL;
        ownedby::Union{Nothing,FDP_AbstractFeatureDefn} = nothing,
        spatialref::Union{Nothing,AbstractSpatialRef} = nothing,
    ) where {GFT<:GType}
        return new(ptr, ownedby, spatialref)
    end
end

#! NEW GFTP_IGeomFieldDefnView
mutable struct GFTP_IGeomFieldDefnView{GFT} <: GFTP_AbstractGeomFieldDefn{GFT}
    ptr::GDAL.OGRGeomFieldDefnH
    ownedby::Union{Nothing,FDP_AbstractFeatureDefn}
    spatialref::Union{Nothing,AbstractSpatialRef}

    function GFTP_IGeomFieldDefnView{GFT}(
        ptr::GDAL.OGRGeomFieldDefnH = C_NULL;
        ownedby::Union{Nothing,FDP_AbstractFeatureDefn} = nothing,
        spatialref::Union{Nothing,AbstractSpatialRef} = nothing,
    ) where {GFT<:GType}
        gftp_igeomfielddefnview = new(ptr, ownedby, spatialref)
        finalizer(destroy, gftp_igeomfielddefnview)
        return gftp_igeomfielddefnview
    end
end

mutable struct RasterAttrTable
    ptr::GDAL.GDALRasterAttributeTableH
end

mutable struct StyleManager
    ptr::GDAL.OGRStyleMgrH

    StyleManager(ptr::GDAL.OGRStyleMgrH = C_NULL) = new(ptr)
end

mutable struct StyleTable
    ptr::GDAL.OGRStyleTableH

    StyleTable(ptr::GDAL.OGRStyleTableH = C_NULL) = new(ptr)
end

mutable struct StyleTool
    ptr::GDAL.OGRStyleToolH
end

mutable struct FeatureLayer <: AbstractFeatureLayer
    ptr::GDAL.OGRLayerH
    ownedby::AbstractDataset
    spatialref::AbstractSpatialRef
end

function FeatureLayer(
    ptr::GDAL.OGRLayerH = C_NULL;
    ownedby::AbstractDataset = Dataset(),
    spatialref::AbstractSpatialRef = SpatialRef(),
)
    return FeatureLayer(ptr, ownedby, spatialref)
end

mutable struct IFeatureLayer <: AbstractFeatureLayer
    ptr::GDAL.OGRLayerH
    ownedby::AbstractDataset
    spatialref::AbstractSpatialRef

    function IFeatureLayer(
        ptr::GDAL.OGRLayerH = C_NULL;
        ownedby::AbstractDataset = Dataset(),
        spatialref::AbstractSpatialRef = SpatialRef(),
    )
        layer = new(ptr, ownedby, spatialref)
        finalizer(destroy, layer)
        return layer
    end
end

mutable struct Feature <: AbstractFeature
    ptr::GDAL.OGRFeatureH
end

mutable struct FeatureDefn <: AbstractFeatureDefn
    ptr::GDAL.OGRFeatureDefnH
end

mutable struct IFeatureDefnView <: AbstractFeatureDefn
    ptr::GDAL.OGRFeatureDefnH

    function IFeatureDefnView(ptr::GDAL.OGRFeatureDefnH = C_NULL)
        featuredefn = new(ptr)
        finalizer(destroy, featuredefn)
        return featuredefn
    end
end

#! NEW FeatureDefn parameterized FeatureDefn
mutable struct FDP_FeatureDefn{FD} <: FDP_AbstractFeatureDefn{FD}
    ptr::GDAL.OGRFeatureDefnH
    ownedby::Union{Nothing,FDP_AbstractFeatureLayer{FD}}

    function FDP_FeatureDefn{FD}(
        ptr::GDAL.OGRFeatureDefnH = C_NULL;
        ownedby::Union{Nothing,FDP_AbstractFeatureLayer{FD}} = nothing,
    ) where {FD<:FDType}
        return new(ptr, ownedby)
    end
end

#! NEW FeatureDefn parameterized IFeatureDefnView
mutable struct FDP_IFeatureDefnView{FD} <: FDP_AbstractFeatureDefn{FD}
    ptr::GDAL.OGRFeatureDefnH
    ownedby::Union{Nothing,FDP_AbstractFeatureLayer{FD}}

    function FDP_IFeatureDefnView{FD}(
        ptr::GDAL.OGRFeatureDefnH = C_NULL;
        ownedby::Union{Nothing,FDP_AbstractFeatureLayer{FD}} = nothing,
    ) where {FD<:FDType}
        fdp_ifeaturedefnview = new(ptr, ownedby)
        finalizer(destroy, fdp_ifeaturedefnview)
        return fdp_ifeaturedefnview
    end
end

#! NEW FeatureDefn parameterized Feature
mutable struct FDP_Feature{FD} <: FDP_AbstractFeature{FD}
    ptr::GDAL.OGRFeatureH
    ownedby::Union{Nothing,FDP_AbstractFeatureLayer}

    function FDP_Feature{FD}(
        ptr::GDAL.OGRFeatureH = C_NULL;
        ownedby::Union{Nothing,FDP_AbstractFeatureLayer} = nothing,
    ) where {FD<:FDType}
        return new(ptr, ownedby)
    end
end
#TODO: Add a ifeatureview on the model of ifeaturedefnview?

#! NEW FeatureDefn parameterized FeatureLayer
mutable struct FDP_FeatureLayer{FD} <: FDP_AbstractFeatureLayer{FD}
    ptr::GDAL.OGRLayerH
    ownedby::AbstractDataset
    spatialref::Union{Nothing,AbstractSpatialRef}

    function FDP_FeatureLayer{FD}(
        ptr::GDAL.OGRLayerH = C_NULL;
        ownedby::AbstractDataset = Dataset(),
        spatialref::Union{Nothing,AbstractSpatialRef} = nothing,
    ) where {FD<:FDType}
        return new(ptr, ownedby, spatialref)
    end
end

#! NEW FeatureDefn parameterized IFeatureLayer
mutable struct FDP_IFeatureLayer{FD} <: FDP_AbstractFeatureLayer{FD}
    ptr::GDAL.OGRLayerH
    ownedby::AbstractDataset
    spatialref::Union{Nothing,AbstractSpatialRef}

    function FDP_IFeatureLayer{FD}(
        ptr::GDAL.OGRLayerH = C_NULL;
        ownedby::AbstractDataset = Dataset(),
        spatialref::Union{Nothing,AbstractSpatialRef} = nothing,
    ) where {FD<:FDType}
        layer = new(ptr, ownedby, spatialref)
        finalizer(destroy, layer)
        return layer
    end
end

"Fetch the pixel data type for this band."
pixeltype(ptr::GDAL.GDALRasterBandH)::DataType =
    convert(GDALDataType, GDAL.gdalgetrasterdatatype(ptr))

mutable struct RasterBand{T} <: AbstractRasterBand{T}
    ptr::GDAL.GDALRasterBandH
end

RasterBand(ptr::GDAL.GDALRasterBandH)::RasterBand{pixeltype(ptr)} =
    RasterBand{pixeltype(ptr)}(ptr)

mutable struct IRasterBand{T} <: AbstractRasterBand{T}
    ptr::GDAL.GDALRasterBandH
    ownedby::AbstractDataset

    function IRasterBand{T}(
        ptr::GDAL.GDALRasterBandH = C_NULL;
        ownedby::AbstractDataset = Dataset(),
    )::IRasterBand{T} where {T}
        rasterband = new(ptr, ownedby)
        finalizer(destroy, rasterband)
        return rasterband
    end
end

function IRasterBand(
    ptr::GDAL.GDALRasterBandH;
    ownedby = Dataset(),
)::IRasterBand{pixeltype(ptr)}
    return IRasterBand{pixeltype(ptr)}(ptr, ownedby = ownedby)
end

mutable struct SpatialRef <: AbstractSpatialRef
    ptr::GDAL.OGRSpatialReferenceH

    SpatialRef(ptr::GDAL.OGRSpatialReferenceH = C_NULL) = new(ptr)
end

mutable struct ISpatialRef <: AbstractSpatialRef
    ptr::GDAL.OGRSpatialReferenceH

    function ISpatialRef(ptr::GDAL.OGRSpatialReferenceH = C_NULL)
        spref = new(ptr)
        finalizer(destroy, spref)
        return spref
    end
end

function _infergeomtype(ptr::GDAL.OGRGeometryH = C_NULL)::OGRwkbGeometryType
    return if ptr != C_NULL
        convert(OGRwkbGeometryType, GDAL.ogr_g_getgeometrytype(ptr))
    else
        wkbUnknown
    end
end

mutable struct Geometry{OGRwkbGeometryType} <: AbstractGeometry
    ptr::GDAL.OGRGeometryH

    Geometry(ptr::GDAL.OGRGeometryH = C_NULL) = new{_infergeomtype(ptr)}(ptr)
end
_geomtype(::Geometry{T}) where {T} = T

function _inferGType(ptr::GDAL.OGRGeometryH = C_NULL)::Type{<:GType}
    return if ptr != C_NULL
        GType{OGRwkbGeometryType(Int32(GDAL.ogr_g_getgeometrytype(ptr)))}
    else
        GType{wkbUnknown}
    end
end

#! NEW Geometry
mutable struct GP_Geometry{G} <: GP_AbstractGeometry{G}
    ptr::GDAL.OGRGeometryH
    ownedby::Union{Nothing,DUAL_AbstractFeature}

    function GP_Geometry{G}(
        ptr::GDAL.OGRGeometryH = C_NULL,
        ownedby::Union{Nothing,DUAL_AbstractFeature} = nothing,
    ) where {G<:GType}
        return new{_inferGType(ptr)}(ptr, ownedby)
    end
end

mutable struct IGeometry{OGRwkbGeometryType} <: AbstractGeometry
    ptr::GDAL.OGRGeometryH

    function IGeometry(ptr::GDAL.OGRGeometryH = C_NULL)
        geom = new{_infergeomtype(ptr)}(ptr)
        finalizer(destroy, geom)
        return geom
    end
end
_geomtype(::IGeometry{T}) where {T} = T

#! NEW IGeometry
mutable struct GP_IGeometry{G} <: GP_AbstractGeometry{G}
    ptr::GDAL.OGRGeometryH
    ownedby::Union{Nothing,DUAL_AbstractFeature}

    function GP_IGeometry{G}(
        ptr::GDAL.OGRGeometryH = C_NULL,
        ownedby::Union{Nothing,DUAL_AbstractFeature} = nothing,
    ) where {G<:GType}
        gp_igeometry = new{_inferGType(ptr)}(ptr, ownedby)
        finalizer(destroy, gp_igeometry)
        return gp_igeometry
    end
end

mutable struct ColorTable
    ptr::GDAL.GDALColorTableH
end

@convert(
    GDALDataType::GDAL.GDALDataType,
    GDT_Unknown::GDAL.GDT_Unknown,
    GDT_Byte::GDAL.GDT_Byte,
    GDT_UInt16::GDAL.GDT_UInt16,
    GDT_Int16::GDAL.GDT_Int16,
    GDT_UInt32::GDAL.GDT_UInt32,
    GDT_Int32::GDAL.GDT_Int32,
    GDT_Float32::GDAL.GDT_Float32,
    GDT_Float64::GDAL.GDT_Float64,
    GDT_CInt16::GDAL.GDT_CInt16,
    GDT_CInt32::GDAL.GDT_CInt32,
    GDT_CFloat32::GDAL.GDT_CFloat32,
    GDT_CFloat64::GDAL.GDT_CFloat64,
    GDT_TypeCount::GDAL.GDT_TypeCount,
)

@convert(
    GDALDataType::Normed,
    GDT_Byte::N0f8,
    GDT_UInt16::N0f16,
    GDT_UInt32::N0f32,
)

@convert(
    GDALDataType::DataType,
    GDT_Unknown::Any,
    GDT_Byte::UInt8,
    GDT_UInt16::UInt16,
    GDT_Int16::Int16,
    GDT_UInt32::UInt32,
    GDT_Int32::Int32,
    GDT_Float32::Float32,
    GDT_Float64::Float64,
    GDT_CFloat32::ComplexF32,
    GDT_CFloat64::ComplexF64
)

@convert(
    OGRFieldType::GDAL.OGRFieldType,
    OFTInteger::GDAL.OFTInteger,
    OFTIntegerList::GDAL.OFTIntegerList,
    OFTReal::GDAL.OFTReal,
    OFTRealList::GDAL.OFTRealList,
    OFTString::GDAL.OFTString,
    OFTStringList::GDAL.OFTStringList,
    OFTWideString::GDAL.OFTWideString, # deprecated
    OFTWideStringList::GDAL.OFTWideStringList, # deprecated
    OFTBinary::GDAL.OFTBinary,
    OFTDate::GDAL.OFTDate,
    OFTTime::GDAL.OFTTime,
    OFTDateTime::GDAL.OFTDateTime,
    OFTInteger64::GDAL.OFTInteger64,
    OFTInteger64List::GDAL.OFTInteger64List,
)

# Default DataType = LAST, for duplicated (oftid, ofstid) values
const DataType_2_OGRFieldType_OGRFieldSubType_mapping = Base.ImmutableDict(
    Bool => (OFTInteger, OFSTBoolean),
    Int8 => (OFTInteger, OFSTNone),
    Int16 => (OFTInteger, OFSTInt16),
    Int32 => (OFTInteger, OFSTNone),       # Default OFTInteger
    Vector{Bool} => (OFTIntegerList, OFSTBoolean),
    Vector{Int16} => (OFTIntegerList, OFSTInt16),
    Vector{Int32} => (OFTIntegerList, OFSTNone),   # Default OFTIntegerList
    Float16 => (OFTReal, OFSTNone),
    Float32 => (OFTReal, OFSTFloat32),
    Float64 => (OFTReal, OFSTNone),          # Default OFTReal
    Vector{Float16} => (OFTRealList, OFSTNone),
    Vector{Float32} => (OFTRealList, OFSTFloat32),
    Vector{Float64} => (OFTRealList, OFSTNone),      # Default OFTRealList
    String => (OFTString, OFSTNone),
    Vector{String} => (OFTStringList, OFSTNone),
    Vector{UInt8} => (OFTBinary, OFSTNone),
    Dates.Date => (OFTDate, OFSTNone),
    Dates.Time => (OFTTime, OFSTNone),
    Dates.DateTime => (OFTDateTime, OFSTNone),
    Int64 => (OFTInteger64, OFSTNone),
    Vector{Int64} => (OFTInteger64List, OFSTNone),
)

# Conversions from DataType to OFType
const DataType2FType = Base.ImmutableDict(
    (
        k => FType{v...} for
        (k, v) in DataType_2_OGRFieldType_OGRFieldSubType_mapping
    )...,
)
GDALDataTypes = Union{keys(DataType2FType)...}
@generated function convert(::Type{FType}, ::Type{T}) where {T<:GDALDataTypes}
    result = get(DataType2FType, T, missing)
    !ismissing(result) || throw(MethodError(convert, (FType, T)))
    return :($(result))
end
#! PROBABLY NOT NECESSARY: Conversions from OFType to DataType
# const FType2DataType = Base.ImmutableDict((v => k for (k, v) in DataType2FType)...)
# # GDALFTypes = Union{keys(FType2DataType)...}
# @generated function convert(::Type{DataType}, ::Type{T}) where T<:FType
#     result = get(FType2DataType, T, missing)
#     result !=== missing || error(
#         "$T is not an FType corresponding to a valid GDAL (OGRFieldType, OGRFieldSubType) couple. \nPlease use one of the following: \n$(join((FType{v...} for (_, v) in DataType_2_OGRFieldType_OGRFieldSubType_mapping), "\n"))",
#     )
#     return :($(result))
# end

@convert(
    OGRFieldType::DataType,
    OFTInteger::Bool,
    OFTInteger::Int16,
    OFTInteger::Int32,  # default type comes last
    OFTIntegerList::Vector{Int32},
    OFTReal::Float32,
    OFTReal::Float64,  # default type comes last
    OFTRealList::Vector{Float64},
    OFTString::String,
    OFTStringList::Vector{String},
    OFTBinary::Vector{UInt8},
    OFTDate::Dates.Date,
    OFTTime::Dates.Time,
    OFTDateTime::Dates.DateTime,
    OFTInteger64::Int64,
    OFTInteger64List::Vector{Int64},
)

@convert(
    OGRFieldSubType::GDAL.OGRFieldSubType,
    OFSTNone::GDAL.OFSTNone,
    OFSTBoolean::GDAL.OFSTBoolean,
    OFSTInt16::GDAL.OFSTInt16,
    OFSTFloat32::GDAL.OFSTFloat32,
    OFSTJSON::GDAL.OFSTJSON,
)

@convert(
    OGRFieldSubType::DataType,
    OFSTNone::Nothing,
    OFSTBoolean::Bool,
    OFSTInt16::Int16,
    OFSTFloat32::Float32,
    OFSTJSON::String,
)

@convert(
    OGRJustification::GDAL.OGRJustification,
    OJUndefined::GDAL.OJUndefined,
    OJLeft::GDAL.OJLeft,
    OJRight::GDAL.OJRight,
)

@convert(
    GDALRATFieldType::GDAL.GDALRATFieldType,
    GFT_Integer::GDAL.GFT_Integer,
    GFT_Real::GDAL.GFT_Real,
    GFT_String::GDAL.GFT_String,
)

@convert(
    GDALRATFieldUsage::GDAL.GDALRATFieldUsage,
    GFU_Generic::GDAL.GFU_Generic,
    GFU_PixelCount::GDAL.GFU_PixelCount,
    GFU_Name::GDAL.GFU_Name,
    GFU_Min::GDAL.GFU_Min,
    GFU_Max::GDAL.GFU_Max,
    GFU_MinMax::GDAL.GFU_MinMax,
    GFU_Red::GDAL.GFU_Red,
    GFU_Green::GDAL.GFU_Green,
    GFU_Blue::GDAL.GFU_Blue,
    GFU_Alpha::GDAL.GFU_Alpha,
    GFU_RedMin::GDAL.GFU_RedMin,
    GFU_GreenMin::GDAL.GFU_GreenMin,
    GFU_BlueMin::GDAL.GFU_BlueMin,
    GFU_AlphaMin::GDAL.GFU_AlphaMin,
    GFU_RedMax::GDAL.GFU_RedMax,
    GFU_GreenMax::GDAL.GFU_GreenMax,
    GFU_BlueMax::GDAL.GFU_BlueMax,
    GFU_AlphaMax::GDAL.GFU_AlphaMax,
    GFU_MaxCount::GDAL.GFU_MaxCount,
)

@convert(
    GDALAccess::GDAL.GDALAccess,
    GA_ReadOnly::GDAL.GA_ReadOnly,
    GA_Update::GDAL.GA_Update,
)

@convert(
    GDALRWFlag::GDAL.GDALRWFlag,
    GF_Read::GDAL.GF_Read,
    GF_Write::GDAL.GF_Write,
)

@convert(
    GDALPaletteInterp::GDAL.GDALPaletteInterp,
    GPI_Gray::GDAL.GPI_Gray,
    GPI_RGB::GDAL.GPI_RGB,
    GPI_CMYK::GDAL.GPI_CMYK,
    GPI_HLS::GDAL.GPI_HLS,
)

@convert(
    GDALColorInterp::GDAL.GDALColorInterp,
    GCI_Undefined::GDAL.GCI_Undefined,
    GCI_GrayIndex::GDAL.GCI_GrayIndex,
    GCI_PaletteIndex::GDAL.GCI_PaletteIndex,
    GCI_RedBand::GDAL.GCI_RedBand,
    GCI_GreenBand::GDAL.GCI_GreenBand,
    GCI_BlueBand::GDAL.GCI_BlueBand,
    GCI_AlphaBand::GDAL.GCI_AlphaBand,
    GCI_HueBand::GDAL.GCI_HueBand,
    GCI_SaturationBand::GDAL.GCI_SaturationBand,
    GCI_LightnessBand::GDAL.GCI_LightnessBand,
    GCI_CyanBand::GDAL.GCI_CyanBand,
    GCI_MagentaBand::GDAL.GCI_MagentaBand,
    GCI_YellowBand::GDAL.GCI_YellowBand,
    GCI_BlackBand::GDAL.GCI_BlackBand,
    GCI_YCbCr_YBand::GDAL.GCI_YCbCr_YBand,
    GCI_YCbCr_CbBand::GDAL.GCI_YCbCr_CbBand,
    GCI_YCbCr_CrBand::GDAL.GCI_YCbCr_CrBand,
)

@convert(
    GDALAsyncStatusType::GDAL.GDALAsyncStatusType,
    GARIO_PENDING::GDAL.GARIO_PENDING,
    GARIO_UPDATE::GDAL.GARIO_UPDATE,
    GARIO_ERROR::GDAL.GARIO_ERROR,
    GARIO_COMPLETE::GDAL.GARIO_COMPLETE,
    GARIO_TypeCount::GDAL.GARIO_TypeCount,
)

@convert(
    OGRSTClassId::GDAL.OGRSTClassId,
    OGRSTCNone::GDAL.OGRSTCNone,
    OGRSTCPen::GDAL.OGRSTCPen,
    OGRSTCBrush::GDAL.OGRSTCBrush,
    OGRSTCSymbol::GDAL.OGRSTCSymbol,
    OGRSTCLabel::GDAL.OGRSTCLabel,
    OGRSTCVector::GDAL.OGRSTCVector,
)

@convert(
    OGRSTUnitId::GDAL.OGRSTUnitId,
    OGRSTUGround::GDAL.OGRSTUGround,
    OGRSTUPixel::GDAL.OGRSTUPixel,
    OGRSTUPoints::GDAL.OGRSTUPoints,
    OGRSTUMM::GDAL.OGRSTUMM,
    OGRSTUCM::GDAL.OGRSTUCM,
    OGRSTUInches::GDAL.OGRSTUInches,
)

# @convert(
#     OGRwkbGeometryType::GDAL.OGRwkbGeometryType,
#     wkbUnknown::GDAL.wkbUnknown,
#     wkbPoint::GDAL.wkbPoint,
#     wkbLineString::GDAL.wkbLineString,
#     wkbPolygon::GDAL.wkbPolygon,
#     wkbMultiPoint::GDAL.wkbMultiPoint,
#     wkbMultiLineString::GDAL.wkbMultiLineString,
#     wkbMultiPolygon::GDAL.wkbMultiPolygon,
#     wkbGeometryCollection::GDAL.wkbGeometryCollection,
#     wkbCircularString::GDAL.wkbCircularString,
#     wkbCompoundCurve::GDAL.wkbCompoundCurve,
#     wkbCurvePolygon::GDAL.wkbCurvePolygon,
#     wkbMultiCurve::GDAL.wkbMultiCurve,
#     wkbMultiSurface::GDAL.wkbMultiSurface,
#     wkbCurve::GDAL.wkbCurve,
#     wkbSurface::GDAL.wkbSurface,
#     wkbPolyhedralSurface::GDAL.wkbPolyhedralSurface,
#     wkbTIN::GDAL.wkbTIN,
#     wkbTriangle::GDAL.wkbTriangle,
#     wkbNone::GDAL.wkbNone,
#     wkbLinearRing::GDAL.wkbLinearRing,
#     wkbCircularStringZ::GDAL.wkbCircularStringZ,
#     wkbCompoundCurveZ::GDAL.wkbCompoundCurveZ,
#     wkbCurvePolygonZ::GDAL.wkbCurvePolygonZ,
#     wkbMultiCurveZ::GDAL.wkbMultiCurveZ,
#     wkbMultiSurfaceZ::GDAL.wkbMultiSurfaceZ,
#     wkbCurveZ::GDAL.wkbCurveZ,
#     wkbSurfaceZ::GDAL.wkbSurfaceZ,
#     wkbPolyhedralSurfaceZ::GDAL.wkbPolyhedralSurfaceZ,
#     wkbTINZ::GDAL.wkbTINZ,
#     wkbTriangleZ::GDAL.wkbTriangleZ,
#     wkbPointM::GDAL.wkbPointM,
#     wkbLineStringM::GDAL.wkbLineStringM,
#     wkbPolygonM::GDAL.wkbPolygonM,
#     wkbMultiPointM::GDAL.wkbMultiPointM,
#     wkbMultiLineStringM::GDAL.wkbMultiLineStringM,
#     wkbMultiPolygonM::GDAL.wkbMultiPolygonM,
#     wkbGeometryCollectionM::GDAL.wkbGeometryCollectionM,
#     wkbCircularStringM::GDAL.wkbCircularStringM,
#     wkbCompoundCurveM::GDAL.wkbCompoundCurveM,
#     wkbCurvePolygonM::GDAL.wkbCurvePolygonM,
#     wkbMultiCurveM::GDAL.wkbMultiCurveM,
#     wkbMultiSurfaceM::GDAL.wkbMultiSurfaceM,
#     wkbCurveM::GDAL.wkbCurveM,
#     wkbSurfaceM::GDAL.wkbSurfaceM,
#     wkbPolyhedralSurfaceM::GDAL.wkbPolyhedralSurfaceM,
#     wkbTINM::GDAL.wkbTINM,
#     wkbTriangleM::GDAL.wkbTriangleM,
#     wkbPointZM::GDAL.wkbPointZM,
#     wkbLineStringZM::GDAL.wkbLineStringZM,
#     wkbPolygonZM::GDAL.wkbPolygonZM,
#     wkbMultiPointZM::GDAL.wkbMultiPointZM,
#     wkbMultiLineStringZM::GDAL.wkbMultiLineStringZM,
#     wkbMultiPolygonZM::GDAL.wkbMultiPolygonZM,
#     wkbGeometryCollectionZM::GDAL.wkbGeometryCollectionZM,
#     wkbCircularStringZM::GDAL.wkbCircularStringZM,
#     wkbCompoundCurveZM::GDAL.wkbCompoundCurveZM,
#     wkbCurvePolygonZM::GDAL.wkbCurvePolygonZM,
#     wkbMultiCurveZM::GDAL.wkbMultiCurveZM,
#     wkbMultiSurfaceZM::GDAL.wkbMultiSurfaceZM,
#     wkbCurveZM::GDAL.wkbCurveZM,
#     wkbSurfaceZM::GDAL.wkbSurfaceZM,
#     wkbPolyhedralSurfaceZM::GDAL.wkbPolyhedralSurfaceZM,
#     wkbTINZM::GDAL.wkbTINZM,
#     wkbTriangleZM::GDAL.wkbTriangleZM,
#     wkbPoint25D::GDAL.wkbPoint25D,
#     wkbLineString25D::GDAL.wkbLineString25D,
#     wkbPolygon25D::GDAL.wkbPolygon25D,
#     wkbMultiPoint25D::GDAL.wkbMultiPoint25D,
#     wkbMultiLineString25D::GDAL.wkbMultiLineString25D,
#     wkbMultiPolygon25D::GDAL.wkbMultiPolygon25D,
#     wkbGeometryCollection25D::GDAL.wkbGeometryCollection25D,
# )

# Conversions below assume that both 
# - OGRwkbGeometryType Enum instances and 
# - GDAL.OGRwkbGeometryType CEnum.Cenum instances 
# have same Integer assigned values
function convert(::Type{OGRwkbGeometryType}, gogtinst::GDAL.OGRwkbGeometryType)
    return OGRwkbGeometryType(Integer(gogtinst))
end
function convert(::Type{GDAL.OGRwkbGeometryType}, ogtinst::OGRwkbGeometryType)
    return GDAL.OGRwkbGeometryType(Integer(ogtinst))
end

function basetype(gt::OGRwkbGeometryType)::OGRwkbGeometryType
    wkbGeomType = convert(GDAL.OGRwkbGeometryType, gt)
    wkbGeomType &= (~0x80000000) # Remove 2.5D flag.
    wkbGeomType %= 1000 # Normalize Z, M, and ZM types.
    return GDAL.OGRwkbGeometryType(wkbGeomType)
end

@convert(
    OGRwkbByteOrder::GDAL.OGRwkbByteOrder,
    wkbXDR::GDAL.wkbXDR,
    wkbNDR::GDAL.wkbNDR,
)

import Base.|

for T in (GDALOpenFlag, FieldValidation)
    eval(quote
        |(x::$T, y::UInt8)::UInt8 = UInt8(x) | y
        |(x::UInt8, y::$T)::UInt8 = x | UInt8(y)
        |(x::$T, y::$T)::UInt8 = UInt8(x) | UInt8(y)
    end)
end

"""
    typesize(dt::GDALDataType)

Get the number of bits or zero if it is not recognised.
"""
typesize(dt::GDALDataType)::Integer = GDAL.gdalgetdatatypesize(dt)

"""
    typename(dt::GDALDataType)

name (string) corresponding to GDAL data type.
"""
typename(dt::GDALDataType)::String = GDAL.gdalgetdatatypename(dt)

"""
    gettype(name::AbstractString)

Returns GDAL data type by symbolic name.
"""
gettype(name::AbstractString)::GDALDataType = GDAL.gdalgetdatatypebyname(name)

"""
    typeunion(dt1::GDALDataType, dt2::GDALDataType)

Return the smallest data type that can fully express both input data types.
"""
typeunion(dt1::GDALDataType, dt2::GDALDataType)::GDALDataType =
    GDAL.gdaldatatypeunion(dt1, dt2)

"""
    iscomplex(dtype::GDALDataType)

`true` if `dtype` is one of `GDT_{CInt16|CInt32|CFloat32|CFloat64}.`
"""
iscomplex(dtype::GDALDataType)::Bool = Bool(GDAL.gdaldatatypeiscomplex(dtype))

"""
    getname(dtype::GDALAsyncStatusType)

Get name of AsyncStatus data type.
"""
getname(dtype::GDALAsyncStatusType)::String =
    GDAL.gdalgetasyncstatustypename(dtype)

"""
    asyncstatustype(name::AbstractString)

Get AsyncStatusType by symbolic name.
"""
asyncstatustype(name::AbstractString)::GDALAsyncStatusType =
    GDAL.gdalgetasyncstatustypebyname(name)

"""
    getname(obj::GDALColorInterp)

Return name (string) corresponding to color interpretation.
"""
getname(obj::GDALColorInterp)::String = GDAL.gdalgetcolorinterpretationname(obj)

"""
    colorinterp(name::AbstractString)

Get color interpretation corresponding to the given symbolic name.
"""
colorinterp(name::AbstractString)::GDALColorInterp =
    GDAL.gdalgetcolorinterpretationbyname(name)

"""
    getname(obj::GDALPaletteInterp)

Get name of palette interpretation.
"""
getname(obj::GDALPaletteInterp)::String =
    GDAL.gdalgetpaletteinterpretationname(obj)

"""
    getname(obj::OGRFieldType)

Fetch human readable name for a field type.
"""
getname(obj::OGRFieldType)::String = GDAL.ogr_getfieldtypename(obj)

"""
    getname(obj::OGRFieldSubType)

Fetch human readable name for a field subtype.

### References
* https://gdal.org/development/rfc/rfc50_ogr_field_subtype.html
"""
getname(obj::OGRFieldSubType)::String = GDAL.ogr_getfieldsubtypename(obj)

"""
    arecompatible(dtype::OGRFieldType, subtype::OGRFieldSubType)

Return if type and subtype are compatible.

### References
* https://gdal.org/development/rfc/rfc50_ogr_field_subtype.html
"""
arecompatible(dtype::OGRFieldType, subtype::OGRFieldSubType)::Bool =
    Bool(GDAL.ogr_aretypesubtypecompatible(dtype, subtype))
