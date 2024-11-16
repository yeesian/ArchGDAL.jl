var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "ArchGDAL.jl documentation",
    "title": "ArchGDAL.jl documentation",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#ArchGDAL.jl-documentation-1",
    "page": "ArchGDAL.jl documentation",
    "title": "ArchGDAL.jl documentation",
    "category": "section",
    "text": "GDAL is a translator library for raster and vector geospatial data formats that is released under an X/MIT license by the Open Source Geospatial Foundation. As a library, it presents an abstract data model to drivers for various raster and vector formats.This package aims to be a complete solution for working with GDAL in Julia, similar in scope to the SWIG bindings for Python. It builds on top of GDAL.jl, and provides a high level API for GDAL, espousing the following principles."
},

{
    "location": "index.html#Principles-(The-Arch-Way)-1",
    "page": "ArchGDAL.jl documentation",
    "title": "Principles (The Arch Way)",
    "category": "section",
    "text": "(adapted from: https://wiki.archlinux.org/index.php/Arch_Linux#Principles)simplicity: without unnecessary additions or modifications.   (i) Preserves GDAL Data Model, and makes available GDAL/OGR methods without trying to mask them from the user.   (ii) minimal dependencies\nmodernity: ArchGDAL strives to maintain the latest stable release versions of GDAL as long as systemic package breakage can be reasonably avoided.\npragmatism: The principles here are only useful guidelines. Ultimately, design decisions are made on a case-by-case basis through developer consensus. Evidence-based technical analysis and debate are what matter, not politics or popular opinion.\nuser-centrality: Whereas other libraries attempt to be more user-friendly, ArchGDAL shall be user-centric. It is intended to fill the needs of those contributing to it, rather than trying to appeal to as many users as possible.\nversatility: ArchGDAL will strive to remain small in its assumptions about the range of user-needs, and to make it easy for users to build their own extensions/conveniences."
},

{
    "location": "index.html#Installation-1",
    "page": "ArchGDAL.jl documentation",
    "title": "Installation",
    "category": "section",
    "text": "This package is currently unregistered, so add it using Pkg.clone, then find or get the GDAL dependencies using Pkg.build:Pkg.clone(\"https://github.com/visr/GDAL.jl.git\")\nPkg.build(\"GDAL\")\nPkg.clone(\"https://github.com/yeesian/ArchGDAL.jl.git\")Pkg.build(\"GDAL\") searches for a GDAL 2.1+ shared library on the path. If not found, it will download and install it. To test if it is installed correctly, use:Pkg.test(\"GDAL\")\nPkg.test(\"ArchGDAL\")"
},

{
    "location": "datasets.html#",
    "page": "GDAL Datasets",
    "title": "GDAL Datasets",
    "category": "page",
    "text": ""
},

{
    "location": "datasets.html#GDAL-Datasets-1",
    "page": "GDAL Datasets",
    "title": "GDAL Datasets",
    "category": "section",
    "text": "The following code demonstrates the general workflow for reading in a dataset:ArchGDAL.registerdrivers() do\n    ArchGDAL.read(filename) do dataset\n        # work with dataset\n    end\nendWe defer the discussions on ArchGDAL.registerdrivers() and ArchGDAL.read(filename) to the sections on Driver Management and Working with Files respectively.note: Note\nIn this case, a handle to the dataset is obtained, and no further data was requested. It is only when we run print(dataset) that calls will be made through GDAL\'s C API to obtain information about dataset for display."
},

{
    "location": "datasets.html#Vector-Datasets-1",
    "page": "GDAL Datasets",
    "title": "Vector Datasets",
    "category": "section",
    "text": "import ArchGDAL\nfilepath = download(\"https://raw.githubusercontent.com/yeesian/ArchGDALDatasets/307f8f0e584a39a050c042849004e6a2bd674f99/data/point.geojson\", \"point.geojson\")In this section, we work with the data/point.geojson dataset viaArchGDAL.registerdrivers() do\n    ArchGDAL.read(filepath) do dataset\n        print(dataset)\n    end\nendThe display indicatesthe type of the object (GDAL Dataset)\nthe driver used to open it (shortname/longname: GeoJSON/GeoJSON)\nthe files that it corresponds to (point.geojson)\nthe number of layers in the dataset, and their brief summary.You can also programmatically retrieve them usingtypeof(dataset): the type of the object\nArchGDAL.filelist(dataset): the files that it corresponds to\nArchGDAL.nlayer(dataset): the number of layers in the dataset\ndrv = ArchGDAL.getdriver(dataset): the driver used to open it\nArchGDAL.shortname(drv): the short name of a driver\nArchGDAL.longname(drv): the long name of a driver\nlayer = ArchGDAL.getlayer(dataset, i): the i-th layer in dataset.\nArchGDAL.getgeomtype(layer): the geometry type for layer (i.e. wkbPoint)\nArchGDAL.getname(layer): the name of layer (i.e. OGRGeoJSON)\nArchGDAL.nfeature(layer): the number of features in layer (i.e. 4)For more on working with features and vector data, see the Section on Feature Data."
},

{
    "location": "datasets.html#Raster-Datasets-1",
    "page": "GDAL Datasets",
    "title": "Raster Datasets",
    "category": "section",
    "text": "import ArchGDAL\nfilepath = download(\"https://github.com/yeesian/ArchGDALDatasets/blob/307f8f0e584a39a050c042849004e6a2bd674f99/gdalworkshop/world.tif?raw=true\", \"world.tif\")In this section, we work with the gdalworkshop/world.tif dataset:ArchGDAL.registerdrivers() do\n    ArchGDAL.read(filepath) do dataset\n        print(dataset)\n    end\nendThe display indicatesthe type of the object (GDAL Dataset)\nthe driver used to open it (shortname/longname: GTiff/GeoTIFF)\nthe files that it corresponds to (world.tif)\nthe number of raster bands in the dataset, and their brief summary.You can also programmatically retrieve them usingtypeof(dataset): the type of the object\nArchGDAL.filelist(dataset): the files that it corresponds to\nArchGDAL.nraster(dataset): the number of rasters\nArchGDAL.width(dataset) the width (2048 pixels)\nArchGDAL.height(dataset) the height (1024 pixels)\ndrv = ArchGDAL.getdriver(dataset): the driver used to open it\nArchGDAL.shortname(drv): the short name of a driver\nArchGDAL.longname(drv): the long name of a driver\nband = ArchGDAL.getband(dataset, i): the i-th raster band\ni = ArchGDAL.getnumber(band): the index of band.\nArchGDAL.getaccess(band): the access flag (i.e. GA_ReadOnly)\nArchGDAL.getname(ArchGDAL.getcolorinterp(rasterband)): the color channel (e.g. Red)\nArchGDAL.width(band) the width (2048 pixels) of the band\nArchGDAL.height(band) the height (1024 pixels) of the band\nArchGDAL.getdatatype(band): the pixel type (i.e. UInt8)For more on working with raster data, see the Section on Raster Data."
},

