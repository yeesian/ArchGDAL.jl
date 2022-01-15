#*#############################################################################
#*          Parametric ArchGDAL vector data types for ArchGDAL.Table          #
#*#############################################################################
# 1. Definition and associated methods of FType, GType and FDType.
#    Used as parameters for parametric ArchGDAL vector data types
# 2. Types hierarchy of parametric ArchGDAL vector data types
# 3. Parametric ArchGDAL vector data types definitions
#    In parenthesis: objects with commented definition or to define
#    - GFTP_GeomFieldDefn and GFTP_IGeomFieldDefnView
#    - FTP_FieldDefn and FTP_IFieldDefnView
#    - FDP_FeatureDefn and FDP_IFeatureDefnView
#    - FDP_Feature (and FDP_IFeatureView)
#    - (GP_Geometry and GP_IGeometry)
#    - (FDP_FeatureLayer and) FDP_IFeatureLayer
# 4. Conversion function for parametric ArchGDAL vector data types
# 5. Subset of ArchGDAL vector functions adpated and optimized for 
#    parametric ArchGDAL vector data types
#    a. Methods for GFTP_AbstractGeomFieldDefn => none found useful yet
#    b. Methofs for FTP_AbstractFieldDefn
#    c. Methods for FDP_AbstractFeatureDefn
#    d. Methods for FDP_AbstractFeature 
#    e. Methods for FDP_AbstractFeatureLayer
###############################################################################

###############################################################################
#            1. Definition of FType, GType and FDType definition              #
###############################################################################

#! AbstractOFType could also be a non parameterized abstract type with
#! OFType{OGRFieldType, OGRFieldSubType} instead of 
#! OFType{T,OGRFieldSubType} <: AbstractOFType{T}
abstract type AbstractFType{OGRFieldType} end
struct FType{T,OGRFieldSubType} <: AbstractFType{T} end
function getFType(ptr::GDAL.OGRFieldDefnH)
    return FType{
        convert(OGRFieldType, GDAL.ogr_fld_gettype(ptr)),
        convert(OGRFieldSubType, GDAL.ogr_fld_getsubtype(ptr)),
    }
end
abstract type AbstractGType end
struct GType{OGRwkbGeometryType} <: AbstractGType end
function getGType(ptr::GDAL.OGRGeomFieldDefnH)
    return GType{convert(OGRwkbGeometryType, GDAL.ogr_gfld_gettype(ptr))}
end

#! NEW simple FeatureDefn type, could later maybe(?) replaced by full 
#! FeatureDefn type in the definitions below
#TODO delete: FDType = Tuple{NTuple{NG,GType} where NG,NTuple{NF,FType} where NF} #! Type alias for FD parameter
FDType = Tuple{
    NamedTuple{NG,<:Tuple{Vararg{GType}}} where NG,
    NamedTuple{NF,<:Tuple{Vararg{FType}}} where NF,
}
@generated function _ngt(::Type{T}) where {T<:FDType}
    return :(length($T.types[1].types))
end
@generated function _gtnames(::Type{T}) where {T<:FDType}
    return :(tuple($T.types[1].parameters[1]...))
end
@generated function _gttypes(::Type{T}) where {T<:FDType}
    return :(tuple($T.types[1].types...))
end
@generated function _nft(::Type{T}) where {T<:FDType}
    return :(length($T.types[2].types))
end
@generated function _ftnames(::Type{T}) where {T<:FDType}
    return :(tuple($T.types[2].parameters[1]...))
end
@generated function _fttypes(::Type{T}) where {T<:FDType}
    return :(tuple($T.types[2].types...))
end
#! There no type difference between GDAL.OGRFeatureDefnH and GDAL.OGRLayerH 
#! (both Ptr{Cvoid})) and we cannot dispatch on it
function _getFDType(ptr::GDAL.OGRFeatureDefnH)
    ng = GDAL.ogr_fd_getgeomfieldcount(ptr)::Int32
    gflddefn_ptrs = (GDAL.ogr_fd_getgeomfielddefn(ptr, i - 1) for i in 1:ng)
    NG = tuple(
        (
            Symbol(GDAL.ogr_gfld_getnameref(gflddefn_ptr)::String) for
            gflddefn_ptr in gflddefn_ptrs
        )...,
    )
    TG = Tuple{(getGType(gflddefn_ptr) for gflddefn_ptr in gflddefn_ptrs)...}
    nf = GDAL.ogr_fd_getfieldcount(ptr)::Int32
    flddefn_ptrs = (GDAL.ogr_fd_getfielddefn(ptr, i - 1) for i in 1:nf)
    NF = tuple(
        (
            Symbol(GDAL.ogr_fld_getnameref(flddefn_ptr)::String) for
            flddefn_ptr in flddefn_ptrs
        )...,
    )
    TF = Tuple{(getFType(flddefn_ptr) for flddefn_ptr in flddefn_ptrs)...}
    # TF = Tuple{ntuple(i -> getFType(flddefn_ptrs[i]), nf)...} => to use in case later conversion from FType to DataType has to be implemented
    return Tuple{NamedTuple{NG,TG},NamedTuple{NF,TF}}
