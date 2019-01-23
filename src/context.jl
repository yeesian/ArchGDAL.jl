function environment(
        f::Function;
        globalconfig::Vector=[],
        threadconfig::Vector=[]
    )
    # Save the current settings
    #
    # CPLGetConfigOption() will return the value of the config option, be it
    #     either defined through environment variable, CPLSetConfigOption() or
    #     CPLSetThreadLocalConfigOption() (from the same thread).
    # CPLGetThreadLocalConfigOption() will return the value of the config
    #     option, but only if it has been set with
    #     CPLSetThreadLocalConfigOption()
    #
    # (ref https://github.com/mapbox/rasterio/pull/997#issuecomment-287117289)
    globalsettings = Dict(k => getconfigoption(k) for (k,v) in globalconfig)
    localsettings = Dict(k => getthreadconfigoption(k) for (k,v) in threadconfig)
    for (k,v) in threadconfig; setthreadconfigoption(k, v) end
    for (k,v) in globalconfig; setconfigoption(k, v) end

    try
        f()
    finally
        # Restore previous settings
        for (k,v) in globalsettings
            if v == ""
                clearconfigoption(k)
            else
                setconfigoption(k, v)
            end
        end
        for (k,v) in localsettings
            if v == ""
                clearthreadconfigoption(k)
            else
                setthreadconfigoption(k, v)
            end
        end
    end
end

function executesql(f::Function, dataset::AbstractDataset, args...)
    result = unsafe_executesql(dataset, args...)
    try f(result) finally releaseresultset(dataset, result) end
end

function createfeature(f::Function, layer::FeatureLayer)
    feature = unsafe_createfeature(layer)
    try f(feature); createfeature!(layer, feature) finally destroy(feature) end
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

for gdalfunc in (
        :boundary, :buffer, :centroid, :clone, :convexhull, :create,
        :createcolortable, :createcoordtrans, :createcopy, :createfeaturedefn,
        :createfielddefn, :creategeom, :creategeomcollection,
        :creategeomfieldcollection, :creategeomfielddefn, :createlinearring,
        :createlinestring, :createmultilinestring, :createmultipoint,
        :createmultipolygon, :createmultipolygon_noholes, :createpoint,
        :createpolygon, :createRAT, :createstylemanager, :createstyletable,
        :createstyletool, :delaunaytriangulation, :difference, :forceto,
        :fromGML, :fromJSON, :fromWKB, :fromWKT, :getcurvegeom, :getfeature,
        :getlineargeom, :getpart, :getspatialref, :intersection, :importEPSG,
        :importEPSGA, :importESRI, :importPROJ4, :importWKT, :importXML,
        :importURL, :newspatialref, :nextfeature, :pointalongline,
        :pointonsurface, :polygonfromedges, :polygonize, :read, :simplify,
        :simplifypreservetopology, :symdifference, :union, :update
    )
    eval(quote
        function $(gdalfunc)(f::Function, args...; kwargs...)
            obj = $(Symbol("unsafe_$gdalfunc"))(args...; kwargs...)
            try f(obj) finally destroy(obj) end
        end
    end)
end
