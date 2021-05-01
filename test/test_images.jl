using Test
import ArchGDAL; const AG = ArchGDAL
import ImageCore

@testset "Test Gray colors" begin
	@test AG.imread("data/utmsmall.tif") isa ImageCore.PermutedDimsArray
end

@testset "Test RGBA colors" begin
	@test AG.imread("gdalworkshop/world.tif") isa ImageCore.PermutedDimsArray
end
