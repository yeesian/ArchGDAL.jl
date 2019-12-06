using Test
import GDAL
import ArchGDAL; const AG = ArchGDAL

buffer = AG.registerdrivers() do
    AG.read("ospy/data4/aster.img") do ds
        @testset "dims dropped correctly" begin
            buffer = ds[:, :, :]
            @test typeof(buffer) <: Array{UInt8,3}
            buffer = ds[:, :, 1]
            @test typeof(buffer) <: Array{UInt8,2}
            buffer = ds[:, 1, 1]
            @test typeof(buffer) <: Array{UInt8,1}
            buffer = ds[1, 1, 1]
            @test typeof(buffer) <: UInt8
        end
        @testset "range indexing" begin
            buffer = ds[1:AG.width(ds), 1:AG.height(ds), 1:1]
            @test typeof(buffer) <: Array{UInt8,3}
            total = sum(buffer)
            count = sum(buffer .> 0)
            @test total / count ≈ 76.33891347095299
            @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
        end
        @testset "colon indexing" begin
            buffer = ds[:, :, 1]
            total = sum(buffer)
            count = sum(buffer .> 0)
            @test total / count ≈ 76.33891347095299
            @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
        end
        @testset "int indexing" begin
            @test ds[755, 2107, 1] == 0xff
        end
    end
end

