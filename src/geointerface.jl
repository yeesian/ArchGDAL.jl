function GeoInterface.geotype(g::AbstractGeometry)
    gtype = getgeomtype(g)
    if gtype in (GDAL.wkbPoint, GDAL.wkbPoint25D, GDAL.wkbPointM, GDAL.wkbPointZM)
        return :Point
    elseif gtype in (GDAL.wkbMultiPoint, GDAL.wkbMultiPoint25D, GDAL.wkbMultiPointM, GDAL.wkbMultiPointZM)
        return :MultiPoint
    elseif gtype in (GDAL.wkbLineString, GDAL.wkbLineString25D, GDAL.wkbLineStringM, GDAL.wkbLineStringZM)
        return :LineString
    elseif gtype == GDAL.wkbLinearRing
        return :LinearRing
    elseif gtype in (GDAL.wkbMultiLineString, GDAL.wkbMultiLineString25D, GDAL.wkbMultiLineStringM, GDAL.wkbMultiLineStringZM)
        return :MultiLineString
    elseif gtype in (GDAL.wkbPolygon, GDAL.wkbPolygon25D, GDAL.wkbPolygonM, GDAL.wkbPolygonZM)
        return :Polygon
    elseif gtype in (GDAL.wkbMultiPolygon, GDAL.wkbMultiPolygon25D, GDAL.wkbMultiPolygonM, GDAL.wkbMultiPolygonZM)
        return :MultiPolygon
    elseif gtype in (GDAL.wkbGeometryCollection, GDAL.wkbGeometryCollection25D, GDAL.wkbGeometryCollectionM, GDAL.wkbGeometryCollectionZM)
        return :GeometryCollection
    else
        warn("unknown geometry type: $gtype")
        return :Unknown
    end
end

function GeoInterface.coordinates(g::AbstractGeometry)
    gtype = getgeomtype(g)
    ndim = getcoorddim(g)
    if gtype in (GDAL.wkbPoint, GDAL.wkbPoint25D, GDAL.wkbPointM, GDAL.wkbPointZM)
        if ndim == 2
            return Float64[getx(g,0), gety(g,0)]
        elseif ndim == 3
            return Float64[getx(g,0), gety(g,0), getz(g,0)]
        else
            @assert ndim == 0
            warn("Empty Point")
        end
    elseif gtype in (GDAL.wkbMultiPoint, GDAL.wkbMultiPoint25D, GDAL.wkbMultiPointM, GDAL.wkbMultiPointZM)
        return Vector{Float64}[
            GeoInterface.coordinates(getgeom(g,i-1)) for i in 1:ngeom(g)
        ]
    elseif gtype in (GDAL.wkbLineString, GDAL.wkbLineString25D, GDAL.wkbLineStringM, GDAL.wkbLineStringZM) || gtype == GDAL.wkbLinearRing
        return Vector{Float64}[
            collect(getpoint(g,i-1)[1:ndim]) for i in 1:npoint(g)
        ]
    elseif gtype in (
            GDAL.wkbMultiLineString, GDAL.wkbMultiLineString25D, GDAL.wkbMultiLineStringM, GDAL.wkbMultiLineStringZM,
            GDAL.wkbPolygon, GDAL.wkbPolygon25D, GDAL.wkbPolygonM, GDAL.wkbPolygonZM
        )
        return Vector{Vector{Float64}}[
            GeoInterface.coordinates(getgeom(g,i-1)) for i in 1:ngeom(g)
        ]
    elseif gtype in (GDAL.wkbMultiPolygon, GDAL.wkbMultiPolygon25D, GDAL.wkbMultiPolygonM, GDAL.wkbMultiPolygonZM)
        return Vector{Vector{Vector{Float64}}}[
            GeoInterface.coordinates(getgeom(g,i-1)) for i in 1:ngeom(g)
        ]
    end
end
