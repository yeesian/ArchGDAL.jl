# This file contains friendly type-pyracy on `convert` for GeoFormatTypes.jl types

"""
    convert(::Type{<:AbstractGeometry}, mode::Geom source::GeoFormat)

Convert a GeoFromat object to Geometry, then to the target format.
The Geom trait is needed to separate out convert for CRS for WellKnownText
and GML, which may contain both.
"""
Base.convert(target::Type{<:GFT.GeoFormat}, mode::Union{GFT.FormatMode,Type{GFT.FormatMode}}, 
             source::GFT.GeoFormat; kwargs...) =
    convert(target, convert(AbstractGeometry, source); kwargs...)

"""
    convert(::Type{<:AbstractGeometry}, source::GeoFormat)

Convert `GeoFormat` geometry data to an ArchGDAL `Geometry` type
"""
Base.convert(::Type{<:AbstractGeometry}, source::GFT.AbstractWellKnownText; kwargs...) = 
    fromWKT(GFT.val(source); kwargs...)
Base.convert(::Type{<:AbstractGeometry}, source::GFT.WellKnownBinary; kwargs...) = 
    fromWKB(GFT.val(source); kwargs...)
Base.convert(::Type{<:AbstractGeometry}, source::GFT.GeoJSON; kwargs...) = 
    fromJSON(GFT.val(source); kwargs...)
Base.convert(::Type{<:AbstractGeometry}, source::GFT.GML; kwargs...) = 
    fromGML(GFT.val(source); kwargs...)

"""
    convert(::Type{<:AbstractGeometry}, source::GeoFormat)

Convert `AbstractGeometry` data to any gemoetry `GeoFormat` 
"""
Base.convert(::Type{<:GFT.AbstractWellKnownText}, source::AbstractGeometry; kwargs...) = 
    GFT.WellKnownText(GFT.Geom(), toWKT(source; kwargs...))
Base.convert(::Type{<:GFT.WellKnownBinary}, source::AbstractGeometry; kwargs...) = 
    GFT.WellKnownBinary(GFT.Geom(), toWKB(source; kwargs...))
Base.convert(::Type{<:GFT.GeoJSON}, source::AbstractGeometry; kwargs...) = 
    GFT.GeoJSON(toJSON(source; kwargs...))
Base.convert(::Type{<:GFT.GML}, source::AbstractGeometry; kwargs...) = 
    GFT.GML(GFT.Geom(), toGML(source; kwargs...))
Base.convert(::Type{<:GFT.KML}, source::AbstractGeometry; kwargs...) = 
    GFT.KML(toKML(source; kwargs...))


"""
    convert(target::Type{GeoFormat}, mode::CRS, source::GeoFormat)

Convert `GeoFormat` crs data to another another `GeoFormat` crs type.
"""
Base.convert(target::Type{<:GFT.GeoFormat}, mode::Union{GFT.CRS,Type{GFT.CRS}}, 
             source::GFT.GeoFormat; kwargs...) =
    importCRS(source; kwargs...) do crs
        unsafe_convertcrs(target, crs)
    end

unsafe_convertcrs(::Type{<:GFT.CoordSys}, crsref; kwargs...) = 
    GFT.CoordSys(toMICoordSys(crsref; kwargs...))
unsafe_convertcrs(::Type{<:GFT.ProjString}, crsref; kwargs...) = 
    GFT.ProjString(toPROJ4(crsref; kwargs...))
unsafe_convertcrs(::Type{<:GFT.WellKnownText}, crsref; kwargs...) = 
    GFT.WellKnownText(GFT.CRS(), toWKT(crsref; kwargs...))
unsafe_convertcrs(::Type{<:GFT.ESRIWellKnownText}, crsref; kwargs...) =
    GFT.ESRIWellKnownText(GFT.CRS(), toWKT(morphtoESRI!(crsref; kwargs...)))
unsafe_convertcrs(::Type{<:GFT.GML}, crsref; kwargs...) = 
    GFT.GML(toXML(crsref; kwargs...))

