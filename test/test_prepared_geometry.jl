using Test
import ArchGDAL as AG

@testset "Prepared Geometry" begin
    point = AG.createpoint(1.0, 1.0)
    polygon = AG.createpolygon([
        [1.0, 2.0, 3.0],
        [4.0, 5.0, 6.0],
        [7.0, 8.0, 9.0],
        [1.0, 2.0, 3.0],
    ])

    @test AG.has_preparedgeom_support()

    prep_polygon = AG.preparegeom(polygon)
    @test prep_polygon isa AG.IPreparedGeometry{AG.wkbPolygon}
    unsafe_prep_polygon = AG.unsafe_preparegeom(polygon)
    @test unsafe_prep_polygon isa AG.PreparedGeometry{AG.wkbPolygon}
    AG.destroy(unsafe_prep_polygon)

    ir1 = AG.intersects(polygon, point)
    ir2 = AG.intersects(prep_polygon, point)
    @test ir1 === ir2

    or1 = AG.contains(polygon, point)
    or2 = AG.contains(prep_polygon, point)
    @test or1 === or2

    @testset "copy and deepcopy" begin
        # GDAL exposes no clone for OGRPreparedGeometryH and no way to recover
        # the source geometry from the handle, so a prepared geometry keeps a
        # reference to what it was prepared from and copies re-prepare from it.
        @test prep_polygon.basegeom === polygon

        for prep_copy in (copy(prep_polygon), deepcopy(prep_polygon))
            @test prep_copy isa AG.IPreparedGeometry{AG.wkbPolygon}
            @test prep_copy.ptr != prep_polygon.ptr
            # the copy owns its base geometry, rather than sharing `polygon`
            @test prep_copy.basegeom isa AG.IGeometry{AG.wkbPolygon}
            @test prep_copy.basegeom !== polygon
            @test prep_copy.basegeom.ptr != polygon.ptr
            @test AG.equals(prep_copy.basegeom, polygon)
            @test AG.intersects(prep_copy, point) === ir1
            @test AG.contains(prep_copy, point) === or1
        end

        # a copy stays usable after the geometry it was prepared from is gone
        survivor = deepcopy(prep_polygon)
        AG.destroy(polygon)
        @test AG.intersects(survivor, point) === ir1

        # `copy` is type-preserving here too: the caller-managed
        # `PreparedGeometry` copies to a `PreparedGeometry`
        unsafe_prep = AG.unsafe_preparegeom(survivor.basegeom)
        unsafe_copy = copy(unsafe_prep)
        @test unsafe_copy isa AG.PreparedGeometry{AG.wkbPolygon}
        @test unsafe_copy.ptr != unsafe_prep.ptr
        @test AG.intersects(unsafe_copy, point) === ir1
        AG.destroy(unsafe_copy)
        AG.destroy(unsafe_prep)
    end
end
