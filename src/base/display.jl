function Base.show(io::IO, drv::Driver)
    drv == C_NULL && (print(io, "NULL Driver"); return)
    print(io, "Driver: $(shortname(drv))/$(longname(drv))")
end

function Base.show(io::IO, dataset::Dataset)
    dataset == C_NULL && (print(io, "NULL Dataset"); return)
    println(io, "GDAL Dataset ($(getdriver(dataset)))")
    print(io, "File(s): ")
    for (i,filename) in enumerate(filelist(dataset))
        print(io, "$filename ")
        # display up to 4 filenames per line
        if i % 4 == 0 println() end
    end
    nrasters = nraster(dataset)
    if nrasters > 0
        print(io, "\nDataset (width x height): ")
        println(io, "$(width(dataset)) x $(height(dataset)) (pixels)")
        println(io, "Number of raster bands: $(nrasters)")
        for i in 1:min(nrasters, 3)
            print(io, "  ")
            summarize(io, getband(dataset, i))
        end
        nrasters > 3 && println(io, "  ...")
    end

    nlayers = nlayer(dataset)
    if nlayers > 0
        println(io, "\nNumber of feature layers: $(nlayers)")
        ndisplay = min(nlayers, 5) # display up to 5 layers
        for i in 1:ndisplay
            layer = getlayer(dataset, i-1)
            layergeomtype = getgeomtype(layer)
            print(io, "  Layer $(i-1): $(getname(layer)) ")
            println(io, "($layergeomtype), nfeatures = $(nfeature(layer))")
        end
        if nlayers > 5
            print(io, "  Remaining layers: ")
            for i in 6:nlayers
                layer = getlayer(dataset, i-1)
                print(io, "$(getname(layer)) ")
                # display up to 5 layer names per line
                if i % 5 == 0 println() end
            end
        end
    end
end

function summarize(io::IO, rasterband::RasterBand)
    rasterband == C_NULL && (print(io, "NULL RasterBand"); return)
    access = getaccess(rasterband)
    color = getname(getcolorinterp(rasterband))
    xsize = width(rasterband)
    ysize = height(rasterband)
    i = getnumber(rasterband)
    pxtype = getdatatype(rasterband)
    println(io, "[$access] Band $i ($color): $xsize x $ysize ($pxtype)")
end

function Base.show(io::IO, rasterband::RasterBand)
    rasterband == C_NULL && (print(io, "NULL RasterBand"); return)
    summarize(io, rasterband)
    (x,y) = getblocksize(rasterband)
    sc = getscale(rasterband)
    ofs = getoffset(rasterband)
    norvw = noverview(rasterband)
    ut = getunittype(rasterband)
    nv = getnodatavalue(rasterband)
    print(io, "    blocksize: $(x)x$(y), nodata: $nv, ")
    println(io, "units: $(sc)px + $(ofs)$ut")
    print(io, "    overviews: ")
    for i in 1:norvw
        ovr_band = getoverview(rasterband, i-1)
        print(io, "($(i-1)) $(width(ovr_band))x$(height(ovr_band)) ")
        i % 3 == 0 && print(io, "\n               ")
    end
end

function Base.show(io::IO, layer::FeatureLayer)
    layer == C_NULL && (println(io, "NULL Layer"); return)
    layergeomtype = getgeomtype(layer)
    print(io, "Layer: $(getname(layer)) ")
    println(io, "($layergeomtype), nfeatures = $(nfeature(layer))")
    println(io, "Feature Definition:")
    featuredefn = getlayerdefn(layer)
    n = ngeomfield(featuredefn)
    ngeomdisplay = min(n, 3)
    for i in 1:ngeomdisplay
        gfd = getgeomfielddefn(featuredefn, i-1)
        print(io, "  Geometry (index $(i-1)): $(getname(gfd)) ")
        println(io, "($(gettype(gfd)))")
    end
    n > 3 && println(io, "  ...\n  Number of Geometries: $n")
    
    n = nfield(featuredefn)
    nfielddisplay = min(n, 5)
    for i in 1:nfielddisplay
        fd = getfielddefn(featuredefn, i-1)
        print(io, "     Field (index $(i-1)): $(getname(fd)) ")
        println(io, "($(gettype(fd)))")
    end
    n > 5 && print(io, "...\n Number of Fields: $n")
end

function Base.show(io::IO, feature::Feature)
    feature == C_NULL && (println(io, "NULL Feature"); return)
    println(io, "Feature")
    n = ngeomfield(feature)
    for i in 1:min(n, 3)
        displayname = getgeomname(getgeomfield(feature, i-1))
        println(io, "  (index $(i-1)) geom => $displayname")
    end
    n > 3 && println(io, "...\n Number of geometries: $n")
    n = nfield(feature)
    for i in 1:min(n, 10)
        displayname = getname(getfielddefn(feature, i-1))
        print(io, "  (index $(i-1)) $displayname => ")
        println(io, "$(getfield(feature, i-1))")
    end
    n > 10 && print(io, "...\n Number of Fields: $n")
end

function Base.show(io::IO, spref::SpatialRef)
    spref == C_NULL && (print(io, "NULL Spatial Reference System"); return)
    print(io, "Spatial Reference System: $(toPROJ4(spref))")
end

function Base.show(io::IO, geom::Geometry)
    geom == C_NULL && (print(io, "NULL Geometry"); return)
    print(io, "Geometry: ")
    print(io, "$(toWKT(geom))")
end