using Test
import GDAL
import ArchGDAL; const AG = ArchGDAL

AG.registerdrivers() do
    AG.read("ospy/data4/aster.img") do ds
        @testset "Dataset indexing" begin
            @testset "dims dropped correctly" begin
                @test typeof(ds[:, :, :]) <: Array{UInt8,3}
                @test typeof(ds[:, :, 1]) <: Array{UInt8,2}
                @test typeof(ds[:, 1, 1]) <: Array{UInt8,1}
                @test typeof(ds[1, 1, 1]) <: UInt8
                @test typeof(ds[:, :]) <: Array{UInt8,2}
                @test typeof(ds[:, 1]) <: Array{UInt8,1}
                @test typeof(ds[1, 1]) <: UInt8
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
                @test buffer == ds[:, :] 
                total = sum(buffer)
                count = sum(buffer .> 0)
                @test total / count ≈ 76.33891347095299
                @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
            end
            @testset "int indexing" begin
                @test ds[755, 2107, 1] == 0xff
            end
        end
        @testset "RasterBand indexing" begin
            band = AG.getband(ds, 1)
            @testset "dims dropped correctly" begin
                @test typeof(band[:, :]) <: Array{UInt8,2}
                @test typeof(band[:, 1]) <: Array{UInt8,1}
                @test typeof(band[1, 1]) <: UInt8
            end
            @testset "range indexing" begin
                buffer = band[1:AG.width(band), 1:AG.height(band)]
                @test typeof(buffer) <: Array{UInt8,2}
                total = sum(buffer)
                count = sum(buffer .> 0)
                @test total / count ≈ 76.33891347095299
                @test total / (AG.height(band) * AG.width(band)) ≈ 47.55674749653172
            end
            @testset "colon indexing" begin
                buffer = band[:, :]
                total = sum(buffer)
                count = sum(buffer .> 0)
                @test total / count ≈ 76.33891347095299
                @test total / (AG.height(band) * AG.width(band)) ≈ 47.55674749653172
            end
            @testset "int indexing" begin
                @test band[755, 2107] == 0xff
            end
        end
    end
end

cp("ospy/data4/aster.img", "ospy/data4/aster_write.img"; force=true)

AG.registerdrivers() do
    AG.read("ospy/data4/aster_write.img"; flags=AG.OF_Update) do ds
        @testset "Dataset setindex" begin
            @test ds[755, 2107, 1] == 0xff
            ds[755, 2107, 1] = 0x00
            @test ds[755, 2107, 1] == 0x00
            ds[755:755, 2107:2107, 1:1] = reshape([0x01], 1, 1, 1)
            @test ds[755, 2107, 1] == 0x01
            ds[755:755, 2107:2107, 1] = reshape([0x02], 1, 1)
            @test ds[755, 2107, 1] == 0x02
            ds[755:755, 2107, 1] = [0x03]
            @test ds[755, 2107, 1] == 0x03
            ds[755, 2107] = 0x04
            @test ds[755, 2107] == 0x04
            ds[755:755, 2107:2107] = reshape([0xff], 1, 1)
            @test ds[755, 2107] == 0xff
            buffer = ds[:, :]
            ds[:, :] = buffer .* 0x00 
            @test sum(ds[:, :]) == 0x00
            ds[:, 1:500] = buffer[:, 1:500]
            ds[:, 501:end] = buffer[:, 501:end]
            @test sum(buffer) / sum(buffer .> 0) ≈ 76.33891347095299
            @test_throws DimensionMismatch ds[:, 501:end] = [1, 2, 3]  
        end
        @testset "RasterBand setindex" begin
            band = AG.getband(ds, 1)
            @test band[755, 2107] == 0xff
            band[755:755, 2107] = [0x00]
            @test band[755, 2107] == 0x00
            band[755, 2107] = 0x01
            @test band[755, 2107] == 0x01
            band[755:755, 2107:2107] = reshape([0xff], 1, 1)
            @test band[755, 2107] == 0xff
            buffer = band[:, :]
            band[:, :] = buffer .* 0x00 
            @test sum(band[:, :]) == 0x00
            band[:, 1:500] = buffer[:, 1:500]
            band[:, 501:end] = buffer[:, 501:end]
            @test sum(buffer) / sum(buffer .> 0) ≈ 76.33891347095299
            @test_throws DimensionMismatch band[:, 501:end] = [1, 2, 3]  
        end
    end
end

