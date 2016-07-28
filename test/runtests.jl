cd(dirname(@__FILE__)) do
    isdir("tmp") || mkpath("tmp")
    include("test_geometry.jl")
    include("test_types.jl")
    include("test_drivers.jl")
    include("test_feature.jl")
    include("test_featurelayer.jl")
    include("test_fielddefn.jl")
    include("test_styletable.jl")
    include("test_dataset.jl")
    include("test_rasterband.jl")
    include("test_rasterattrtable.jl")
    include("test_ospy_examples.jl")
    include("test_geos_operations.jl")
    include("test_gdal_tutorials.jl")
    include("test_cookbook_geometry.jl")
    # left out until https://github.com/visr/GDAL.jl/issues/30 is resolved
    # include("test_cookbook_projection.jl")
end