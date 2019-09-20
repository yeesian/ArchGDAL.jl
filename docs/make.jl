using Documenter, ArchGDAL

makedocs(
    modules = [ArchGDAL],
    format = Documenter.HTML(),
    sitename = "ArchGDAL.jl",
    pages = [
        "index.md",
        "GDAL Datasets" => "datasets.md",
        "Feature Data" => "features.md",
        "Raster Data" => "rasters.md",
        "Geometric Operations" => "geometries.md",
        "Spatial Projections" => "projections.md",
        "Interactive versus Scoped Objects" => "memory.md"
        # "Working with Spatialite" => "spatialite.md"
        # "Naming Conventions" => "conventions.md", # table between GDAL, GDAL.jl, and ArchGDAL.jl
    ]
    
)

deploydocs(
    deps = nothing,
    make = nothing,
    target = "build",
    repo = "github.com/yeesian/ArchGDAL.jl.git",
)
