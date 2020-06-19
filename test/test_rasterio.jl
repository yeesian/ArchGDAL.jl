using Test
import GDAL
import ArchGDAL; const AG = ArchGDAL

AG.read("ospy/data4/aster.img") do ds
    @testset "version 1" begin
        band = AG.getband(ds, 1)
        count = 0
        total = 0
        buffer = Array{AG.pixeltype(band)}(undef, AG.blocksize(band)..., 1)
        for (cols,rows) in AG.windows(band)
            AG.rasterio!(ds, buffer, [1], rows .- 1, cols .- 1)
            data = buffer[1:length(cols),1:length(rows)]
            count += sum(data .> 0)
            total += sum(data)
        end
        @test total / count ≈ 76.33891347095299
        @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
    end

    @testset "version 2" begin
        band = AG.getband(ds, 1)
        count = 0
        total = 0
        buffer = Array{AG.pixeltype(band)}(undef, AG.blocksize(band)..., 1)
        for (cols,rows) in AG.windows(band)
            AG.read!(ds, buffer, [1], rows .- 1, cols .- 1)
            data = buffer[1:length(cols),1:length(rows)]
            count += sum(data .> 0)
            total += sum(data)
        end
        @test total / count ≈ 76.33891347095299
        @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
    end

    @testset "version 3" begin
        band = AG.getband(ds, 1)
        count = 0
        total = 0
        buffer = Array{AG.pixeltype(band)}(undef, AG.blocksize(band)...)
        for (cols,rows) in AG.windows(band)
            AG.read!(ds, buffer, 1, rows, cols)
            data = buffer[1:length(cols),1:length(rows)]
            count += sum(data .> 0)
            total += sum(data)
        end
        @test total / count ≈ 76.33891347095299
        @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
    end

    @testset "version 4" begin
        band = AG.getband(ds, 1)
        count = 0
        total = 0
        buffer = Array{AG.pixeltype(band)}(undef, AG.blocksize(band)...)
        for (cols,rows) in AG.windows(band)
            AG.read!(band, buffer, rows, cols)
            data = buffer[1:length(cols),1:length(rows)]
            count += sum(data .> 0)
            total += sum(data)
        end
        @test total / count ≈ 76.33891347095299
        @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
    end

    @testset "version 5" begin
        band = AG.getband(ds, 1)
        count = 0
        total = 0
        xbsize, ybsize = AG.blocksize(band)
        buffer = Array{AG.pixeltype(band)}(undef, ybsize, xbsize)
        for ((i,j),(nrows,ncols)) in AG.blocks(band)
            # AG.rasterio!(ds,buffer,[1],i,j,nrows,ncols)
            # AG.read!(band, buffer, j, i, ncols, nrows)
            AG.readblock!(band, j, i, buffer)
            data = buffer[1:nrows, 1:ncols]
            count += sum(data .> 0)
            total += sum(data)
        end
        @test total / count ≈ 76.33891347095299
        @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
    end

    @testset "version 6" begin
        band = AG.getband(ds, 1)
        buffer = Array{AG.pixeltype(band)}(undef, AG.width(ds), AG.height(ds), 1)
        AG.rasterio!(ds, buffer, [1])
        count = sum(buffer .> 0)
        total = sum(buffer)
        @test total / count ≈ 76.33891347095299
        @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
    end

    @testset "version 7" begin
        band = AG.getband(ds, 1)
        buffer = Array{AG.pixeltype(band)}(undef, AG.width(ds), AG.height(ds))
        AG.read!(band, buffer)
        count = sum(buffer .> 0)
        total = sum(buffer)
        @test total / count ≈ 76.33891347095299
        @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
    end

    @testset "version 8" begin
        band = AG.getband(ds, 1)
        buffer = Array{AG.pixeltype(band)}(undef, AG.width(ds), AG.height(ds))
        AG.read!(ds, buffer, 1)
        count = sum(buffer .> 0)
        total = sum(buffer)
        @test total / count ≈ 76.33891347095299
        @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
    end

    @testset "version 9" begin
        band = AG.getband(ds, 1)
        buffer = Array{AG.pixeltype(band)}(undef, AG.width(ds), AG.height(ds), 1)
        AG.read!(ds, buffer, [1])
        count = sum(buffer .> 0)
        total = sum(buffer)
        @test total / count ≈ 76.33891347095299
        @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
    end

    @testset "version 10" begin
        band = AG.getband(ds, 1)
        buffer = Array{AG.pixeltype(band)}(undef, AG.width(ds), AG.height(ds), 3)
        AG.read!(ds, buffer)
        count = sum(buffer[:,:,1] .> 0)
        total = sum(buffer[:,:,1])
        @test total / count ≈ 76.33891347095299
        @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
    end

    # check for calling with Tuple
    @testset "version 11" begin
        band = AG.getband(ds, 1)
        count = 0
        total = 0
        buffer = Array{AG.pixeltype(band)}(undef, AG.blocksize(band)..., 1)
        for (cols,rows) in AG.windows(band)
            AG.rasterio!(ds, buffer, (1,), rows .- 1, cols .- 1)
            data = buffer[1:length(cols),1:length(rows)]
            count += sum(data .> 0)
            total += sum(data)
        end
        @test total / count ≈ 76.33891347095299
        @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
    end