end

###############################################################################
#        2. Types hierarchy of parametric ArchGDAL vector data types          #
###############################################################################

abstract type GFTP_AbstractGeomFieldDefn{GFT<:GType} <:
              DUAL_AbstractGeomFieldDefn end
abstract type FTP_AbstractFieldDefn{FT<:FType} <: DUAL_AbstractFieldDefn end
abstract type FDP_AbstractFeatureDefn{FD<:FDType} <: DUAL_AbstractFeatureDefn end
abstract type FDP_AbstractFeature{FD<:FDType} <: DUAL_AbstractFeature end
abstract type FDP_AbstractFeatureLayer{FD<:FDType} <: DUAL_AbstractFeatureLayer end

###############################################################################
#           3. Definition of parametric ArchGDAL vector data types            #
###############################################################################

#! NEW GFTP_GeomFieldDefn and GFTP_IGeomFieldDefnView
#! Unsafe version disabled as there is no usage for Table struct
# mutable struct GFTP_GeomFieldDefn{GFT} <: GFTP_AbstractGeomFieldDefn{GFT}
#     ptr::GDAL.OGRGeomFieldDefnH
#     ownedby::Union{Nothing,FDP_AbstractFeatureDefn}
#     spatialref::Union{Nothing,AbstractSpatialRef}

#     function GFTP_GeomFieldDefn{GFT}(
#         ptr::GDAL.OGRGeomFieldDefnH = C_NULL;
#         ownedby::Union{Nothing,FDP_AbstractFeatureDefn} = nothing,
#         spatialref::Union{Nothing,AbstractSpatialRef} = nothing,
#     ) where {GFT<:GType}
#         return new(ptr, ownedby, spatialref)
#     end
# end

# function destroy(gftp_geomfielddefn::GFTP_GeomFieldDefn)
#     GDAL.ogr_gfld_destroy(gftp_geomfielddefn)
#     gftp_geomfielddefn.ptr = C_NULL
#     gftp_geomfielddefn.ownedby = nothing
#     gftp_geomfielddefn.spatialref = nothing
#     return nothing
# end

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

function destroy(gftp_igeomfielddefnview::GFTP_IGeomFieldDefnView)
    gftp_igeomfielddefnview.ptr = C_NULL
    gftp_igeomfielddefnview.ownedby = nothing
    gftp_igeomfielddefnview.spatialref = nothing
    return nothing
end

#! NEW FTP_FieldDefn and FTP_IFieldDefnView
#! Unsafe version disabled as there is no usage for Table struct
# mutable struct FTP_FieldDefn{FT} <: FTP_AbstractFieldDefn{FT}
#     ptr::GDAL.OGRFieldDefnH
#     ownedby::Union{Nothing,FDP_AbstractFeatureDefn}

#     function FTP_FieldDefn{FT}(
#         ptr::GDAL.OGRFieldDefnH = C_NULL;
#         ownedby::Union{Nothing,FDP_AbstractFeatureDefn} = nothing,
#     ) where {FT<:FType}
#         return new(ptr, ownedby)
#     end
# end

# function destroy(ftp_fielddefn::FTP_FieldDefn)
#     GDAL.ogr_fld_destroy(ftp_fielddefn)
#     ftp_fielddefn.ptr = C_NULL
#     ftp_fielddefn.ownedby = nothing
#     return nothing
# end

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

function destroy(ftp_fielddefn::FTP_IFieldDefnView)
    ftp_fielddefn.ptr = C_NULL
    ftp_fielddefn.ownedby = nothing
    return nothing
end

