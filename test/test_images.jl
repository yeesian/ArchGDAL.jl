using Test
import ArchGDAL; const AG = ArchGDAL
import ImageCore
import ColorTypes

@testset "test_images.jl" begin

@testset "Test Gray colors" begin
    @test eltype(AG.imread("data/utmsmall.tif")) ==
        ColorTypes.Gray{ImageCore.N0f8}
end

AG.read("gdalworkshop/world.tif") do dataset
    @testset "Test RGB colors" begin
        @test eltype(AG.imread(dataset)) ==
            ColorTypes.RGB{ImageCore.N0f8}
    end
end

AG.create(
        AG.getdriver("MEM"),
        width = 2,
        height = 2,
        nbands = 4,
        dtype = UInt8,
    ) do dataset
    @testset "Test RGBA colors" begin
        AG.setcolorinterp!(AG.getband(dataset, 1), AG.GCI_RedBand)
        AG.setcolorinterp!(AG.getband(dataset, 2), AG.GCI_GreenBand)
        AG.setcolorinterp!(AG.getband(dataset, 3), AG.GCI_BlueBand)
        AG.setcolorinterp!(AG.getband(dataset, 4), AG.GCI_AlphaBand)
        @test eltype(AG.imread(dataset)) ==
            ColorTypes.RGBA{ImageCore.N0f8}
    end

    @testset "Test ColorTable colors" begin
        AG.setcolorinterp!(AG.getband(dataset, 1), AG.GCI_PaletteIndex)
        AG.setcolorinterp!(AG.getband(dataset, 2), AG.GCI_PaletteIndex)
        AG.setcolorinterp!(AG.getband(dataset, 3), AG.GCI_PaletteIndex)
        AG.setcolorinterp!(AG.getband(dataset, 4), AG.GCI_PaletteIndex)
        
        AG.createcolortable(AG.GPI_RGB) do ct
            AG.setcolortable!(AG.getband(dataset, 1), ct)
            AG.setcolortable!(AG.getband(dataset, 2), ct)
            AG.setcolortable!(AG.getband(dataset, 3), ct)
            AG.setcolortable!(AG.getband(dataset, 4), ct)
        end
        @test eltype(AG.imread(dataset)) ==
            ColorTypes.RGBA{ImageCore.N0f8}

        AG.createcolortable(AG.GPI_CMYK) do ct # CMYK not supported yet
            AG.setcolortable!(AG.getband(dataset, 1), ct)
            AG.setcolortable!(AG.getband(dataset, 2), ct)
            AG.setcolortable!(AG.getband(dataset, 3), ct)
        end
        @test_throws ErrorException AG.imread(dataset, 1:3)
    end
end

end
