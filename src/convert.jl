# This file contains friendly type-pyracy on `convert` for GeoFormatTypes.jl types

# Geometry conversions. 
#
# Convert to Geometry, then to the target format.
# The Geom trait is needed to separate out convert for CRS for WellKnownText
# and GML, which may contain both. It is handled in GeoFormatTypes.
Base.convert(target::Type{<:GFT.GeoFormat}, mode::GFT.Geom, source::GFT.GeoFormat) =
    convert(target, convert(Geometry, source))

Base.convert(::Type{<:Geometry}, source::GFT.AbstractWellKnownText) = 
    fromWKT(GFT.val(source))
Base.convert(::Type{<:Geometry}, source::GFT.WellKnownBinary) = 
    fromWKB(GFT.val(source))
Base.convert(::Type{<:Geometry}, source::GFT.GeoJSON) = 
    fromJSON(GFT.val(source))
Base.convert(::Type{<:Geometry}, source::GFT.GML) = 
    fromGML(GFT.val(source))

Base.convert(::Type{<:GFT.AbstractWellKnownText}, source::AbstractGeometry) = 
    GFT.WellKnownText(GFT.Geom(), toWKT(source))
Base.convert(::Type{<:GFT.WellKnownBinary}, source::AbstractGeometry) = 
    GFT.WellKnownBinary(GFT.Geom(), toWKB(source))
Base.convert(::Type{<:GFT.GeoJSON}, source::AbstractGeometry) = 
    GFT.GeoJSON(toJSON(source))
Base.convert(::Type{<:GFT.GML}, source::AbstractGeometry) = 
    GFT.GML(GFT.Geom(), toGML(source))
Base.convert(::Type{<:GFT.KML}, source::AbstractGeometry) = 
    GFT.KML(toKML(source))


# CRS conversions
Base.convert(target::Type{<:GFT.GeoFormat}, mode::GFT.CRS, source::GFT.GeoFormat) =
    unsafe_convertcrs(target, importCRS(source))

unsafe_convertcrs(::Type{<:GFT.CoordSys}, crsref) = 
    GFT.CoordSys(toMICoordSys(crsref))
unsafe_convertcrs(::Type{<:GFT.ProjString}, crsref) = 
    GFT.ProjString(toPROJ4(crsref))
unsafe_convertcrs(::Type{<:GFT.WellKnownText}, crsref) = 
    GFT.WellKnownText(GFT.CRS(), toWKT(crsref))
unsafe_convertcrs(::Type{<:GFT.ESRIWellKnownText}, crsref) =
    GFT.ESRIWellKnownText(toWKT(morphtoESRI!(crsref)))
unsafe_convertcrs(::Type{<:GFT.GML}, crsref) = 
    GFT.GML(toXML(crsref))