#! NEW FeatureDefn parameterized FeatureDefn and IFeatureDefnView
#! Unsafe version disabled as there is no usage for Table struct
# mutable struct FDP_FeatureDefn{FD} <: FDP_AbstractFeatureDefn{FD}
#     ptr::GDAL.OGRFeatureDefnH
#     ownedby::Union{Nothing,FDP_AbstractFeatureLayer{FD}}

#     function FDP_FeatureDefn{FD}(
#         ptr::GDAL.OGRFeatureDefnH = C_NULL;
#         ownedby::Union{Nothing,FDP_AbstractFeatureLayer{FD}} = nothing,
#     ) where {FD<:FDType}
#         return new(ptr, ownedby)
#     end
# end

# function destroy(fdp_featuredefn::FDP_FeatureDefn)
#     GDAL.ogr_fd_destroy(fdp_featuredefn.ptr)
#     fdp_featuredefn.ptr = C_NULL
#     fdp_featuredefn.ownedby = nothing
#     return nothing
# end

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

function destroy(fdp_ifeaturedefnview::FDP_IFeatureDefnView)
    fdp_ifeaturedefnview.ptr = C_NULL
    fdp_ifeaturedefnview.ownedby = nothing
    return nothing
end

#! NEW FeatureDefn parameterized Feature and IFeature
#! Unsafe version disabled as there is no usage for Table struct
# mutable struct FDP_Feature{FD} <: FDP_AbstractFeature{FD}
#     ptr::GDAL.OGRFeatureH
#     ownedby::Union{Nothing,FDP_AbstractFeatureLayer}

#     function FDP_Feature{FD}(
#         ptr::GDAL.OGRFeatureH = C_NULL;
#         ownedby::Union{Nothing,FDP_AbstractFeatureLayer} = nothing,
#     ) where {FD<:FDType}
#         return new(ptr, ownedby)
#     end
# end

function destroy(fdp_feature::FDP_AbstractFeature)
    GDAL.ogr_f_destroy(fdp_feature.ptr)
    fdp_feature.ptr = C_NULL
    fdp_feature.ownedby = nothing
    return nothing
end

mutable struct FDP_IFeature{FD} <: FDP_AbstractFeature{FD}
    ptr::GDAL.OGRFeatureH
    ownedby::Union{Nothing,FDP_AbstractFeatureLayer}

    function FDP_IFeature{FD}(
        ptr::GDAL.OGRFeatureH = C_NULL;
        ownedby::Union{Nothing,FDP_AbstractFeatureLayer} = nothing,
    ) where {FD<:FDType}
        fdp_ifeature = new(ptr, ownedby)
        finalizer(destroy, fdp_ifeature)
        return fdp_ifeature
    end
end

#! NEW Geometry and IGeometry => disabled since no performance gain identified yet
# abstract type GP_AbstractGeometry{G<:GType} <: GeoInterface.AbstractGeometry end

# function _inferGType(ptr::GDAL.OGRGeometryH = C_NULL)::Type{<:GType}
#     return ptr != C_NULL ?
#            GType{OGRwkbGeometryType(Int32(GDAL.ogr_g_getgeometrytype(ptr)))} :
#            GType{wkbUnknown}
# end

# mutable struct GP_Geometry{G} <: GP_AbstractGeometry{G}
#     ptr::GDAL.OGRGeometryH
#     ownedby::Union{Nothing,FDP_AbstractFeature}

#     function GP_Geometry{G}(
#         ptr::GDAL.OGRGeometryH = C_NULL,
#         ownedby::Union{Nothing,FDP_AbstractFeature} = nothing,
#     ) where {G<:GType}
#         return GP_Geometry{_inferGType(ptr)}(ptr, ownedby)
#     end
# end

# mutable struct GP_IGeometry{G} <: GP_AbstractGeometry{G}
#     ptr::GDAL.OGRGeometryH
#     ownedby::Union{Nothing,FDP_AbstractFeature}

#     function GP_IGeometry{G}(
#         ptr::GDAL.OGRGeometryH = C_NULL,
#         ownedby::Union{Nothing,FDP_AbstractFeature} = nothing,
#     ) where {G<:GType}
#         gp_igeometry = new{_inferGType(ptr)}(ptr, ownedby)
#         finalizer(destroy, gp_igeometry)
#         return gp_igeometry
#     end
# end

#! NEW FeatureDefn parameterized FeatureLayer and IFeatureLayer
#! Unsafe version disabled as there is no usage for Table struct
# mutable struct FDP_FeatureLayer{FD} <: FDP_AbstractFeatureLayer{FD}
#     ptr::GDAL.OGRLayerH
#     ownedby::AbstractDataset
#     spatialref::Union{Nothing,AbstractSpatialRef}

