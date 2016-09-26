# ArchGDAL

[![Build Status](https://travis-ci.org/yeesian/ArchGDAL.jl.svg?branch=master)](https://travis-ci.org/yeesian/ArchGDAL.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/github/yeesian/ArchGDAL.jl?svg=true&branch=master)](https://ci.appveyor.com/project/NgYeeSian/archgdal-jl/branch/master)
[![Coverage Status](https://coveralls.io/repos/github/yeesian/ArchGDAL.jl/badge.svg?branch=master)](https://coveralls.io/github/yeesian/ArchGDAL.jl?branch=master)
[![codecov](https://codecov.io/gh/yeesian/ArchGDAL.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/yeesian/ArchGDAL.jl)

[GDAL](http://gdal.org/) is a translator library for raster and vector geospatial data formats that is released under an [X/MIT](https://trac.osgeo.org/gdal/wiki/FAQGeneral#WhatlicensedoesGDALOGRuse) license by the [Open Source Geospatial Foundation](http://www.osgeo.org/). As a library, it presents an abstract data model to drivers for various [raster](http://www.gdal.org/formats_list.html) and [vector](http://www.gdal.org/ogr_formats.html) formats.

## Principles (The Arch Way)
(adapted from: https://wiki.archlinux.org/index.php/Arch_Linux#Principles)

This package aims to be a complete solution for working with GDAL in Julia, similar in scope to [the SWIG bindings for Python](https://pypi.python.org/pypi/GDAL/). It builds on top of [GDAL.jl](https://github.com/visr/GDAL.jl), and provides a high level API for GDAL, espousing the following principles:

- **simplicity**: without unnecessary additions or modifications.
    (i) Preserves GDAL Data Model, and makes available GDAL/OGR methods without trying to mask them from the user.
    (ii) minimal dependencies
- **modernity**: ArchGDAL strives to maintain the latest stable release versions of GDAL as long as systemic package breakage can be reasonably avoided. You can stay with older versions by [pinning them](http://docs.julialang.org/en/release-0.4/manual/packages/#checkout-pin-and-free)
- **pragmatism**: The principles here are only useful guidelines. Ultimately, design decisions are made on a case-by-case basis through developer consensus. Evidence-based technical analysis and debate are what matter, not politics or popular opinion.
- **user-centrality**: whereas other libraries attempt to be more user-friendly, ArchGDAL shall be user-centric. It is intended to fill the needs of those contributing to it, rather than trying to appeal to as many users as possible.
- **versatility**: ArchGDAL will strive to remain small in its assumptions about the range of user-needs, and to make it easy for users to build their own extensions/conveniences.

## Installation
This package is currently unregistered, so add it using `Pkg.clone`, then find or get the GDAL dependencies using `Pkg.build`:

```julia
Pkg.clone("https://github.com/visr/GDAL.jl.git")
Pkg.build("GDAL")
Pkg.clone("https://github.com/yeesian/ArchGDAL.jl.git")
```

`Pkg.build("GDAL")` searches for a GDAL 2.1+ shared library on the path. If not found, it will download and install it. To test if it is installed correctly, use:

```julia
Pkg.test("GDAL")
Pkg.test("ArchGDAL")
```

## Usage

Here are some usage examples:
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
               end
           end
       end
read (generic function with 1 method)

julia> read("data/point.geojson") do dataset
           print(dataset)
       end
GDAL Dataset (Driver: GeoJSON/GeoJSON)
File(s):
  data/point.geojson

Number of feature layers: 1
  Layer 0: OGRGeoJSON (wkbPoint)

julia> read("data/point.geojson") do dataset
           print(AG.getlayer(dataset, 0))
       end;
Layer: OGRGeoJSON
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
       end
GDAL Dataset (Driver: GTiff/GeoTIFF)
File(s):
  gdalworkshop/world.tif

Dataset (width x height): 2048 x 1024 (pixels)
Number of raster bands: 3
  [GA_ReadOnly] Band 1 (Red): 2048 x 1024 (UInt8)
  [GA_ReadOnly] Band 2 (Green): 2048 x 1024 (UInt8)
  [GA_ReadOnly] Band 3 (Blue): 2048 x 1024 (UInt8)

julia> read("gdalworkshop/world.tif") do dataset
           print(AG.getband(dataset, 1))
       end
[GA_ReadOnly] Band 1 (Red): 2048 x 1024 (UInt8)
    blocksize: 256×256, nodata: -1.0e10, units: 1.0px + 0.0
    overviews: (0) 1024x512 (1) 512x256 (2) 256x128
               (3) 128x64 (4) 64x32 (5) 32x16
               (6) 16x8
```

The examples demonstrate that it is easy to achieve a degree of user friendliness similar to the [fiona](https://github.com/Toblerity/Fiona) and [rasterio](https://github.com/mapbox/rasterio) python bindings, without suffering from the [gotchas in the SWIG bindings](https://trac.osgeo.org/gdal/wiki/PythonGotchas).

Unlike the [design of fiona](http://toblerity.org/fiona/manual.html#introduction):

> Please understand this: Fiona is designed to excel in a certain range of tasks and is less optimal in others. Fiona trades memory and speed for simplicity and reliability. Where OGR’s Python bindings (for example) use C pointers, Fiona copies vector data from the data source to Python objects. These are simpler and safer to use, but more memory intensive. Fiona’s performance is relatively more slow if you only need access to a single record field – and of course if you just want to reproject or filter data files, nothing beats the ogr2ogr program – but Fiona’s performance is much better than OGR’s Python bindings if you want all fields and coordinates of a record. The copying is a constraint, but it simplifies programs. With Fiona, you don’t have to track references to C objects to avoid crashes, and you can work with vector data using familiar Python mapping accessors.

`ArchGDAL` does not automatically copy data from data sources, making it approriate for a broader range of geospatial processing tasks. As modern [builds](https://trac.osgeo.org/gdal/wiki/BuildHints) of GDAL (e.g. by [Homebrew](https://github.com/OSGeo/homebrew-osgeo4mac) and [Conda-Forge](https://github.com/conda-forge/gdal-feedstock)) comes pre-compiled with support for PROJ.4 and GEOS, `ArchGDAL.jl` avoids the price of data serialization (in [duck-typing proposals](https://gist.github.com/sgillies/2217756)) while enjoying the full spectrum of GIS functionality.