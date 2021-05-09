# ArchGDAL
[![CI](https://github.com/yeesian/ArchGDAL.jl/workflows/CI/badge.svg)](https://github.com/yeesian/ArchGDAL.jl/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/github/yeesian/ArchGDAL.jl/badge.svg?branch=master)](https://coveralls.io/github/yeesian/ArchGDAL.jl?branch=master)
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://yeesian.com/ArchGDAL.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://yeesian.com/ArchGDAL.jl/dev)

[GDAL](http://gdal.org/) is a translator library for raster and vector geospatial data formats that is released under an [X/MIT](https://trac.osgeo.org/gdal/wiki/FAQGeneral#WhatlicensedoesGDALOGRuse) license by the [Open Source Geospatial Foundation](http://www.osgeo.org/). As a library, it presents an abstract data model to drivers for various [raster](http://www.gdal.org/formats_list.html) and [vector](http://www.gdal.org/ogr_formats.html) formats.

This package aims to be a complete solution for working with GDAL in Julia, similar in scope to [the SWIG bindings for Python](https://pypi.python.org/pypi/GDAL/) and the user-friendliness of [Fiona](https://github.com/Toblerity/Fiona) and [Rasterio](https://github.com/mapbox/rasterio). It builds on top of [GDAL.jl](https://github.com/JuliaGeo/GDAL.jl), and provides a high level API for GDAL, espousing the following principles.

## Principles (The Arch Way)
(adapted from: https://wiki.archlinux.org/index.php/Arch_Linux#Principles)

- **simplicity**: ArchGDAL tries to avoid unnecessary additions or modifications. It preserves the GDAL Data Model and requires minimal dependencies.
- **modernity**: ArchGDAL strives to maintain the latest stable release versions of GDAL as long as systemic package breakage can be reasonably avoided.
- **pragmatism**: The principles here are only useful guidelines. Ultimately, design decisions are made on a case-by-case basis through developer consensus. Evidence-based technical analysis and debate are what matter, not politics or popular opinion.
- **user-centrality**: Whereas other libraries attempt to be more user-friendly, ArchGDAL shall be user-centric. It is intended to fill the needs of those contributing to it, rather than trying to appeal to as many users as possible.
- **versatility**: ArchGDAL will strive to remain small in its assumptions about the range of user-needs, and to make it easy for users to build their own extensions/conveniences.

## Installation
To install this package, run the following command in the Pkg REPL-mode,

```julia
pkg> add ArchGDAL
```

To test if it is installed correctly,

```julia
pkg> test ArchGDAL
```

## Getting Involved

### Community

This package will not be possible without https://github.com/OSGeo/gdal and https://github.com/JuliaGeo/GDAL.jl. They are maintained by the https://www.osgeo.org/ and https://juliageo.org/ communities respectively. In case there is any source of contention or confusion, for support and involvement, we encourage participation and contributions to those libraries and communities over this package.

### Style Guide

ArchGDAL.jl uses [JuliaFormatter.jl](https://github.com/domluna/JuliaFormatter.jl) as
an autoformatting tool.

We use the options contained in [`.JuliaFormatter.toml`](https://github.com/yeesian/ArchGDAL.jl/blob/master/.JuliaFormatter.toml).

To format code, `cd` to the ArchGDAL.jl directory, then run:
```julia
] add JuliaFormatter@0.13.10
using JuliaFormatter
format("src")
```

!!! info
    A continuous integration check verifies that all PRs made to ArchGDAL.jl have
    passed the formatter.

### Dependencies
To manage the dependencies of this package, we work with [environments](https://pkgdocs.julialang.org/v1.6/environments/):

1. Navigate to the directory corresponding to the package:

```julia
shell> cd /Users/yeesian/.julia/dev/ArchGDAL
/Users/yeesian/.julia/dev/ArchGDAL
```

2. Activate the environment corresponding to `Project.toml`):

```julia
(@v1.6) pkg> activate .
  Activating environment at `~/.julia/environments/v1.6/Project.toml`
```

3. Manage the dependencies using Pkg in https://pkgdocs.julialang.org/v1.6/managing-packages/, e.g.

```julia
(ArchGDAL) pkg> st
     Project ArchGDAL v0.6.0
      Status `~/.julia/dev/ArchGDAL/Project.toml`
  [3c3547ce] DiskArrays
  [add2ef01] GDAL
  [68eda718] GeoFormatTypes
  [cf35fbd7] GeoInterface
  [bd369af6] Tables
  [ade2ca70] Dates

(ArchGDAL) pkg> add CEnum
   Resolving package versions...
    Updating `~/.julia/dev/ArchGDAL/Project.toml`
  [fa961155] + CEnum v0.4.1
  [3c3547ce] + DiskArrays v0.2.7
  [add2ef01] + GDAL v1.2.1
  [68eda718] + GeoFormatTypes v0.3.0
  [cf35fbd7] + GeoInterface v0.5.5
  [bd369af6] + Tables v1.4.2
```
