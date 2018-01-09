function GeoInterface.geotype(g::AbstractGeometry)
    gtype = getgeomtype(g)
    if gtype == GDAL.wkbPoint
        return :Point
    elseif gtype == GDAL.wkbMultiPoint
        return :MultiPoint
    elseif gtype == GDAL.wkbLineString
        return :LineString
    elseif gtype == GDAL.wkbLinearRing
        return :LinearRing
    elseif gtype == GDAL.wkbMultiLineString
        return :MultiLineString
    elseif gtype == GDAL.wkbPolygon
        return :Polygon
    elseif gtype == GDAL.wkbMultiPolygon
        return :MultiPolygon
    else
        warn("unknown geometry type: $gtype")
        return :Unknown
    end
end

function GeoInterface.coordinates(g::AbstractGeometry)
    gtype = getgeomtype(g)
    ndim = getcoorddim(g)
    if gtype == GDAL.wkbPoint
        if ndim == 2
            return Float64[getx(g,0), gety(g,0)]
        elseif ndim == 3
            return Float64[getx(g,0), gety(g,0), getz(g,0)]
        else
            @assert ndim == 0
            warn("Empty Point")
        end
    elseif gtype == GDAL.wkbMultiPoint
        return Vector{Float64}[
            GeoInterface.coordinates(getgeom(g,i-1)) for i in 1:ngeom(g)
        ]
    elseif gtype == GDAL.wkbLineString || gtype == GDAL.wkbLinearRing
        return Vector{Float64}[
            collect(getpoint(g,i-1)[1:ndim]) for i in 1:npoint(g)
        ]
    elseif gtype == GDAL.wkbMultiLineString || gtype == GDAL.wkbPolygon
        return Vector{Vector{Float64}}[
            GeoInterface.coordinates(getgeom(g,i-1)) for i in 1:ngeom(g)
        ]
    elseif gtype == GDAL.wkbMultiPolygon
        return Vector{Vector{Vector{Float64}}}[
            GeoInterface.coordinates(getgeom(g,i-1)) for i in 1:ngeom(g)
        ]
    end
end
