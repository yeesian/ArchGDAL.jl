using Test
import ArchGDAL; const AG = ArchGDAL
import DataStreams

@testset "DataStream Support" begin
    df = AG.read("data/point.geojson") do dataset
        DataStreams.Data.close!(DataStreams.Data.stream!(
            AG.Source(AG.getlayer(dataset,0)), DataStreams.Data.Table
        ))
    end
    @test df.FID == [2.0, 3.0, 0.0, 3.0]
    @test df.pointname == ["point-a", "point-b", "a", "b"]
    @test AG.toWKT.(df.geometry0) == [
        "POINT (100 0)",
        "POINT (100.2785 0.0893)",
        "POINT (100 0)",
        "POINT (100.2785 0.0893)"
    ]
end
