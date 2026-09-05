module ArchGDALJLD2Ext

import ArchGDAL as AG
import GeoInterface as GI
import JLD2

# GDAL objects are pointers, and JLD2 writes a `ptr` field out as NULL, so
# anything reached through one has to be serialized as its definition instead.
# The structs below are that on-disk form. Being an on-disk format, their
# fields cannot change without breaking files already written: JLD2 hands back
# a `ReconstructedMutable` on a field mismatch, which no `rconvert` method
# matches. Add a new struct instead, and keep reading the old one.

"""
The v1 geometry form, which had no room for a spatial reference. Read-only:
nothing writes it any more.
"""
struct ArchGDALSerializedGeometry
    wkb::Vector{UInt8}
end

"""
A geometry as WKB plus the crs it was carrying, since WKB cannot hold one.
`crs` is the WKT2 definition, or `""` when the geometry had no spatial
reference.
"""
struct ArchGDALSerializedGeometryWithCRS
    wkb::Vector{UInt8}
    crs::String
end

"""
A spatial reference as its WKT2 definition, plus the two things WKT cannot
carry: the data axis to CRS axis mapping, which decides whether coordinates
read as lon/lat or lat/lon, and the coordinate epoch.
"""
struct ArchGDALSerializedSpatialRef
    crs::String
    axismapping::Vector{Int32}
    epoch::Float64
end

function _definition(spref::AG.AbstractSpatialRef)
    return AG.isempty(spref) ? "" : AG.toWKT2(spref)
end

JLD2.writeas(::Type{<:AG.AbstractGeometry}) = ArchGDALSerializedGeometryWithCRS

function JLD2.wconvert(
    ::Type{ArchGDALSerializedGeometryWithCRS},
    x::AG.AbstractGeometry,
)
    return ArchGDALSerializedGeometryWithCRS(
        AG.toWKB(x),
        _definition(AG.getspatialref(x)),
    )
end

function JLD2.rconvert(
    ::Type{<:AG.AbstractGeometry},
    x::ArchGDALSerializedGeometryWithCRS,
)
    isempty(x.crs) && return AG.fromWKB(x.wkb)
    return AG.fromWKB(x.wkb; spatialref = AG.ISpatialRef(x.crs))
end

function JLD2.rconvert(
    ::Type{<:AG.AbstractGeometry},
    x::ArchGDALSerializedGeometry,
)
    return AG.fromWKB(x.wkb)
end

JLD2.writeas(::Type{<:AG.AbstractSpatialRef}) = ArchGDALSerializedSpatialRef

function JLD2.wconvert(
    ::Type{ArchGDALSerializedSpatialRef},
    x::AG.AbstractSpatialRef,
)
    # An empty spatial reference has no definition, no mapping and no epoch to
    # save. That check is not just a shortcut: a NULL handle is empty too, and
    # GDAL refuses to be asked anything at all about one.
    AG.isempty(x) && return ArchGDALSerializedSpatialRef("", Int32[], 0.0)
    return ArchGDALSerializedSpatialRef(
        AG.toWKT2(x),
        AG.getaxismapping(x),
        AG.getcoordinateepoch(x),
    )
end

function JLD2.rconvert(
    ::Type{<:AG.AbstractSpatialRef},
    x::ArchGDALSerializedSpatialRef,
)
    isempty(x.crs) && return AG.ISpatialRef()
    spref = AG.ISpatialRef(x.crs)
    # Only force a custom mapping when the reconstructed default does not
    # already match, so that an ordinary authority-compliant crs does not come
    # back marked OAMS_CUSTOM.
    if AG.getaxismapping(spref) != x.axismapping
        AG.setaxismapping!(spref, x.axismapping)
    end
    return AG.setcoordinateepoch!(spref, x.epoch)
end

end