{
    "location": "datasets.html#Driver-Management-1",
    "page": "GDAL Datasets",
    "title": "Driver Management",
    "category": "section",
    "text": "Before opening a GDAL supported datastore it is necessary to register drivers. Normally this is accomplished with the GDAL.allregister() function which registers all known drivers. However, the user will then need to remember to de-register the drivers using GDAL.destroydrivermanager() when they\'re done.In ArchGDAL, we provide a registerdrivers() block, such thatArchGDAL.registerdrivers() do\n    # your code here\nendis equivalent toGDAL.allregister()\n# your code here\nGDAL.destroydrivermanager()"
},

{
    "location": "datasets.html#Working-with-Files-1",
    "page": "GDAL Datasets",
    "title": "Working with Files",
    "category": "section",
    "text": "We provide the following methods for working with files:ArchGDAL.createcopy(): create a copy of a raster dataset. This is often used with a virtual source dataset allowing configuration of band types, and other information without actually duplicating raster data.\nArchGDAL.create(): creates a new dataset Note: many sequential write-once formats (such as JPEG and PNG) don\'t implement the Create() method but do implement the CreateCopy() method. If the driver doesn\'t implement CreateCopy(), but does implement Create() then the default CreateCopy() mechanism built on calling Create() will be used.\nArchGDAL.read(): opens a dataset in read-only mode. The returned dataset should only be accessed by one thread at a time. To use it from different threads, you must add all necessary code (mutexes, etc.) to avoid concurrent use of the object. (Some drivers, such as GeoTIFF, maintain internal state variables that are updated each time a new block is read, preventing concurrent use.)\nArchGDAL.update(): opens a dataset with the possibility of updating it. If you open a dataset object with update access, it is not recommended to open a new dataset on the same underlying file.For each one of them, we will call ArchGDAL.destroy at the end of the do-block which will dispatch to the corresponding GDAL method. For example,ArchGDAL.read(filename) do dataset\n    # work with dataset\nendwill correspond todataset = ArchGDAL.unsafe_read(filename)\n# work with dataset\nArchGDAL.destroy(dataset) # the equivalent of GDAL.close(dataset.ptr)note: Note\nIn GDAL, datasets are closed by calling GDAL.close(). This will result in proper cleanup, and flushing of any pending writes. Forgetting to call GDAL.close() on a dataset opened in update mode in a popular format like GTiff will likely result in being unable to open it afterwards.note: Note\nThis pattern of using do-blocks to manage context plays a big way into the way we handle memory in this package. For details, see the section on Memory Management."
},

{
    "location": "features.html#",
    "page": "Feature Data",
    "title": "Feature Data",
    "category": "page",
    "text": ""
},

{
    "location": "features.html#Feature-Data-1",
    "page": "Feature Data",
    "title": "Feature Data",
    "category": "section",
    "text": "In this section, we revisit the data/point.geojson dataset.import ArchGDAL\nfilepath = download(\"https://raw.githubusercontent.com/yeesian/ArchGDALDatasets/307f8f0e584a39a050c042849004e6a2bd674f99/data/point.geojson\", \"point.geojson\")ArchGDAL.registerdrivers() do\n    ArchGDAL.read(filepath) do dataset\n        print(dataset)\n    end\nend"
},

{
    "location": "features.html#Feature-Layers-1",
    "page": "Feature Data",
    "title": "Feature Layers",
    "category": "section",
    "text": "ArchGDAL.registerdrivers() do\n    ArchGDAL.read(filepath) do dataset\n        layer = ArchGDAL.getlayer(dataset, 0)\n        print(layer)\n    end\nendThe display providesthe name of the feature layer (point)\nthe geometries in the dataset, and their brief summary.\nthe fields in the dataset, and their brief summary.You can also programmatically retrieve them usingArchGDAL.getname(layer): the name of the feature layer\nArchGDAL.nfeature(layer): the number of features in the layer\nfeaturedefn = ArchGDAL.getlayerdefn(layer): the schema of the layer features\nArchGDAL.nfield(featuredefn): the number of fields\nArchGDAL.ngeomfield(featuredefn): the number of geometries\nfielddefn = ArchGDAL.getfielddefn(featuredefn, i): the definition for field i\ngeomfielddefn = ArchGDAL.getgeomfielddefn(featuredefn, i): the definition for geometry i"
},

{
    "location": "features.html#Field-Definitions-1",
    "page": "Feature Data",
    "title": "Field Definitions",
    "category": "section",
    "text": "Each fielddefn defines an attribute of a feature, and supports the following:ArchGDAL.getname(fielddefn): the name of the field (FID or pointname)\nArchGDAL.gettype(fielddefn): the type of the field (OFTReal or OFTString)Each geomfielddefn defines an attribute of a geometry, and supports the following:ArchGDAL.getgeomname(geomfielddefn): the name of the geometry (empty in this case)\nArchGDAL.gettype(geomfielddefn): the type of the geometry (wkbPoint)"
},

{
    "location": "features.html#Individual-Features-1",
    "page": "Feature Data",
    "title": "Individual Features",
    "category": "section",
    "text": "We can examine an individual featureArchGDAL.registerdrivers() do\n    ArchGDAL.read(filepath) do dataset\n        layer = ArchGDAL.getlayer(dataset, 0)\n        ArchGDAL.getfeature(layer, 2) do feature\n            print(feature)\n        end\n    end\nendYou can programmatically retrieve the information usingArchGDAL.nfield(feature): the number of fields (2)\nArchGDAL.ngeomfield(feature): the number of geometries (1)\nArchGDAL.getfield(feature, i): the i-th field (0.0 and \"a\")\nArchGDAL.getgeomfield(feature, i): the i-th geometry (the WKT display POINT)More information on geometries can be found in Geometric Operations."
},

{
    "location": "rasters.html#",
    "page": "Raster Data",
    "title": "Raster Data",
    "category": "page",
    "text": ""
},

{
    "location": "rasters.html#Raster-Data-1",
    "page": "Raster Data",
    "title": "Raster Data",
    "category": "section",
    "text": "In this section, we revisit the gdalworkshop/world.tif dataset.import ArchGDAL\nfilepath = download(\"https://github.com/yeesian/ArchGDALDatasets/blob/307f8f0e584a39a050c042849004e6a2bd674f99/gdalworkshop/world.tif?raw=true\", \"world.tif\")ArchGDAL.registerdrivers() do\n    ArchGDAL.read(filepath) do dataset\n        print(dataset)\n    end\nendA description of the display is available in Raster Datasets."
},

