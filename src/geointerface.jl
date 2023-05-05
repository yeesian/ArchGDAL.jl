using Extents

geointerface_geomtype(::GeoInterface.AbstractGeometryTrait) = IGeometry

const lookup_method = Dict{DataType,Function}(
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
        GeoInterface.CircularStringTrait,
        GeoInterface.CompoundCurveTrait,
        GeoInterface.CurvePolygonTrait,
        GeoInterface.MultiSurfaceTrait,
        GeoInterface.PolyhedralSurfaceTrait,
        GeoInterface.TINTrait,
        GeoInterface.TriangleTrait,
    }

    # Feature
    GeoInterface.isfeature(feat::AbstractFeature) = true
    function GeoInterface.properties(feat::AbstractFeature)
        return (; (zip(Symbol.(keys(feat)), values(feat)))...)
    end
    GeoInterface.geometry(feat::AbstractFeature) = getgeom(feat, 0)

    GeoInterface.isgeometry(::Type{<:AbstractGeometry}) = true
    @enable_geo_plots AbstractGeometry
    GeoInterface.is3d(::GeometryTraits, geom::AbstractGeometry) = is3d(geom)
    function GeoInterface.ismeasured(::GeometryTraits, geom::AbstractGeometry)
        return ismeasured(geom)
    end

    function GeoInterface.ncoord(::GeometryTraits, geom::AbstractGeometry)
        return getcoorddim(geom)
    end

    function GeoInterface.x(
        ::GeoInterface.AbstractPointTrait,
        geom::AbstractGeometry,
    )
        return getx(geom, 0)
    end
    function GeoInterface.y(
        ::GeoInterface.AbstractPointTrait,
        geom::AbstractGeometry,
    )
        return gety(geom, 0)
    end
    function GeoInterface.z(
        ::GeoInterface.AbstractPointTrait,
        geom::AbstractGeometry,
    )
        geom isa _AbstractGeometry3d || throw(ArgumentError("Geometry does not have `Z` values")) 
        return getz(geom, 0)
    end
    function GeoInterface.m(
        ::GeoInterface.AbstractPointTrait,
        geom::AbstractGeometry,
    )
        geom isa _AbstractGeometryHasM || throw(ArgumentError("Geometry does not have `M` values")) 
        return getm(geom, 0)
    end

    function GeoInterface.getcoord(
        ::GeoInterface.AbstractPointTrait,
        geom::AbstractGeometry,
        i::Integer,
    )
        if i == 1
            getx(geom, 0)
        elseif i == 2
            gety(geom, 0)
        elseif i == 3 && is3d(geom)
            getz(geom, 0)
        elseif i == 3 && ismeasured(geom)
            getm(geom, 0)
        elseif i == 4 && ismeasured(geom) && is3d(geom)
            getm(geom, 0)
        else
            _getcoord_error(i)
        end
    end

    @noinline function _getcoord_error(i)
        throw(ArgumentError("Invalid getcoord index $i, must be between 1 and 2/3/4."))
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
        if GeoInterface.is3d(a)
            env = envelope3d(a)
            return Extent(
                X = (env.MinX, env.MaxX),
                Y = (env.MinY, env.MaxY),
                Z = (env.MinZ, env.MaxZ),
            )
        else
            env = envelope(a)
            return Extent(X = (env.MinX, env.MaxX), Y = (env.MinY, env.MaxY))
        end
    end

    function GeoInterface.asbinary(::GeometryTraits, geom::AbstractGeometry)
        return toWKB(geom)
    end

    function GeoInterface.astext(::GeometryTraits, geom::AbstractGeometry)
        return toWKT(geom)
    end

    function GeoInterface.convert(
        ::Type{T},
        type::GeometryTraits,
        geom,
    ) where {T<:IGeometry}
        f = get(lookup_method, typeof(type), nothing)
        isnothing(f) && error(
            "Cannot convert an object of $(typeof(geom)) with the $(typeof(type)) trait (yet). Please report an issue.",
        )
        return f(GeoInterface.coordinates(geom))
    end

    function GeoInterface.geomtrait(
        geom::Union{map(T -> AbstractGeometry{T}, pointtypes)...},
    )
        return GeoInterface.PointTrait()
    end
    function GeoInterface.geomtrait(
        geom::Union{map(T -> AbstractGeometry{T}, multipointtypes)...},
    )
        return GeoInterface.MultiPointTrait()
    end
    function GeoInterface.geomtrait(
        geom::Union{map(T -> AbstractGeometry{T}, linetypes)...},
    )
        return GeoInterface.LineStringTrait()
    end
    function GeoInterface.geomtrait(
        geom::Union{map(T -> AbstractGeometry{T}, multilinetypes)...},
    )
        return GeoInterface.MultiLineStringTrait()
    end
    function GeoInterface.geomtrait(
        geom::Union{map(T -> AbstractGeometry{T}, polygontypes)...},
    )
        return GeoInterface.PolygonTrait()
    end
    function GeoInterface.geomtrait(
        geom::Union{map(T -> AbstractGeometry{T}, multipolygontypes)...},
    )
        return GeoInterface.MultiPolygonTrait()
    end
    function GeoInterface.geomtrait(
        geom::Union{map(T -> AbstractGeometry{T}, collectiontypes)...},
    )
        return GeoInterface.GeometryCollectionTrait()
    end
    function GeoInterface.geomtrait(geom::AbstractGeometry{wkbLinearRing})
        return GeoInterface.LinearRingTrait()
    end
    function GeoInterface.geomtrait(geom::AbstractGeometry{wkbCircularString})
        return GeoInterface.CircularStringTrait()
    end
    function GeoInterface.geomtrait(geom::AbstractGeometry{wkbCompoundCurve})
        return GeoInterface.CompoundCurveTrait()
    end
    function GeoInterface.geomtrait(geom::AbstractGeometry{wkbCurvePolygon})
        return GeoInterface.CurvePolygonTrait()
    end
    function GeoInterface.geomtrait(geom::AbstractGeometry{wkbMultiSurface})
        return GeoInterface.MultiSurfaceTrait()
    end
    function GeoInterface.geomtrait(
        geom::AbstractGeometry{wkbPolyhedralSurface},
    )
        return GeoInterface.PolyhedralSurfaceTrait()
    end
    function GeoInterface.geomtrait(geom::AbstractGeometry{wkbTIN})
        return GeoInterface.TINTrait()
    end
    function GeoInterface.geomtrait(geom::AbstractGeometry{wkbTriangle})
        return GeoInterface.TriangleTrait()
    end
end
