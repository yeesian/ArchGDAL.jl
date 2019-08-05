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

function executesql(f::Function, dataset::Dataset, args...)
    result = unsafe_executesql(dataset, args...)
    try
        f(result)
    finally
        releaseresultset(dataset, result)
    end
end

function writefeature(f::Function, layer::FeatureLayer)
    feature = unsafe_createfeature(layer)
    try
        f(feature)
        write!(layer, feature)
    finally
        destroy(feature)
    end
end

function createfeature(f::Function, featuredefn::FeatureDefn)
    feature = unsafe_createfeature(featuredefn)
    reference(featuredefn)
    # the additional reference & dereference here is to deal with the case
    # where you start by (1) creating a featuredefn (0 references)
    # before (2) using it to create a feature here.
    # if we do not artificially increase the reference, then destroy(feature)
    # will release the featuredefn, when we're going to handle it ourselves
    # later. Therefore we dereference (rather than release) the featuredefn.
    try
        f(feature)
    finally
        destroy(feature)
        dereference(featuredefn)
    end
end

"""
Create a new field on a layer.

This function should not be called while there are feature objects in existence
that were obtained or created with the previous layer definition.

Not all drivers support this function. You can query a layer to check if it
supports it with the OLCCreateField capability. Some drivers may only support
this method while there are still no features in the layer. When it is
supported, the existing features of the backing file/database should be updated
accordingly.

Drivers may or may not support not-null constraints. If they support creating
fields with not-null constraints, this is generally before creating any feature
to the layer.

### Parameters
* `layer`:  the layer to write the field definition.
* `name`:   name of the field definition to write to disk.
* `etype`:  type of the field definition to write to disk.

### Keyword arguments
* `nwidth`:     the preferred formatting width. 0 (default) indicates undefined.
* `nprecision`: number of decimals for formatting. 0 (default) for undefined.
* `justify`:    the formatting justification ([OJUndefined], OJLeft or OJRight)
* `approx`:     If `true` (default `false`), the field may be created in a
                slightly different form depending on the limitations of the
                format driver.
"""
function writefielddefn!(
        layer::FeatureLayer,
        name::AbstractString,
        etype::OGRFieldType;
        nwidth::Integer             = 0,
        nprecision::Integer         = 0,
        justify::OGRJustification   = GDAL.OJUndefined,
        approx::Bool                = false
    )
    fielddefn = unsafe_createfielddefn(name, etype)
    setparams!(fielddefn, name, etype, nwidth = nwidth, nprecision = nprecision,
        justify = justify)
    write!(layer, fielddefn)
    destroy(fielddefn)
    layer
end

function writefielddefn(
        f::Function,
        layer::FeatureLayer,
        name::AbstractString,
        etype::OGRFieldType;
        nwidth::Integer             = 0,
        nprecision::Integer         = 0,
        justify::OGRJustification   = GDAL.OJUndefined,
        approx::Bool                = false
    )
    fielddefn = unsafe_createfielddefn(name, etype)
    setparams!(fielddefn, name, etype, nwidth = nwidth, nprecision = nprecision,
        justify = justify)
    try
        f(fielddefn)
        write!(layer, fielddefn)
    finally
        destroy(fielddefn)
    end
end

"""
Write a new geometry field on a layer.

This function should not be called while there are feature objects in existence
that were obtained or created with the previous layer definition.

Not all drivers support this function. You can query a layer to check if it
supports it with the OLCCreateField capability. Some drivers may only support
this method while there are still no features in the layer. When it is
supported, the existing features of the backing file/database should be updated
accordingly.

Drivers may or may not support not-null constraints. If they support creating
fields with not-null constraints, this is generally before creating any feature
to the layer.

### Parameters
* `layer`:  the layer to write the field definition.
* `name`:   name of the field definition to write to disk.
* `etype`:  type of the geometry field defintion to write to disk.

### Keyword arguments
* `approx`: If `true` (default `false`), the geometry field may be created in a
            slightly different form depending on the limitations of the driver.
"""
function writegeomdefn(
        f::Function,
        layer::FeatureLayer,
        name::AbstractString,
        etype::OGRwkbGeometryType;
        approx::Bool = false
    )
    geomdefn = unsafe_creategeomdefn(name, etype)
    try
        f(geomdefn)
        write!(layer, geomdefn)
    finally
        destroy(geomdefn)
    end
end

for gdalfunc in (
        :boundary, :buffer, :centroid, :clone, :convexhull, :create,
        :createcolortable, :createcoordtrans, :createcopy, :createfeaturedefn,
        :createfielddefn, :creategeom, :creategeomcollection,
        :creategeomfieldcollection, :creategeomdefn, :createlinearring,
        :createlinestring, :createmultilinestring, :createmultipoint,
        :createmultipolygon, :createmultipolygon_noholes, :createpoint,
        :createpolygon, :createRAT, :createstylemanager, :createstyletable,
        :createstyletool, :delaunaytriangulation, :difference, :forceto,
        :fromGML, :fromJSON, :fromWKB, :fromWKT, :gdalbuildvrt, :gdaldem,
        :gdalgrid, :gdalnearblack, :gdalrasterize, :gdaltranslate,
        :gdalvectortranslate, :gdalwarp, :getcolortable, :getcurvegeom,
        :getfeature, :getgeom, :getlineargeom, :getpart, :getspatialref,
        :intersection, :importEPSG, :importEPSGA, :importESRI, :importPROJ4,
        :importWKT, :importXML, :importURL, :newspatialref, :nextfeature,
        :pointalongline, :pointonsurface, :polygonfromedges, :polygonize, :read,
        :simplify, :simplifypreservetopology, :symdifference, :union, :update
    )
    eval(quote
        function $(gdalfunc)(f::Function, args...; kwargs...)
            obj = $(Symbol("unsafe_$gdalfunc"))(args...; kwargs...)
            try f(obj) finally destroy(obj) end
        end
    end)
end
