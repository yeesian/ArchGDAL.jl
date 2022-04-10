let pointtypes = (wkbPoint, wkbPoint25D, wkbPointM, wkbPointZM),
    multipointtypes =
        (wkbMultiPoint, wkbMultiPoint25D, wkbMultiPointM, wkbMultiPointZM),
    linetypes =
        (wkbLineString, wkbLineString25D, wkbLineStringM, wkbLineStringZM),
    multilinetypes = (
        wkbMultiLineString,
        wkbMultiLineString25D,
        wkbMultiLineStringM,
        wkbMultiLineStringZM,
    ),
    polygontypes = (wkbPolygon, wkbPolygon25D, wkbPolygonM, wkbPolygonZM),
    multipolygontypes = (
        wkbMultiPolygon,
        wkbMultiPolygon25D,
        wkbMultiPolygonM,
        wkbMultiPolygonZM,
    ),
    collectiontypes = (
        wkbGeometryCollection,
        wkbGeometryCollection25D,
        wkbGeometryCollectionM,
        wkbGeometryCollectionZM,
    )

    twodtypes = (
        wkbMultiPoint,
        wkbLineString,
        wkbMultiLineString,
        wkbPolygon,
        wkbMultiPolygon,
        wkbGeometryCollection,
    )
    threedtypes = (
        wkbPoint25D,
        wkbMultiPoint25D,
        wkbLineString25D,
        wkbMultiLineString25D,
        wkbPolygon25D,
        wkbMultiPolygon25D,
        wkbGeometryCollection25D,
        wkbPointM,
        wkbMultiPointM,
        wkbLineStringM,
        wkbMultiLineStringM,
        wkbPolygonM,
        wkbMultiPolygonM,
        wkbGeometryCollectionM,
    )
    mtypes = (
        wkbPointM,
        wkbMultiPointM,
        wkbLineStringM,
        wkbMultiLineStringM,
        wkbPolygonM,
        wkbMultiPolygonM,
        wkbGeometryCollectionM,
    )
    fourdtypes = (
        wkbPointZM,
        wkbMultiPointZM,
        wkbLineStringZM,
        wkbMultiLineStringZM,
        wkbPolygonZM,
        wkbMultiPolygonZM,
        wkbGeometryCollectionZM,
    )
    hasztypes = (
        wkbPoint25D,
        wkbMultiPoint25D,
        wkbLineString25D,
        wkbMultiLineString25D,
        wkbPolygon25D,
        wkbMultiPolygon25D,
        wkbGeometryCollection25D,
        wkbPointZM,
        wkbMultiPointZM,
        wkbLineStringZM,
        wkbMultiLineStringZM,
        wkbPolygonZM,
        wkbMultiPolygonZM,
        wkbGeometryCollectionZM,
    )
    hasmtypes = (
        wkbPointM,
        wkbMultiPointM,
        wkbLineStringM,
        wkbMultiLineStringM,
        wkbPolygonM,
        wkbMultiPolygonM,
        wkbGeometryCollectionM,
        wkbPointZM,
        wkbMultiPointZM,
        wkbLineStringZM,
        wkbMultiLineStringZM,
        wkbPolygonZM,
        wkbMultiPolygonZM,
        wkbGeometryCollectionZM,
    )

    GeoInterface.isgeometry(geom::AbstractGeometry) = true
    function GeoInterface.geomtype(geom::AbstractGeometry)
        # TODO Dispatch directly once #266 is merged
        gtype = getgeomtype(geom)
        return if gtype in pointtypes
            GeoInterface.Point
        elseif gtype in multipointtypes
            GeoInterface.MultiPoint
        elseif gtype in linetypes
            GeoInterface.LineString
        elseif gtype == wkbLinearRing
            GeoInterface.LinearRing
        elseif gtype in multilinetypes
            GeoInterface.MultiLineString
        elseif gtype in polygontypes
            GeoInterface.Polygon
        elseif gtype in multipolygontypes
            GeoInterface.MultiPolygon
        elseif gtype in collectiontypes
            GeoInterface.GeometryCollection
        else
            @warn "unknown geometry type" gtype
            nothing
        end
    end

    function GeoInterface.ncoord(
        ::Type{<:GeoInterface.AbstractGeometry},
        geom::AbstractGeometry,
    )
        return getcoorddim(geom)
    end

    function GeoInterface.getcoord(
        ::Type{<:GeoInterface.AbstractGeometry},
        geom::AbstractGeometry,
        i,
    )
        if i == 1
            getx(geom, 0)
        elseif i == 2
            gety(geom, 0)
        elseif i == 3  # M is an option here, but not properly supported by ArchGDAL yet
            getm(geom, 0)
        elseif i == 4
            getm(geom, 0)
        else
            return nothing
        end
    end

    function GeoInterface.ngeom(
        ::Type{<:GeoInterface.AbstractGeometry},
        geom::AbstractGeometry,
    )
        return ngeom(geom)
    end

    function GeoInterface.getgeom(
        ::Type{<:GeoInterface.AbstractGeometry},
        geom::AbstractGeometry,
        i::Integer,
    )
        return getgeom(geom, i - 1)
    end
end
