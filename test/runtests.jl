using ArchGDAL
using Base.Test

cd(dirname(@__FILE__)) do
    isdir("tmp") || mkpath("tmp")
    include("test_ospy_examples.jl")
    include("test_geos_operations.jl")
    include("test_gdal_tutorials.jl")
    include("test_cookbook_geometry.jl")
    # left out until https://github.com/visr/GDAL.jl/issues/30 is resolved
    # include("test_cookbook_projection.jl")
end