{
    "location": "rasters.html#Raster-Bands-1",
    "page": "Raster Data",
    "title": "Raster Bands",
    "category": "section",
    "text": "We can examine an individual raster bandArchGDAL.registerdrivers() do\n    ArchGDAL.read(filepath) do dataset\n        band = ArchGDAL.getband(dataset, 1)\n        print(band)\n    end\nendYou can programmatically retrieve the information in the header usingArchGDAL.getaccess(band): whether we have update permission for this band. (GA_ReadOnly)\ncolorinterp = ArchGDAL.getcolorinterp(band): color interpretation of the values in the band (GCI_RedBand)\nArchGDAL.getname(colorinterp): name (string) corresponding to color interpretation (\"Red\")\nArchGDAL.width(band): width (pixels) of the band (2048)\nArchGDAL.height(band): height (pixels) of the band (1024)\nArchGDAL.getnumber(band): the band number (1+) within its dataset, or 0 if unknown. (1)\nArchGDAL.getdatatype(band): pixel data type for this band. (UInt8)You can get additional attribute information usingArchGDAL.getscale(band): the scale in units = (px * scale) + offset (1.0)\nArchGDAL.getoffset(band): the offset in units = (px * scale) + offset (0.0)\nArchGDAL.getunittype(band): name for the units, e.g. \"m\" (meters) or \"ft\" (feet). (\"\")\nArchGDAL.getnodatavalue(band): a special marker value used to mark pixels that are not valid data. (-1.0e10)\n(x,y) = ArchGDAL.getblocksize(band): the \"natural\" block size of this band ((256,256))note: Note\nGDAL contains a concept of the natural block size of rasters so that applications can organized data access efficiently for some file formats. The natural block size is the block size that is most efficient for accessing the format. For many formats this is simple a whole scanline in which case *pnXSize is set to GetXSize(), and *pnYSize is set to 1.However, for tiled images this will typically be the tile size.Note that the X and Y block sizes don\'t have to divide the image size evenly, meaning that right and bottom edge blocks may be incomplete.Finally, you can obtain overviews:ArchGDAL.noverview(band): the number of overview layers available, zero if none. (7)\nArchGDAL.getoverview(band, i): returns the i-th overview in the raster band. Each overview is itself a raster band."
},

{
    "location": "rasters.html#Raster-I/O-1",
    "page": "Raster Data",
    "title": "Raster I/O",
    "category": "section",
    "text": ""
},

{
    "location": "rasters.html#Reading-Raster-Values-1",
    "page": "Raster Data",
    "title": "Reading Raster Values",
    "category": "section",
    "text": "The general operative method for reading in raster values from a dataset or band is to use ArchGDAL.read().ArchGDAL.read(dataset): reads the entire dataset as a single multidimensional array.\nArchGDAL.read(dataset, indices): reads the raster bands at the indices (in that order) into a multidimensional array.\nArchGDAL.read(dataset, i): reads the i-th raster band into an array.\nArchGDAL.read(band): reads the raster band into an array.You can also specify the subset of rows and columns (provided as UnitRanges) to read:ArchGDAL.read(dataset, indices, rows, cols)\nArchGDAL.read(dataset, i, rows, cols)\nArchGDAL.read(band, rows, cols)On other occasions, it might be easier to first specify a position (xoffset,yoffset) to read from, and the size (xsize, ysize) of the window to read:ArchGDAL.read(dataset, indices, xoffset, yoffset, xsize, ysize)\nArchGDAL.read(dataset, i, xoffset, yoffset, xsize, ysize)\nArchGDAL.read(band, xoffset, yoffset, xsize, ysize)You might have an existing buffer that you wish to read the values into. In such cases, the general API for doing so is to write ArchGDAL.read!(source, buffer, args...) instead of ArchGDAL.read(source, args...)."
},

{
    "location": "rasters.html#Writing-Raster-Values-1",
    "page": "Raster Data",
    "title": "Writing Raster Values",
    "category": "section",
    "text": "For writing values from a buffer to a raster dataset or band, the following methods are available:ArchGDAL.write!(band, buffer)\nArchGDAL.write!(band, buffer, rows, cols)\nArchGDAL.write!(band, buffer, xoffset, yoffset, xsize, ysize)\nArchGDAL.write!(dataset, buffer, i)\nArchGDAL.write!(dataset, buffer, i, rows, cols)\nArchGDAL.write!(dataset, buffer, i, xoffset, yoffset, xsize, ysize)\nArchGDAL.write!(dataset, buffer, indices)\nArchGDAL.write!(dataset, buffer, indices, rows, cols)\nArchGDAL.write!(dataset, buffer, indices, xoffset, yoffset, xsize, ysize)"
},

{
    "location": "rasters.html#Windowed-Reads-and-Writes-1",
    "page": "Raster Data",
    "title": "Windowed Reads and Writes",
    "category": "section",
    "text": "Following the description in mapbox/rasterio\'s documentation, a window is a view onto a rectangular subset of a raster dataset. This is useful when you want to work on rasters that are larger than your computers RAM or process chunks of large rasters in parallel.For that purpose, we have a method called ArchGDAL.windows(band) which iterates over the windows of a raster band, returning the indices corresponding to the rasterblocks within that raster band for efficiency:ArchGDAL.registerdrivers() do\n    ArchGDAL.read(filepath) do dataset\n        band = ArchGDAL.getband(dataset, 1)\n        for (cols,rows) in ArchGDAL.windows(band)\n            println((cols,rows))\n        end\n    end\nendAlternatively, we have another method called ArchGDAL.blocks(band) which iterates over the windows of a raster band, returning the offset and size corresponding to the rasterblocks within that raster band for efficiency:ArchGDAL.registerdrivers() do\n    ArchGDAL.read(filepath) do dataset\n        band = ArchGDAL.getband(dataset, 1)\n        for (xyoffset,xysize) in ArchGDAL.blocks(band)\n            println((xyoffset,xysize))\n        end\n    end\nendnote: Note\nThese methods are often used for reading/writing a block of image data efficiently, as it accesses \"natural\" blocks from the raster band without resampling, or data type conversion."
},

{
    "location": "geometries.html#",
    "page": "Geometric Operations",
    "title": "Geometric Operations",
    "category": "page",
    "text": ""
},

{
    "location": "geometries.html#Geometric-Operations-1",
    "page": "Geometric Operations",
    "title": "Geometric Operations",
    "category": "section",
    "text": "In this section, we consider some of the common kinds of geometries that arises in applications. These include Point, LineString, Polygon, GeometryCollection, MultiPolygon, MultiPoint, and MultiLineString. For brevity in the examples, we will use the prefix const AG = ArchGDAL."
},

