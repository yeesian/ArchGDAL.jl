using Test
import ArchGDAL;
const AG = ArchGDAL;

@testset "test_rasterio.jl" begin
    AG.read("ospy/data4/aster.img") do ds
        @testset "version 1" begin
            band = AG.getband(ds, 1)
            count = 0
            total = 0
            buffer = Array{AG.pixeltype(band)}(undef, AG.blocksize(band)..., 1)
            for (cols, rows) in AG.windows(band)
                AG.rasterio!(ds, buffer, [1], rows, cols)
                data = buffer[1:length(cols), 1:length(rows)]
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
            for (cols, rows) in AG.windows(band)
                AG.read!(ds, buffer, [1], rows, cols)
                data = buffer[1:length(cols), 1:length(rows)]
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
            buffer = Matrix{AG.pixeltype(band)}(undef, AG.blocksize(band)...)
            for (cols, rows) in AG.windows(band)
                AG.read!(ds, buffer, 1, rows, cols)
                data = buffer[1:length(cols), 1:length(rows)]
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
            buffer = Matrix{AG.pixeltype(band)}(undef, AG.blocksize(band)...)
            for (cols, rows) in AG.windows(band)
                AG.read!(band, buffer, rows, cols)
                data = buffer[1:length(cols), 1:length(rows)]
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
            buffer = Matrix{AG.pixeltype(band)}(undef, ybsize, xbsize)
            for ((i, j), (nrows, ncols)) in AG.blocks(band)
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
            buffer =
                Array{AG.pixeltype(band)}(undef, AG.width(ds), AG.height(ds), 1)
            AG.rasterio!(ds, buffer, [1])
            count = sum(buffer .> 0)
            total = sum(buffer)
            @test total / count ≈ 76.33891347095299
            @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
        end

        @testset "version 7" begin
            band = AG.getband(ds, 1)
            buffer =
                Matrix{AG.pixeltype(band)}(undef, AG.width(ds), AG.height(ds))
            AG.read!(band, buffer)
            count = sum(buffer .> 0)
            total = sum(buffer)
            @test total / count ≈ 76.33891347095299
            @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
        end

        @testset "version 8" begin
            band = AG.getband(ds, 1)
            buffer =
                Matrix{AG.pixeltype(band)}(undef, AG.width(ds), AG.height(ds))
            AG.read!(ds, buffer, 1)
            count = sum(buffer .> 0)
            total = sum(buffer)
            @test total / count ≈ 76.33891347095299
            @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
        end

        @testset "version 9" begin
            band = AG.getband(ds, 1)
            buffer =
                Array{AG.pixeltype(band)}(undef, AG.width(ds), AG.height(ds), 1)
            AG.read!(ds, buffer, [1])
            count = sum(buffer .> 0)
            total = sum(buffer)
            @test total / count ≈ 76.33891347095299
            @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
        end

        @testset "version 10" begin
            band = AG.getband(ds, 1)
            buffer =
                Array{AG.pixeltype(band)}(undef, AG.width(ds), AG.height(ds), 3)
            AG.read!(ds, buffer)
            count = sum(buffer[:, :, 1] .> 0)
            total = sum(buffer[:, :, 1])
            @test total / count ≈ 76.33891347095299
            @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
        end

        # check for calling with Tuple
        @testset "version 11" begin
            band = AG.getband(ds, 1)
            count = 0
            total = 0
            buffer = Array{AG.pixeltype(band)}(undef, AG.blocksize(band)..., 1)
            for (cols, rows) in AG.windows(band)
                AG.rasterio!(ds, buffer, (1,), rows, cols)
                data = buffer[1:length(cols), 1:length(rows)]
                count += sum(data .> 0)
                total += sum(data)
            end
            @test total / count ≈ 76.33891347095299
            @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
        end

        @testset "buffer size" begin
            @test size(AG.read(ds, 1, 0, 0, 20, 10)) === (20, 10)
            @test size(AG.read(ds, [1, 3], 0, 0, 20, 10)) === (20, 10, 2)
            @test size(AG.read(ds, 1, 1:10, 31:50)) === (20, 10)
            @test size(AG.read(ds, [1, 3], 1:10, 31:50)) === (20, 10, 2)
            @test size(AG.read(ds, 1:2)) == (5665, 5033, 2)
            band = AG.getband(ds, 1)
            @test size(AG.read(band, 0, 0, 20, 10)) === (20, 10)
        end

        @testset "Writing to buffers" begin
            band = AG.getband(ds, 1)
            @test AG.pixeltype(band) == UInt8
            xbsize, ybsize = AG.blocksize(band)
            AG.create(
                AG.getdriver("MEM"),
                width = AG.width(band),
                height = AG.height(band),
                nbands = 2,
                dtype = AG.pixeltype(band),
            ) do dsout
                bandout = AG.getband(dsout, 1)

                @testset "writeblock!(rb::RasterBand, xoffset, yoffset, buffer)" begin
                    # We write everything to typemax(UInt8)
                    for ((i, j), (nrows, ncols)) in AG.blocks(bandout)
                        AG.writeblock!(
                            bandout,
                            j,
                            i,
                            fill(typemax(UInt8), ncols, nrows),
                        )
                    end
                    buffer = AG.read(bandout)
                    nnzero = sum(buffer .> 0)
                    @test nnzero == AG.height(bandout) * AG.width(bandout)
                    @test sum(buffer) / nnzero ≈ Float64(typemax(UInt8))

                    # Now we write everything to 0
                    for ((i, j), (nrows, ncols)) in AG.blocks(bandout)
                        AG.writeblock!(bandout, j, i, fill(0x00, ncols, nrows))
                    end
                    @test sum(AG.read(bandout) .> 0) == 0
                end

                @testset "write!(rb::RasterBand, buffer::Matrix[, rows, cols])" begin
                    # We write everything to typemax(UInt8)
                    AG.write!(
                        bandout,
                        fill(
                            typemax(UInt8),
                            AG.height(bandout),
                            AG.width(bandout),
                        ),
                    )
                    buffer = AG.read(bandout)
                    nnzero = sum(buffer .> 0)
                    @test nnzero == AG.height(bandout) * AG.width(bandout)
                    @test sum(buffer) / nnzero ≈ Float64(typemax(UInt8))

                    # Now we write everything to 0
                    AG.write!(
                        bandout,
                        fill(0x00, AG.height(bandout), AG.width(bandout)),
                    )
                    @test sum(AG.read(bandout) .> 0) == 0
                end

                @testset "write!(dataset::Dataset, buffer::Matrix, i::Integer[, rows, cols])" begin
                    # We write everything to typemax(UInt8)
                    AG.write!(
                        dsout,
                        fill(
                            typemax(UInt8),
                            AG.height(bandout),
                            AG.width(bandout),
                        ),
                        1,
                    )
                    buffer = AG.read(bandout)
                    nnzero = sum(buffer .> 0)
                    @test nnzero == AG.height(bandout) * AG.width(bandout)
                    @test sum(buffer) / nnzero ≈ Float64(typemax(UInt8))

                    # Now we write everything to 0
                    AG.write!(
                        dsout,
                        fill(0x00, AG.height(bandout), AG.width(bandout)),
                        1,
                    )
                    @test sum(AG.read(bandout) .> 0) == 0
                end

                @testset "write!(dataset::Dataset, buffer::Array, indices[, rows, cols])" begin
                    # We write everything to typemax(UInt8)
                    AG.write!(
                        dsout,
                        fill(
                            typemax(UInt8),
                            AG.height(dsout),
                            AG.width(dsout),
                            2,
                        ),
                        1:2,
                    )
                    buffer = AG.read(dsout)
                    nnzero = sum(buffer .> 0)
                    @test nnzero == 2 * AG.height(dsout) * AG.width(dsout)
                    @test sum(buffer) / nnzero ≈ Float64(typemax(UInt8))

                    # Now we write everything to 0
                    AG.write!(
                        dsout,
                        fill(0x00, AG.height(dsout), AG.width(dsout), 2),
                        1:2,
                    )
                    @test sum(AG.read(dsout) .> 0) == 0
                end
            end
        end
    end
end

@testset "Complex IO" begin 
    a = rand(ComplexF32, 10,10)

    outpath = "/vsimem/" * "testcomplex1.tif"
    AG.create(outpath, driver=AG.getdriver("GTiff"), width=10, height=10, nbands=1,dtype=ComplexF32)  do ds
        AG.write!(ds, a, 1)
    end

    AG.read(outpath) do ds_copy
        @test AG.getband(ds_copy,1) == a
    end
end

