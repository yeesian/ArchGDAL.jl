using Test
import GDAL
import ArchGDAL; const AG = ArchGDAL

@testset "Test Array getindex" begin
    AG.read("ospy/data4/cropped_aster.img") do ds
        @testset "Dataset indexing" begin
            @testset "dims dropped correctly" begin
                # These don't break with `cropped_aster`
                @test typeof(ds[:, :, :]) <: Array{UInt8,3}
                @test typeof(ds[:, :, 1]) <: Array{UInt8,2}
                @test typeof(ds[:, 1, 1]) <: Array{UInt8,1}
                @test typeof(ds[1, 1, 1]) <: UInt8
                @test typeof(ds[:, :]) <: Array{UInt8,2}
                @test typeof(ds[:, 1]) <: Array{UInt8,1}
                @test typeof(ds[1, 1]) <: UInt8
            end
            @testset "range indexing" begin
                # These don't break with `cropped_aster`
                buffer = ds[1:AG.width(ds), 1:AG.height(ds), 1:1]
                
                # Works
                @test typeof(buffer) <: Array{UInt8,3}
                total = sum(buffer)
                count = sum(buffer .> 0)            # Count the non-zero/non-nan values
                
                # Works
                # total = 74985     --  Julia and Rasterio
                # count = 863       --  Julia and Rasterio
                # [python] total/count = 74985/863 ≈ 86.88876013904982 
                @test total / count ≈ 86.88876013904982 

                # Works
                # [python] total / (band.shape[0] * band.shape[1])  -- in python
                #  = 27.741398446170923
                @test total / (AG.height(ds) * AG.width(ds)) ≈ 27.741398446170923

                # COMMENT
                # Cropped raster from an area containing valid non-zero values and 
                #   Nodata values works fine for "range indexing testset"
            end
            @testset "colon indexing" begin
                # These don't break with `cropped_aster`
                buffer = ds[:, :, 1]
                
                # Works
                @test buffer == ds[:, :] 
                total = sum(buffer)
                count = sum(buffer .> 0)

                # Works
                # total = 74985     --  Julia and Rasterio
                # count = 863       --  Julia and Rasterio
                # [python] total/count = 74985/863 ≈ 86.88876013904982 
                @test total / count ≈ 86.88876013904982

                # Works
                # [python] total / (band.shape[0] * band.shape[1])  -- in python
                #  = 27.741398446170923
                @test total / (AG.height(ds) * AG.width(ds)) ≈ 27.741398446170923
            end
            # @testset "int indexing" begin

            #     # Question -> What is the intent behind checking this exact point (755, 2107, 1) 
            #     #               Rasterio reports correct value of (255) at this indices (0, 2106, 754)
                
            #     @test ds[755, 2107, 1] == 0xff
            # end
        end
        # @testset "RasterBand indexing" begin
        #     band = AG.getband(ds, 1)
        #     @testset "dims dropped correctly" begin
        #         @test typeof(band[:, :]) <: Array{UInt8,2}
        #         @test typeof(band[:, 1]) <: Array{UInt8,1}
        #         @test typeof(band[1, 1]) <: UInt8
        #     end
        #     @testset "range indexing" begin
        #         buffer = band[1:AG.width(band), 1:AG.height(band)]
        #         @test typeof(buffer) <: Array{UInt8,2}
        #         total = sum(buffer)
        #         count = sum(buffer .> 0)
        #         @test total / count ≈ 76.33891347095299
        #         @test total / (AG.height(band) * AG.width(band)) ≈ 47.55674749653172
        #     end
        #     @testset "colon indexing" begin
        #         buffer = band[:, :]
        #         total = sum(buffer)
        #         count = sum(buffer .> 0)
        #         @test total / count ≈ 76.33891347095299
        #         @test total / (AG.height(band) * AG.width(band)) ≈ 47.55674749653172
        #     end
        #     @testset "int indexing" begin
        #         @test band[755, 2107] == 0xff
        #     end
        # end
    end
end

# cp("ospy/data4/cropped_aster.img", "ospy/data4/aster_write.img"; force=true)

# @testset "Test Array setindex" begin
#     AG.read("ospy/data4/aster_write.img"; flags=AG.OF_Update) do ds
#         @testset "Dataset setindex" begin
#             @test ds[755, 2107, 1] == 0xff
#             ds[755, 2107, 1] = 0x00
#             @test ds[755, 2107, 1] == 0x00
#             ds[755:755, 2107:2107, 1:1] = reshape([0x01], 1, 1, 1)
#             @test ds[755, 2107, 1] == 0x01
#             ds[755:755, 2107:2107, 1] = reshape([0x02], 1, 1)
#             @test ds[755, 2107, 1] == 0x02
#             ds[755:755, 2107, 1] = [0x03]
#             @test ds[755, 2107, 1] == 0x03
#             ds[755, 2107] = 0x04
#             @test ds[755, 2107] == 0x04
#             ds[755:755, 2107:2107] = reshape([0xff], 1, 1)
#             @test ds[755, 2107] == 0xff
#             buffer = ds[:, :]
#             ds[:, :] = buffer .* 0x00 
#             @test sum(ds[:, :]) == 0x00
#             ds[:, 1:500] = buffer[:, 1:500]
#             ds[:, 501:end] = buffer[:, 501:end]
#             @test sum(buffer) / sum(buffer .> 0) ≈ 76.33891347095299
#             @test_throws DimensionMismatch ds[:, 501:end] = [1, 2, 3]  
#         end
#         @testset "RasterBand setindex" begin
#             band = AG.getband(ds, 1)
#             @test band[755, 2107] == 0xff
#             band[755:755, 2107] = [0x00]
#             @test band[755, 2107] == 0x00
#             band[755, 2107] = 0x01
#             @test band[755, 2107] == 0x01
#             band[755:755, 2107:2107] = reshape([0xff], 1, 1)
#             @test band[755, 2107] == 0xff
#             buffer = band[:, :]
#             band[:, :] = buffer .* 0x00 
#             @test sum(band[:, :]) == 0x00
#             band[:, 1:500] = buffer[:, 1:500]
#             band[:, 501:end] = buffer[:, 501:end]
#             @test sum(buffer) / sum(buffer .> 0) ≈ 76.33891347095299
#             @test_throws DimensionMismatch band[:, 501:end] = [1, 2, 3]  
#         end
#     end
# end

# @testset "Test Array constructor" begin
#     AG.read("ospy/data4/aster_write.img"; flags=AG.OF_Update) do ds
#         buffer = Array(ds)
#         typeof(buffer) <: Array{UInt8,3}
#         total = sum(buffer[:, :, 1:1])
#         count = sum(buffer[:, :, 1:1] .> 0)
#         @test total / count ≈ 76.33891347095299
#         @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
#     end
# end
