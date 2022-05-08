using Extents

lookup_method = Dict(
    GeoInterface.PointTrait => createpoint,
    GeoInterface.MultiPointTrait => createmultipoint,
    GeoInterface.LineStringTrait => createlinestring,
    GeoInterface.LinearRingTrait => createlinearring,
    GeoInterface.MultiLineStringTrait => createmultilinestring,
    GeoInterface.PolygonTrait => createpolygon,
    GeoInterface.MultiPolygonTrait => createmultipolygon,
)

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

    GeometryTraits = Union{
        GeoInterface.PointTrait,
        GeoInterface.MultiPointTrait,
        GeoInterface.LineStringTrait,
        GeoInterface.LinearRingTrait,
        GeoInterface.MultiLineStringTrait,
        GeoInterface.PolygonTrait,
        GeoInterface.MultiPolygonTrait,
        GeoInterface.GeometryCollectionTrait,
    }

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

    function GeoInterface.ncoord(::GeometryTraits, geom::AbstractGeometry)
        return getcoorddim(geom)
    end

    function GeoInterface.getcoord(::GeometryTraits, geom::AbstractGeometry, i)
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

    function GeoInterface.isempty(::GeometryTraits, geom::AbstractGeometry)
        return isempty(geom)
    end

    function GeoInterface.ngeom(::GeometryTraits, geom::AbstractGeometry)
        return ngeom(geom)
    end

    function GeoInterface.getgeom(
        ::GeometryTraits,
        geom::AbstractGeometry,
        i::Integer,
    )
        return getgeom(geom, i - 1)
    end

    # Operations
    function GeoInterface.intersects(
        ::GeometryTraits,
        ::GeometryTraits,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return intersects(a, b)
    end
    function GeoInterface.equals(
        ::GeometryTraits,
        ::GeometryTraits,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return equals(a, b)
    end
    function GeoInterface.disjoint(
        ::GeometryTraits,
        ::GeometryTraits,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return disjoint(a, b)
    end
    function GeoInterface.touches(
        ::GeometryTraits,
        ::GeometryTraits,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return touches(a, b)
    end
    function GeoInterface.crosses(
        ::GeometryTraits,
        ::GeometryTraits,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return crosses(a, b)
    end
    function GeoInterface.within(
        ::GeometryTraits,
        ::GeometryTraits,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return within(a, b)
    end
    function GeoInterface.contains(
        ::GeometryTraits,
        ::GeometryTraits,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return contains(a, b)
    end
    function GeoInterface.overlaps(
        ::GeometryTraits,
        ::GeometryTraits,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return overlaps(a, b)
    end

    function GeoInterface.union(
        ::GeometryTraits,
        ::GeometryTraits,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return union(a, b)
    end
    function GeoInterface.intersection(
        ::GeometryTraits,
        ::GeometryTraits,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return intersection(a, b)
    end
    function GeoInterface.difference(
        ::GeometryTraits,
        ::GeometryTraits,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return difference(a, b)
    end
    function GeoInterface.symdifference(
        ::GeometryTraits,
        ::GeometryTraits,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return symdifference(a, b)
    end

    function GeoInterface.distance(
        ::GeometryTraits,
        ::GeometryTraits,
        a::AbstractGeometry,
        b::AbstractGeometry,
    )
        return distance(a, b)
    end

    function GeoInterface.length(::GeometryTraits, a::AbstractGeometry)
        return geomlength(a)
    end

    function GeoInterface.area(::GeometryTraits, a::AbstractGeometry)
        return geomarea(a)
    end

    function GeoInterface.buffer(::GeometryTraits, a::AbstractGeometry, d)
        return buffer(a, d)
    end

    function GeoInterface.convexhull(::GeometryTraits, a::AbstractGeometry)
        return convexhull(a)
    end

    function GeoInterface.extent(::GeometryTraits, a::AbstractGeometry)
        env = envelope3d(a)
        return Extent(
            X = (env.MinX, env.MaxX),
            Y = (env.MinY, env.MaxY),
            Z = (env.MinZ, env.MaxZ),
        )
    end

    function GeoInterface.asbinary(::GeometryTraits, a::AbstractGeometry)
        return toWKB(geom)
    end

    function GeoInterface.astext(::GeometryTraits, a::AbstractGeometry)
        return toWKT(geom)
    end

    function GeoInterface.convert(::Type{IGeometry}, type::GeometryTraits, geom)
        f = get(lookup_method, typeof(type), nothing)
        isnothing(f) || error(
            "Cannot convert an object of $(typeof(geom)) with the $(typeof(type)) trait (yet). Please report an issue.",
        )
        return f(GeoInterface.coordinates(geom))
    end
end
