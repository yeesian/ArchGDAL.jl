using Test
using Dates
using GDAL

# ensure all testing files are present
include("remotefiles.jl")

@testset "ArchGDAL" begin
    cd(dirname(@__FILE__)) do
        isdir("tmp") || mkpath("tmp")
        include("test_doctest.jl")
        include("test_convert.jl")
        include("test_tables.jl")
        include("test_gdal_tutorials.jl")
        include("test_geometry.jl")
        include("test_types.jl")
        include("test_display.jl")
        include("test_drivers.jl")
        include("test_feature.jl")
        include("test_featurelayer.jl")
        include("test_fielddefn.jl")
        include("test_iterators.jl")
        include("test_styletable.jl")
        include("test_dataset.jl")
        include("test_rasterband.jl")
        include("test_rasterio.jl")
        include("test_array.jl")
        include("test_spatialref.jl")
        include("test_gdalutilities.jl")
        include("test_gdalutilities_errors.jl")
        include("test_rasterattrtable.jl")
        include("test_ospy_examples.jl")
        include("test_geos_operations.jl")
        include("test_cookbook_geometry.jl")
        include("test_cookbook_projection.jl")
        include("test_geotransform.jl")
        include("test_images.jl")
        include("test_utils.jl")
        include("test_prepared_geometry.jl")
        return nothing
    end
end