{
    "location": "geometries.html#Geometry-Creation-1",
    "page": "Geometric Operations",
    "title": "Geometry Creation",
    "category": "section",
    "text": "To create geometries of different types.point = AG.createpoint(1.0, 2.0)\nlinestring = AG.createlinestring([(i,i+1) for i in 1.0:3.0])\nlinearring = AG.createlinearring([(0.,0.), (0.,1.), (1.,1.)])\nsimplepolygon = AG.createpolygon([(0.,0.), (0.,1.), (1.,1.)])\ncomplexpolygon = AG.createpolygon([[(0.,0.), (0.,j), (j,j)] for j in 1.0:-0.1:0.9])\nmultipoint = AG.createlinearring([(0.,0.), (0.,1.), (1.,1.)])\nmultilinestring = AG.createmultilinestring([[(i,i+1) for i in j:j+3] for j in 1.0:5.0:6.0])\nmultipolygon = AG.createmultipolygon([[[(0.,0.), (0.,j), (j,j)]] for j in 1.0:-0.1:0.9])Alternatively, they can be assembled from their components.point = AG.createpoint()\n    AG.addpoint!(point, 1.0, 2.0)\nlinestring = AG.createlinestring()\n    for i in 1.0:3.0\n        AG.addpoint!(linestring, i, i+1)\n    end\nlinearring = AG.createlinearring()\n    for i in 1.0:3.0\n        AG.addpoint!(linearring, i, i+1)\n    end\npolygon = AG.createpolygon()\n    for j in 1.0:-0.1:0.9\n        ring = AG.createlinearring([(0.,0.), (0.,j), (j,j)])\n        AG.addgeom!(polygon, ring)\n    end\nmultipoint = AG.createmultipoint()\n    for i in 1.0:3.0\n        pt = AG.createpoint(i, i+1)\n        AG.addgeom!(multipoint, pt)\n    end\nmultilinestring = AG.createmultilinestring()\n    for j in 1.0:5.0:6.0\n        line = AG.createlinestring([(i,i+1) for i in j:j+3])\n        AG.addgeom!(multilinestring, line)\n    end\nmultipolygon = AG.createmultipolygon()\n    for j in 1.0:-0.1:0.9\n        poly = AG.createpolygon([(0.,0.), (0.,j), (j,j)])\n        AG.addgeom!(multipolygon, poly)\n    endThey can also be constructed from other data formats such as:Well-Known Binary (WKB): AG.fromWKB([0x01,0x01,...,0x27,0x41])\nWell-Known Text (WKT): AG.fromWKT(\"POINT (1 2)\")\nJavaScript Object Notation (JSON): AG.fromJSON(\"\"\"{\"type\":\"Point\",\"coordinates\":[1,2]}\"\"\")"
},

{
    "location": "geometries.html#Geometry-Modification-1",
    "page": "Geometric Operations",
    "title": "Geometry Modification",
    "category": "section",
    "text": "The following methods are commonly used for retrieving elements of a geometry.AG.getcoorddim(geom): dimension of the coordinates. Returns 0 for an empty point\nAG.getspatialref(geom)\nAG.getx(geom, i)\nAG.gety(geom, i)\nAG.getz(geom, i)\nAG.getpoint(geom, i)\nAG.getgeom(geom, i)The following methods are commonly used for modifying or adding to a geometry.AG.setcoorddim!(geom, dim)\nAG.setspatialref!(geom, spatialref)\nAG.setpointcount!(geom, n)\nAG.setpoint!(geom, i, x, y)\nAG.setpoint!(geom, i, x, y, z)\nAG.addpoint!(geom, x, y)\nAG.addpoint!(geom, x, y, z)\nAG.addgeom!(geom1, geom2)\nAG.addgeomdirectly!(geom1, geom2)\nAG.removegeom!(geom, i)\nAG.removeallgeoms!(geom)"
},

{
    "location": "geometries.html#Unary-Operations-1",
    "page": "Geometric Operations",
    "title": "Unary Operations",
    "category": "section",
    "text": "The following is an non-exhaustive list of unary operations available for geometries."
},

{
    "location": "geometries.html#Attributes-1",
    "page": "Geometric Operations",
    "title": "Attributes",
    "category": "section",
    "text": "AG.getdim(geom): 0 for points, 1 for lines and 2 for surfaces\nAG.getcoorddim(geom): dimension of the coordinates. Returns 0 for an empty point\nAG.getenvelope(geom): the bounding envelope for this geometry\nAG.getenvelope3d(geom): the bounding envelope for this geometry\nAG.wkbsize(geom): size (in bytes) of related binary representation\nAG.getgeomtype(geom): geometry type code (in OGRwkbGeometryType)\nAG.getgeomname(geom): WKT name for geometry type\nAG.getspatialref(geom): spatial reference system. May be NULL\nAG.geomlength(geom): the length of the geometry, or 0.0 for unsupported types\nAG.geomarea(geom): the area of the geometry, or 0.0 for unsupported types"
},

{
    "location": "geometries.html#Predicates-1",
    "page": "Geometric Operations",
    "title": "Predicates",
    "category": "section",
    "text": "The following predicates return a Bool.AG.isempty(geom)\nAG.isvalid(geom)\nAG.issimple(geom)\nAG.isring(geom)\nAG.hascurvegeom(geom, nonlinear::Bool)"
},

{
    "location": "geometries.html#Immutable-Operations-1",
    "page": "Geometric Operations",
    "title": "Immutable Operations",
    "category": "section",
    "text": "The following methods do not modify geom.AG.clone(geom): a copy of the geometry with the original spatial reference system.\nAG.forceto(geom, targettype): force the provided geometry to the specified geometry type.\nAG.simplify(geom, tol): Compute a simplified geometry.\nAG.simplifypreservetopology(geom, tol): Simplify the geometry while preserving topology.\nAG.delaunaytriangulation(geom, tol, onlyedges): a delaunay triangulation of the vertices of the geometry.\nAG.boundary(geom): the boundary of the geometry\nAG.convexhull(geom): the convex hull of the geometry.\nAG.buffer(geom, dist, quadsegs): a polygon containing the region within the buffer distance of the original geometry.\nAG.union(geom): the union of the geometry using cascading\nAG.pointonsurface(geom): Returns a point guaranteed to lie on the surface.\nAG.centroid(geom): Compute the geometry centroid. It is not necessarily within the geometry.\nAG.pointalongline(geom, distance): Fetch point at given distance along curve.\nAG.polygonize(geom): Polygonizes a set of sparse edges."
},