#     function FDP_FeatureLayer{FD}(
#         ptr::GDAL.OGRLayerH = C_NULL;
#         ownedby::AbstractDataset = Dataset(),
#         spatialref::Union{Nothing,AbstractSpatialRef} = nothing,
#     ) where {FD<:FDType}
#         return new(ptr, ownedby, spatialref)
#     end
# end

mutable struct FDP_IFeatureLayer{FD} <: FDP_AbstractFeatureLayer{FD}
    ptr::GDAL.OGRLayerH
    ownedby::Union{Nothing,AbstractDataset}
    spatialref::Union{Nothing,AbstractSpatialRef}

    function FDP_IFeatureLayer{FD}(
        ptr::GDAL.OGRLayerH = C_NULL;
        ownedby::AbstractDataset = Dataset(),
        spatialref::Union{Nothing,AbstractSpatialRef} = nothing,
    ) where {FD<:FDType}
        fdp_layer = new(ptr, ownedby, spatialref)
        finalizer(destroy, fdp_layer)
        return fdp_layer
    end
end

function destroy(fdp_layer::FDP_AbstractFeatureLayer)
    # No specific GDAL object destructor for layer, it will be handled by the dataset closing
    fdp_layer.ptr = C_NULL
    fdp_layer.ownedby = nothing
    fdp_layer.spatialref = nothing
    return nothing
end

###############################################################################
#       4. Conversion function for parametric ArchGDAL vector data types      #
###############################################################################

# Default DataType = LAST, for duplicated (oftid, ofstid) values
const DataType_2_OGRFieldType_OGRFieldSubType_mapping = Base.ImmutableDict(
    Bool => (OFTInteger, OFSTBoolean),
    Int8 => (OFTInteger, OFSTNone),
    Int16 => (OFTInteger, OFSTInt16),
    Int32 => (OFTInteger, OFSTNone),                # Default OFTInteger
    Vector{Bool} => (OFTIntegerList, OFSTBoolean),
    Vector{Int16} => (OFTIntegerList, OFSTInt16),
    Vector{Int32} => (OFTIntegerList, OFSTNone),    # Default OFTIntegerList
    Float16 => (OFTReal, OFSTNone),
    Float32 => (OFTReal, OFSTFloat32),
    Float64 => (OFTReal, OFSTNone),                 # Default OFTReal
    Vector{Float16} => (OFTRealList, OFSTNone),
    Vector{Float32} => (OFTRealList, OFSTFloat32),
    Vector{Float64} => (OFTRealList, OFSTNone),     # Default OFTRealList
    String => (OFTString, OFSTNone),
    Vector{String} => (OFTStringList, OFSTNone),
    Vector{UInt8} => (OFTBinary, OFSTNone),
    Dates.Date => (OFTDate, OFSTNone),
    Dates.Time => (OFTTime, OFSTNone),
    Dates.DateTime => (OFTDateTime, OFSTNone),
    Int64 => (OFTInteger64, OFSTNone),
    Vector{Int64} => (OFTInteger64List, OFSTNone),
)

const OGRField_DataTypes = Union{
    Missing,
    Nothing,
    keys(DataType_2_OGRFieldType_OGRFieldSubType_mapping)...,
}

# Conversions from DataType to FType
const DataType2FType = Base.ImmutableDict(
    (
        k => FType{v...} for
        (k, v) in DataType_2_OGRFieldType_OGRFieldSubType_mapping
    )...,
)
# GDALDataTypes = Union{keys(DataType2FType)...}
# @generated function convert(::Type{FType}, ::Type{T}) where {T<:GDALDataTypes}
#     result = get(DataType2FType, T, missing)
#     !ismissing(result) || throw(MethodError(convert, (FType, T)))
#     return :($(result))
# end
# #! Conversion from FType to DataType not implemented because it creates a mess
# #! use get(FType2DataType, FT, missing) instead
const FType2DataType =
    Base.ImmutableDict((v => k for (k, v) in DataType2FType)...)
# # # GDALFTypes = Union{keys(FType2DataType)...}
# # @generated function convert(::Type{DataType}, ::Type{T}) where T<:FType
# #     result = get(FType2DataType, T, missing)
# #     result !== missing || error(
# #         "$T is not an FType corresponding to a valid GDAL (OGRFieldType, OGRFieldSubType) couple. \nPlease use one of the following: \n$(join((FType{v...} for (_, v) in DataType_2_OGRFieldType_OGRFieldSubType_mapping), "\n"))",
# #     )
# #     return :($(result))
# # end

