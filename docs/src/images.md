# Images

```@setup rasters
using ArchGDAL
const AG = ArchGDAL
```

In this section, we revisit the [`gdalworkshop/world.tif`](https://github.com/yeesian/ArchGDALDatasets/blob/307f8f0e584a39a050c042849004e6a2bd674f99/gdalworkshop/world.tif) dataset.
```@example rasters
dataset = AG.read("gdalworkshop/world.tif")
```
A description of the display is available in [Raster Datasets](@ref).

## Reading from Datasets
We can construct an image from it in the following way:
```@example rasters
AG.imread(dataset)
```

## Reading from Files
We can read the file as an image instead:
```@example rasters
AG.imread("gdalworkshop/world.tif")
```

## Reading from Rasterbands
We can also read from individual raster bands:
```@example rasters
AG.imread(AG.getband(dataset, 1))
```
Or equivalently,
```@example rasters
AG.imread(dataset, 1)
```
It will interpret the color channel (for RGB) correctly there is one. E.g.
```@example rasters
AG.imread(dataset, 2)
```
and
```@example rasters
AG.imread(dataset, 3)
```

## Working with Colors
Operations on colors behave as you think they might:
```@example rasters
AG.imread(dataset, 2) + AG.imread(dataset, 3)
```
and
```@example rasters
0.5 * AG.imread(dataset, 1) + AG.imread(dataset, 3)
```
See [Colors.jl](http://juliagraphics.github.io/Colors.jl/stable/) for more on what you can do.