{
    "location": "geometries.html#Mutable-Operations-1",
    "page": "Geometric Operations",
    "title": "Mutable Operations",
    "category": "section",
    "text": "The following methods modifies the first argument geom.AG.setcoorddim!(geom, dim): sets the explicit coordinate dimension.\nAG.flattento2d!(geom): Convert geometry to strictly 2D.\nAG.closerings!(geom): Force rings to be closed by adding the start point to the end.\nAG.setspatialref!(geom, spatialref): Assign spatial reference to this object.\nAG.transform!(geom, coordtransform): Apply coordinate transformation to geometry.\nAG.transform!(geom, spatialref): Transform geometry to new spatial reference system.\nAG.segmentize!(geom, maxlength): Modify the geometry such it has no segment longer than the given distance.\nAG.empty!(geom): Clear geometry information."
},

{
    "location": "geometries.html#Export-Formats-1",
    "page": "Geometric Operations",
    "title": "Export Formats",
    "category": "section",
    "text": "AG.toWKB(geom)\nAG.toISOWKB(geom)\nAG.toWKT(geom)\nAG.toISOWKT(geom)\nAG.toGML(geom)\nAG.toKML(geom)\nAG.toJSON(geom)"
},

{
    "location": "geometries.html#Binary-Operations-1",
    "page": "Geometric Operations",
    "title": "Binary Operations",
    "category": "section",
    "text": "The following is an non-exhaustive list of binary operations available for geometries."
},

{
    "location": "geometries.html#Predicates-2",
    "page": "Geometric Operations",
    "title": "Predicates",
    "category": "section",
    "text": "The following predicates return a Bool.AG.intersects(g1, g2)\nAG.equals(g1, g2)\nAG.disjoint(g1, g2)\nAG.touches(g1, g2)\nAG.crosses(g1, g2)\nAG.within(g1, g2)\nAG.contains(g1, g2)\nAG.overlaps(g1, g2)"
},

{
    "location": "geometries.html#Immutable-Operations-2",
    "page": "Geometric Operations",
    "title": "Immutable Operations",
    "category": "section",
    "text": "The following methods do not mutate the input geomteries g1 and g2.AG.intersection(g1, g2)\nAG.union(g1, g2)\nAG.difference(g1, g2)\nAG.symdifference(g1, g2)"
},

{
    "location": "geometries.html#Mutable-Operations-2",
    "page": "Geometric Operations",
    "title": "Mutable Operations",
    "category": "section",
    "text": "The following methods modifies the first argument g1.AG.addgeom!(g1, g2)\nAG.addgeomdirectly!(g1, g2)"
},

{
    "location": "projections.html#",
    "page": "Spatial Projections",
    "title": "Spatial Projections",
    "category": "page",
    "text": ""
},

{
    "location": "projections.html#Spatial-Projections-1",
    "page": "Spatial Projections",
    "title": "Spatial Projections",
    "category": "section",
    "text": "(This is based entirely on the GDAL/OSR Tutorial and Python GDAL/OGR Cookbook.)The ArchGDAL.SpatialRef, and ArchGDAL.CoordTransform types are lightweight wrappers around GDAL objects that represent coordinate systems (projections and datums) and provide services to transform between them. These services are loosely modeled on the OpenGIS Coordinate Transformations specification, and use the same Well Known Text format for describing coordinate systems."
},

{
    "location": "projections.html#Coordinate-Systems-1",
    "page": "Spatial Projections",
    "title": "Coordinate Systems",
    "category": "section",
    "text": "There are two primary kinds of coordinate systems. The first is geographic (positions are measured in long/lat) and the second is projected (such as UTM - positions are measured in meters or feet).Geographic Coordinate Systems: A Geographic coordinate system contains information on the datum (which implies an spheroid described by a semi-major axis, and inverse flattening), prime meridian (normally Greenwich), and an angular units type which is normally degrees.\nProjected Coordinate Systems: A projected coordinate system (such as UTM, Lambert Conformal Conic, etc) requires and underlying geographic coordinate system as well as a definition for the projection transform used to translate between linear positions (in meters or feet) and angular long/lat positions."
},

{
    "location": "projections.html#Creating-Spatial-References-1",
    "page": "Spatial Projections",
    "title": "Creating Spatial References",
    "category": "section",
    "text": "import ArchGDAL; const AG = ArchGDAL\n\nprojstring2927 = AG.importEPSG(2927) do spref\n    AG.toPROJ4(spref)\nendThe details of how to interpret the results can be found in http://proj4.org/usage/projections.html.In the above example, we constructed a SpatialRef object from the EPSG Code 2927. There are a variety of other formats from which SpatialRefs can be constructed, such asArchGDAL.importEPSG(::Int): based on the EPSG code\nArchGDAL.importEPSGA(::Int): based on the EPSGA code\nArchGDAL.importESRI(::String): based on ESRI projection codes\nArchGDAL.importPROJ4(::String) based on the PROJ.4 string (reference)\nArchGDAL.importURL(::String): download from a given URL and feed it into SetFromUserInput for you.\nArchGDAL.importWKT(::String): WKT string\nArchGDAL.importXML(::String): XML format (GML only currently)We currently support a few export formats too:ArchGDAL.toMICoordSys(spref): Mapinfo style CoordSys format.\nArchGDAL.toPROJ4(spref): coordinate system in PROJ.4 format.\nArchGDAL.toWKT(spref): nicely formatted WKT string for display to a person.\nArchGDAL.toXML(spref): converts into XML format to the extent possible."
},

{
    "location": "projections.html#Reprojecting-a-Geometry-1",
    "page": "Spatial Projections",
    "title": "Reprojecting a Geometry",
    "category": "section",
    "text": "AG.importEPSG(2927) do source\n    AG.importEPSG(4326) do target\n        AG.createcoordtrans(source, target) do transform\n            AG.fromWKT(\"POINT (1120351.57 741921.42)\") do point\n                println(\"Before: $(AG.toWKT(point))\")\n                AG.transform!(point, transform)\n                println(\"After: $(AG.toWKT(point))\")\nend end end end"
},

{
    "location": "projections.html#References-1",
    "page": "Spatial Projections",
    "title": "References",
    "category": "section",
    "text": "Some background on OpenGIS coordinate systems and services can be found in the Simple Features for COM, and Spatial Reference Systems Abstract Model documents available from the Open Geospatial Consortium. The GeoTIFF Projections Transform List may also be of assistance in understanding formulations of projections in WKT. The EPSG Geodesy web page is also a useful resource. You may also consult the OGC WKT Coordinate System Issues page."
},

{
    "location": "memory.html#",
    "page": "Memory Management",
    "title": "Memory Management",
    "category": "page",
    "text": ""
},

