using Test
using DiskArrays: eachchunk, haschunks, Chunked, GridChunks, readblock!
import ArchGDAL;
const AG = ArchGDAL;

@testset "test_array.jl" begin
    @testset "RasterDataset Type" begin
        AG.readraster("ospy/data4/aster.img") do ds
            @testset "Test forwarded methods" begin
                @test ds isa AG.RasterDataset{UInt8}
                @test AG.getgeotransform(ds) ==
                      [419976.5, 15.0, 0.0, 4.6624225e6, 0.0, -15.0]
                @test AG.nraster(ds) == 3
                @test AG.getband(ds, 1) isa AG.AbstractRasterBand
                @test startswith(AG.getproj(ds), "PROJCS")
                @test AG.width(ds) == 5665
                @test AG.height(ds) == 5033
                @test AG.getdriver(ds) isa AG.Driver
                @test splitpath(AG.filelist(ds)[1]) ==
                      ["ospy", "data4", "aster.img"]
                @test splitpath(AG.filelist(ds)[2]) ==
                      ["ospy", "data4", "aster.rrd"]
                @test AG.listcapability(ds) isa Dict
                @test AG.ngcp(ds) == 0
                @test AG.write(ds, tempname()) == nothing
                @test AG.testcapability(ds, "ODsCCreateLayer") == false
            end
            @testset "DiskArray chunk interface" begin
                b = AG.getband(ds, 1)
                @test eachchunk(ds) == GridChunks(size(ds), (64, 64, 1))
                @test eachchunk(b) == GridChunks(size(b), (64, 64))
                @test haschunks(ds) == Chunked()
                @test haschunks(b) == Chunked()
            end
            @testset "Reading into non-arrays" begin
                data1 = view(zeros(3, 3, 3), 1:3, 1:3, 1:3)
                readblock!(ds, data1, 1:3, 1:3, 1:3)
                @test data1 == ds[1:3, 1:3, 1:3]
            end
        end
    end

    @testset "Test Array getindex" begin
        AG.readraster("ospy/data4/aster.img") do ds
            @testset "Dataset indexing" begin
                @testset "dims dropped correctly" begin
                    @test typeof(ds[:, :, :]) <: Array{UInt8,3}
                    @test typeof(ds[:, :, 1]) <: Array{UInt8,2}
                    @test typeof(ds[:, 1, 1]) <: Array{UInt8,1}
                    @test typeof(ds[1, 1, 1]) <: UInt8
                end
                @testset "range indexing" begin
                    buffer = ds[1:AG.width(ds), 1:AG.height(ds), 1:1]
                    @test typeof(buffer) <: Array{UInt8,3}
                    total = sum(buffer)
                    count = sum(buffer .> 0)
                    @test total / count ≈ 76.33891347095299
                    @test total / (AG.height(ds) * AG.width(ds)) ≈
                          47.55674749653172
                end
                @testset "colon indexing" begin
                    buffer = ds[:, :, 1]
                    total = sum(buffer)
                    count = sum(buffer .> 0)
                    @test total / count ≈ 76.33891347095299
                    @test total / (AG.height(ds) * AG.width(ds)) ≈
                          47.55674749653172
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
                    @test total / (AG.height(band) * AG.width(band)) ≈
                          47.55674749653172
                end
                @testset "colon indexing" begin
                    buffer = band[:, :]
                    total = sum(buffer)
                    count = sum(buffer .> 0)
                    @test total / count ≈ 76.33891347095299
                    @test total / (AG.height(band) * AG.width(band)) ≈
                          47.55674749653172
                end
                @testset "int indexing" begin
                    @test band[755, 2107] == 0xff
                end
            end
        end
    end

    cp("ospy/data4/aster.img", "ospy/data4/aster_write.img"; force = true)

    @testset "Test Array setindex" begin
        AG.readraster("ospy/data4/aster_write.img"; flags = AG.OF_UPDATE) do ds
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
            end
            @testset "RasterBand setindex" begin
                band = AG.getband(ds, 1)
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

    @testset "Test Array constructor" begin
        AG.readraster("ospy/data4/aster_write.img"; flags = AG.OF_UPDATE) do ds
            @test sprint(print, ds) == """
            GDAL Dataset (Driver: HFA/Erdas Imagine Images (.img))
            File(s): 
              ospy/data4/aster_write.img

            Dataset (width x height): 5665 x 5033 (pixels)
            Number of raster bands: 3
              [GA_Update] Band 1 (Undefined): 5665 x 5033 (UInt8)
              [GA_Update] Band 2 (Undefined): 5665 x 5033 (UInt8)
              [GA_Update] Band 3 (Undefined): 5665 x 5033 (UInt8)
            """
            buffer = Array(ds)
            typeof(buffer) <: Array{UInt8,3}
            total = sum(buffer[:, :, 1:1])
            count = sum(buffer[:, :, 1:1] .> 0)
            @test total / count ≈ 76.33891347095299
            @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172

            AG.copy(ds) do copy1
                @test typeof(AG.copywholeraster!(ds, copy1)) == typeof(copy1)
                @test typeof(
                    AG.copywholeraster!(AG.RasterDataset(copy1), ds),
                ) == typeof(ds)
                @test typeof(AG.copywholeraster!(copy1, ds)) == typeof(ds)
            end
        end

        AG.create(
            AG.getdriver("MEM"),
            width = 2,
            height = 2,
            nbands = 0,
            dtype = UInt8,
        ) do dataset
            @test_throws Union{ArgumentError,MethodError} AG.RasterDataset(
                dataset,
            )
            @test_throws DimensionMismatch AG._common_size(dataset)
        end
    end
end