# Conversion between Geometry or IGeometry subtypes and GType subtypes
# function convert(::Type{Geometry}, G::Type{GType{T}}) where {T}
#     return Geometry{T}
# end
function convert(::Type{IGeometry}, ::Type{GType{T}}) where {T}
    return IGeometry{T}
end
# function convert(::Type{GType}, ::Type{Geometry{T}}) where {T}
#     return GType{T}
# end
# function convert(::Type{GType}, ::Type{IGeometry{T}}) where {T}
#     return GType{T}
# end

# Conversion between GP_Geometry or GP_IGeometry subtypes and GType subtypes
# function convert(::Type{GP_Geometry}, ::Type{G}) where {G<:GType}
#     return GP_Geometry{G}
# end
# function convert(::Type{GType}, ::Type{GP_Geometry{G}}) where {G<:GType}
#     return G
# end
# function convert(::Type{GP_IGeometry}, ::Type{G}) where {G<:GType}
#     return GP_IGeometry{G}
# end
# function convert(::Type{GType}, ::Type{GP_IGeometry{G}}) where {G<:GType}
#     return G
# end

###############################################################################
#                 5.a Methods for GFTP_AbstractGeomFieldDefn                  #
###############################################################################

# None found useful to specialize yet

###############################################################################
#                    5.b Methods for FTP_AbstractFieldDefn                    #
###############################################################################

@generated function gettype(::FTP_AbstractFieldDefn{FType{T,ST}}) where {T,ST}
    return :($T)
end

@generated function getsubtype(
    ::FTP_AbstractFieldDefn{FType{T,ST}},
) where {T,ST}
    return :($ST)
end

@generated function getfieldtype(
    ::FTP_AbstractFieldDefn{FType{T,ST}},
) where {T,ST}
    return ST != OFSTNone ? :($ST) : :($T)
end

###############################################################################
#                  5.c Methods for FDP_AbstractFeatureDefn                    #
###############################################################################

# Geometries methods
@generated function ngeom(::FDP_AbstractFeatureDefn{FD}) where {FD<:FDType}
    return :($(_ngt(FD)))
end

# function getgeomdefn(
#     fdp_featuredefn::FDP_FeatureDefn{FD},
#     i::Integer = 0,
# ) where {FD<:FDType}
#     return GFTP_GeomFieldDefn{_gttypes(FD)[i+1]}(
#         GDAL.ogr_fd_getgeomfielddefn(fdp_featuredefn.ptr, i);
#         ownedby = fdp_featuredefn,
#     )
# end

function getgeomdefn(
    fdp_ifeaturedefnview::FDP_IFeatureDefnView{FD},
    i::Integer = 0,
) where {FD<:FDType}
    return GFTP_IGeomFieldDefnView{_gttypes(FD)[i+1]}(
        GDAL.ogr_fd_getgeomfielddefn(fdp_ifeaturedefnview.ptr, i);
        ownedby = fdp_ifeaturedefnview,
    )
end

# @generated function findgeomindex(
#     ::FDP_AbstractFeatureDefn{FD},
#     name::AbstractString = "",
# ) where {FD<:FDType}
#     return return quote
#         i = findfirst(isequal(Symbol(name)), $(_gtnames(FD)))
#         return i !== nothing ? i - 1 : nothing
#     end
# end

# Fields methods
@generated function nfield(::FDP_AbstractFeatureDefn{FD}) where {FD<:FDType}
    return :($(_nft(FD)))
end

# function getfielddefn(
#     fdp_featuredefn::FDP_FeatureDefn{FD},
#     i::Integer = 0,
# ) where {FD<:FDType}
#     return FTP_FieldDefn{_fttypes(FD)[i+1]}(
#         GDAL.ogr_fd_getfielddefn(fdp_featuredefn.ptr, i);
#         ownedby = fdp_featuredefn,
#     )
# end

function getfielddefn(
    fdp_ifeaturedefnview::FDP_IFeatureDefnView{FD},
    i::Integer = 0,
) where {FD<:FDType}
    return FTP_IFieldDefnView{_fttypes(FD)[i+1]}(
        GDAL.ogr_fd_getfielddefn(fdp_ifeaturedefnview.ptr, i);
        ownedby = fdp_ifeaturedefnview,
    )
