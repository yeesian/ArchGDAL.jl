using Test
using Dates
using BinaryProvider

const testdatadir = @__DIR__

REPO_URL = "https://github.com/yeesian/ArchGDALDatasets/blob/master/"

# remote files with SHA-2 256 hash
remotefiles = [
    ("data/A.tif", "8e8654c56dcb6cfd4b446f811cf3ca84713dbc4768107c1d84a614abeec77898"),
    ("data/point.geojson", "8744593479054a67c784322e0c198bfa880c9388b39a2ddd4c56726944711bd9"),
    ("data/utmsmall.tif", "f40dae6e8b5e18f3648e9f095e22a0d7027014bb463418d32f732c3756d8c54f"),
    ("gdalworkshop/world.tif", "b376dc8af62f9894b5050a6a9273ac0763ae2990b556910d35d4a8f4753278bb"),
    ("ospy/data1/sites.dbf", "7df95edea06c46418287ae3430887f44f9116b29715783f7d1a11b2b931d6e7d"),
    ("ospy/data1/sites.prj", "81fb1a246728609a446b25b0df9ede41c3e7b6a133ce78f10edbd2647fc38ce1"),
    ("ospy/data1/sites.sbn", "198d9d695f3e7a0a0ac0ebfd6afbe044b78db3e685fffd241a32396e8b341ed3"),
    ("ospy/data1/sites.sbx", "49bbe1942b899d52cf1d1b01ea10bd481ec40bdc4c94ff866aece5e81f2261f6"),
    ("ospy/data1/sites.shp", "69af5a6184053f0b71f266dc54c944f1ec02013fb66dbb33412d8b1976d5ea2b"),
    ("ospy/data1/sites.shx", "1f3da459ccb151958743171e41e6a01810b2a007305d55666e01d680da7bbf08"),
    ("ospy/data2/ut_counties.dbf", "94607dfbcb1b547bef9956e5704520003e20d3c1b7d9c38ae6c275a68a359c35"),
    ("ospy/data2/ut_counties.prj", "f10dda97619145fe1e0c6b067675171c5b7f3861755a2daecb18f9a688df4620"),
    ("ospy/data2/ut_counties.shp", "e05104edc9c2120cccad9bd4e316fc3e937f706e8c3ad79118784fcafe78f695"),
    ("ospy/data2/ut_counties.shx", "20d9acbf261bfbcb8a751e6945aeb1589809c9bd5361f5714577d9513bb32bc6"),
    ("ospy/data2/ut_counties.txt", "06585b736091f5bbc62eb040918b1693b2716f550ab306026732e1dfa6cd49a7"),
    ("ospy/data3/cache_towns.dbf", "2344b5195e1a7cbc141f38d6f3214f04c0d43058309b162e877fca755cd1d9fa"),
    ("ospy/data3/cache_towns.sbn", "217e938eb0bec1cdccf26d87e5127d395d68b5d660bc1ecc1d7ec7b3f052f4e3"),
    ("ospy/data3/cache_towns.sbx", "e027b3f67bbb60fc9cf67ab6f430b286fd8a1eaa6c344edaa7da4327485ee9f2"),
    ("ospy/data3/cache_towns.shp", "635998f789d349d80368cb105e7e0d61f95cc6eecd36b34bf005d8c7e966fedb"),
    ("ospy/data3/cache_towns.shx", "0cafc504b829a3da2c0363074f775266f9e1f6aaaf1e066b8a613d5862f313b7"),
    ("ospy/data3/sites.dbf", "7df95edea06c46418287ae3430887f44f9116b29715783f7d1a11b2b931d6e7d"),
    ("ospy/data3/sites.sbn", "198d9d695f3e7a0a0ac0ebfd6afbe044b78db3e685fffd241a32396e8b341ed3"),
    ("ospy/data3/sites.sbx", "49bbe1942b899d52cf1d1b01ea10bd481ec40bdc4c94ff866aece5e81f2261f6"),
    ("ospy/data3/sites.shp", "69af5a6184053f0b71f266dc54c944f1ec02013fb66dbb33412d8b1976d5ea2b"),
    ("ospy/data3/sites.shx", "1f3da459ccb151958743171e41e6a01810b2a007305d55666e01d680da7bbf08"),
    ("ospy/data4/aster.img", "2423205bdf820b1c2a3f03862664d84ea4b5b899c57ed33afd8962664e80a298"),
    ("ospy/data4/aster.rrd", "18e038aabe8fd92b0d12cd4f324bb2e0368343e20cc41e5411a6d038108a25cf"),
    ("ospy/data4/sites.dbf", "7df95edea06c46418287ae3430887f44f9116b29715783f7d1a11b2b931d6e7d"),
    ("ospy/data4/sites.sbn", "198d9d695f3e7a0a0ac0ebfd6afbe044b78db3e685fffd241a32396e8b341ed3"),
    ("ospy/data4/sites.sbx", "49bbe1942b899d52cf1d1b01ea10bd481ec40bdc4c94ff866aece5e81f2261f6"),
    ("ospy/data4/sites.shp", "69af5a6184053f0b71f266dc54c944f1ec02013fb66dbb33412d8b1976d5ea2b"),
    ("ospy/data4/sites.shx", "1f3da459ccb151958743171e41e6a01810b2a007305d55666e01d680da7bbf08"),
    ("ospy/data5/aster.img", "2423205bdf820b1c2a3f03862664d84ea4b5b899c57ed33afd8962664e80a298"),
    ("ospy/data5/aster.rrd", "18e038aabe8fd92b0d12cd4f324bb2e0368343e20cc41e5411a6d038108a25cf"),
    ("ospy/data5/doq1.img", "70b8e641c52367107654962e81977be65402aa3c46736a07cb512ce960203bb7"),
    ("ospy/data5/doq1.rrd", "f9f2fe57d789977090ec0c31e465052161886e79a4c4e10805b5e7ab28c06177"),
    ("ospy/data5/doq2.img", "1e1d744f17e6a3b97dd9b7d8705133c72ff162613bae43ad94417c54e6aced5d"),
    ("ospy/data5/doq2.rrd", "8274dad00b27e008e5ada62afb1025b0e6e2ef2d2ff2642487ecaee64befd914"),
    ("pyrasterio/example.tif", "e4f50bf1f92d8b045c41c6ec101c60e88d663213db9ab90983a66219f28e1b8e"),
    ("pyrasterio/example2.tif", "08145d14e37d68dc586e0ddc74ad5047577ab86c52f2999cd34c0d851a82214c"),
    ("pyrasterio/example3.tif", "e37f6e54d3fb565905a53e9c4a54cc2dd4937df92e35a0aba40470ac166e8688"),
    ("pyrasterio/float_nan.tif", "ae2b8df3ff521d358c1cdd06a3d721ebb028fb19ce89f7e7e83f5efe66d39e1d"),
    ("pyrasterio/float.tif", "758905d08f0f577571bdc083b50c638872c4e1c6465e75076c4ecdd1599e3b24"),
    ("pyrasterio/RGB.byte.tif", "8a9079098409b516d0c3d1965b6ebf64ab69fec12e0c2495d6b200c2ea9dd12a"),
    ("pyrasterio/shade.tif", "a763eb1f223845eeaf6309a11d03acb221b7d54cda526a639fb71a75ba5ec49b")
]

for (f, sha) in remotefiles
    # create the directories if they don't exist
    currdir = dirname(f)
    isdir(currdir) || mkpath(currdir)
    # download the file if it is not there or if it has a different checksum
    currfile = normpath(joinpath(testdatadir, f))
    url = REPO_URL * f * "?raw=true"
    download_verify(url, sha, currfile; force=true)
end

@testset "ArchGDAL" begin
    cd(dirname(@__FILE__)) do
        isdir("tmp") || mkpath("tmp")
        include("test_datastreams.jl")
        include("test_gdal_tutorials.jl")
        include("test_geometry.jl")
        include("test_types.jl")
        include("test_display.jl")
        include("test_drivers.jl")
        include("test_feature.jl")
        include("test_featurelayer.jl")
        include("test_fielddefn.jl")
        include("test_styletable.jl")
        include("test_dataset.jl")
        include("test_rasterband.jl")
        include("test_rasterio.jl")
        include("test_spatialref.jl")
        include("test_gdalutilities.jl")
        include("test_rasterattrtable.jl")
        include("test_ospy_examples.jl")
        include("test_geos_operations.jl")
        include("test_cookbook_geometry.jl")
        include("test_cookbook_projection.jl")
    end
end