{
    "location": "memory.html#Memory-Management-1",
    "page": "Memory Management",
    "title": "Memory Management",
    "category": "section",
    "text": "Unlike the design of fiona, ArchGDAL does not automatically copy data from her data sources. This introduces concerns about memory management (whether objects should be managed by Julia\'s garbage collector, or by manually destroying the corresponding GDAL object).Currently this package provides data types corresponding to GDAL\'s Data Model, e.g.mutable struct ColorTable;                    ptr::GDALColorTable         end\nmutable struct CoordTransform;                ptr::GDALCoordTransform     end\nmutable struct Dataset;                       ptr::GDALDataset            end\nmutable struct Driver;                        ptr::GDALDriver             end\nmutable struct Feature;                       ptr::GDALFeature            end\nmutable struct FeatureDefn;                   ptr::GDALFeatureDefn        end\nmutable struct FeatureLayer;                  ptr::GDALFeatureLayer       end\nmutable struct Field;                         ptr::GDALField              end\nmutable struct FieldDefn;                     ptr::GDALFieldDefn          end\nmutable struct Geometry <: AbstractGeometry;  ptr::GDALGeometry           end\nmutable struct GeomFieldDefn;                 ptr::GDALGeomFieldDefn      end\nmutable struct RasterAttrTable;               ptr::GDALRasterAttrTable    end\nmutable struct RasterBand;                    ptr::GDALRasterBand         end\nmutable struct SpatialRef;                    ptr::GDALSpatialRef         end\nmutable struct StyleManager;                  ptr::GDALStyleManager       end\nmutable struct StyleTable;                    ptr::GDALStyleTable         end\nmutable struct StyleTool;                     ptr::GDALStyleTool          endand makes it the responsibility of the user to free the allocation of memory from GDAL, by calling ArchGDAL.destroy(obj) (which sets obj.ptr to C_NULL after destroying the GDAL object corresponding to obj)."
},

{
    "location": "memory.html#Manual-versus-Context-Management-1",
    "page": "Memory Management",
    "title": "Manual versus Context Management",
    "category": "section",
    "text": "There are two approaches for doing so.The first uses the unsafe_ prefix to indicate methods that returns objects that needs to be manually destroyed.\nThe second uses do-blocks as context managers.The first approach will result in code that looks likedataset = ArchGDAL.unsafe_read(filename)\n# work with dataset\nArchGDAL.destroy(dataset) # the equivalent of GDAL.close(dataset.ptr)This can be helpful when working interactively with dataset at the REPL. The second approach will result in the following codeArchGDAL.read(filename) do dataset\n    # work with dataset\nendwhich uses do-blocks to scope the lifetime of the dataset object."
},

{
    "location": "memory.html#Interactive-versus-Scoped-Geometries-1",
    "page": "Memory Management",
    "title": "Interactive versus Scoped Geometries",
    "category": "section",
    "text": "There is a third option for managing memory, which is to register a finalizer with julia, which gets called by the garbage collector at some point after it is out-of-scope. This is in contrast to an approach where users manage memory by working with it within the scope of a do-block, or by manually destroying objects themselves. Therefore, we introduce an AbstractGeometry type:abstract type AbstractGeometry <: GeoInterface.AbstractGeometry endwhich is then subtyped into Geometry and IGeometrymutable struct Geometry <: AbstractGeometry\n    ptr::GDALGeometry\nend\n\nmutable struct IGeometry <: AbstractGeometry\n    ptr::GDALGeometry\n\n    function IGeometry(ptr::GDALGeometry)\n        geom = new(GDAL.clone(ptr))\n        finalizer(geom, destroy)\n        geom\n    end\nendObjects of type IGeometry use the third type of memory management, where we register ArchGDAL.destroy() as a finalizer. This is useful for users who are interested in working with geometries in a julia session, when they wish to read it from a geospatial database into a dataframe, and want it to persist within the julia session even after the connection to the database has been closed.As a result, the general API for geometries isunsafe_<method>(G, args...) will return a geometry of type G (one of Geometry or IGeometry).\nunsafe_<method>(args...) will return a geometry of type Geometry (whichhas to be destroyed by the user).<method>(::Function, args...) allows for the do-block syntax which creates a geometry::Geometry which is operated on by the function, before being destroyed.\n<method>(args...) returns a geometry of type IGeometry.note: Note\nSo long as the user does not manually call ArchGDAL.destroy() on any object themselves, users are allowed to mix both the methods of memory management (i) using do-blocks for scoped geometries, and (ii) using finalizers for interactive geometries. However, there are plenty of pitfalls (e.g. in PythonGotchas) if users try to mix in their own custom style of calling ArchGDAL.destroy()."
},

{
    "location": "memory.html#References-1",
    "page": "Memory Management",
    "title": "References",
    "category": "section",
    "text": "Here\'s a collection of references for developers who are interested.http://docs.julialang.org/en/release-0.4/manual/calling-c-and-fortran-code/\nhttps://github.com/JuliaLang/julia/issues/7721\nhttps://github.com/JuliaLang/julia/issues/11207\nhttps://trac.osgeo.org/gdal/wiki/PythonGotchas\nhttps://lists.osgeo.org/pipermail/gdal-dev/2010-September/026027.html\nhttps://sgillies.net/2013/12/17/teaching-python-gis-users-to-be-more-rational.html\nhttps://pcjericks.github.io/py-gdalogr-cookbook/gotchas.html#features-and-geometries-have-a-relationship-you-don-t-want-to-break"
},

{
    "location": "spatialite.html#",
    "page": "Working with Spatialite",
    "title": "Working with Spatialite",
    "category": "page",
    "text": ""
},

{
    "location": "spatialite.html#Working-with-Spatialite-1",
    "page": "Working with Spatialite",
    "title": "Working with Spatialite",
    "category": "section",
    "text": "Here is an example of how you can work with a SQLite Database in ArchGDAL.jl, and follows the tutorial in http://www.gaia-gis.it/gaia-sins/spatialite-tutorial-2.3.1.html.We will work with the following database:import ArchGDAL\nconst AG = ArchGDAL\n\nfilepath = download(\"https://github.com/yeesian/ArchGDALDatasets/raw/e0b15dca5ad493c5ebe8111688c5d14b031b7305/spatialite/test-2.3.sqlite\", \"test.sqlite\")Here\'s a quick summary of test.sqlite:AG.registerdrivers() do\n    AG.read(filepath) do dataset\n        print(dataset)\n    end\nendWe will display the results of running query on the dataset using the following function:function inspect(query, filename=filepath)\n    AG.registerdrivers() do\n        AG.read(filename) do dataset\n            AG.executesql(dataset, query) do results\n                print(results)\n            end\n        end\n    end\nend"
},

{
    "location": "spatialite.html#Constructing-SQL-Queries-1",
    "page": "Working with Spatialite",
    "title": "Constructing SQL Queries",
    "category": "section",
    "text": ""
},

{
    "location": "spatialite.html#A-Simple-LIMIT-Query-1",
    "page": "Working with Spatialite",
    "title": "A Simple LIMIT Query",
    "category": "section",
    "text": "Here\'s a first query:inspect(\"SELECT * FROM towns LIMIT 5\")A few points to understand:the SELECT statement requests SQLite to perform a query\nfetching all columns [*]\nFROM the database table of name towns\nretrieving only the first five rows [LIMIT 5]"
},

