function registerdrivers(f::Function)
    GDAL.allregister()
    try f() finally GDAL.destroydrivermanager() end
end

function executesql(f::Function, dataset::Dataset, args...)
    result = unsafe_executesql(dataset, args...)
    try f(result) finally releaseresultset(dataset, result) end
end

function createfeature(f::Function, layer::FeatureLayer)
    feature = unsafe_createfeature(layer)
    try f(feature); createfeature(layer, feature) finally destroy(feature) end
end

function createfeature(f::Function, featuredefn::FeatureDefn)
    feature = unsafe_createfeature(featuredefn)
    try f(feature) finally destroy(feature) end
end

for gdalfunc in (:boundary, :buffer, :centroid, :convexhull, :create,
                 :createcoordtrans, :createcopy, :createfeaturedefn,
                 :createfielddefn, :creategeom, :creategeomcollection,
                 :creategeomfieldcollection, :createlinearring,
                 :createlinestring, :createmultilinestring, :createmultipoint,
                 :createmultipolygon, :createmultipolygon_noholes, :createpoint,
                 :createpolygon, :delaunaytriangulation, :difference, :fromEPSG,
                 :fromEPSGA, :fromESRI, :fromGML, :fromJSON, :fromPROJ4,
                 :fromURL, :fromWKB, :fromWKT, :fromXML, :getcurvegeom,
                 :getfeature, :getlineargeom, :intersection, :newspatialref,
                 :nextfeature, :pointalongline, :pointonsurface,
                 :polygonfromedges, :polygonize, :read, :symdifference, :union,
                 :update)
    eval(quote
        function $(gdalfunc)(f::Function, args...; kwargs...)
            obj = $(symbol("unsafe_$gdalfunc"))(args...; kwargs...)
            try f(obj) finally destroy(obj) end
        end
    end)
end