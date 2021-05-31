# Tabular Interface

```@setup tables
using ArchGDAL
using DataFrames
```

ArchGDAL now brings in greater flexibilty in terms of vector data handling via the
[Tables.jl](https://github.com/JuliaData/Tables.jl) API. In general, tables are modelled based on feature layers and support multiple geometries per layer. Namely, the layer(s) of a dataset can be converted to DataFrame(s) to perform miscellaneous spatial operations.

Here is a quick example based on the
[`data/point.geojson`](https://github.com/yeesian/ArchGDALDatasets/blob/307f8f0e584a39a050c042849004e6a2bd674f99/data/point.geojson)
dataset:

```@example tables
dataset = ArchGDAL.read("data/point.geojson")

DataFrame(ArchGDAL.getlayer(dataset, 0))
```

Here is an example with multiple geometries based on the
[`data/multi_geom.csv`](https://github.com/yeesian/ArchGDALDatasets/blob/master/data/multi_geom.csv)
dataset:

```@example tables
dataset1 = ArchGDAL.read("data/multi_geom.csv", options = ["GEOM_POSSIBLE_NAMES=point,linestring", "KEEP_GEOM_COLUMNS=NO"])

DataFrame(ArchGDAL.getlayer(dataset1, 0))
```
