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
    r1 = AG.intersects(polygon, point)
    prep_polygon = AG.preparegeom(polygon)
    r2 = AG.intersects(prep_polygon, point)
    @test r1 == r2
end