end

# @generated function findfieldindex(
#     ::FDP_AbstractFeatureDefn{FD},
#     name::Union{AbstractString,Symbol},
# ) where {FD<:FDType}
#     return return quote
#         i = findfirst(isequal(Symbol(name)), $(_ftnames(FD)))
#         return i !== nothing ? i - 1 : nothing
#     end
# end

function getfeaturedefn(fdp_feature::FDP_IFeature{FD}) where {FD<:FDType}
    return FDP_IFeatureDefnView{FD}(
        GDAL.ogr_f_getdefnref(fdp_feature.ptr);
        ownedby = fdp_feature.ownedby,
    )
end

###############################################################################
#                    5.d Methods for FDP_AbstractFeature                      #
###############################################################################

# Geometries
@generated function ngeom(::FDP_AbstractFeature{FD}) where {FD<:FDType}
    return :($(_ngt(FD)))
end

@generated function findgeomindex(
    ::FDP_AbstractFeature{FD},
    name::Union{AbstractString,Symbol} = "",
) where {FD<:FDType}
    return return quote
        i = findfirst(isequal(Symbol(name)), $(_gtnames(FD)))
        return i !== nothing ? i - 1 : nothing
    end
end

function stealgeom(
    fdp_feature::FDP_AbstractFeature{FD},
    i::Integer,
) where {FD<:FDType}
    return i == 0 ? IGeometry(GDAL.ogr_f_stealgeometry(fdp_feature.ptr)) :
           getgeom(fdp_feature, i)
end

# function stealgeom(
#     fdp_feature::FDP_AbstractFeature{FD},
#     name::Union{AbstractString,Symbol},
# ) where {FD<:FDType}
#     i = findgeomindex(fdp_feature, name)
#     return i == 0 ? IGeometry(GDAL.ogr_f_stealgeometry(fdp_feature.ptr)) :
#            getgeom(fdp_feature, i)
# end

# Fields
@generated function nfield(::FDP_AbstractFeature{FD}) where {FD<:FDType}
    return :($(_nft(FD)))
end

function getfielddefn(
    fdp_feature::FDP_IFeature{FD},
    i::Integer,
) where {FD<:FDType}
    return FTP_IFieldDefnView{_fttypes(FD)[i+1]}(
        GDAL.ogr_f_getfielddefnref(fdp_feature.ptr, i);
        ownedby = getfeaturedefn(fdp_feature),
    )
end

# @generated function findfieldindex(
#     ::FDP_AbstractFeature{FD},
#     name::Union{AbstractString,Symbol},
# ) where {FD<:FDType}
#     return quote
#         i = findfirst(isequal(Symbol(name)), $(_ftnames(FD)))
#         return i !== nothing ? i - 1 : nothing
#     end
# end

@generated function _get_fields_asfuncs(::Type{FD}) where {FD<:FDType}
    return ((_FETCHFIELD[T.parameters[1]] for T in _fttypes(FD))...,)
end

@generated function getfield(
    fdp_feature::FDP_AbstractFeature{FD},
    i::Integer,
) where {FD<:FDType}
    return quote
        return if !isfieldset(fdp_feature, i)
            nothing
        elseif isfieldnull(fdp_feature, i)
            missing
        else
            $(_get_fields_asfuncs(FD))[i+1](fdp_feature, i)
        end
    end
end

# @generated function getfield(
#     fdp_feature::FDP_AbstractFeature{FD},
#     name::Union{AbstractString,Symbol},
# ) where {FD<:FDType}
#     return quote
#         i = findfieldindex(fdp_feature, name)
#         return if i === nothing
#             missing
#         elseif !isfieldset(fdp_feature, i)
#             nothing
#         elseif isfieldnull(fdp_feature, i)
#             missing
#         else
#             @inbounds $(_get_fields_asfuncs(FD))[i+1](fdp_feature, i)
#         end
#     end
# end

function getindex(row::FDP_AbstractFeature{FD}, i::Int) where {FD<:FDType}
    ng = ngeom(row)
    return if i <= ng
        geom = getgeom(row, i - 1)
        geom.ptr != C_NULL ? geom : missing
    else
        getfield(row, i - ng - 1)
    end
end

