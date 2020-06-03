# This file contains friendly type-pyracy on `convert` for GeoFormatTypes.jl types

"""
    convert(::Type{<:AbstractGeometry}, mode::Geom source::GeoFormat)

Convert a GeoFromat object to Geometry, then to the target format.
The Geom trait is needed to separate out convert for CRS for WellKnownText
and GML, which may contain both.

Both `Geom` and `Mixed` formats are converted to Geometries by default. 
To convert a `Mixed` format to crs, `CRS` must be explicitly passed for `mode`.
"""
Base.convert(target::Type{<:GFT.GeoFormat}, mode::Union{GFT.FormatMode,Type{GFT.FormatMode}}, 
             source::GFT.GeoFormat) =
    convert(target, convert(AbstractGeometry, source))

"""
    convert(::Type{<:AbstractGeometry}, source::GeoFormat)

Convert `GeoFormat` geometry data to an ArchGDAL `Geometry` type
"""
Base.convert(::Type{<:AbstractGeometry}, source::GFT.AbstractWellKnownText) = 
    fromWKT(GFT.val(source))
Base.convert(::Type{<:AbstractGeometry}, source::GFT.WellKnownBinary) = 
    fromWKB(GFT.val(source))
Base.convert(::Type{<:AbstractGeometry}, source::GFT.GeoJSON) = 
    fromJSON(GFT.val(source))
Base.convert(::Type{<:AbstractGeometry}, source::GFT.GML) = 
    fromGML(GFT.val(source))

"""
    convert(::Type{<:AbstractGeometry}, source::GeoFormat)

Convert `AbstractGeometry` data to any gemoetry `GeoFormat` 
"""
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


"""
    convert(target::Type{GeoFormat}, mode::CRS, source::GeoFormat)

Convert `GeoFormat` crs data to another another `GeoFormat` crs type.
"""
Base.convert(target::Type{<:GFT.GeoFormat}, mode::Union{GFT.CRS,Type{GFT.CRS}}, 
             source::GFT.GeoFormat) =
    unsafe_convertcrs(target, importCRS(source))

unsafe_convertcrs(::Type{<:GFT.CoordSys}, crsref) = 
    GFT.CoordSys(toMICoordSys(crsref))
unsafe_convertcrs(::Type{<:GFT.ProjString}, crsref) = 
    GFT.ProjString(toPROJ4(crsref))
unsafe_convertcrs(::Type{<:GFT.WellKnownText}, crsref) = 
    GFT.WellKnownText(GFT.CRS(), toWKT(crsref))
unsafe_convertcrs(::Type{<:GFT.ESRIWellKnownText}, crsref) =
    GFT.ESRIWellKnownText(GFT.CRS(), toWKT(morphtoESRI!(crsref)))
unsafe_convertcrs(::Type{<:GFT.GML}, crsref) = 
    GFT.GML(toXML(crsref))

