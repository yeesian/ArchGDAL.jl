module ArchGDALMakieExt

import ArchGDAL
import GeoInterface
import Makie

GeoInterface.@enable_makie Makie ArchGDAL.IGeometry
GeoInterface.@enable_makie Makie ArchGDAL.Geometry

end