# function getindex(row::FDP_AbstractFeature{FD}, name::Symbol) where {FD<:FDType}
#     field = getfield(row, name)
#     if !ismissing(field)
#         return field
#     end
#     geom = getgeom(row, name)
#     if geom.ptr != C_NULL
#         return geom
#     end
#     return missing
# end

#! getindex which steals the geometry from the feature
function getindex!(row::FDP_AbstractFeature{FD}, i::Int) where {FD<:FDType}
    ng = ngeom(row)
    return if i <= ng
        geom = stealgeom(row, i - 1)
        geom.ptr != C_NULL ? geom : missing
    else
        getfield(row, i - ng - 1)
    end
end

# function getindex!(row::FDP_AbstractFeature{FD}, name::Symbol) where {FD<:FDType}
#     field = getfield(row, name)
#     if !ismissing(field)
#         return field
#     end
#     geom = stealgeom(row, name)
#     if geom.ptr != C_NULL
#         return geom
#     end
#     return missing
# end

###############################################################################
#                  5.e Methods for FDP_AbstractFeatureLayer                   #
###############################################################################

@generated function _getFD(::FDP_AbstractFeatureLayer{FD}) where {FD<:FDType}
    return FD
end

function getFDPlayer(dataset::AbstractDataset, i::Integer)::FDP_IFeatureLayer
    ptr::GDAL.OGRLayerH = GDAL.gdaldatasetgetlayer(dataset.ptr, i)
    fd_ptr = GDAL.ogr_l_getlayerdefn(ptr)
    FD = _getFDType(fd_ptr)
    return FDP_IFeatureLayer{FD}(ptr, ownedby = dataset)
end

function getFDPlayer(dataset::AbstractDataset)
    nlayer(dataset) == 1 ||
        error("Dataset has multiple layers. Specify the layer number or name")
    return getFDPlayer(dataset, 0)
end

@generated function Base.iterate(
    layer::FDP_AbstractFeatureLayer{FD},
    state::Integer = 0,
) where {FD<:FDType}
    return quote
        layer.ptr == C_NULL && return nothing
        state == 0 && resetreading!(layer)
        ptr = GDAL.ogr_l_getnextfeature(layer.ptr)
        return if ptr == C_NULL
            resetreading!(layer)
            nothing
        else
            (FDP_IFeature{$FD}(ptr; ownedby = layer), state + 1)
        end
    end
end

# function Base.eltype(::FDP_AbstractFeatureLayer{FD}) where {FD<:FDType}
#     return FDP_IFeature{FD}
# end

function layerdefn(fdp_layer::FDP_AbstractFeatureLayer{FD}) where {FD<:FDType}
    return FDP_IFeatureDefnView{FD}(
        GDAL.ogr_l_getlayerdefn(fdp_layer.ptr);
        ownedby = fdp_layer,
    )
end

# @generated function findfieldindex(
#     ::FDP_AbstractFeatureLayer{FD},
#     field::Union{AbstractString,Symbol},
#     #! Note that exactmatch::Bool is not used in GDAL except when OGRAPISPY_ENABLED is true => dropped
# ) where {FD<:FDType}
#     return return quote
#         i = findfirst(isequal(Symbol(field)), $(_ftnames(FD)))
#         return i !== nothing ? i - 1 : nothing
#     end
# end

# @generated function ngeom(::FDP_AbstractFeatureLayer{FD}) where {FD<:FDType}
#     return :($(_ngt(FD)))
# end

# @generated function nfield(::FDP_AbstractFeatureLayer{FD}) where {FD<:FDType}
#     return :($(_nft(FD)))
# end

@generated function gdal_schema(
    ::FDP_AbstractFeatureLayer{FD},
) where {FD<:FDType}
    gnames = _gtnames(FD)
    fnames = _ftnames(FD)
    gtypes = (convert(IGeometry, gt) for gt in _gttypes(FD))
    ftypes = (get(FType2DataType, ft, missing) for ft in _fttypes(FD))
    return Tables.Schema((gnames..., fnames...), (gtypes..., ftypes...))
end

#######################################################################
# Tables.columns on FDP_AbstractFeatureLayer with generated functions #
#######################################################################
# - Feature to columns line function: FDPf2c and FDP2c! (geometry stealing)
# - Feature layer to array of columns : FDPfillcolumns! with geometry stealing option
# - Feature layer to NamedTuple: _getcols with geometry stealing option

