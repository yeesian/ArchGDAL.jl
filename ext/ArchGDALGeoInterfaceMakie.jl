module ArchGDALGeoInterfaceMakie
using GeoInterfaceMakie: GeoInterfaceMakie as GIM
using ArchGDAL: ArchGDAL

println("ArchGDALGeoInterfaceMakie.jl")
GIM.@enable ArchGDAL.IGeometry
GIM.@enable ArchGDAL.Geometry
end