using Test
import ArchGDAL;
const AG = ArchGDAL;
import ImageCore
import ColorTypes
import GDAL

@testset "test_images.jl" begin
    @testset "Test Gray colors" begin
        @test eltype(AG.imread("data/utmsmall.tif")) ==
              ColorTypes.Gray{ImageCore.N0f8}
    end

    AG.read("gdalworkshop/world.tif") do dataset
        @testset "Test RGB colors" begin
            @test eltype(AG.imread(dataset)) == ColorTypes.RGB{ImageCore.N0f8}
            rasterdataset = AG.RasterDataset(dataset)
            @test eltype(AG.imread(rasterdataset)) == ColorTypes.RGB{ImageCore.N0f8}
        end
    end

    AG.create(
        AG.getdriver("MEM"),
        width = 2,
        height = 2,
        nbands = 4,
        dtype = UInt8,
    ) do dataset
        @testset "imview" begin
            @test eltype(AG.imview(AG.GCI_GrayIndex, ones(UInt8, 2, 2))) ==
                  ColorTypes.Gray{ImageCore.N0f8}
            @test eltype(AG.imview(AG.GCI_Undefined, ones(UInt8, 2, 2))) ==
                  ColorTypes.Gray{ImageCore.N0f8}
            @test eltype(AG.imview(AG.GCI_RedBand, ones(UInt8, 2, 2))) ==
                  ColorTypes.RGB{ImageCore.N0f8}
            @test eltype(AG.imview(AG.GCI_GreenBand, ones(UInt8, 2, 2))) ==
                  ColorTypes.RGB{ImageCore.N0f8}
            @test eltype(AG.imview(AG.GCI_BlueBand, ones(UInt8, 2, 2))) ==
                  ColorTypes.RGB{ImageCore.N0f8}
            @test_throws ErrorException AG.imview(AG.GCI_Max, ones(UInt8, 2, 2))
            @test eltype(AG.imview(AG.GPI_Gray, ones(UInt8, 2, 2))) ==
                  ColorTypes.Gray{ImageCore.N0f8}
            @test eltype(
                AG.imview(
                    AG.GPI_Gray,
                    ones(UInt8, 2, 2),
                    ones(UInt8, 2, 2),
                    ones(UInt8, 2, 2),
                ),
            ) == ColorTypes.Gray{ImageCore.N0f8}
            @test_throws ErrorException AG.imview(AG.GPI_HLS, ones(UInt8, 2, 2))
            @test_throws ErrorException AG.imview(
                AG.GPI_HLS,
                ones(UInt8, 2, 2),
                ones(UInt8, 2, 2),
                ones(UInt8, 2, 2),
            )
            @test_throws ErrorException AG.imview(
                AG.GPI_HLS,
                ones(UInt8, 2, 2),
                ones(UInt8, 2, 2),
                ones(UInt8, 2, 2),
                ones(UInt8, 2, 2),
            )
        end

        @testset "imread(color, ..., xoffset, yoffset, xsize, ysize)" begin
            @test eltype(
                AG.imread(AG.GCI_GrayIndex, AG.getband(dataset, 1), 0, 0, 2, 2),
            ) == ColorTypes.Gray{ImageCore.N0f8}
            @test eltype(
                AG.imread(AG.GPI_Gray, AG.getband(dataset, 1), 0, 0, 2, 2),
            ) == ColorTypes.Gray{ImageCore.N0f8}
            @test eltype(AG.imread(AG.GCI_GrayIndex, dataset, 1, 0, 0, 2, 2)) ==
                  ColorTypes.Gray{ImageCore.N0f8}
            @test eltype(AG.imread(AG.GPI_Gray, dataset, 1, 0, 0, 2, 2)) ==
                  ColorTypes.Gray{ImageCore.N0f8}
        end

        @testset "imread(color, ..., rows::UnitRange, cols::UnitRange)" begin
            @test eltype(
                AG.imread(AG.GCI_GrayIndex, AG.getband(dataset, 1), 1:2, 1:2),
            ) == ColorTypes.Gray{ImageCore.N0f8}
            @test eltype(
                AG.imread(AG.GPI_Gray, AG.getband(dataset, 1), 1:2, 1:2),
            ) == ColorTypes.Gray{ImageCore.N0f8}
            @test eltype(AG.imread(AG.GCI_GrayIndex, dataset, 1, 1:2, 1:2)) ==
                  ColorTypes.Gray{ImageCore.N0f8}
            @test eltype(AG.imread(AG.GPI_Gray, dataset, 1, 1:2, 1:2)) ==
                  ColorTypes.Gray{ImageCore.N0f8}
        end

        @testset "imread(color, ...)" begin
            @test eltype(AG.imread(AG.GCI_GrayIndex, AG.getband(dataset, 1))) ==
                  ColorTypes.Gray{ImageCore.N0f8}
            @test eltype(AG.imread(AG.GPI_Gray, AG.getband(dataset, 1))) ==
                  ColorTypes.Gray{ImageCore.N0f8}
            @test eltype(AG.imread(AG.GCI_GrayIndex, dataset, 1)) ==
                  ColorTypes.Gray{ImageCore.N0f8}
            @test eltype(AG.imread(AG.GPI_Gray, dataset, 1)) ==
                  ColorTypes.Gray{ImageCore.N0f8}
        end

        @testset "Test RGBA colors" begin
            AG.setcolorinterp!(AG.getband(dataset, 1), AG.GCI_RedBand)
            AG.setcolorinterp!(AG.getband(dataset, 2), AG.GCI_GreenBand)
            AG.setcolorinterp!(AG.getband(dataset, 3), AG.GCI_BlueBand)
            AG.setcolorinterp!(AG.getband(dataset, 4), AG.GCI_AlphaBand)
            @test eltype(AG.imread(AG.getband(dataset, 1))) ==
                  ColorTypes.RGB{ImageCore.N0f8}
            @test eltype(AG.imread(dataset, 1)) ==
                  ColorTypes.RGB{ImageCore.N0f8}
            @test eltype(AG.imread(AG.getband(dataset, 1), 0, 0, 2, 2)) ==
                  ColorTypes.RGB{ImageCore.N0f8}
            @test eltype(AG.imread(dataset, 1, 0, 0, 2, 2)) ==
                  ColorTypes.RGB{ImageCore.N0f8}
            @test eltype(AG.imread(AG.getband(dataset, 1), 1:2, 1:2)) ==
                  ColorTypes.RGB{ImageCore.N0f8}
            @test eltype(AG.imread(dataset, 1, 1:2, 1:2)) ==
                  ColorTypes.RGB{ImageCore.N0f8}
            @test eltype(AG.imread(AG.getband(dataset, 1))) ==
                  ColorTypes.RGB{ImageCore.N0f8}
            @test eltype(AG.imread(dataset, 1)) ==
                  ColorTypes.RGB{ImageCore.N0f8}
            @test eltype(AG.imread(dataset, 1:4, 0, 0, 2, 2)) ==
                  ColorTypes.RGBA{ImageCore.N0f8}
            @test eltype(AG.imread(dataset, 1:4, 1:2, 1:2)) ==
                  ColorTypes.RGBA{ImageCore.N0f8}
            @test eltype(AG.imread(dataset)) == ColorTypes.RGBA{ImageCore.N0f8}
        end

        @testset "Test HSL colors" begin
            AG.setcolorinterp!(AG.getband(dataset, 1), AG.GCI_HueBand)
            AG.setcolorinterp!(AG.getband(dataset, 2), AG.GCI_SaturationBand)
            AG.setcolorinterp!(AG.getband(dataset, 3), AG.GCI_LightnessBand)
            @test_throws ErrorException AG.imread(dataset, 1:3)
        end

        @testset "Test ColorTable colors" begin
            AG.setcolorinterp!(AG.getband(dataset, 1), AG.GCI_PaletteIndex)
            AG.setcolorinterp!(AG.getband(dataset, 2), AG.GCI_PaletteIndex)
            AG.setcolorinterp!(AG.getband(dataset, 3), AG.GCI_PaletteIndex)
            AG.setcolorinterp!(AG.getband(dataset, 4), AG.GCI_PaletteIndex)

            AG.createcolortable(AG.GPI_RGB) do ct
                AG.setcolorentry!(
                    ct,
                    typemax(UInt8),
                    GDAL.GDALColorEntry(0, 0, 0, 0),
                )
                AG.setcolortable!(AG.getband(dataset, 1), ct)
                AG.setcolortable!(AG.getband(dataset, 2), ct)
                AG.setcolortable!(AG.getband(dataset, 3), ct)
                return AG.setcolortable!(AG.getband(dataset, 4), ct)
            end
            @test eltype(AG.imread(dataset)) == ColorTypes.RGBA{ImageCore.N0f8}

            AG.createcolortable(AG.GPI_Gray) do ct
                AG.setcolorentry!(
                    ct,
                    typemax(UInt8),
                    GDAL.GDALColorEntry(0, 0, 0, 0),
                )
                return AG.setcolortable!(AG.getband(dataset, 4), ct)
            end
            @test eltype(AG.imread(dataset, 4)) ==
                  ColorTypes.Gray{ImageCore.N0f8}

            AG.createcolortable(AG.GPI_CMYK) do ct # CMYK not supported yet
                AG.setcolortable!(AG.getband(dataset, 1), ct)
                AG.setcolortable!(AG.getband(dataset, 2), ct)
                return AG.setcolortable!(AG.getband(dataset, 3), ct)
            end
            @test_throws ErrorException AG.imread(dataset, 1:3)
        end
    end
end
