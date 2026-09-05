module ArchGDALJLD2Ext

import ArchGDAL as AG
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
A CRS as its WKT2 definition, plus the two things WKT cannot carry: the data
axis to CRS axis mapping, which decides whether coordinates read as lon/lat or
lat/lon, and the coordinate epoch. An empty spatial reference is
`("", Int32[], 0.0)`.

Mutable so that JLD2 stores it by reference and writes each distinct record
once per file. `interned` hands back the same record for the same definition,
so a million geometries in one CRS share one copy of it on disk and, once
loaded, one GDAL object in memory. That only works for a record reached
through a field, which is why the two structs below wrap it rather than
carrying its fields.
"""
mutable struct ArchGDALSerializedCRS
    crs::String
    axismapping::Vector{Int32}
    epoch::Float64
end

"""
A spatial reference: a pointer to its shared CRS record.
"""
struct ArchGDALSerializedSpatialRef
    crs::ArchGDALSerializedCRS
end

"""
A geometry as WKB plus the spatial reference it was carrying, since WKB
cannot hold one.
"""
struct ArchGDALSerializedGeometryWithCRS
    wkb::Vector{UInt8}
    crs::ArchGDALSerializedCRS
end

const INTERNED =
    Dict{Tuple{String,Vector{Int32},Float64},ArchGDALSerializedCRS}()
const INTERNED_LOCK = ReentrantLock()
# A process normally meets a handful of distinct definitions. The cap guards
# against a workload with a fresh CRS per geometry; emptying the table during
# a save costs at most a duplicate record in the file, never a wrong one.
const INTERNED_LIMIT = 256

"""
The on-disk record for `spref`, shared with every other object serialized in
this process that has the same definition, axis mapping and epoch.
"""
function interned(spref::AG.AbstractSpatialRef)::ArchGDALSerializedCRS
    # A NULL handle is empty too, and GDAL refuses to be asked anything at all
    # about one, so this check has to come before any export.
    key = if AG.isempty(spref)
        ("", Int32[], 0.0)
    else
        wkt = AG.toWKT2(spref)
        (wkt, AG.getaxismapping(spref), AG.getcoordinateepoch(spref))
    end
    return lock(INTERNED_LOCK) do
        length(INTERNED) >= INTERNED_LIMIT && empty!(INTERNED)
        return get!(() -> ArchGDALSerializedCRS(key...), INTERNED, key)
    end
end

"""
A fresh spatial reference built from its record.
"""
function build(x::ArchGDALSerializedCRS)::AG.ISpatialRef
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

# JLD2 reads a record referenced from many places back as one object, so the
# geometries of one file can share a single GDAL spatial reference, the way
# features of a layer share the layer's. Nothing can observe the sharing,
# because `getspatialref` clones. Weak keys let a finished load release both.
const LOADED = WeakKeyDict{ArchGDALSerializedCRS,AG.ISpatialRef}()

function shared(x::ArchGDALSerializedCRS)::AG.ISpatialRef
    return get!(() -> build(x), LOADED, x)
end

JLD2.writeas(::Type{<:AG.AbstractSpatialRef}) = ArchGDALSerializedSpatialRef

function JLD2.wconvert(
    ::Type{ArchGDALSerializedSpatialRef},
    x::AG.AbstractSpatialRef,
)
    return ArchGDALSerializedSpatialRef(interned(x))
end

# A spatial reference loaded on its own is the caller's to mutate, so it must
# not be the shared one.
function JLD2.rconvert(
    ::Type{<:AG.AbstractSpatialRef},
    x::ArchGDALSerializedSpatialRef,
)
    return build(x.crs)
end

JLD2.writeas(::Type{<:AG.AbstractGeometry}) = ArchGDALSerializedGeometryWithCRS

function JLD2.wconvert(
    ::Type{ArchGDALSerializedGeometryWithCRS},
    x::AG.AbstractGeometry,
)
    return ArchGDALSerializedGeometryWithCRS(
        AG.toWKB(x),
        interned(AG.getspatialref(x)),
    )
end

function JLD2.rconvert(
    ::Type{<:AG.AbstractGeometry},
    x::ArchGDALSerializedGeometryWithCRS,
)
    isempty(x.crs.crs) && return AG.fromWKB(x.wkb)
    return AG.fromWKB(x.wkb; spatialref = shared(x.crs))
end

function JLD2.rconvert(
    ::Type{<:AG.AbstractGeometry},
    x::ArchGDALSerializedGeometry,
)
    return AG.fromWKB(x.wkb)
end

end
