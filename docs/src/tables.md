# Tabular Interface

```@setup tables
using ArchGDAL
using DataFrames
```

ArchGDAL now brings in greater flexibilty in terms of raster data handling via the
[Tables.jl](https://github.com/JuliaData/Tables.jl) API, that aims to provide a fast and
responsive tabular interface to data.

In this section, we revisit the
[`data/point.geojson`](https://github.com/yeesian/ArchGDALDatasets/blob/307f8f0e584a39a050c042849004e6a2bd674f99/data/point.geojson)
dataset.

```@example tables
dataset = ArchGDAL.read("data/point.geojson")
```

Each layer can be represented as a separate Table.

```@example tables
layer = ArchGDAL.getlayer(dataset, 0)
```

The [`ArchGDAL.Table`](@ref) method accepts an `ArchGDAL.FeatureLayer`.
```@example tables
table = ArchGDAL.Table(layer)
```

Finally layers can be converted to DataFrames to perform miscellaneous spatial operations. Here, we visit the
[`data/multi_geom.csv`](https://github.com/yeesian/ArchGDALDatasets/blob/master/data/multi_geom.csv)
dataset.

```@example tables
dataset1 = ArchGDAL.read("data/multi_geom.csv", options = ["GEOM_POSSIBLE_NAMES=point,linestring", "KEEP_GEOM_COLUMNS=NO"])

layer = ArchGDAL.getlayer(dataset1, 0)
table = ArchGDAL.Table(layer)
df = DataFrame(table)
```

The Tables interface also supports multiple geometries per layer.
