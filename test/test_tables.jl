using Test
import ArchGDAL; const AG = ArchGDAL
using Tables

# @testset "DataStream Support" begin
#     df = AG.read("data/point.geojson") do dataset
#         DataStreams.Data.close!(DataStreams.Data.stream!(
#             AG.Source(AG.getlayer(dataset,0)), DataStreams.Data.Table
#         ))
#     end
#     @test df.FID == [2.0, 3.0, 0.0, 3.0]
#     @test df.pointname == ["point-a", "point-b", "a", "b"]
#     @test AG.toWKT.(df.geometry0) == [
#         "POINT (100 0)",
#         "POINT (100.2785 0.0893)",
#         "POINT (100 0)",
#         "POINT (100.2785 0.0893)"
#     ]
# end

dataset = AG.read(joinpath(@__DIR__, "data/point.geojson"))
layer = AG.getlayer(dataset, 0)

nfeat = AG.nfeature(layer)
nfield = AG.nfield(layer)
featuredefn = AG.layerdefn(layer)
ngeometries = AG.ngeom(featuredefn)

Tables.istable(layer::AG.AbstractFeatureLayer) = true
Tables.rowaccess(layer::AG.AbstractFeatureLayer) = true

function Tables.schema(layer::AG.AbstractFeatureLayer)
    # TODO include names and types of geometry columns
    featuredefn = AG.layerdefn(layer)
    fielddefns = (AG.getfielddefn(featuredefn, i) for i in 0:nfield-1)
    names = Tuple(AG.getname(fielddefn) for fielddefn in fielddefns)
    types = Tuple(AG._FIELDTYPE[AG.gettype(fielddefn)] for fielddefn in fielddefns)
    Tables.Schema(names, types)
end

schema = Tables.schema(layer)

function Tables.rows(layer::AG.AbstractFeatureLayer)
    # TODO return an iterator rather than a vector of NamedTuples
    schema = Tables.schema(layer)
    T = NamedTuple{schema.names, Tuple{schema.types...}}
    AG.resetreading!(layer)
    nfeat = AG.nfeature(layer)
    nfield = AG.nfield(layer)
    rows = T[]
    for _ in 1:nfeat
        AG.nextfeature(layer) do feature
            # AG.getgeom(feature, 0)  # TODO
            push!(rows, T(AG.getfield(feature, j) for j in 0:nfield-1))
        end
    end
    return rows
end

Tables.rows(layer)

# TODO getcolumn support
# using DataFrames
# DataFrame(layer)
