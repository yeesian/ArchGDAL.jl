# This file contains friendly type-pyracy on `convert` for GeoFormatTypes.jl types

"""
    convert(
        target::Type{<:GeoFormatTypes.GeoFormat},
        mode::Union{GeoFormatTypes.FormatMode, Type{GeoFormatTypes.FormatMode}},
        source::GeoFormatTypes.GeoFormat
    )

Convert a `GeoFormatTypes.GeoFormat` object to Geometry, then to the target
format. The Geom trait is needed to separate out convert for CRS for
WellKnownText and GML, which may contain both.

Both `Geom` and `Mixed` formats are converted to Geometries by default. 
To convert a `Mixed` format to crs, `CRS` must be explicitly passed for `mode`.
"""

function Base.convert(
    target::Type{<:GFT.GeoFormat},
    mode::Union{GFT.FormatMode,Type{GFT.FormatMode}},
    source::GFT.GeoFormat,
)
    return convert(target, convert(AbstractGeometry, source))
end

"""
    convert(::Type{<:AbstractGeometry},
        source::GeoFormatTypes.AbstractWellKnownText)
    convert(::Type{<:AbstractGeometry}, source::GeoFormatTypes.WellKnownBinary)
    convert(::Type{<:AbstractGeometry}, source::GeoFormatTypes.GeoJSON)
    convert(::Type{<:AbstractGeometry}, source::GeoFormatTypes.GML)

Convert `GeoFormat` geometry data to an ArchGDAL `Geometry` type
"""

function Base.convert(
    ::Type{<:AbstractGeometry},
    source::GFT.AbstractWellKnownText,
)
    return fromWKT(GFT.val(source))
end
function Base.convert(::Type{<:AbstractGeometry}, source::GFT.WellKnownBinary)
    return fromWKB(GFT.val(source))
end
function Base.convert(::Type{<:AbstractGeometry}, source::GFT.GeoJSON)
    return fromJSON(GFT.val(source))
end
function Base.convert(::Type{<:AbstractGeometry}, source::GFT.GML)
    return fromGML(GFT.val(source))
end

function Base.convert(
    ::Type{IGeometry{wkbUnknown}},
    source::AbstractGeometry,
)
    result = IGeometry(C_NULL)
    result.ptr = unsafe_clone(source).ptr
    return result
end

"""
    convert(::Type{<:GeoFormatTypes.AbstractWellKnownText},
        source::AbstractGeometry)
    convert(::Type{<:GeoFormatTypes.WellKnownBinary}, source::AbstractGeometry)
    convert(::Type{<:GeoFormatTypes.GeoJSON}, source::AbstractGeometry)
    convert(::Type{<:GeoFormatTypes.GML}, source::AbstractGeometry)
    convert(::Type{<:GeoFormatTypes.KML}, source::AbstractGeometry)

Convert `AbstractGeometry` data to any geometry `GeoFormat`.
"""

function Base.convert(
    ::Type{<:GFT.AbstractWellKnownText},
    source::AbstractGeometry,
)
    return GFT.WellKnownText(GFT.Geom(), toWKT(source))
end
function Base.convert(::Type{<:GFT.WellKnownBinary}, source::AbstractGeometry)
    return GFT.WellKnownBinary(GFT.Geom(), toWKB(source))
end
function Base.convert(::Type{<:GFT.GeoJSON}, source::AbstractGeometry)
    return GFT.GeoJSON(toJSON(source))
end
function Base.convert(::Type{<:GFT.GML}, source::AbstractGeometry)
    return GFT.GML(GFT.Geom(), toGML(source))
end
function Base.convert(::Type{<:GFT.KML}, source::AbstractGeometry)
    return GFT.KML(toKML(source))
end

"""
    convert(target::Type{<:GeoFormatTypes.GeoFormat}, mode::CRS,
        source::GeoFormat)

Convert `GeoFormat` CRS data to another `GeoFormat` CRS type.
"""

function Base.convert(
    target::Type{<:GFT.GeoFormat},
    mode::Union{GFT.CRS,Type{GFT.CRS}},
    source::GFT.GeoFormat,
)
    return unsafe_convertcrs(target, importCRS(source))
end

function unsafe_convertcrs(::Type{<:GFT.CoordSys}, crsref)
    return GFT.CoordSys(toMICoordSys(crsref))
end
function unsafe_convertcrs(::Type{<:GFT.ProjString}, crsref)
    return GFT.ProjString(toPROJ4(crsref))
end
function unsafe_convertcrs(::Type{<:GFT.WellKnownText}, crsref)
    return GFT.WellKnownText(GFT.CRS(), toWKT(crsref))
end
function unsafe_convertcrs(::Type{<:GFT.ESRIWellKnownText}, crsref)
    return GFT.ESRIWellKnownText(GFT.CRS(), toWKT(morphtoESRI!(crsref)))
end
unsafe_convertcrs(::Type{<:GFT.GML}, crsref) = GFT.GML(toXML(crsref))
