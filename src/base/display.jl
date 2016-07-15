function Base.show(io::IO, drv::Driver)
    if drv == C_NULL
        print(io, "Null Driver")
    else
        print(io, "Driver: $(shortname(drv))/$(longname(drv))")
    end
end

function Base.show(io::IO, dataset::Dataset)
    if dataset == C_NULL
        print(io, "Closed Dataset")
    else
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
                layer = borrow_getlayer(dataset, i-1)
                layergeomtype = _WKBGEOMTYPE[getgeomtype(layer)]
                print(io, "  Layer $(i-1): $(getname(layer)) ")
                println(io, "($layergeomtype), nfeatures = $(nfeature(layer))")
            end
            if nlayers > 5
                print(io, "  Remaining layers: ")
                for i in 6:nlayers
                    layer = getlayer(dataset, i-1)
                    print("$(getname(layer)) ")
                    # display up to 5 layer names per line
                    if i % 5 == 0 println() end
                end
            end
        end
    end
end

function summarize(io::IO, rasterband::RasterBand)
    if rasterband == C_NULL
        print(io, "Null RasterBand")
    else
        access = _ACCESSFLAG[getaccess(rasterband)]
        color = colorname(getcolorinterp(rasterband))
        xsize = width(rasterband)
        ysize = height(rasterband)
        i = indexof(rasterband)
        pxtype = getdatatype(rasterband)
        println(io, "[$access] Band $i ($color): $xsize x $ysize ($pxtype)")
    end
end

function Base.show(io::IO, rasterband::RasterBand)
    summarize(io, rasterband)
    (x,y) = getblocksize(rasterband)
    sc = getscale(rasterband)
    ofs = getoffset(rasterband)
    norvw = noverview(rasterband)
    ut = getunittype(rasterband)
    nv = getnodatavalue(rasterband)
    println(io, "    blocksize: $(x)x$(y), nodata: $nv, units: $(sc)px + $(ofs)$ut")
    print(io, "    overviews: ")
    for i in 1:norvw
        ovr_band = getoverview(rasterband, i-1)
        print(io, "($(i-1)) $(width(ovr_band))x$(height(ovr_band)) ")
        if i % 3 == 0
            println(io, "")
            print(io, "               ")
        end
    end
end

function Base.show(io::IO, layer::FeatureLayer)
    layergeomtype = _WKBGEOMTYPE[getgeomtype(layer)]
    print(io, "Layer: $(getname(layer)) ")
    println(io, "($layergeomtype), nfeatures = $(nfeature(layer))")
    println("Feature Definition:")
    featuredefn = borrow_getlayerdefn(layer)
    n = ngeomfield(featuredefn)
    ngeomdisplay = min(n, 3)
    for i in 1:ngeomdisplay
        gfd = borrow_getgeomfielddefn(featuredefn, i-1)
        print(io, "  Geometry (index $(i-1)): $(getname(gfd)) ")
        println(io, "($(_WKBGEOMTYPE[gettype(gfd)]))")
    end
    n > 3 && println(io, "  ...\n  Number of Geometries: $n")
    
    n = nfield(featuredefn)
    nfielddisplay = min(n, 5)
    for i in 1:nfielddisplay
        fd = borrow_getfielddefn(featuredefn, i-1)
        print(io, "     Field (index $(i-1)): $(getname(fd)) ")
        println(io, "($(_FIELDTYPE[gettype(fd)]))")
    end
    n > 5 && print(io, "...\n Number of Fields: $n")
end

function Base.show(io::IO, feature::Feature)
    println(io, "Feature")
    n = ngeomfield(feature)
    for i in 1:min(n, 3)
        displayname = getgeomname(borrow_getgeomfield(feature, i-1))
        println(io, "  (index $(i-1)) geom => $displayname")
    end
    n > 3 && println(io, "...\n Number of geometries: $n")
    n = nfield(feature)
    for i in 1:min(n, 10)
        displayname = getname(borrow_getfielddefn(feature, i-1))
        print(io, "  (index $(i-1)) $displayname => ")
        println("$(getfield(feature, i-1))")
    end
    n > 10 && print(io, "...\n Number of Fields: $n")
end

function Base.show(io::IO, spref::SpatialRef)
    println(io, "Spatial Reference System")
    print(io, "$(toWKT(spref, true))")
end