end

# Untested
# writeblock!(rb::RasterBand, xoffset::Integer, yoffset::Integer, buffer)
# read!(rb::RasterBand, buffer::Array{Real,2}, xoffset::Integer, yoffset::Integer, xsize::Integer, ysize::Integer)
# read!(dataset::Dataset, buffer::Array{T,2}, i::Integer, xoffset::Integer, yoffset::Integer, xsize::Integer, ysize::Integer)
# read!(dataset::Dataset, buffer::Array{T,3}, indices, xoffset::Integer, yoffset::Integer, xsize::Integer, ysize::Integer)

# read{U <: Integer}(rb::RasterBand, rows::UnitRange{U}, cols::UnitRange{U})
# read(dataset::Dataset, indices)
# read(dataset::Dataset)
# read{T <: Integer}(dataset::Dataset, indices::Vector{T}, xoffset::Integer, yoffset::Integer, xsize::Integer, ysize::Integer)
# read{U <: Integer}(dataset::Dataset, i::Integer, rows::UnitRange{U}, cols::UnitRange{U})
# read{U <: Integer}(dataset::Dataset, indices, rows::UnitRange{U}, cols::UnitRange{U})update!{T <: Real}(rb::RasterBand, buffer::Array{T,2}) =

# write!(rb::RasterBand, buffer::Array{T,2}, rows::UnitRange{U}, cols::UnitRange{U})
# write!(dataset::Dataset, buffer::Array{T,2}, i::Integer)
# write!(dataset::Dataset, buffer::Array{T,3}, indices)
# write!(dataset::Dataset, buffer::Array{T,3}, indices, xoffset::Integer, yoffset::Integer, xsize::Integer, ysize::Integer)
# write!(dataset::Dataset, buffer::Array{T,2}, i::Integer, rows::UnitRange{U}, cols::UnitRange{U})
# write!(dataset::Dataset, buffer::Array{T,3}, indices, rows::UnitRange{U}, cols::UnitRange{U})

# function rasterio!(dataset::Dataset,
#                            buffer::Array{$T, 3},
#                            bands,
#                            xoffset::Integer,
#                            yoffset::Integer,
#                            xsize::Integer,
#                            ysize::Integer,
#                            access::GDALRWFlag=GF_Read,
#                            pxspace::Integer=0,
#                            linespace::Integer=0,
#                            bandspace::Integer=0,
#                            extraargs=Ptr{GDAL.GDALRasterIOExtraArg}(C_NULL))
#             (dataset == C_NULL) && error("Can't read invalid rasterband")
#             xbsize, ybsize, zbsize = size(buffer)
#             nband = length(bands); @assert nband == zbsize
#             result = ccall((:GDALDatasetRasterIOEx,GDAL.libgdal),GDAL.CPLErr,
#                            (Dataset,GDAL.GDALRWFlag,Cint,Cint,Cint,Cint,
#                             Ptr{Cvoid},Cint,Cint,GDAL.GDALDataType,Cint,
#                             Ptr{Cint},GDAL.GSpacing,GDAL.GSpacing,GDAL.GSpacing,
#                             Ptr{GDAL.GDALRasterIOExtraArg}),dataset,access,
#                             xoffset,yoffset,xsize,ysize,pointer(buffer),xbsize,
#                             ybsize,$GT,nband,pointer(bands),pxspace,linespace,
#                             bandspace,extraargs)
#             @cplerr result "Access in DatasetRasterIO failed."
#             buffer
#         end
