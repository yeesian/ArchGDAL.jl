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

    prep_polygon = AG.preparegeom(polygon)  # this segfaults
    unsafe_prep_polygon = AG.unsafe_preparegeom(polygon)
    @test isa(unsafe_prep_polygon, AG.PreparedGeometry)
    AG.destroy(unsafe_prep_polygon)

    ir1 = AG.intersects(polygon, point)
    ir2 = AG.intersects(prep_polygon, point)
    @test ir1 === ir2

    or1 = AG.contains(polygon, point)
    or2 = AG.contains(prep_polygon, point)
    @test or1 === or2
end
