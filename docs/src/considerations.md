# Design Considerations

## Code Defensiveness

Although GDAL provides a unified data model for different data formats, there are still significant differences between their implementations such that each driver is effectively its own application. This has the following implications:

- Not all configuration options works for all drivers.
- Not all capabilities are available for all drivers.
- Performance characteristics may vary significantly depending on the driver.

`ArchGDAL.jl` provides mechanisms for setting GDAL's configuration options, and does not maintain its own list of sanctioned options for each driver. Although work is underway to make this an easier experience for the user, it remains the responsibility of the user to check that a particular configuration exists and works for their choice of drivers.

Here's a collection of references for developers who are interested:
- [https://trac.osgeo.org/gdal/wiki/ConfigOptions](https://trac.osgeo.org/gdal/wiki/ConfigOptions)
- [https://github.com/mapbox/rasterio/pull/665](https://github.com/mapbox/rasterio/pull/665)
- [https://github.com/mapbox/rasterio/issues/875](https://github.com/mapbox/rasterio/issues/875)
- [https://rasterio.readthedocs.io/en/latest/topics/configuration.html](https://rasterio.readthedocs.io/en/latest/topics/configuration.html)

## GDAL Enum Values

[GDAL.jl](https://github.com/JuliaGeo/GDAL.jl) uses [CEnum.jl](https://github.com/JuliaInterop/CEnum.jl), which is a C-compatible enum, this is the default in [Clang.jl](https://github.com/JuliaInterop/Clang.jl). This is useful when the underlying values are of interest, for example the following snippets from [`src/types.jl`](https://github.com/yeesian/ArchGDAL.jl/blob/master/src/types.jl):

```julia
import Base.|

for T in (GDALOpenFlag, FieldValidation)
    eval(quote
        |(x::$T, y::UInt8) = UInt8(x) | y
        |(x::UInt8, y::$T) = x | UInt8(y)
        |(x::$T, y::$T) = UInt8(x) | UInt8(y)
    end)
end
```

and

```julia
function basetype(gt::OGRwkbGeometryType)::OGRwkbGeometryType
    wkbGeomType = convert(GDAL.OGRwkbGeometryType, gt)
    wkbGeomType &= (~0x80000000) # Remove 2.5D flag.
    wkbGeomType %= 1000 # Normalize Z, M, and ZM types.
    return GDAL.OGRwkbGeometryType(wkbGeomType)
end
```

However, the use of CEnum.jl allows for multiple enums to have the same underlying value, resulting in unintuitive behavior if they are used as keys in a dictionary. For example, in the following code:

```julia
julia> Dict(GDAL.GCI_YCbCr_CrBand => "a", GDAL.GCI_Max => "b")
Dict{GDAL.GDALColorInterp, String} with 1 entry:
  GCI_YCbCr_CrBand => "b"
```

the entry for `GDAL.GCI_YCbCr_CrBand => "a"` got overwritten by `GDAL.GCI_Max => "b"` because both `GDAL.GCI_YCbCr_CrBand` and `GDAL.GCI_Max` corresponded to the same value.

To avoid such forms of behavior, this package uses [`Base.Enums`](https://docs.julialang.org/en/v1/base/base/#Base.Enums.Enum) instead, so the above example would result in the following behavior:


```julia
julia> Dict(ArchGDAL.GCI_YCbCr_CrBand => "a", ArchGDAL.GCI_Max => "b")
Dict{ArchGDAL.GDALColorInterp, String} with 2 entries:
  GCI_YCbCr_CrBand => "a"
  GCI_Max          => "b"
```

To maintain parity with GDAL behavior, ArchGDAL.jl provides conversion methods to map from the enums in ArchGDAL to the corresponding cenums from GDAL.jl when calling the corresponding GDAL functions.

## Colors

Rather than encouraging [operations on colortables](https://gdal.org/python/osgeo.gdal.ColorTable-class.html) (with very limited functionality from GDAL), users are better served by arrays of [ColorTypes](https://github.com/JuliaGraphics/ColorTypes.jl) using [Colors.jl](https://github.com/JuliaGraphics/Colors.jl), [for example](http://juliagraphics.github.io/Colors.jl/stable/colormapsandcolorscales/#Generating-a-range-of-colors)

```julia
range(startcolor, stop=endcolor, length=15)
```

instead of

```julia
createcolorramp!(colortable, startindex, startcolor, startindex+15, endcolor)
```

## Images

To differentiate 2d arrays of colors from 3d arrays with band as the third dimension:

* For 2D arrays (a single rasterband), if they have a color interpretation, we use the color interpretation. If they don't have a color interpretation, ArchGDAL.jl defaults to "Grey".
* For >2D arrays (multiple rasterbands), if they have a palette interpretation (or combination of color interpretations) that resolves to a valid colortype, ArchGDAL.jl uses the palette interpretation. If they don't have a palette interpretation, we throw an error.

In general, `read()` will return `Array{UInt8}`, and `imread()` will return `Array{<:Colorant}`.

## Tables.jl Interface

The interface is implemented in [`src/tables.jl`](https://github.com/yeesian/ArchGDAL.jl/blob/master/src/tables.jl), and is only for feature and geometries in OGR (and not for images and rasters). The current API from GDAL makes it row-based in the conventions of Tables.jl. Therefore,

* `ArchGDAL.Feature` meets the criteria for an [`AbstractRow`](https://tables.juliadata.org/dev/#Tables.AbstractRow-1) based on https://github.com/yeesian/ArchGDAL.jl/blob/a665f3407930b8221269f8949c246db022c3a85c/src/tables.jl#L31-L58.
* `ArchGDAL.FeatureLayer` meets the criteria for an `AbstractRow`-iterator based on the previous bullet and meeting the criteria for [`Iteration`](https://docs.julialang.org/en/v1/manual/interfaces/#man-interface-iteration) in [`base/iterators.jl`](https://github.com/yeesian/ArchGDAL.jl/blob/a665f3407930b8221269f8949c246db022c3a85c/src/base/iterators.jl#L1-L18).
* `ArchGDAL.AbstractDataset` might contain multiple layers, and might correspond to multiple tables. The way to construct tables would be to get the layers before forming the corresponding tables.

## Missing and Null Semantics in GDAL

When reading the fields of a feature using `getfield(feature, i)`, ArchGDAL observes the following behavior:

| Field | null    | notnull |
|-------|---------|---------|
| set   | missing | value   |
| unset | nothing | nothing |

This reflects that
* a field that is notnull will never return `missing`: use `isfieldnull(feature, i)` to determine if a field has been set.
* a field is set will never return `nothing` (and a field that unset will always return `nothing`): use `isfieldset(feature, i)` to determine if a field has been set.
* a field that is set and not null will always have a concrete value: use `isfieldsetandnotnull(feature, i)` to test for it.

When writing the fields of a feature using `setfield!(feature, i, value)`, ArchGDAL observes the following behavior:

| Field   | nullable | notnullable  |
|---------|----------|--------------|
| nothing | unset    | unset        |
| missing | null     | getdefault() |
| value   | value    | value        |

This reflects that
* writing `nothing` will cause the field to be unset.
* writing `missing` will cause the field to be null. In the cause of a notnullable field, it will take the default value (see https://gdal.org/development/rfc/rfc53_ogr_notnull_default.html for details). If there is no default value, `getdefault()` will return `nothing`, causing the field to be unset.
* writing a value will behave in the usual manner.

For additional references, see
* https://docs.julialang.org/en/v1/manual/faq/#faq-nothing
* https://gdal.org/development/rfc/rfc53_ogr_notnull_default.html
* https://gdal.org/development/rfc/rfc67_nullfieldvalues.html