{
    "location": "spatialite.html#A-Simple-ORDER-BY-Query-1",
    "page": "Working with Spatialite",
    "title": "A Simple ORDER BY Query",
    "category": "section",
    "text": "Now try this second SQL query:inspect(\"select name AS Town, peoples as Population from towns ORDER BY name LIMIT 5\")Some remarks:in SQL, constructs using lower- or upper-case have identical effects; So the commands constructed using SELECT and select, or FROM and from are equivalent.\nyou can freely choose which columns to fetch, determine their ordering, and rename then if you wish by using the AS clause.\nyou can order the fetched rows by using the ORDER BY clause."
},

{
    "location": "spatialite.html#The-WHERE-and-ORDER-BY-clauses-1",
    "page": "Working with Spatialite",
    "title": "The WHERE and ORDER BY clauses",
    "category": "section",
    "text": "A more complex SQL query:inspect(\"\"\"select name, peoples from towns\n           WHERE peoples > 350000 order by peoples DESC\"\"\")Some remarks:you can filter a specific set of rows by imposing a WHERE clause; only those rows that satisfies the logical expression you specify will be fetched.\nIn this example only towns with a population greater than 350000 peoples has been fetched.\nyou can order rows in descending order if appropriate, by using the DESC clause."
},

{
    "location": "spatialite.html#Using-SQL-functions-1",
    "page": "Working with Spatialite",
    "title": "Using SQL functions",
    "category": "section",
    "text": "inspect(\"\"\"\nselect COUNT(*) as \'# Towns\',\n    MIN(peoples) as Smaller,\n    MAX(peoples) as Bigger,\n    SUM(peoples) as \'Total peoples\',\n    SUM(peoples) / COUNT(*) as \'mean peoples for town\'\nfrom towns\n\"\"\")you can split complex queries along many lines\nyou can use functions in an SQL query. COUNT(), MIN(), MAX() and SUM() are functions. Not at all surprisingly:\nCOUNT() returns the total number of rows.\nMIN() returns the minimum value for the given column.\nMAX() returns the maximum value for the given column.\nSUM() returns the total of all values for the given column.\nyou can do calculations in your query. e.g. we have calculated the mean of peoples per village dividing the SUM() by the COUNT() values."
},

{
    "location": "spatialite.html#Constructing-Expressions-1",
    "page": "Working with Spatialite",
    "title": "Constructing Expressions",
    "category": "section",
    "text": "inspect(\"select (10 - 11) * 2 as Number, ABS((10 - 11) * 2) as AbsoluteValue\")the (10 - 11) * 2 term is an example of an expression.\nthe ABS() function returns the absolute value of a number.\nnote that in this example we have not used any DB column or DB table at all."
},

{
    "location": "spatialite.html#The-HEX()-function-1",
    "page": "Working with Spatialite",
    "title": "The HEX() function",
    "category": "section",
    "text": "inspect(\"\"\"\nselect name, peoples, HEX(Geometry)\nfrom Towns where peoples > 350000 order by peoples DESC\n\"\"\")the HEX() function returns the hexadecimal representation of a BLOB column value.\nin the preceding execution of this query, the geom column seemed empty; now, by using the HEX() function, we discover that it contains lots of strange binary data.\ngeom contains GEOMETRY values, stored as BLOBs and encoded in the internal representation used by SpatiaLite.note: Note\nSQLite in its own hasn\'t the slightest idea of what GEOMETRY is, and cannot do any other operation on it. To really use GEOMETRY values, it\'s time use the SpatiaLite extension."
},

{
    "location": "spatialite.html#Spatialite-Features-1",
    "page": "Working with Spatialite",
    "title": "Spatialite Features",
    "category": "section",
    "text": ""
},

{
    "location": "spatialite.html#Well-Known-Text-1",
    "page": "Working with Spatialite",
    "title": "Well-Known Text",
    "category": "section",
    "text": "inspect(\"\"\"\nSELECT name, peoples, AsText(Geometry)\nfrom Towns where peoples > 350000 order by peoples DESC\n\"\"\")the AsText() function comes from SpatiaLite, and returns the Well Known Text - WKT representation for a GEOMETRY column value. WKT is a standard notation conformant to OpenGIS specification.\nin the preceding execution of this query, the HEX() function returned lots of strange binary data. Now the AsText() function shows useful and quite easily understandable GEOMETRY values.\na POINT is the simplest GEOMETRY class, and has only a couple of [X,Y] coordinates."
},

{
    "location": "spatialite.html#Working-with-Coordinates-1",
    "page": "Working with Spatialite",
    "title": "Working with Coordinates",
    "category": "section",
    "text": "inspect(\"\"\"\nSELECT name, X(Geometry), Y(Geometry) FROM Towns\nWHERE peoples > 350000 \nORDER BY peoples DESC\n\"\"\")the SpatiaLite X() function returns the X coordinate for a POINT.\nthe Y() function returns the Y coordinate for a POINT.inspect(\"SELECT HEX(GeomFromText(\'POINT(10 20)\'))\")"
},

{
    "location": "spatialite.html#Format-Conversions-1",
    "page": "Working with Spatialite",
    "title": "Format Conversions",
    "category": "section",
    "text": "you can use the following GEOMETRY format conversion functions:inspect(\"SELECT HEX(AsBinary(GeomFromText(\'POINT(10 20)\')))\")inspect(\"SELECT AsText(GeomFromWKB(X\'010100000000000000000024400000000000003440\'))\")the SpatiaLite GeomFromText() function returns the internal BLOB representation for a GEOMETRY.\nthe AsBinary() function returns the Well Known Binary - WKB representation for a GEOMETRY column value. WKB is a standard notation conformant to OpenGIS specification.\nthe GeomFromWKB() function converts a WKB value into the corresponding internal BLOB value."
},

{
    "location": "spatialite.html#GEOMETRY-Classes-1",
    "page": "Working with Spatialite",
    "title": "GEOMETRY Classes",
    "category": "section",
    "text": ""
},

