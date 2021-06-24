# Images

```@setup rasters
using ArchGDAL
```

In this section, we revisit the [`gdalworkshop/world.tif`](https://github.com/yeesian/ArchGDALDatasets/blob/307f8f0e584a39a050c042849004e6a2bd674f99/gdalworkshop/world.tif) dataset.
```@example rasters
dataset = ArchGDAL.read("gdalworkshop/world.tif")
```
A description of the display is available in [Raster Datasets](@ref).

## Reading from Datasets
We can construct an image from it in the following way:
```@example rasters
ArchGDAL.imread(dataset)
```

## Reading from Files
We can read the file as an image instead:
```@example rasters
ArchGDAL.imread("gdalworkshop/world.tif")
```

## Reading from Rasterbands
We can also read from individual raster bands:
```@example rasters
ArchGDAL.imread(ArchGDAL.getband(dataset, 1))
```
Or equivalently,
```@example rasters
ArchGDAL.imread(dataset, 1)
```
It will interpret the color channel (for RGB) correctly if there is one. E.g.
```@example rasters
ArchGDAL.imread(dataset, 2)
```
and
```@example rasters
ArchGDAL.imread(dataset, 3)
```

## Working with Colors
Operations on colors behave as you think they might:
```@example rasters
ArchGDAL.imread(dataset, 2) + ArchGDAL.imread(dataset, 3)
```
and
```@example rasters
0.5 * ArchGDAL.imread(dataset, 1) + ArchGDAL.imread(dataset, 3)
```
See [Colors.jl](https://juliagraphics.github.io/Colors.jl/stable/) for more on what you can do.
