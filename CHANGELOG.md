# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]

### Added

- `ArchGDAL.AbstractSpatialRef` is now a `GeoFormatTypes.CoordinateReferenceSystemFormat`, so
  `SpatialRef` and `ISpatialRef` are `GeoFormat`s ([#403], [#434]). A spatial reference obtained
  from ArchGDAL — `getspatialref`, `importEPSG`, `importWKT`, ... — can now be passed anywhere a
  `GeoFormat` crs is accepted, including `reproject` and `crs2transform`, and converts to and from
  every other CRS `GeoFormat`. Downstream code that branches on `crs isa GeoFormat` will now take
  the `GeoFormat` branch for a spatial reference.
- `toWKT2` exports a spatial reference as WKT2, which unlike the WKT1 that `toWKT` emits is
  lossless for datum ensembles, dynamic CRSs, coordinate epochs and compound CRSs. It is also what
  `GeoFormatTypes.val` and `convert(String, spref)` return, and backs
  `convert(GeoFormatTypes.WellKnownText2, spref)`.
- `toPROJJSON` exports a spatial reference as PROJJSON, backing
  `convert(GeoFormatTypes.ProjJSON, spref)`.
- `isempty(spref)` reports whether a spatial reference holds no CRS definition. This is true both
  for a NULL handle and for the live but unpopulated one `newspatialref()` returns, which cannot be
  exported to any format.
- `getaxismapping` and `setaxismapping!` read and write the data axis to CRS axis mapping, and
  `getcoordinateepoch` and `setcoordinateepoch!` read and write the coordinate epoch of a dynamic
  CRS. Neither is carried by WKT, and both affect `==`.
- `ISpatialRef(::AbstractString)` constructs a spatial reference from anything GDAL can parse —
  WKT1, WKT2, a PROJ.4 string, `"EPSG:4326"`, a URN, PROJJSON — equivalent to `importUserInput`.
- `fromWKB` and `unsafe_fromWKB` take a `spatialref` keyword, since WKB itself carries no CRS.

### Fixed

- `convert(GeoFormatTypes.ESRIWellKnownText, spref)` no longer rewrites `spref` in place. It used
  to call `morphtoESRI!` on its argument, which was harmless only while that argument was always a
  temporary.
- `show` no longer throws for an empty (non-NULL) spatial reference, such as the one
  `newspatialref()` returns; it prints `"Empty Spatial Reference System"`.
- `deepcopy` of a spatial reference or a geometry now clones the underlying GDAL object instead of
  copying the pointer field verbatim. The copy previously aliased an object it did not own, and
  read freed memory once the original was destroyed or finalized.
- Saving a spatial reference with JLD2 no longer silently loses it. Serialization goes through the
  WKT2 definition plus the axis mapping and coordinate epoch that WKT cannot carry, rather than
  writing out a pointer field that reloads as NULL.
- A geometry saved with JLD2 now keeps its spatial reference, which was previously dropped because
  the WKB it is serialized as cannot hold one. Geometries written by earlier versions still load.

### Changed

- `==` on two spatial references is now GDAL's `OSRIsSame` — CRS equivalence — rather than object
  identity, with a matching `hash`. A spatial reference now compares equal to its own clone and to
  its WKT or PROJ.4 round-trip, but not to the same CRS with a different axis mapping strategy.
- The `order` keyword on `newspatialref` and the `import*` functions now defaults to `nothing`,
  meaning "leave GDAL's own default in place", and `order = :compliant` now really does force
  authority-compliant axis order instead of being a no-op. Behaviour is unchanged unless you set
  the `OSR_DEFAULT_AXIS_MAPPING_STRATEGY` config option, which GDAL applies when constructing an
  SRS and which the previous documented default of `:compliant` silently claimed to override.
  `importCRS` on a spatial reference clones it, keeping its axis mapping strategy unless `order`
  is given.
- `reproject`'s `GeoFormat` geometry method is restricted to formats that can hold a geometry, so
  passing a crs as the geometry is now a `MethodError` rather than a failure inside `convert`.

[#403]: https://github.com/yeesian/ArchGDAL.jl/issues/403
[#434]: https://github.com/yeesian/ArchGDAL.jl/issues/434

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
