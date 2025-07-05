module ArchGDALRecipesBaseExt

import ArchGDAL
import GeoInterface
import RecipesBase

GeoInterface.@enable_plots RecipesBase ArchGDAL.IGeometry
GeoInterface.@enable_plots RecipesBase ArchGDAL.Geometry

end
