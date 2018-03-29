# Feature Data

In this section, we revisit the [`data/point.geojson`](https://github.com/yeesian/ArchGDALDatasets/blob/307f8f0e584a39a050c042849004e6a2bd674f99/data/point.geojson) dataset.

## Feature Layers
```julia
ArchGDAL.registerdrivers() do
    ArchGDAL.read("data/point.geojson") do dataset
        layer = AG.getlayer(dataset, 0)
        print(layer)
    end
end
```
which might print
```julia
Layer: OGRGeoJSON, nfeatures = 4
  Geometry 0 (): [wkbPoint], POINT (100 0), POINT (100.2785 0.0893), ...
     Field 0 (FID): [OFTReal], 2.0, 3.0, 0.0, 3.0
     Field 1 (pointname): [OFTString], point-a, point-b, a, b
```

The display provides
* the **name** of the feature layer (`OGRGeoJSON`)
* the **number of features** that are inside the layer. (`4`)
* the **geometries** in the dataset, and their brief summary.
* the **fields** in the dataset, and their brief summary.

You can also programmatically retrieve them using
* `ArchGDAL.getname(layer)`: the name of the feature layer
* `featuredefn = ArchGDAL.getlayerdefn(layer)`: the schema of the layer features
* `ArchGDAL.nfield(featuredefn)`: the number of fields
* `ArchGDAL.ngeomfield(featuredefn)`: the number of geometries
* `fielddefn = ArchGDAL.getfielddefn(featuredefn, i)`: the definition for field `i`
* `geomfielddefn = ArchGDAL.getgeomfielddefn(featuredefn, i)`: the definition for geometry `i`

Each `fielddefn` defines an attribute of a feature, and supports the following:
* `ArchGDAL.getname(fielddefn)`: the name of the field (`FID` or `pointname`)
* `ArchGDAL.gettype(fielddefn)`: the type of the field (`OFTReal` or `OFTString`)

Each `geomfielddefn` defines an attribute of a geometry, and supports the following:
* `ArchGDAL.getgeomname(geomfielddefn)`: the name of the geometry (empty in this case)
* `ArchGDAL.gettype(geomfielddefn)`: the type of the geometry (`wkbPoint`)

## Individual Features
We can examine an individual feature
```julia
AG.getfeature(layer, 2) do feature
    print(feature)
end
```
which might print
```julia
Feature
  (index 0) geom => POINT
  (index 0) FID => 0.0
  (index 1) pointname => a
```

You can programmatically retrieve the information using
* `ArchGDAL.nfield(feature)`: the number of fields (`2`)
* `ArchGDAL.ngeomfield(feature)`: the number of geometries (`1`)
* `ArchGDAL.getfield(feature, i)`: the `i`-th field (`0.0` and `"a"`)
* `ArchGDAL.getgeomfield(feature, i)`: the `i`-th geometry (the WKT display `POINT`)

More information on geometries can be found in `Geometric Operations`.
