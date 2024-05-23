using Base.Test

const testdatadir = dirname(@__FILE__)

REPO_URL = "https://github.com/yeesian/ArchGDALDatasets/blob/master/"

remotefiles = [
    "data/A.tif",
    "data/point.geojson",
    "data/utmsmall.tif",
    "gdalworkshop/world.tif",
    "ospy/data1/sites.dbf",
    "ospy/data1/sites.prj",
    "ospy/data1/sites.sbn",
    "ospy/data1/sites.sbx",
    "ospy/data1/sites.shp",
    "ospy/data1/sites.shx",
    "ospy/data2/ut_counties.dbf",
    "ospy/data2/ut_counties.prj",
    "ospy/data2/ut_counties.shp",
    "ospy/data2/ut_counties.shx",
    "ospy/data2/ut_counties.txt",
    "ospy/data3/cache_towns.dbf",
    "ospy/data3/cache_towns.sbn",
    "ospy/data3/cache_towns.sbx",
    "ospy/data3/cache_towns.shp",
    "ospy/data3/cache_towns.shx",
    "ospy/data3/sites.dbf",
    "ospy/data3/sites.sbn",
    "ospy/data3/sites.sbx",
    "ospy/data3/sites.shp",
    "ospy/data3/sites.shx",        
    "ospy/data4/aster.img",
    "ospy/data4/aster.rrd",
    "ospy/data4/sites.dbf",
    "ospy/data4/sites.sbn",
    "ospy/data4/sites.sbx",
    "ospy/data4/sites.shp",
    "ospy/data4/sites.shx",
    "ospy/data5/aster.img",
    "ospy/data5/aster.rrd",
    "ospy/data5/doq1.img",
    "ospy/data5/doq1.rrd",
    "ospy/data5/doq2.img",
    "ospy/data5/doq2.rrd",
    "pyrasterio/example.tif",
    "pyrasterio/example2.tif",
    "pyrasterio/example3.tif",
    "pyrasterio/float_nan.tif",
    "pyrasterio/float.tif",
    "pyrasterio/RGB.byte.tif",
    "pyrasterio/shade.tif"
]

for f in remotefiles
    # create the directories if they don't exist
    currdir = dirname(f)
    isdir(currdir) || mkpath(currdir)
    # download the file
    currfile = joinpath(testdatadir, f)
    isfile(currfile) || download(REPO_URL*f*"?raw=true", currfile)
end

cd(dirname(@__FILE__)) do
    isdir("tmp") || mkpath("tmp")
    include("test_gdal_tutorials.jl")
    include("test_geometry.jl")
    include("test_types.jl")
    include("test_drivers.jl")
    include("test_feature.jl")
    include("test_featurelayer.jl")
    include("test_fielddefn.jl")
    include("test_styletable.jl")
    include("test_dataset.jl")
    include("test_rasterband.jl")
    include("test_rasterio.jl")
    include("test_rasterattrtable.jl")
    include("test_ospy_examples.jl")
    include("test_geos_operations.jl")
    include("test_cookbook_geometry.jl")
    include("test_cookbook_projection.jl")
end

for f in remotefiles
    currfile = joinpath(testdatadir, f)
    isfile(currfile) && run(`rm $currfile`)
end
