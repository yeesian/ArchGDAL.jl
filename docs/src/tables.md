# Tabular Interface

```@setup tables
using ArchGDAL, DataFrames
```

ArchGDAL now brings in greater flexibilty in terms of vector data handling via the
[Tables.jl](https://github.com/JuliaData/Tables.jl) API. In general, tables are modelled based on feature layers and support multiple geometries per layer. Namely, the layer(s) of a dataset can be converted to DataFrame(s) to perform miscellaneous spatial operations.

Here is a quick example based on the
[`data/point.geojson`](https://github.com/yeesian/ArchGDALDatasets/blob/307f8f0e584a39a050c042849004e6a2bd674f99/data/point.geojson)
dataset:

```@example tables
dataset = ArchGDAL.read("data/point.geojson")

DataFrames.DataFrame(ArchGDAL.getlayer(dataset, 0))
```

To illustrate multiple geometries, here is a second example based on the
[`data/multi_geom.csv`](https://github.com/yeesian/ArchGDALDatasets/blob/master/data/multi_geom.csv)
dataset:

```@example tables
dataset1 = ArchGDAL.read("data/multi_geom.csv", options = ["GEOM_POSSIBLE_NAMES=point,linestring", "KEEP_GEOM_COLUMNS=NO"])

DataFrames.DataFrame(ArchGDAL.getlayer(dataset1, 0))
```

## Feature IDs

Database-like formats (GeoPackage, PostGIS, SQLite, ...) give each feature a
persistent primary key, the *FID*, which GDAL keeps out of the field
definitions. Where a driver reports one through
[`ArchGDAL.fidcolumnname`](@ref), it leads the table under that name, and its
values match [`ArchGDAL.getfid`](@ref):

```julia
julia> layer = ArchGDAL.getlayer(ArchGDAL.read("rivers.gpkg"), 0);

julia> ArchGDAL.fidcolumnname(layer)
"id"

julia> DataFrames.DataFrame(layer)
357×5 DataFrame
 Row │ id     geom                     property_0  property_1      property_2
     │ Int64  IGeometry                String      String          String
─────┼────────────────────────────────────────────────────────────────────────
   1 │     1  Geometry: wkbLineString  6           Sutlej          null
   2 │     2  Geometry: wkbLineString  4           Svernaya Dvina  null
  ⋮  │   ⋮               ⋮                 ⋮             ⋮              ⋮
```

Formats without one, such as ESRI Shapefile and FlatGeobuf, report `""` and
gain no column. Where a driver reports a FID column that is also an ordinary
field — GeoJSON does this for `id`, both holding the same value — the field
wins, so the column is never duplicated.