@generated function FDPf2c(
    fdp_feature::FDP_AbstractFeature{FD},
    i::Int,
    cols::Vector{Vector{T} where T},
) where {FD<:FDType}
    ng = _ngt(FD)
    nf = _nft(FD)
    return quote
        @inbounds for j in 1:($nf+$ng)
            cols[j][i] = getindex(fdp_feature, j)
        end
        return nothing
    end
end

@generated function FDPf2c!(
    fdp_feature::FDP_AbstractFeature{FD},
    i::Int,
    cols::Vector{Vector{T} where T},
) where {FD<:FDType}
    ng = _ngt(FD)
    nf = _nft(FD)
    return quote
        @inbounds for j in 1:($nf+$ng)
            cols[j][i] = getindex!(fdp_feature, j)
        end
        return nothing
    end
end

function FDPfillcolumns!(
    fdp_layer::FDP_AbstractFeatureLayer{FD},
    cols::Vector{Vector{T} where T},
    preserve::Bool = true,
) where {FD<:FDType}
    state = 0
    if preserve
        while true
            next = iterate(fdp_layer, state)
            next === nothing && break
            fdp_feature, state = next
            FDPf2c(fdp_feature, state, cols)
        end
    else
        while true
            next = iterate(fdp_layer, state)
            next === nothing && break
            fdp_feature, state = next
            FDPf2c!(fdp_feature, state, cols)
        end
    end
end

function _getcols(
    fdp_layer::FDP_AbstractFeatureLayer{FD};
    preserve::Bool,
) where {FD<:FDType}
    len = length(fdp_layer)
    gdal_sch = gdal_schema(fdp_layer)
    ng = _ngt(FD)
    cols = [
        [Vector{Union{Missing,IGeometry}}(missing, len) for _ in 1:ng]
        [
            Vector{Union{Missing,Nothing,T}}(missing, len) for
            T in gdal_sch.types[ng+1:end]
        ]
    ]
    FDPfillcolumns!(fdp_layer, cols, preserve)
    return if VERSION < v"1.7"
        NamedTuple{gdal_sch.names}(
            NTuple{length(gdal_sch.names),Vector{T} where T}([
                convert(
                    Vector{promote_type(unique(typeof(e) for e in c)...)},
                    c,
                ) for c in cols
            ]),
        )
    else # Shorter code
        NamedTuple{gdal_sch.names}(
            convert(Vector{promote_type(unique(typeof(e) for e in c)...)}, c)
            for c in cols
        )
    end
end

#*#############################################################################
#*                           ArchGDAL.Table object                            #
#*#############################################################################

struct Table
    cols::T where {T<:NamedTuple}
end

# Table constructors
function Table(layer::AbstractFeatureLayer)
    return Table(
        _getcols(
            FDP_IFeatureLayer{_getFDType(layerdefn(layer).ptr)}(
                layer.ptr::GDAL.OGRLayerH;
                ownedby = layer.ownedby,
            );
            preserve = true,
        ),
    )
end
function Table(dataset::AbstractDataset, i::Integer)
    return Table(_getcols(getFDPlayer(dataset, i); preserve = false))
end
function Table(dataset::AbstractDataset)
    return Table(_getcols(getFDPlayer(dataset); preserve = false))
end
function Table(file::String, i::Integer; kwargs...)
    return Table(
        _getcols(getFDPlayer(read(file; kwargs...), i); preserve = false),
    )
end
function Table(file::String; kwargs...)
    return Table(_getcols(getFDPlayer(read(file; kwargs...)); preserve = false))
end

#*#############################################################################
#*                        Table's Tables.jl interface                         #
#*#############################################################################
# Usage of NamedTuples in Table struct brings native support of Tables.jl interface
# Usage of NamedTuples prevents extremely wide tables with # of columns > 67K
# which is due to Julia compiler limitation
# Should a need arise for larger tables, Table struct would have to be modified

Tables.istable(::Table) = true
Tables.schema(table::Table) = Tables.schema(table.cols)
#TODO after completion of PR #243: Tables.materializer(table::Table) = XXX

# Table Tables.Columns interface
Tables.columnaccess(::Table) = true
Tables.columns(table::Table) = table.cols

# Table Tables.Rows interface
Tables.rowaccess(::Table) = true
function Tables.rows(table::Table)
    return [
        NamedTuple{
            fieldnames(typeof(table.cols)),
            Tuple{eltype.(fieldtypes(typeof(table.cols)))...},
        }(
            Base.getindex(c, k) for c in table.cols
        ) for k in 1:length(table.cols[begin])
    ]
end
