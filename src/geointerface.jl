let pointtypes = (wkbPoint, wkbPoint25D, wkbPointM, wkbPointZM),
    multipointtypes = (wkbMultiPoint, wkbMultiPoint25D, wkbMultiPointM,
        wkbMultiPointZM),
    linetypes = (wkbLineString, wkbLineString25D, wkbLineStringM,
        wkbLineStringZM),
    multilinetypes = (wkbMultiLineString, wkbMultiLineString25D,
        wkbMultiLineStringM, wkbMultiLineStringZM),
    polygontypes = (wkbPolygon, wkbPolygon25D, wkbPolygonM, wkbPolygonZM),
    multipolygontypes = (wkbMultiPolygon, wkbMultiPolygon25D, wkbMultiPolygonM,
        wkbMultiPolygonZM),
    collectiontypes = (wkbGeometryCollection, wkbGeometryCollection25D,
        wkbGeometryCollectionM, wkbGeometryCollectionZM)

    function GeoInterface.geotype(g::AbstractGeometry)::Symbol
        gtype = getgeomtype(g)
        return if gtype in pointtypes
            :Point
        elseif gtype in multipointtypes
            :MultiPoint
        elseif gtype in linetypes
            :LineString
        elseif gtype == wkbLinearRing
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
        elseif gtype in linetypes || gtype == wkbLinearRing
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
