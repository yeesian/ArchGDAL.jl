# ArchGDAL

[![Build Status](https://travis-ci.org/yeesian/ArchGDAL.jl.svg?branch=travis)](https://travis-ci.org/yeesian/ArchGDAL.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/q4nw4rf7solrsn3q/branch/master?svg=true)](https://ci.appveyor.com/project/NgYeeSian/archgdal-jl/branch/master)
[![Coverage Status](https://coveralls.io/repos/github/yeesian/ArchGDAL.jl/badge.svg?branch=master)](https://coveralls.io/github/yeesian/ArchGDAL.jl?branch=master)

```julia
  | | |_| | | | (_| |  |  Version 0.4.6 (2016-06-19 17:16 UTC)
 _/ |\__'_|_|_|\__'_|  |  Official http://julialang.org/ release
|__/                   |  x86_64-apple-darwin13.4.0

julia> import ArchGDAL; const AG = ArchGDAL
ArchGDAL

julia> AG.registerdrivers() do
           AG.read("data/point.geojson") do dataset
               print(dataset)
       end
       end
GDAL Dataset (Driver: GeoJSON/GeoJSON)
File(s): data/point.geojson
Number of feature layers: 1
  Layer 0: OGRGeoJSON (Point), nfeatures = 4

julia> AG.registerdrivers() do
           AG.read("data/point.geojson") do dataset
               print(AG.borrow_getlayer(dataset, 0))
       end
       end
Layer: OGRGeoJSON (Point), nfeatures = 4
Feature Definition:
  Geometry (index 0):  (Point)
     Field (index 0): FID (Float64)
     Field (index 1): pointname (Cstring)
false

julia> AG.registerdrivers() do
           AG.read("data/point.geojson") do dataset
               layer = AG.borrow_getlayer(dataset, 0)
               AG.getfeature(layer, 2) do feature
                   print(feature)
       end
       end
       end
Feature
  (index 0) geom => POINT
  (index 0) FID => 0.0
  (index 1) pointname => a
false

julia> AG.registerdrivers() do
           AG.read("gdalworkshop/world.tif") do dataset
               print(dataset)
       end
       end
GDAL Dataset (Driver: GTiff/GeoTIFF)
File(s): gdalworkshop/world.tif
Dataset (width x height): 2048 x 1024 (pixels)
Number of raster bands: 3
  [ReadOnly] Band 1 (Red): 2048 x 1024 (UInt8)
  [ReadOnly] Band 2 (Green): 2048 x 1024 (UInt8)
  [ReadOnly] Band 3 (Blue): 2048 x 1024 (UInt8)

julia> AG.registerdrivers() do
           AG.read("gdalworkshop/world.tif") do dataset
               print(AG.getband(dataset, 1))
       end
       end
[ReadOnly] Band 1 (Red): 2048 x 1024 (UInt8)
    blocksize: 256x256, nodata: -1.0e10, units: 1.0px + 0.0
    overviews: (0) 1024x512 (1) 512x256 (2) 256x128 (3) 128x64
               (4) 64x32 (5) 32x16 (6) 16x8
```