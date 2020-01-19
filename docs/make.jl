using Documenter, ArchGDAL

# make sure you have run the tests before such that the test files are present
makedocs(
    modules = [ArchGDAL],
    format = Documenter.HTML(),
    sitename = "ArchGDAL.jl",
    workdir = joinpath(@__DIR__, "..", "test"),
    strict = true,
    pages = [
        "index.md",
        "GDAL Datasets" => "datasets.md",
        "Feature Data" => "features.md",
        "Raster Data" => "rasters.md",
        "Geometric Operations" => "geometries.md",
        "Spatial Projections" => "projections.md",
        # "Working with Spatialite" => "spatialite.md",
        "Interactive versus Scoped Objects" => "memory.md",
        "Design Considerations" => "considerations.md",
        "API Reference" => "reference.md",
        # "Naming Conventions" => "conventions.md", # table between GDAL, GDAL.jl, and ArchGDAL.jl
    ]
)

deploydocs(
    deps = nothing,
    make = nothing,
    target = "build",
    repo = "github.com/yeesian/ArchGDAL.jl.git",
)
