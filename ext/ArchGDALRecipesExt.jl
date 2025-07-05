module ArchGDALRecipesBaseExt

import ArchGDAL
import GeoInterface
import RecipesBase

GeoInterface.@enable_makie RecipesBase ArchGDAL.IGeometry
GeoInterface.@enable_makie RecipesBase ArchGDAL.Geometry

end
