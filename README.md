# ArchGDAL

[![Build Status](https://travis-ci.org/yeesian/ArchGDAL.jl.svg?branch=master)](https://travis-ci.org/yeesian/ArchGDAL.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/github/yeesian/ArchGDAL.jl?svg=true&branch=master)](https://ci.appveyor.com/project/NgYeeSian/archgdal-jl/branch/master)
[![Coverage Status](https://coveralls.io/repos/github/yeesian/ArchGDAL.jl/badge.svg?branch=master)](https://coveralls.io/github/yeesian/ArchGDAL.jl?branch=master)

```julia
  | | |_| | | | (_| |  |  Version 0.4.6 (2016-06-19 17:16 UTC)
 _/ |\__'_|_|_|\__'_|  |  Official http://julialang.org/ release
|__/                   |  x86_64-apple-darwin13.4.0

julia> import ArchGDAL; const AG = ArchGDAL
ArchGDAL

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
Layer: OGRGeoJSON (wkbPoint), nfeatures = 4
Feature Definition:
  Geometry (index 0):  (wkbPoint)
     Field (index 0): FID (OFTReal)
     Field (index 1): pointname (OFTString)

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
