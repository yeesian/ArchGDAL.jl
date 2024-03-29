# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]

### Added

### Fixed

### Changed

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
