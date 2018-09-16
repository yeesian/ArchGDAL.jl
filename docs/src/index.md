# ArchGDAL.jl documentation

[GDAL](http://gdal.org/) is a translator library for raster and vector geospatial data formats that is released under an [X/MIT](https://trac.osgeo.org/gdal/wiki/FAQGeneral#WhatlicensedoesGDALOGRuse) license by the [Open Source Geospatial Foundation](http://www.osgeo.org/). As a library, it presents an abstract data model to drivers for various [raster](http://www.gdal.org/formats_list.html) and [vector](http://www.gdal.org/ogr_formats.html) formats.

This package aims to be a complete solution for working with GDAL in Julia, similar in scope to [the SWIG bindings for Python](https://pypi.python.org/pypi/GDAL/). It builds on top of [GDAL.jl](https://github.com/visr/GDAL.jl), and provides a high level API for GDAL, espousing the following principles.

## Principles (The Arch Way)
(adapted from: https://wiki.archlinux.org/index.php/Arch_Linux#Principles)

- **simplicity**: without unnecessary additions or modifications.
    (i) Preserves GDAL Data Model, and makes available GDAL/OGR methods without trying to mask them from the user.
    (ii) minimal dependencies
- **modernity**: ArchGDAL strives to maintain the latest stable release versions of GDAL as long as systemic package breakage can be reasonably avoided.
- **pragmatism**: The principles here are only useful guidelines. Ultimately, design decisions are made on a case-by-case basis through developer consensus. Evidence-based technical analysis and debate are what matter, not politics or popular opinion.
- **user-centrality**: Whereas other libraries attempt to be more user-friendly, ArchGDAL shall be user-centric. It is intended to fill the needs of those contributing to it, rather than trying to appeal to as many users as possible.
- **versatility**: ArchGDAL will strive to remain small in its assumptions about the range of user-needs, and to make it easy for users to build their own extensions/conveniences.

## Installation
This package is currently unregistered, so add it by running:

```julia
pkg> add https://github.com/yeesian/ArchGDAL.jl #master
```

To test if it is installed correctly,

```julia
pkg> test ArchGDAL
```
