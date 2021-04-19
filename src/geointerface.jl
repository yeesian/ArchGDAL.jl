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
        return if gtype in pointtypes
            :Point
        elseif gtype in multipointtypes
            :MultiPoint
        elseif gtype in linetypes
            :LineString
        elseif gtype == GDAL.wkbLinearRing
            :LinearRing
        elseif gtype in multilinetypes
            :MultiLineString
        elseif gtype in polygontypes
            :Polygon
        elseif gtype in multipolygontypes
            :MultiPolygon
        elseif gtype in collectiontypes
            :GeometryCollection
        else
            @warn "unknown geometry type" gtype
            :Unknown
        end
    end

    function GeoInterface.coordinates(g::AbstractGeometry)
        gtype = getgeomtype(g)
        ndim = getcoorddim(g)
        return if gtype in pointtypes
            if ndim == 2
                Float64[getx(g,0), gety(g,0)]
            elseif ndim == 3
                Float64[getx(g,0), gety(g,0), getz(g,0)]
            else
                @assert ndim == 0
                @warn("Empty Point")
                nothing
            end
        elseif gtype in multipointtypes
            Vector{Float64}[
                GeoInterface.coordinates(getgeom(g,i-1)) for i in 1:ngeom(g)
            ]
        elseif gtype in linetypes || gtype == GDAL.wkbLinearRing
            Vector{Float64}[
                collect(getpoint(g,i-1)[1:ndim]) for i in 1:ngeom(g)
            ]
        elseif gtype in multilinetypes || gtype in polygontypes
            Vector{Vector{Float64}}[
                GeoInterface.coordinates(getgeom(g,i-1)) for i in 1:ngeom(g)
            ]
        elseif gtype in multipolygontypes
            Vector{Vector{Vector{Float64}}}[
                GeoInterface.coordinates(getgeom(g,i-1)) for i in 1:ngeom(g)
            ]
        end
    end

end