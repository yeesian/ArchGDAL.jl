import DiskArrays: AbstractDiskArray
import Base.convert

abstract type AbstractGeometry <: GeoInterface.AbstractGeometry end
    # needs to have a `ptr::GDAL.OGRGeometryH` attribute

abstract type AbstractSpatialRef end
    # needs to have a `ptr::GDAL.OGRSpatialReferenceH` attribute

abstract type AbstractDataset end
    # needs to have a `ptr::GDAL.GDALDatasetH` attribute

abstract type AbstractFeatureDefn end
    # needs to have a `ptr::GDAL.OGRFeatureDefnH` attribute

abstract type AbstractFeatureLayer end
    # needs to have a `ptr::GDAL.OGRLayerH` attribute

abstract type AbstractFieldDefn end
    # needs to have a `ptr::GDAL.OGRFieldDefnH` attribute

abstract type AbstractGeomFieldDefn end
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

mutable struct GeomFieldDefn <: AbstractGeomFieldDefn
    ptr::GDAL.OGRGeomFieldDefnH
    spatialref::AbstractSpatialRef

    function GeomFieldDefn(
            ptr::GDAL.OGRGeomFieldDefnH = C_NULL;
            spatialref::AbstractSpatialRef = SpatialRef()
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

mutable struct RasterAttrTable
    ptr::GDAL.GDALRasterAttributeTableH
end

mutable struct StyleManager
    ptr::GDAL.OGRStyleMgrH
end

mutable struct StyleTable
    ptr::GDAL.OGRStyleTableH
end

mutable struct StyleTool
    ptr::GDAL.OGRStyleToolH
end

mutable struct FeatureLayer <: AbstractFeatureLayer
    ptr::GDAL.OGRLayerH
end

mutable struct IFeatureLayer <: AbstractFeatureLayer
    ptr::GDAL.OGRLayerH
    ownedby::AbstractDataset
    spatialref::AbstractSpatialRef

    function IFeatureLayer(
            ptr::GDAL.OGRLayerH = C_NULL;
            ownedby::AbstractDataset = Dataset(),
            spatialref::AbstractSpatialRef = SpatialRef()
        )
        layer = new(ptr, ownedby, spatialref)
        finalizer(destroy, layer)
        return layer
    end
end

mutable struct Feature
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

mutable struct RasterBand{T} <: AbstractRasterBand{T}
    ptr::GDAL.GDALRasterBandH
end

function RasterBand(
        ptr::GDAL.GDALRasterBandH
    )::RasterBand{datatype(GDAL.gdalgetrasterdatatype(ptr))}
    return RasterBand{datatype(GDAL.gdalgetrasterdatatype(ptr))}(ptr)
end

mutable struct IRasterBand{T} <: AbstractRasterBand{T}
    ptr::GDAL.GDALRasterBandH
    ownedby::AbstractDataset

    function IRasterBand{T}(
            ptr::GDAL.GDALRasterBandH = C_NULL;
            ownedby::AbstractDataset = Dataset()
        ) where T
        rasterband = new(ptr, ownedby)
        finalizer(destroy, rasterband)
        return rasterband
    end
end

function IRasterBand(
        ptr::GDAL.GDALRasterBandH;
        ownedby = Dataset()
    )::IRasterBand{datatype(GDAL.gdalgetrasterdatatype(ptr))}
    T = datatype(GDAL.gdalgetrasterdatatype(ptr))
    return IRasterBand{T}(ptr, ownedby = ownedby)
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

mutable struct Geometry <: AbstractGeometry
    ptr::GDAL.OGRGeometryH

    Geometry(ptr::GDAL.OGRGeometryH = C_NULL) = new(ptr)
end

mutable struct IGeometry <: AbstractGeometry
    ptr::GDAL.OGRGeometryH

    function IGeometry(ptr::GDAL.OGRGeometryH = C_NULL)
        geom = new(ptr)
        finalizer(destroy, geom)
        return geom
    end
end

mutable struct ColorTable
    ptr::GDAL.GDALColorTableH
end

"return the corresponding `DataType` in julia"
datatype(gt::GDALDataType)::DataType = get(_JLTYPE, gt) do
    error("Unknown GDALDataType: $gt")
end

"return the corresponding `GDAL.GDALDataType`"
gdaltype(dt::DataType)::GDAL.GDALDataType = get(_GDALTYPE, dt) do
    error("Unknown DataType: $dt")
end

"return the corresponding `DataType` in julia"
datatype(ft::OGRFieldType)::DataType = get(_FIELDTYPE, ft) do
    error("Unknown OGRFieldType: $ft")
end

eval(@gdalenum(OGRFieldType::GDAL.OGRFieldType,
    OFTInteger::GDAL.OFTInteger,
    OFTIntegerList::GDAL.OFTIntegerList,
    OFTReal::GDAL.OFTReal,
    OFTRealList::GDAL.OFTRealList,
    OFTString::GDAL.OFTString,
    OFTStringList::GDAL.OFTStringList,
    OFTWideString::GDAL.OFTWideString,
    OFTWideStringList::GDAL.OFTWideStringList,
    OFTBinary::GDAL.OFTBinary,
    OFTDate::GDAL.OFTDate,
    OFTTime::GDAL.OFTTime,
    OFTDateTime::GDAL.OFTDateTime,
    OFTInteger64::GDAL.OFTInteger64,
    OFTInteger64List::GDAL.OFTInteger64List
))

eval(@gdalenum(WKBGeometryType::GDAL.OGRwkbGeometryType,
    wkbUnknown::GDAL.wkbUnknown,
    wkbPoint::GDAL.wkbPoint,
    wkbLineString::GDAL.wkbLineString,
    wkbPolygon::GDAL.wkbPolygon,
    wkbMultiPoint::GDAL.wkbMultiPoint,
    wkbMultiLineString::GDAL.wkbMultiLineString,
    wkbMultiPolygon::GDAL.wkbMultiPolygon,
    wkbGeometryCollection::GDAL.wkbGeometryCollection,
    wkbCircularString::GDAL.wkbCircularString,
    wkbCompoundCurve::GDAL.wkbCompoundCurve,
    wkbCurvePolygon::GDAL.wkbCurvePolygon,
    wkbMultiCurve::GDAL.wkbMultiCurve,
    wkbMultiSurface::GDAL.wkbMultiSurface,
    wkbCurve::GDAL.wkbCurve,
    wkbSurface::GDAL.wkbSurface,
    wkbPolyhedralSurface::GDAL.wkbPolyhedralSurface,
    wkbTIN::GDAL.wkbTIN,
    wkbTriangle::GDAL.wkbTriangle,
    wkbNone::GDAL.wkbNone,
    wkbLinearRing::GDAL.wkbLinearRing,
    wkbCircularStringZ::GDAL.wkbCircularStringZ,
    wkbCompoundCurveZ::GDAL.wkbCompoundCurveZ,
    wkbCurvePolygonZ::GDAL.wkbCurvePolygonZ,
    wkbMultiCurveZ::GDAL.wkbMultiCurveZ,
    wkbMultiSurfaceZ::GDAL.wkbMultiSurfaceZ,
    wkbCurveZ::GDAL.wkbCurveZ,
    wkbSurfaceZ::GDAL.wkbSurfaceZ,
    wkbPolyhedralSurfaceZ::GDAL.wkbPolyhedralSurfaceZ,
    wkbTINZ::GDAL.wkbTINZ,
    wkbTriangleZ::GDAL.wkbTriangleZ,
    wkbPointM::GDAL.wkbPointM,
    wkbLineStringM::GDAL.wkbLineStringM,
    wkbPolygonM::GDAL.wkbPolygonM,
    wkbMultiPointM::GDAL.wkbMultiPointM,
    wkbMultiLineStringM::GDAL.wkbMultiLineStringM,
    wkbMultiPolygonM::GDAL.wkbMultiPolygonM,
    wkbGeometryCollectionM::GDAL.wkbGeometryCollectionM,
    wkbCircularStringM::GDAL.wkbCircularStringM,
    wkbCompoundCurveM::GDAL.wkbCompoundCurveM,
    wkbCurvePolygonM::GDAL.wkbCurvePolygonM,
    wkbMultiCurveM::GDAL.wkbMultiCurveM,
    wkbMultiSurfaceM::GDAL.wkbMultiSurfaceM,
    wkbCurveM::GDAL.wkbCurveM,
    wkbSurfaceM::GDAL.wkbSurfaceM,
    wkbPolyhedralSurfaceM::GDAL.wkbPolyhedralSurfaceM,
    wkbTINM::GDAL.wkbTINM,
    wkbTriangleM::GDAL.wkbTriangleM,
    wkbPointZM::GDAL.wkbPointZM,
    wkbLineStringZM::GDAL.wkbLineStringZM,
    wkbPolygonZM::GDAL.wkbPolygonZM,
    wkbMultiPointZM::GDAL.wkbMultiPointZM,
    wkbMultiLineStringZM::GDAL.wkbMultiLineStringZM,
    wkbMultiPolygonZM::GDAL.wkbMultiPolygonZM,
    wkbGeometryCollectionZM::GDAL.wkbGeometryCollectionZM,
    wkbCircularStringZM::GDAL.wkbCircularStringZM,
    wkbCompoundCurveZM::GDAL.wkbCompoundCurveZM,
    wkbCurvePolygonZM::GDAL.wkbCurvePolygonZM,
    wkbMultiCurveZM::GDAL.wkbMultiCurveZM,
    wkbMultiSurfaceZM::GDAL.wkbMultiSurfaceZM,
    wkbCurveZM::GDAL.wkbCurveZM,
    wkbSurfaceZM::GDAL.wkbSurfaceZM,
    wkbPolyhedralSurfaceZM::GDAL.wkbPolyhedralSurfaceZM,
    wkbTINZM::GDAL.wkbTINZM,
    wkbTriangleZM::GDAL.wkbTriangleZM,
    wkbPoint25D::GDAL.wkbPoint25D,
    wkbLineString25D::GDAL.wkbLineString25D,
    wkbPolygon25D::GDAL.wkbPolygon25D,
    wkbMultiPoint25D::GDAL.wkbMultiPoint25D,
    wkbMultiLineString25D::GDAL.wkbMultiLineString25D,
    wkbMultiPolygon25D::GDAL.wkbMultiPolygon25D,
    wkbGeometryCollection25D::GDAL.wkbGeometryCollection25D,
))

eval(@gdalenum(WKBByteOrder::GDAL.OGRwkbByteOrder,
    wkbXDR::GDAL.wkbXDR,
    wkbNDR::GDAL.wkbNDR,
))

import Base.|

|(x::GDALOpenFlag,y::UInt8) = UInt8(x) | y
|(x::UInt8,y::GDALOpenFlag) = x | UInt8(y)
|(x::GDALOpenFlag,y::GDALOpenFlag) = UInt8(x) | UInt8(y)

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
gettype(name::AbstractString)::GDAL.GDALDataType =
    GDAL.gdalgetdatatypebyname(name)

"""
    typeunion(dt1::GDALDataType, dt2::GDALDataType)

Return the smallest data type that can fully express both input data types.
"""
typeunion(dt1::GDALDataType, dt2::GDALDataType)::GDAL.GDALDataType =
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
asyncstatustype(name::AbstractString)::GDAL.GDALAsyncStatusType =
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
colorinterp(name::AbstractString)::GDAL.GDALColorInterp =
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
"""
getname(obj::OGRFieldSubType)::String = GDAL.ogr_getfieldsubtypename(obj)

"""
    arecompatible(dtype::OGRFieldType, subtype::OGRFieldSubType)

Return if type and subtype are compatible.
"""
arecompatible(dtype::OGRFieldType, subtype::OGRFieldSubType)::Bool =
    Bool(GDAL.ogr_aretypesubtypecompatible(dtype, subtype))
