# ArchGDAL quickstart
>This tutorial is highly inspired by the [Python Quickstart](https://rasterio.readthedocs.io/en/latest/quickstart.html), and aims to provide a similar introductory guide to the ArchGDAL package.


This guide uses a GeoTIFF image of the band 4 of a Landsat 8 image, covering a part of the United State's Colorado Plateau. This image was acquired on July 12, 2016, and can be download at [this link](https://landsatonaws.com/L8/037/034/LC08_L1TP_037034_20160712_20170221_01_T1).
![example.tif](https://user-images.githubusercontent.com/4471859/87169013-a32ee600-c2cf-11ea-9d09-e82446812282.png)

## Opening the dataset
Assuming that the ArchGDAL package is already installed, first import the package, and preferably assign an alias to the package.
```@setup quickstart
using ArchGDAL; const AG = ArchGDAL
```
In this example, we'll be fetching the raster dataset from where it is hosted.
```@repl quickstart
dataset = AG.readraster("/vsicurl/http://landsat-pds.s3.amazonaws.com/c1/L8/037/034/LC08_L1TP_037034_20160712_20170221_01_T1/LC08_L1TP_037034_20160712_20170221_01_T1_B4.TIF")
```
A dataset can be opened using ArchGDAL's `readraster(...)` method. This method takes in the path of a dataset as a string, and returns a GDAL Dataset object in read-only mode. 

ArchGDAL can read a variety of file types using appropriate drivers. The driver used for opening the dataset can be queried as such.
```@repl quickstart
AG.getdriver(dataset)
```

## Dataset Attributes
A raster dataset can have multiple bands of information. To get the number of bands present in a dataset - 
```@repl quickstart
AG.nraster(dataset)
```
In our case, the raster dataset only has a single band. 

Other properties of a raster dataset, such as the width and height can be accessed using the following functions
```@repl quickstart
AG.width(dataset)
AG.height(dataset)
```

## Dataset Georeferencing
All raster datasets contain embedded georeferencing information, using which the raster image can be located at a geographic location. The georeferencing attributes are stored as the dataset's Geospatial Transform. 
```@repl quickstart
gt = AG.getgeotransform(dataset)
```
The x-y coordinates of the top-left corner of the raster dataset are denoted by `gt[1]` and `gt[4]` values. In this case, the coordinates . The cell size is represented by `gt[2]` and `gt[6]` values, corresponding to the cell size in x and y directions respectively, and the `gt[3]` and `gt[5]` values define the rotation. In our case, the top left pixel is at an offset of 358485.0m and 4.265115e6m in x and y directions respectively, from the origin.

The Origin of the dataset is defined using what is called, a Coordinate Reference System (CRS in short). 
```@repl quickstart
p = AG.getproj(dataset)
```
The `getproj(...)` function returns the projection of a dataset as a string representing the CRS in the OpenGIS WKT format. To convert it into other CRS representations, such as PROJ.4, `toPROJ4(...)` can be used. However, first the string representation of the CRS has to be converted into an `ArchGDAL.ISpatialRef` type using the `importWKT(...)` function.
```@repl quickstart
AG.toPROJ4(AG.importWKT(p))
```

## Reading Raster data
In the previous steps, we read the raster file as a dataset. To obtain the actual raster data, we can slice the array accordingly.
```@repl quickstart
dataset[:, :, 1]
```
Since the dimensions of the dataset are `[cols, rows, bands]`, respectively, using `[:, :, 1]` returns all the columns and rows for the first band. Accordingly other complex slice operations can also be performed. 

To get the individual band
```@repl quickstart
band = AG.getband(dataset, 1)
```
Band specific attributes can be easily accessed through a variety of functions
```@repl quickstart
AG.width(band)
AG.height(band)
AG.getnodatavalue(band)
AG.indexof(band)
```
The no-data value of the band can be obtained using the `getnodatavalue(...)` function, which in our case is -1.0e10. 

## Writing into Dataset
Creating dummy data to be written as raster dataset.
```@example quickstart
x = range(-4.0, 4.0, length=240)
y = range(-3.0, 3.0, length=180)
X = repeat(collect(x)', size(y)[1])
Y = repeat(collect(y), 1, size(x)[1])
Z1 = exp.(-2*log(2) .*((X.-0.5).^2 + (Y.-0.5).^2)./(1^2))
Z2 = exp.(-3*log(2) .*((X.+0.5).^2 + (Y.+0.5).^2)./(2.5^2))
Z = 10.0 .* (Z2 .- Z1)
```
The fictional field for this example consists of the difference of two Gaussian distributions and is represented by the array `Z`. Its contours are shown below.
![creating-dataset](https://user-images.githubusercontent.com/7526346/87633084-5bd5a900-c758-11ea-8fd3-548d039f1a43.png)

Once we have the data to write into a raster dataset, before performing the write operation itself, it is a good idea to define the geotransform and the coordinate reference system of the resulting dataset. For North-up raster images, only the *pixel-size/resolution* and the coordinates of the *upper-left* pixel is required. 
```@example quickstart
# Resolution
res = (x[end] - x[1]) /240.0

# Upper-left pixel coordinates
ul_x = x[1] - res/2
ul_y = y[1] - res/2

gt = [ul_x, res, 0.0, ul_y, 0.0, res]
```
The coordinate reference system of the dataset needs to be a string in the WKT format. 
```@example quickstart
crs = AG.toWKT(AG.importPROJ4("+proj=latlong"))
```

To write this array, first a dataset has to be created. This can be done using the `AG.create` function. The first argument defines the path of the resulting dataset. The following keyword arguments are hopefully self-explanatory. 

Once inside the ```do...end``` block, the `write!` method can be used to write the array(`Z`), in the 1st band of the opened `dataset`. Next, the geotransform and CRS can be specified using the `setgeotransform!` and `setproj!` methods.
```@example quickstart
AG.create(
    "./temporary.tif",
    driver = AG.getdriver("GTiff"), 
    width=240, 
    height=180, 
    nbands=1, 
    dtype=Float64
) do dataset
    AG.write!(dataset, Z, 1)
    
    AG.setgeotransform!(dataset, gt)
    AG.setproj!(dataset, crs)
end
```