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

Individual rows can be retrieved using the `Base.getindex(t::ArchGDAL.Table, idx::Int)` method.

```@example tables
row = table[1]
```

Layers are retrievable!
One can get back the layer that a Table is made up of.
```@example tables
lyr = ArchGDAL.getlayer(table)
```

The Tables interface also support multiple geometries per layer.

Here, we visit the
[`data/multi_geom.csv`](https://github.com/yeesian/ArchGDALDatasets/blob/master/data/multi_geom.csv)
dataset.

```@example tables
dataset1 = ArchGDAL.read("data/multi_geom.csv", options = ["GEOM_POSSIBLE_NAMES=point,linestring", "KEEP_GEOM_COLUMNS=NO"])

layer = ArchGDAL.getlayer(dataset, 0)
table = ArchGDAL.Table(layer)
```

Exatracting a row from the table, we see that the row/feature is made up of two geometries
viz. `point` and `linestring`.
```@example tables
row = Base.getindex(table, 1)
```

Finally layers can be converted to DataFrames to perform miscellaneous spatial operations.
```@example tables
df = DataFrame(table)
```
In some cases the `nextfeature` might become a bit tedious to use. In which case the `ArchGDAL.nextnamedtuple()` method comes in handy. Though built upon `nextfeature`, simply calling it, yields the `feature` as a `NamedTuple`. Though one might have to use `ArchGDAL.resetreading!(layer)` method to reset the layer reading to the start.

```@example tables
ArchGDAL.resetreading!(layer)
feat1 = ArchGDAL.nextnamedtuple(layer)
feat2 = ArchGDAL.nextnamedtuple(layer)
```
