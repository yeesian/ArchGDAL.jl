using Test
import ArchGDAL; const AG = ArchGDAL

@testset "test_geotransform.jl" begin
    
    f(gt, pixel, line) = [
        gt[1] + pixel * gt[2] + line * gt[3],
        gt[4] + pixel * gt[5] + line * gt[6],
    ]
    gt1 = [
        -1111950.519667, 463.3127165279167,                0.0,
            6671703.118, 0.0,               -463.3127165279165,
    ]
    for (pixel, line) in ((0.0, 0.0), (3.0, 2.0), (15.5, 9.9))
        @test AG.applygeotransform(gt1, pixel, line) ≈ f(gt1, pixel, line)
    end

    gt2 = AG.invgeotransform(gt1)
    @test gt2 ≈ [
         2400.0,  0.0021583694216166533, 0.0,
        14400.0, 0.0,                   -0.002158369421616654,
    ]

    gt3 = AG.composegeotransform(gt1, gt2)
    @test gt3 ≈ [
    	0.0, 1.0, 0.0,
    	0.0, 0.0, 1.0,
    ]

    for (pixel, line) in ((0.0, 0.0), (3.0, 2.0), (15.5, 9.9))
        @test AG.applygeotransform(gt3, pixel, line) ≈ [pixel, line]
    end
end
