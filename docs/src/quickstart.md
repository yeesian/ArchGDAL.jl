# ArchGDAL quickstart
>This tutorial is highly inspired by the [Python Quickstart](https://rasterio.readthedocs.io/en/latest/quickstart.html), and aims to provide a similar introductory guide to the ArchGDAL package.

> The output of each code block is represented as a series of comments after each code block. For example,
>```Julia
> println("Hello World")
># Hello World
>```

This guide uses a GeoTIFF image of the band 4 of a Landsat 8 image, covering a part of the United State's Colorado Plateau. This image was acquired on July 12, 2016, and can be download at [this link](https://landsatonaws.com/L8/037/034/LC08_L1TP_037034_20160712_20170221_01_T1).
![example.tif](https://user-images.githubusercontent.com/4471859/87169013-a32ee600-c2cf-11ea-9d09-e82446812282.png)

## Opening the dataset
Assuming that the ArchGDAL package is already installed, first import the package, and assign an alias for the package.
```Julia
using ArchGDAL; const ag = ArchGDAL
```
Assuming that the dataset exists in the following path: `./example.tiff`, the dataset can be opened in reading mode as follows -
```Julia
dataset = ag.read("example.tiff")
# GDAL Dataset (Driver: GTiff/GeoTIFF)
# File(s): 
# example.tiff

# Dataset (width x height): 7731 x 7861 (pixels)
# Number of raster bands: 1
# [GA_ReadOnly] Band 1 (Gray): 7731 x 7861 (UInt16)
```
A dataset can be opened using ArchGDAL's `read(...)` function. This function takes in the path of a dataset as a string, and returns a GDAL Dataset object in read-only mode.

ArchGDAL can read a variety of file types using appropriate drivers. The driver used for opening the dataset can be queried as such.
```Julia
ag.getdriver(dataset)
# Driver: GTiff/GeoTIFF
```

## Dataset Attributes
A raster dataset can have multiple bands of information. To get the number of bands present in a dataset - 
```Julia
ag.nraster(dataset)
# 1
```
In our case, the raster dataset only has a single band. 

Other properties of a raster dataset, such as the width and height can be accessed using the following functions
```Julia
ag.width(dataset)
# 7731
ag.height(dataset)
# 7861
```

## Dataset Georeferencing
All raster datasets contain embedded georeferencing information, using which the raster image can be located at a geographic location. The georeferencing attributes are stored as the dataset's Geospatial Transform. 
```Julia
gt = ag.getgeotransform(dataset)
# 6-element Array{Float64,1}:
#  358485.0
#      30.0
#       0.0
#       4.265115e6
#       0.0
#     -30.0
```
The x-y coordinates of the top-left corner of the raster dataset are denoted by `gt[1]` and `gt[4]` values. In this case, the coordinates . The cell size is represented by `gt[2]` and `gt[6]` values, corresponding to the cell size in x and y directions respectively, and the `gt[3]` and `gt[5]` values define the rotation. In our case, the top left pixel is at an offset of 358485.0m and 4.265115e6m in x and y directions respectively, from the origin.

The Origin of the dataset is defined using what is called, a Coordinate Reference System (CRS in short). 
```Julia
p = ag.getproj(dataset)
# PROJCS["WGS 84 / UTM zone 12N",GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563,AUTHORITY["EPSG","7030"]],AUTHORITY["EPSG","6326"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4326"]],PROJECTION["Transverse_Mercator"],PARAMETER["latitude_of_origin",0],PARAMETER["central_meridian",-111],PARAMETER["scale_factor",0.9996],PARAMETER["false_easting",500000],PARAMETER["false_northing",0],UNIT["metre",1,AUTHORITY["EPSG","9001"]],AXIS["Easting",EAST],AXIS["Northing",NORTH],AUTHORITY["EPSG","32612"]]
```
The `getproj(...)` function returns the projection of a dataset as a string representing the CRS in the OpenGIS WKT format. To convert it into other CRS representations, such as PROJ.4, `toPROJ4(...)` can be used. However, first the string representation of the CRS has to be converted into an `ArchGDAL.ISpatialRef` type using the `importWKT(...)` function.
```Julia
ag.toPROJ4(ag.importWKT(p))
# "+proj=utm +zone=12 +datum=WGS84 +units=m +no_defs"
```

## Reading Raster data
In the previous steps, we read the raster file as a dataset. To get the actual raster data, stored as bands, we can again use the `read(...)` function.
```Julia
ag.read(dataset, 1)
# 7731×7861 Array{UInt16,2}:
#  0x0000  0x0000  0x0000  0x0000  0x0000  …  0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000     0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000     0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000     0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000     0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000  …  0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000     0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000     0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000     0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000     0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000  …  0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000     0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000     0x0000  0x0000  0x0000  0x0000
#       ⋮                                  ⋱                               ⋮
#  0x0000  0x0000  0x0000  0x0000  0x0000     0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000  …  0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000     0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000     0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000     0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000     0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000  …  0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000     0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000     0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000     0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000     0x0000  0x0000  0x0000  0x0000
#  0x0000  0x0000  0x0000  0x0000  0x0000  …  0x0000  0x0000  0x0000  0x0000
```
The function takes in a dataset as the first argument, and the index of the band that is to be read, as the second argument. To read the whole dataset, `read(dataset)` can be used, in which case, a single multidimensional array will be returned, containing all the bands. The indices will correspond to `(cols, rows, bands)`.

To get the individual band
```Julia
band = ag.getband(dataset, 1)
# [GA_ReadOnly] Band 1 (Gray): 7731 x 7861 (UInt16)
#     blocksize: 512×512, nodata: -1.0e10, units: 1.0px + 0.0
#     overviews: 
```
Band specific attributes can be easily accessed through a variety of functions
```Julia
ag.width(band)
# 7731
ag.height(band)
# 7861
ag.getnodatavalue(band)
# -1.0e10
ag.indexof(band)
# 1
```
The no-data value of the band can be obtained using the `getnodatavalue(...)` function, which in our case is -1.0e10. 

## Creating Data
