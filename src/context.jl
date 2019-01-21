function registerdrivers(f::Function;
                         globalconfig::Vector=[],
                         threadconfig::Vector=[])
    # Save the current settings
    globalsettings = Dict{String, String}()
    for (k, v) in globalconfig
        globalsettings[k] = getconfigoption(k)
    end
    localsettings = Dict{String, String}()
    for (k, v) in threadconfig
        localsettings[k] = getthreadconfigoption(k)
    end
    # TODO use syntax below once v0.4 support is dropped (not in Compat.jl)
    # globalsettings=Dict(k=>getconfigoption(k) for (k,v) in globalconfig)
    # localsettings=Dict(k=>getthreadconfigoption(k) for (k,v) in threadconfig)
    # Set the user settings
    for (k,v) in threadconfig; setthreadconfigoption(k, v) end
    for (k,v) in globalconfig; setconfigoption(k, v) end

    try
        GDAL.allregister(); f()
    finally
        GDAL.destroydrivermanager()
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

function executesql(f::Function, dataset::Dataset, args...)
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
        :fromGML, :fromJSON, :fromWKB, :fromWKT, :gdalbuildvrt, :gdaldem,
        :gdalgrid, :gdalnearblack, :gdalrasterize, :gdaltranslate,
        :gdalvectortranslate, :gdalwarp, :getcurvegeom, :getfeature,
        :getlineargeom, :getpart, :intersection, :importEPSG, :importEPSGA,
        :importESRI, :importPROJ4, :importWKT, :importXML, :importURL,
        :newspatialref, :nextfeature, :pointalongline, :pointonsurface,
        :polygonfromedges, :polygonize, :read, :simplify,
        :simplifypreservetopology, :symdifference, :union, :update
    )
    eval(quote
        function $(gdalfunc)(f::Function, args...; kwargs...)
            obj = $(Symbol("unsafe_$gdalfunc"))(args...; kwargs...)
            try f(obj) finally destroy(obj) end
        end
    end)
end
