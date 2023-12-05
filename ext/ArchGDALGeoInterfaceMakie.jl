module ArchGDALGeoInterfaceMakie
using GeoInterfaceMakie: GeoInterfaceMakie
using ArchGDAL: ArchGDAL

println("ArchGDALGeoInterfaceMakie.jl")
GeoInterfaceMakie.@enable ArchGDAL.IGeometry
GeoInterfaceMakie.@enable ArchGDAL.Geometry
end