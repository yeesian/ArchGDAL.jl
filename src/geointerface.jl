using Extents

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
            GeoInterface.PointTrait()
        elseif gtype in multipointtypes
            GeoInterface.MultiPointTrait()
        elseif gtype in linetypes
            GeoInterface.LineStringTrait()
        elseif gtype == wkbLinearRing
            GeoInterface.LinearRingTrait()
        elseif gtype in multilinetypes
            GeoInterface.MultiLineStringTrait()
        elseif gtype in polygontypes
            GeoInterface.PolygonTrait()
        elseif gtype in multipolygontypes
            GeoInterface.MultiPolygonTrait()
        elseif gtype in collectiontypes
            GeoInterface.GeometryCollectionTrait()
        else
            @warn "unknown geometry type" gtype
            nothing
        end
    end

    function GeoInterface.ncoord(
        ::GeoInterface.AbstractGeometryTrait,
        geom::AbstractGeometry,
    )
        return getcoorddim(geom)
    end

    function GeoInterface.getcoord(
        ::GeoInterface.AbstractGeometryTrait,
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
        ::GeoInterface.AbstractGeometryTrait,
        geom::AbstractGeometry,
    )
        return ngeom(geom)
    end

    function GeoInterface.getgeom(
        ::GeoInterface.AbstractGeometryTrait,
        geom::AbstractGeometry,
        i::Integer,
    )
        return getgeom(geom, i - 1)
    end

    # Operations
    function GeoInterface.intersects(
        ::GeoInterface.AbstractGeometryTrait,
        ::GeoInterface.AbstractGeometryTrait,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return intersects(a, b)
    end
    function GeoInterface.equals(
        ::GeoInterface.AbstractGeometryTrait,
        ::GeoInterface.AbstractGeometryTrait,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return equals(a, b)
    end
    function GeoInterface.disjoint(
        ::GeoInterface.AbstractGeometryTrait,
        ::GeoInterface.AbstractGeometryTrait,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return disjoint(a, b)
    end
    function GeoInterface.touches(
        ::GeoInterface.AbstractGeometryTrait,
        ::GeoInterface.AbstractGeometryTrait,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return touches(a, b)
    end
    function GeoInterface.crosses(
        ::GeoInterface.AbstractGeometryTrait,
        ::GeoInterface.AbstractGeometryTrait,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return crosses(a, b)
    end
    function GeoInterface.within(
        ::GeoInterface.AbstractGeometryTrait,
        ::GeoInterface.AbstractGeometryTrait,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return within(a, b)
    end
    function GeoInterface.contains(
        ::GeoInterface.AbstractGeometryTrait,
        ::GeoInterface.AbstractGeometryTrait,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return contains(a, b)
    end
    function GeoInterface.overlaps(
        ::GeoInterface.AbstractGeometryTrait,
        ::GeoInterface.AbstractGeometryTrait,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return overlaps(a, b)
    end

    function GeoInterface.union(
        ::GeoInterface.AbstractGeometryTrait,
        ::GeoInterface.AbstractGeometryTrait,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return union(a, b)
    end
    function GeoInterface.intersection(
        ::GeoInterface.AbstractGeometryTrait,
        ::GeoInterface.AbstractGeometryTrait,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return intersection(a, b)
    end
    function GeoInterface.difference(
        ::GeoInterface.AbstractGeometryTrait,
        ::GeoInterface.AbstractGeometryTrait,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return difference(a, b)
    end
    function GeoInterface.symdifference(
        ::GeoInterface.AbstractGeometryTrait,
        ::GeoInterface.AbstractGeometryTrait,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return symdifference(a, b)
    end
    function GeoInterface.symdifference(
        ::GeoInterface.AbstractGeometryTrait,
        ::GeoInterface.AbstractGeometryTrait,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return symdifference(a, b)
    end

    function GeoInterface.distance(
        ::GeoInterface.AbstractGeometryTrait,
        ::GeoInterface.AbstractGeometryTrait,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return distance(a, b)
    end

    function GeoInterface.length(
        ::GeoInterface.AbstractGeometryTrait,
        a::AbstractGeometry,
    )
        return geomlength(a)
    end

    function GeoInterface.area(
        ::GeoInterface.AbstractGeometryTrait,
        a::AbstractGeometry,
    )
        return geomarea(a)
    end

    function GeoInterface.buffer(
        ::GeoInterface.AbstractGeometryTrait,
        a::AbstractGeometry,
        d,
    )
        return buffer(a, d)
    end

    function GeoInterface.convexhull(
        ::GeoInterface.AbstractGeometryTrait,
        a::AbstractGeometry,
    )
        return convexhull(a)
    end

    function GeoInterface.extent(
        ::GeoInterface.AbstractGeometryTrait,
        a::AbstractGeometry,
    )
        env = envelope3d(a)
        return Extent(
            X = (env.MinX, env.MaxX),
            Y = (env.MinY, env.MaxY),
            Z = (env.MinZ, env.MaxZ),
        )
    end
end
