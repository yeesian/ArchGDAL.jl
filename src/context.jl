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
    feature = unsafe_createfeature(featuredefn); reference(featuredefn)
    # the additional reference & dereference here is to deal with the case
    # where you start by (1) creating a featuredefn (0 references)
    # before (2) using it to create a feature here.
    # if we do not artificially increase the reference, then destroy(feature)
    # will release the featuredefn, when we're going to handle it ourselves
    # later. Therefore we dereference (rather than release) the featuredefn.
    try f(feature) finally destroy(feature); dereference(featuredefn) end
end

for gdalfunc in (:boundary, :buffer, :centroid, :clone, :convexhull, :create,
                 :createcolortable, :createcoordtrans, :createcopy,
                 :createfeaturedefn, :createfielddefn, :creategeom,
                 :creategeomcollection, :creategeomfieldcollection,
                 :creategeomfielddefn, :createlinearring, :createlinestring,
                 :createmultilinestring, :createmultipoint, :createmultipolygon,
                 :createmultipolygon_noholes, :createpoint, :createpolygon,
                 :createRAT, :createstylemanager, :createstyletable,
                 :createstyletool, :delaunaytriangulation, :difference,
                 :forceto, :fromEPSG, :fromEPSGA, :fromESRI, :fromGML,
                 :fromJSON, :fromPROJ4, :fromURL, :fromWKB, :fromWKT, :fromXML,
                 :getcurvegeom, :getfeature, :getlineargeom, :intersection,
                 :newspatialref, :nextfeature, :pointalongline, :pointonsurface,
                 :polygonfromedges, :polygonize, :read, :symdifference, :union,
                 :update)
    eval(quote
        function $(gdalfunc)(f::Function, args...; kwargs...)
            obj = $(symbol("unsafe_$gdalfunc"))(args...; kwargs...)
            try f(obj) finally destroy(obj) end
        end
    end)
end