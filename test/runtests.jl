using Test
using Dates
using GDAL
import ArchGDAL
import Aqua

# ensure all testing files are present
include("remotefiles.jl")

@testset "ArchGDAL" begin
    cd(dirname(@__FILE__)) do
        isdir("tmp") || mkpath("tmp")
        #TODO include("test_doctest.jl")
        #TODO include("test_convert.jl")
        #TODO include("test_tables.jl")
        #TODO include("test_gdal_tutorials.jl")
        #TODO include("test_geometry.jl")
        #TODO include("test_types.jl")
        #TODO include("test_display.jl")
        #TODO include("test_drivers.jl")
        #TODO include("test_feature.jl")
        #TODO include("test_featurelayer.jl")
        #TODO include("test_fielddefn.jl")
        #TODO include("test_iterators.jl")
        #TODO include("test_styletable.jl")
        #TODO include("test_dataset.jl")
        #TODO include("test_rasterband.jl")
        #TODO include("test_rasterio.jl")
        #TODO include("test_array.jl")
        #TODO include("test_spatialref.jl")
        #TODO include("test_gdalutilities.jl")
        #TODO include("test_gdalutilities_errors.jl")
        #TODO include("test_rasterattrtable.jl")
        include("test_mdarray.jl")
        #TODO include("test_ospy_examples.jl")
        #TODO include("test_geos_operations.jl")
        #TODO include("test_cookbook_geometry.jl")
        #TODO include("test_cookbook_projection.jl")
        #TODO include("test_geotransform.jl")
        #TODO include("test_images.jl")
        #TODO include("test_utils.jl")
        #TODO include("test_prepared_geometry.jl")
        #TODO Aqua.test_all(
        #TODO     ArchGDAL;
        #TODO     ambiguities = false,
        #TODO     stale_deps = false,
        #TODO     piracies = false,
        #TODO )
        return nothing
    end
end
