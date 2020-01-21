using Test
using Dates
using BinaryProvider

# ensure all testing files are present
# include("remotefiles.jl")

@testset "ArchGDAL" begin
    cd(dirname(@__FILE__)) do
        isdir("tmp") || mkpath("tmp")
        # include("test_datastreams.jl")
        # include("test_gdal_tutorials.jl")
        # include("test_geometry.jl")
        # include("test_types.jl")
        # include("test_display.jl")
        # include("test_drivers.jl")
        # include("test_feature.jl")
        # include("test_featurelayer.jl")
        # include("test_fielddefn.jl")
        # include("test_styletable.jl")
        # include("test_dataset.jl")
        # include("test_rasterband.jl")
        # include("test_rasterio.jl")

        # Uses largest raster
        include("test_array.jl")
        # include("test_spatialref.jl")
        # include("test_gdalutilities.jl")
        # include("test_rasterattrtable.jl")
        # include("test_ospy_examples.jl")
        # include("test_geos_operations.jl")
        # include("test_cookbook_geometry.jl")
        # include("test_cookbook_projection.jl")
    end
end
