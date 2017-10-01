# ArchGDAL

[![Build Status](https://travis-ci.org/yeesian/ArchGDAL.jl.svg?branch=master)](https://travis-ci.org/yeesian/ArchGDAL.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/github/yeesian/ArchGDAL.jl?svg=true&branch=master)](https://ci.appveyor.com/project/NgYeeSian/archgdal-jl/branch/master)
[![Coverage Status](https://coveralls.io/repos/github/yeesian/ArchGDAL.jl/badge.svg?branch=master)](https://coveralls.io/github/yeesian/ArchGDAL.jl?branch=master)
[![codecov](https://codecov.io/gh/yeesian/ArchGDAL.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/yeesian/ArchGDAL.jl)


```julia
   _       _ _(_)_     |  A fresh approach to technical computing
  (_)     | (_) (_)    |  Documentation: https://docs.julialang.org
   _ _   _| |_  __ _   |  Type "?help" for help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 0.6.0 (2017-08-03 08:04 UTC)
 _/ |\__'_|_|_|\__'_|  |  Commit 80a9f1f11* (58 days old release-0.6)
|__/                   |  x86_64-apple-darwin16.7.0

julia> import ArchGDAL; const AG = ArchGDAL
ArchGDAL

julia> import Base.read

julia> function read(f, filename)
           return AG.registerdrivers() do
               AG.read(filename) do dataset
                   f(dataset)
       end end end
read (generic function with 1 method)

julia> read("data/point.geojson") do dataset
           print(dataset)
       end;
GDAL Dataset (Driver: GeoJSON/GeoJSON)
File(s): data/point.geojson
Number of feature layers: 1
  Layer 0: OGRGeoJSON (wkbPoint), nfeatures = 4

julia> read("data/point.geojson") do dataset
           print(AG.getlayer(dataset, 0))
       end;
Layer: OGRGeoJSON, nfeatures = 4
  Geometry 0 (): [wkbPoint], POINT (100 0), POINT (100.2785 0.0893), ...
     Field 0 (FID): [OFTReal], 2.0, 3.0, 0.0, 3.0
     Field 1 (pointname): [OFTString], point-a, point-b, a, b

julia> read("data/point.geojson") do dataset
           AG.getfeature(AG.getlayer(dataset, 0), 2) do feature
              print(feature)
           end
       end;
Feature
  (index 0) geom => POINT
  (index 0) FID => 0.0
  (index 1) pointname => a

julia> read("gdalworkshop/world.tif") do dataset
           print(dataset)
       end;
GDAL Dataset (Driver: GTiff/GeoTIFF)
File(s): gdalworkshop/world.tif
Dataset (width x height): 2048 x 1024 (pixels)
Number of raster bands: 3
  [GA_ReadOnly] Band 1 (Red): 2048 x 1024 (UInt8)
  [GA_ReadOnly] Band 2 (Green): 2048 x 1024 (UInt8)
  [GA_ReadOnly] Band 3 (Blue): 2048 x 1024 (UInt8)

julia> read("gdalworkshop/world.tif") do dataset
           print(AG.getband(dataset, 1))
       end;
[GA_ReadOnly] Band 1 (Red): 2048 x 1024 (UInt8)
    blocksize: 256x256, nodata: -1.0e10, units: 1.0px + 0.0
    overviews: (0) 1024x512 (1) 512x256 (2) 256x128
               (3) 128x64 (4) 64x32 (5) 32x16
               (6) 16x8
```
