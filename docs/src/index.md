# ArchGDAL.jl documentation

[GDAL](http://gdal.org/) is a translator library for raster and vector geospatial data formats that is released under an [X/MIT](https://trac.osgeo.org/gdal/wiki/FAQGeneral#WhatlicensedoesGDALOGRuse) license by the [Open Source Geospatial Foundation](http://www.osgeo.org/). As a library, it presents an abstract data model to drivers for various [raster](http://www.gdal.org/formats_list.html) and [vector](http://www.gdal.org/ogr_formats.html) formats.

ArchGDAL.jl aims to be a complete solution for working with GDAL in Julia, similar in scope to [the SWIG bindings for Python](https://pypi.python.org/pypi/GDAL/). It builds on top of [GDAL.jl](https://github.com/visr/GDAL.jl), and provides a high level API for GDAL, espousing the following principles.

## Principles (The Arch Way)
(adapted from https://wiki.archlinux.org/index.php/Arch_Linux#Principles)

- **simplicity**: without unnecessary additions or modifications. It preserves the GDAL Data Model and requires minimal dependencies.
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

To load the package,

```julia
julia> using ArchGDAL
```

In the documentation `AG` is often used as a shorthand for `ArchGDAL`. To use this shorthand you can use:
```julia
import ArchGDAL as AG
```

## Contents

```@contents
```
