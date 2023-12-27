module ArchGDALMakieExt
using GeoInterfaceMakie: GeoInterfaceMakie
using ArchGDAL: ArchGDAL

GeoInterfaceMakie.@enable ArchGDAL.IGeometry
GeoInterfaceMakie.@enable ArchGDAL.Geometry
end
