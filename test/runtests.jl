using Test
using Dates
using GDAL
#TODO import ArchGDAL
import ArchGDAL as AG
import Aqua

include("test_mdarray.jl")

#TODO # ensure all testing files are present
#TODO include("remotefiles.jl")
#TODO 
#TODO @testset "ArchGDAL" begin
#TODO     cd(dirname(@__FILE__)) do
#TODO         isdir("tmp") || mkpath("tmp")
#TODO         #TODO include("test_doctest.jl")
#TODO         #TODO include("test_convert.jl")
#TODO         #TODO include("test_tables.jl")
#TODO         #TODO include("test_gdal_tutorials.jl")
#TODO         #TODO include("test_geometry.jl")
#TODO         #TODO include("test_types.jl")
#TODO         #TODO include("test_display.jl")
#TODO         #TODO include("test_drivers.jl")
#TODO         #TODO include("test_feature.jl")
#TODO         #TODO include("test_featurelayer.jl")
#TODO         #TODO include("test_fielddefn.jl")
#TODO         #TODO include("test_iterators.jl")
#TODO         #TODO include("test_styletable.jl")
#TODO         #TODO include("test_dataset.jl")
#TODO         #TODO include("test_rasterband.jl")
#TODO         #TODO include("test_rasterio.jl")
#TODO         #TODO include("test_array.jl")
#TODO         #TODO include("test_spatialref.jl")
#TODO         #TODO include("test_gdalutilities.jl")
#TODO         #TODO include("test_gdalutilities_errors.jl")
#TODO         #TODO include("test_rasterattrtable.jl")
#TODO         include("test_mdarray.jl")
#TODO         #TODO include("test_ospy_examples.jl")
#TODO         #TODO include("test_geos_operations.jl")
#TODO         #TODO include("test_cookbook_geometry.jl")
#TODO         #TODO include("test_cookbook_projection.jl")
#TODO         #TODO include("test_geotransform.jl")
#TODO         #TODO include("test_images.jl")
#TODO         #TODO include("test_utils.jl")
#TODO         #TODO include("test_prepared_geometry.jl")
#TODO         #TODO Aqua.test_all(
#TODO         #TODO     ArchGDAL;
#TODO         #TODO     ambiguities = false,
#TODO         #TODO     stale_deps = false,
#TODO         #TODO     piracies = false,
#TODO         #TODO )
#TODO         return nothing
#TODO     end
#TODO end
