# Feature Data

```@setup features
using ArchGDAL
```

In this section, we revisit the [`data/point.geojson`](https://github.com/yeesian/ArchGDALDatasets/blob/307f8f0e584a39a050c042849004e6a2bd674f99/data/point.geojson) dataset.

```@example features
dataset = ArchGDAL.read("data/point.geojson")
```

## Feature Layers

```@example features
layer = ArchGDAL.getlayer(dataset, 0)
```

The display provides
* the **name** of the feature layer (`point`)
* the **geometries** in the dataset, and their brief summary.
* the **fields** in the dataset, and their brief summary.

You can also programmatically retrieve them using
* `ArchGDAL.getname(layer)`: the **name** of the feature layer
* `ArchGDAL.nfeature(layer)`: the **number of features** in the layer
* `featuredefn = ArchGDAL.layerdefn(layer)`: the **schema** of the layer features
* `ArchGDAL.nfield(featuredefn)`: the **number of fields**
* `ArchGDAL.ngeom(featuredefn)`: the **number of geometries**
* `ArchGDAL.getfielddefn(featuredefn, i)`: the definition for the `i`-th field
* `ArchGDAL.getgeomdefn(featuredefn, i)`: the definition for the `i`-th geometry

### Field Definitions

Each `fielddefn` defines an attribute of a feature, and supports the following:
* `ArchGDAL.getname(fielddefn)`: the name of the field (`"FID"` or `"pointname"`)
* `ArchGDAL.gettype(fielddefn)`: the type of the field (`OFTReal` or `OFTString`)

Each `geomdefn` defines an attribute of a geometry, and supports the following:
* `ArchGDAL.getname(geomdefn)`: the name of the geometry (`""` in this case)
* `ArchGDAL.gettype(geomdefn)`: the type of the geometry (`wkbPoint`)

## Individual Features
We can examine an individual feature
```@example features
ArchGDAL.getfeature(layer, 2) do feature
    print(feature)
end
```

You can programmatically retrieve the information using
* `ArchGDAL.nfield(feature)`: the **number of fields** (`2`)
* `ArchGDAL.ngeom(feature)`: the **number of geometries** (`1`)
* `ArchGDAL.getfield(feature, i)`: the `i`-th field (`0.0` and `"a"`)
* `ArchGDAL.getgeom(feature, i)`: the `i`-th geometry (the WKT display `POINT`)

More information on geometries can be found in [Geometric Operations](@ref).
