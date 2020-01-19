let pointtypes = (GDAL.wkbPoint, GDAL.wkbPoint25D, GDAL.wkbPointM,
        GDAL.wkbPointZM),
    multipointtypes = (GDAL.wkbMultiPoint, GDAL.wkbMultiPoint25D,
        GDAL.wkbMultiPointM, GDAL.wkbMultiPointZM),
    linetypes = (GDAL.wkbLineString, GDAL.wkbLineString25D, GDAL.wkbLineStringM,
        GDAL.wkbLineStringZM),
    multilinetypes = (GDAL.wkbMultiLineString, GDAL.wkbMultiLineString25D,
        GDAL.wkbMultiLineStringM, GDAL.wkbMultiLineStringZM),
    polygontypes = (GDAL.wkbPolygon, GDAL.wkbPolygon25D, GDAL.wkbPolygonM,
        GDAL.wkbPolygonZM),
    multipolygontypes = (GDAL.wkbMultiPolygon, GDAL.wkbMultiPolygon25D,
        GDAL.wkbMultiPolygonM, GDAL.wkbMultiPolygonZM),
    collectiontypes = (GDAL.wkbGeometryCollection,
        GDAL.wkbGeometryCollection25D, GDAL.wkbGeometryCollectionM,
        GDAL.wkbGeometryCollectionZM)

    function GeoInterface.geotype(g::AbstractGeometry)
        gtype = getgeomtype(g)
        if gtype in pointtypes
            return :Point
        elseif gtype in multipointtypes
            return :MultiPoint
        elseif gtype in linetypes
            return :LineString
        elseif gtype == GDAL.wkbLinearRing
            return :LinearRing
        elseif gtype in multilinetypes
            return :MultiLineString
        elseif gtype in polygontypes
            return :Polygon
        elseif gtype in multipolygontypes
            return :MultiPolygon
        elseif gtype in collectiontypes
            return :GeometryCollection
        else
            @warn "unknown geometry type" gtype
            return :Unknown
        end
    end

    function GeoInterface.coordinates(g::AbstractGeometry)
        gtype = getgeomtype(g)
        ndim = getcoorddim(g)
        if gtype in pointtypes
            if ndim == 2
                return Float64[getx(g,0), gety(g,0)]
            elseif ndim == 3
                return Float64[getx(g,0), gety(g,0), getz(g,0)]
            else
                @assert ndim == 0
                @warn("Empty Point")
            end
        elseif gtype in multipointtypes
            return Vector{Float64}[
                GeoInterface.coordinates(getgeom(g,i-1)) for i in 1:ngeom(g)
            ]
        elseif gtype in linetypes || gtype == GDAL.wkbLinearRing
            return Vector{Float64}[
                collect(getpoint(g,i-1)[1:ndim]) for i in 1:ngeom(g)
            ]
        elseif gtype in multilinetypes || gtype in polygontypes
            return Vector{Vector{Float64}}[
                GeoInterface.coordinates(getgeom(g,i-1)) for i in 1:ngeom(g)
            ]
        elseif gtype in multipolygontypes
            return Vector{Vector{Vector{Float64}}}[
                GeoInterface.coordinates(getgeom(g,i-1)) for i in 1:ngeom(g)
            ]
        end
    end

end