{
    "location": "spatialite.html#LINESTRING-1",
    "page": "Working with Spatialite",
    "title": "LINESTRING",
    "category": "section",
    "text": "inspect(\"SELECT PK_UID, AsText(Geometry) FROM HighWays WHERE PK_UID = 10\")LINESTRING is another GEOMETRY class, and has lots of POINTs.\nin this case you have fetched a very simple LINESTRING, representing a polyline with just 4 vertices.\nit isn\'t unusual to encounter LINESTRINGs with thousands of vertices in real GIS data.inspect(\"\"\"\nSELECT PK_UID, NumPoints(Geometry), GLength(Geometry),\n       Dimension(Geometry), GeometryType(Geometry)\nFROM HighWays ORDER BY NumPoints(Geometry) DESC LIMIT 5\n\"\"\")the SpatiaLite NumPoints() function returns the number of vertices for a LINESTRING GEOMETRY.\nthe GLength() function returns the geometric length [expressed in map units] for a LINESTRING GEOMETRY.\nthe Dimension() function returns the dimensions\' number for any GEOMETRY class [e.g. 1 for lines].\nthe GeometryType() function returns the class type for any kind of GEOMETRY value.inspect(\"\"\"\nSELECT PK_UID, NumPoints(Geometry),\n       AsText(StartPoint(Geometry)), AsText(EndPoint(Geometry)),\n       X(PointN(Geometry, 2)), Y(PointN(Geometry, 2))\nFROM HighWays ORDER BY NumPoints(Geometry) DESC LIMIT 5\n\"\"\")the SpatiaLite StartPoint() function returns the first POINT for a LINESTRING GEOMETRY.\nthe EndPoint() function returns the last POINT for a LINESTRING GEOMETRY.\nthe PointN() function returns the selected vertex as a POINT; each one vertex is identified by a relative index. The first vertex is identified by an index value 1, the second by an index value 2 and so on.\nYou can freely nest the various SpatiaLite functions, by passing the return value of the inner function as an argument for the outer one."
},

{
    "location": "spatialite.html#POLYGON-1",
    "page": "Working with Spatialite",
    "title": "POLYGON",
    "category": "section",
    "text": "inspect(\"SELECT name, AsText(Geometry) FROM Regions WHERE PK_UID = 52\")POLYGON is another GEOMETRY class.\nin this case you have fetched a very simple POLYGON, having only the exterior ring [i.e. it doesn\'t contains any internal hole]. Remember that POLYGONs may optionally contain an arbitrary number of internal holes, each one delimited by an interior ring.\nthe exterior ring in itself is simply a LINESTRING [and interior rings too are LINESTRINGS].\nnote that a POLYGON is a closed geometry, and thus the first and the last POINT for each ring are exactly identical.inspect(\"\"\"\nSELECT PK_UID, Area(Geometry), AsText(Centroid(Geometry)),\n       Dimension(Geometry), GeometryType(Geometry)\nFROM Regions ORDER BY Area(Geometry) DESC LIMIT 5\n\"\"\")we have already meet the SpatiaLite Dimension() and GeometryType() functions; they works for POLYGONs exactly in same fashion as for any other kind of GEOMETRY.\nthe SpatiaLite Area() function returns the geometric area [expressed in square map units] for a POLYGON GEOMETRY.\nthe Centroid() function returns the POINT identifying the centroid for a POLYGON GEOMETRY.inspect(\"\"\"\nSELECT PK_UID, NumInteriorRings(Geometry),\n       NumPoints(ExteriorRing(Geometry)), NumPoints(InteriorRingN(Geometry, 1))\nFROM regions ORDER BY NumInteriorRings(Geometry) DESC LIMIT 5\n\"\"\")the SpatiaLite ExteriorRing() functions returns the exterior ring for a given GEOMETRY. Any valid POLYGON must have an exterior ring. Remember: each one of the rings belonging to a POLYGON is a closed LINESTRING.\nthe SpatiaLite NumInteriorRings() function returns the number of interior rings belonging to a POLYGON. A valid POLYGON may have any number of interior rings, including zero i.e. no interior ring at all.\nThe SpatiaLite InteriorRingN() function returns the selected interior rings as a LINESTRING; each one interior ring is identified by a relative index. The first interior ring is identified by an index value 1, the second by an index value 2 and so on.\nAny ring is a LINESTRING, so we can use the NumPoints() function in order to detect the number of related vertices. If we call the NumPoints() function on a NULL GEOMETRY [or on a GEOMETRY of non-LINESTRING class] we\'ll get a NULL result. This explains why the the last three rows has a NULL NumPoints() result; there is no corresponding interior ring!inspect(\"\"\"\nSELECT AsText(InteriorRingN(Geometry, 1)),\n       AsText(PointN(InteriorRingN(Geometry, 1), 4)),\n       X(PointN(InteriorRingN(Geometry, 1), 5)),\n       Y(PointN(InteriorRingN(Geometry, 1), 5))\nFROM Regions WHERE PK_UID = 55\n\"\"\")we have already met in the preceding ones the usage of nested functions. For POLYGONs it becomes to be a little more tedious, but still easily understandable.\ne.g. to obtain the last column we have used InteriorRingN() in order to get the first interior ring, and then PointN() to get the fifth vertex. At last we can call Y() to get the coordinate value.inspect(\"\"\"\nSELECT Name, AsText(Envelope(Geometry)) FROM Regions LIMIT 5\n\"\"\")the SpatiaLite Envelope() function always returns a POLYGON that is the Minimum Bounding Rectangle - MBR for the given GEOMETRY. Because an MBR is a rectangle, it always has 5 POINTs [remember: in closed geometries the last POINT must be identical to the first one].\nindividual POINTs are as follows:\nPOINT #1: minX,minY\nPOINT #2: maxX,minY\nPOINT #3: maxX,maxY\nPOINT #4: minX,maxY\nPOINT #5: minX,minY\nMBRs are of peculiar interest, because by using them you can evaluate spatial relationships between two geometries in a simplified and roughly approximative way. But MBR comparisons are very fast to compute, so they are very useful and widely used to speed up data processing.\nMBRs are also widely referenced as bounding boxes, or \"BBOX\" as well."
},

{
    "location": "spatialite.html#Complex-Geometry-Classes-1",
    "page": "Working with Spatialite",
    "title": "Complex Geometry Classes",
    "category": "section",
    "text": "POINT, LINESTRING and POLYGON are the elementary classes for GEOMETRY. But GEOMETRY supports the following complex classes as well:a MULTIPOINT is a collection of two or more POINTs belonging to the same entity.\na MULTILINESTRING is a collection of two or more LINESTRINGs.\na MULTIPOLYGON is a collection of two or more POLYGONs.\na GEOMETRYCOLLECTION is an arbitrary collection containing any other kind of geometries.We\'ll not explain in detail this kind of collections, because it will be simply too boring and dispersive. Generally speaking, they extend in the expected way to their corresponding elementary classes, e.g.the SpatiaLite NumGeometries() function returns the number of elements for a collection.\nthe GeometryN() function returns the N-th element for a collection.\nthe GLength() function applied to a MULTILINESTRING returns the sum of individual lengths for each LINESTRING composing the collection.\nthe Area() function applied to a MULTIPOLYGON returns the sum of individual areas for each POLYGON in the collection.\nthe Centroid() function returns the average centroid when applied to a MULTIPOLYGON."
},

]}
