# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]

### Added

- ArchGDAL added `subdatasets` to list the filenames of a dataset's subdatasets. [#489](https://github.com/yeesian/ArchGDAL.jl/pull/489)

### Fixed

- The CompatHelper workflow avoids Julia version parsing failures. [#499](https://github.com/yeesian/ArchGDAL.jl/pull/499)

### Changed

- JuliaFormatter formatted the Julia source and tests. [#495](https://github.com/yeesian/ArchGDAL.jl/pull/495), [#502](https://github.com/yeesian/ArchGDAL.jl/pull/502)

## [0.10.12] - 2026-08-13

### Added

- ArchGDAL exposed driver-defined feature IDs as columns through the Tables interface. [#496](https://github.com/yeesian/ArchGDAL.jl/pull/496)
- `GeoInterface.coordtype` reports `Float64` for ArchGDAL geometries. [#479](https://github.com/yeesian/ArchGDAL.jl/pull/479)

### Fixed

- The macOS CI jobs no longer set a fixed runner architecture. [#497](https://github.com/yeesian/ArchGDAL.jl/pull/497)

### Changed

- `RasterDataset` precomputes its chunks to avoid repeated construction. [#462](https://github.com/yeesian/ArchGDAL.jl/pull/462)
- CI updated its cache, checkout, setup-julia, and Codecov actions. [#488](https://github.com/yeesian/ArchGDAL.jl/pull/488), [#490](https://github.com/yeesian/ArchGDAL.jl/pull/490), [#491](https://github.com/yeesian/ArchGDAL.jl/pull/491), [#492](https://github.com/yeesian/ArchGDAL.jl/pull/492), [#493](https://github.com/yeesian/ArchGDAL.jl/pull/493)

## [0.10.11] - 2026-01-05

### Changed

- ArchGDAL supports JLD2 0.6. [#485](https://github.com/yeesian/ArchGDAL.jl/pull/485)
- CI updated its checkout and pull-request actions. [#478](https://github.com/yeesian/ArchGDAL.jl/pull/478), [#483](https://github.com/yeesian/ArchGDAL.jl/pull/483), [#484](https://github.com/yeesian/ArchGDAL.jl/pull/484)

## [0.10.10] - 2025-07-13

### Fixed

- ArchGDAL restored the canonical GTiff and GeoJSON extension mappings for GDAL 3.11. [#476](https://github.com/yeesian/ArchGDAL.jl/pull/476)

## [0.10.9] - 2025-07-11

### Changed

- ArchGDAL supports Makie 0.24. [#471](https://github.com/yeesian/ArchGDAL.jl/pull/471)
- The Makie extension uses GeoInterface plot macros. [#473](https://github.com/yeesian/ArchGDAL.jl/pull/473)
- JuliaFormatter formatted the Julia source and tests. [#465](https://github.com/yeesian/ArchGDAL.jl/pull/465)

## [0.10.8] - 2025-01-22

### Changed

- ArchGDAL supports Makie 0.22. [#461](https://github.com/yeesian/ArchGDAL.jl/pull/461)
- JuliaFormatter formatted the Julia tests. [#460](https://github.com/yeesian/ArchGDAL.jl/pull/460)

## [0.10.7] - 2025-01-09

### Added

- ArchGDAL supports the `GFT.ProjJSON` field type. [#458](https://github.com/yeesian/ArchGDAL.jl/pull/458)
- `GeoInterface.trait` returns `FeatureTrait` for ArchGDAL features. [#457](https://github.com/yeesian/ArchGDAL.jl/pull/457)

### Changed

- CI updated its pull-request and Codecov actions. [#455](https://github.com/yeesian/ArchGDAL.jl/pull/455), [#456](https://github.com/yeesian/ArchGDAL.jl/pull/456)

## [0.10.6] - 2024-12-20

### Added

- ArchGDAL added generic field-setting fallbacks for `Real` and `Integer` values. [#454](https://github.com/yeesian/ArchGDAL.jl/pull/454)

### Fixed

- Empty layers now return a Tables schema. [#441](https://github.com/yeesian/ArchGDAL.jl/pull/441)

### Changed

- CI updated the Julia setup action to version 2. [#422](https://github.com/yeesian/ArchGDAL.jl/pull/422)
- JuliaFormatter formatted the Julia source. [#450](https://github.com/yeesian/ArchGDAL.jl/pull/450)

### Removed

- ArchGDAL removed support for Julia 1.6. [#451](https://github.com/yeesian/ArchGDAL.jl/pull/451)

## [0.10.5] - 2024-11-15

### Added

- ArchGDAL added JLD2 geometry serialization through WKB. [#448](https://github.com/yeesian/ArchGDAL.jl/pull/448)

### Fixed

- ArchGDAL copies array-like feature fields before GDAL can overwrite their memory. [#442](https://github.com/yeesian/ArchGDAL.jl/pull/442)
- The test suite supports GDAL 3.9. [#447](https://github.com/yeesian/ArchGDAL.jl/pull/447)

### Changed

- ArchGDAL supports ColorTypes 0.12. [#439](https://github.com/yeesian/ArchGDAL.jl/pull/439)
- The benchmark workflow uses the current Julia LTS release. [#443](https://github.com/yeesian/ArchGDAL.jl/pull/443)
- JuliaFormatter formatted the Julia source. [#437](https://github.com/yeesian/ArchGDAL.jl/pull/437), [#438](https://github.com/yeesian/ArchGDAL.jl/pull/438)

## [0.10.4] - 2024-05-23

### Changed

- ArchGDAL supports GDAL.jl 1.7. [#426](https://github.com/yeesian/ArchGDAL.jl/pull/426)

## [0.10.3] - 2024-05-10

### Added

- ArchGDAL added a Makie extension for plotting geometries. [#404](https://github.com/yeesian/ArchGDAL.jl/pull/404)
- `read!` and `rasterio!` can write into any `AbstractArray`. [#411](https://github.com/yeesian/ArchGDAL.jl/pull/411)
- `RasterDataset` forwards `gdalinfo` calls. [#415](https://github.com/yeesian/ArchGDAL.jl/pull/415)
- ArchGDAL added the GDAL `GDT_Int8` type and Julia `Int8` mapping. [#423](https://github.com/yeesian/ArchGDAL.jl/pull/423)

### Fixed

- The tests use the current spatialreference.org URL. [#407](https://github.com/yeesian/ArchGDAL.jl/pull/407)

### Changed

- ArchGDAL supports DiskArrays 0.4 and Makie 0.21. [#417](https://github.com/yeesian/ArchGDAL.jl/pull/417), [#424](https://github.com/yeesian/ArchGDAL.jl/pull/424)
- JuliaFormatter formatted the raster source and tests. [#408](https://github.com/yeesian/ArchGDAL.jl/pull/408), [#412](https://github.com/yeesian/ArchGDAL.jl/pull/412)
- CI updated its cache, Codecov, and pull-request actions. [#406](https://github.com/yeesian/ArchGDAL.jl/pull/406), [#413](https://github.com/yeesian/ArchGDAL.jl/pull/413), [#414](https://github.com/yeesian/ArchGDAL.jl/pull/414)

## [0.10.2] - 2023-12-22

### Added

- ArchGDAL added `importUserInput` for custom coordinate reference system strings. [#372](https://github.com/yeesian/ArchGDAL.jl/pull/372)
- ArchGDAL added `copylayers!` for copying layers between datasets. [#382](https://github.com/yeesian/ArchGDAL.jl/pull/382)
- `writelayers` can select the source layers that it writes. [#382](https://github.com/yeesian/ArchGDAL.jl/pull/382)
- ArchGDAL converts spatial references between WKT and EPSG GeoFormatTypes forms. [#391](https://github.com/yeesian/ArchGDAL.jl/pull/391)
- ArchGDAL supports compound two-code GeoFormatTypes EPSG references. [#374](https://github.com/yeesian/ArchGDAL.jl/pull/374)
- `GeoInterface.crs` returns coordinate reference systems for ArchGDAL geometries, layers, and datasets. [#405](https://github.com/yeesian/ArchGDAL.jl/pull/405)

### Fixed

- ArchGDAL infers `GeoInterface.getcoord` return types more precisely. [#379](https://github.com/yeesian/ArchGDAL.jl/pull/379)
- `GeoInterface.getcoord` reports invalid coordinate requests. [#379](https://github.com/yeesian/ArchGDAL.jl/pull/379)
- The test suite supports GDAL 3.7.2. [#395](https://github.com/yeesian/ArchGDAL.jl/pull/395)
- The documentation uses the correct geometry tutorial link. [#398](https://github.com/yeesian/ArchGDAL.jl/pull/398)

### Changed

- ArchGDAL provides faster GeoInterface point access for line strings. [#369](https://github.com/yeesian/ArchGDAL.jl/pull/369)
- ArchGDAL supports CEnum 0.5 and ImageCore 0.10. [#396](https://github.com/yeesian/ArchGDAL.jl/pull/396), [#392](https://github.com/yeesian/ArchGDAL.jl/pull/392)
- JuliaFormatter formatted the Julia source and tests. [#380](https://github.com/yeesian/ArchGDAL.jl/pull/380), [#388](https://github.com/yeesian/ArchGDAL.jl/pull/388), [#401](https://github.com/yeesian/ArchGDAL.jl/pull/401)
- The project enabled Dependabot. [#383](https://github.com/yeesian/ArchGDAL.jl/pull/383)
- CompatHelper runs the package tests. [#393](https://github.com/yeesian/ArchGDAL.jl/pull/393)
- CI updated its checkout, cache, Codecov, and pull-request actions. [#384](https://github.com/yeesian/ArchGDAL.jl/pull/384), [#385](https://github.com/yeesian/ArchGDAL.jl/pull/385), [#386](https://github.com/yeesian/ArchGDAL.jl/pull/386), [#387](https://github.com/yeesian/ArchGDAL.jl/pull/387), [#394](https://github.com/yeesian/ArchGDAL.jl/pull/394)

## [0.10.1] - 2023-04-21

### Added

- ArchGDAL added module-level `GeoInterface.convert` support for compatible geometries. [#362](https://github.com/yeesian/ArchGDAL.jl/pull/362)
- The documentation added a GeoFormatTypes reprojection example. [#368](https://github.com/yeesian/ArchGDAL.jl/pull/368)

### Fixed

- SQL queries accept concrete `IGeometry` values as spatial filters. [#364](https://github.com/yeesian/ArchGDAL.jl/pull/364)

### Changed

- The project added its first changelog for v0.10.0. [#360](https://github.com/yeesian/ArchGDAL.jl/pull/360)
- JuliaFormatter formatted the Julia source and geometry tests. [#363](https://github.com/yeesian/ArchGDAL.jl/pull/363)

## [0.10.0] - 2023-01-07

### Added

- Added CHANGELOG.md

### Changed

- breaking: Updated compat for GDAL.jl 1.5 and fixed tests for GDAL 3.6. These include changes to `gdalnearblack`, `fillunsetwithdefault!` and `gdalgetgeotransform`.
- breaking: Use `GeoInterface.convert` instead of `convert` to convert geometries from other
  packages to ArchGDAL via the GeoInterface. Example: `GeoInterface.convert(AG.IGeometry, geom)`

## [0.9.4] - 2022-12-30

### Fixed

-  Fix macro callback. [#352](https://github.com/yeesian/ArchGDAL.jl/pull/352)

### Changed

- Let's handle pointers in ccall using unsafe_convert [#349](https://github.com/yeesian/ArchGDAL.jl/pull/349)

[Unreleased]: https://github.com/yeesian/ArchGDAL.jl/compare/v0.10.12...HEAD
[0.10.12]: https://github.com/yeesian/ArchGDAL.jl/compare/v0.10.11...v0.10.12
[0.10.11]: https://github.com/yeesian/ArchGDAL.jl/compare/v0.10.10...v0.10.11
[0.10.10]: https://github.com/yeesian/ArchGDAL.jl/compare/v0.10.9...v0.10.10
[0.10.9]: https://github.com/yeesian/ArchGDAL.jl/compare/v0.10.8...v0.10.9
[0.10.8]: https://github.com/yeesian/ArchGDAL.jl/compare/v0.10.7...v0.10.8
[0.10.7]: https://github.com/yeesian/ArchGDAL.jl/compare/v0.10.6...v0.10.7
[0.10.6]: https://github.com/yeesian/ArchGDAL.jl/compare/v0.10.5...v0.10.6
[0.10.5]: https://github.com/yeesian/ArchGDAL.jl/compare/v0.10.4...v0.10.5
[0.10.4]: https://github.com/yeesian/ArchGDAL.jl/compare/v0.10.3...v0.10.4
[0.10.3]: https://github.com/yeesian/ArchGDAL.jl/compare/v0.10.2...v0.10.3
[0.10.2]: https://github.com/yeesian/ArchGDAL.jl/compare/v0.10.1...v0.10.2
[0.10.1]: https://github.com/yeesian/ArchGDAL.jl/compare/v0.10.0...v0.10.1
[0.10.0]: https://github.com/yeesian/ArchGDAL.jl/compare/v0.9.4...v0.10.0
[0.9.4]: https://github.com/yeesian/ArchGDAL.jl/releases/tag/v0.9.4
