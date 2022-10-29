function Base.show(io::IO, drv::Driver)::Nothing
    if drv.ptr == C_NULL
        print(io, "NULL Driver")
    else
        print(io, "Driver: $(shortname(drv))/$(longname(drv))")
    end
    return nothing
end

function Base.show(io::IO, dataset::AbstractDataset)::Nothing
    if dataset.ptr == C_NULL
        print(io, "NULL Dataset")
        return nothing
    end
    println(io, "GDAL Dataset ($(getdriver(dataset)))")
    println(io, "File(s): ")
    for (i, filename) in enumerate(filelist(dataset))
        println(io, "  $filename")
        if i > 5
            println(io, "  ...")
            break
        end
    end
    nrasters = nraster(dataset)
    if nrasters > 0
        print(io, "\nDataset (width x height): ")
        println(io, "$(width(dataset)) x $(height(dataset)) (pixels)")
        println(io, "Number of raster bands: $nrasters")
        for i in 1:min(nrasters, 3)
            print(io, "  ")
            summarize(io, getband(dataset, i))
        end
        nrasters > 3 && println(io, "  ...")
    end

    nlayers = nlayer(dataset)
    if nlayers > 0
        println(io, "\nNumber of feature layers: $nlayers")
        ndisplay = min(nlayers, 5) # display up to 5 layers
        for i in 1:ndisplay
            layer = getlayer(dataset, i - 1)
            layergeomtype = getgeomtype(layer)
            println(io, "  Layer $(i - 1): $(getname(layer)) ($layergeomtype)")
        end
        if nlayers > 5
            print(io, "  Remaining layers:\n    ")
            for i in 6:nlayers
                print(io, "$(getname(getlayer(dataset, i - 1))), ")
                # display up to 5 layer names per line
                if i % 5 == 0 && i < nlayers
                    print(io, "\n    ")
                end
            end
        end
    end
    return nothing
end

#Add method to avoid show from DiskArrays
Base.show(io::IO, raster::RasterDataset)::Nothing = show(io, raster.ds)

Base.show(io::IO, ::MIME"text/plain", raster::RasterDataset)::Nothing =
    show(io, raster.ds)

function summarize(io::IO, rasterband::AbstractRasterBand)::Nothing
    if rasterband.ptr == C_NULL
        print(io, "NULL RasterBand")
        return nothing
    end
    access = accessflag(rasterband)
    color = getname(getcolorinterp(rasterband))
    xsize = width(rasterband)
    ysize = height(rasterband)
    i = indexof(rasterband)
    pxtype = pixeltype(rasterband)
    println(io, "[$access] Band $i ($color): $xsize x $ysize ($pxtype)")
    return nothing
end

Base.show(io::IO, rasterband::AbstractRasterBand)::Nothing =
    show(io, "text/plain", rasterband)

function Base.show(
    io::IO,
    ::MIME"text/plain",
    rasterband::AbstractRasterBand,
)::Nothing
    summarize(io, rasterband)
    if rasterband.ptr == C_NULL
        return nothing
    end
    (x, y) = blocksize(rasterband)
    sc = getscale(rasterband)
    ofs = getoffset(rasterband)
    norvw = noverview(rasterband)
    ut = getunittype(rasterband)
    nv = getnodatavalue(rasterband)
    print(io, "    blocksize: $(x)×$(y), nodata: $nv, ")
    println(io, "units: $(sc)px + $ofs$ut")
    print(io, "    overviews: ")
    for i in 1:norvw
        ovr_band = getoverview(rasterband, i - 1)
        print(io, "($(i - 1)) $(width(ovr_band))x$(height(ovr_band)) ")
        i % 3 == 0 && print(io, "\n               ")
    end
    return nothing
end

# assumes that the layer is reset, and will reset it after display
function Base.show(io::IO, layer::AbstractFeatureLayer)::Nothing
    if layer.ptr == C_NULL
        print(io, "NULL FeatureLayer")
        return nothing
    end
    layergeomtype = getgeomtype(layer)
    println(io, "Layer: $(getname(layer))")
    featuredefn = layerdefn(layer)

    # Print Geometries
    n = ngeom(featuredefn)
    ngeomdisplay = min(n, 3)
    for i in 1:ngeomdisplay
        gfd = getgeomdefn(featuredefn, i - 1)
        display = "  Geometry $(i - 1) ($(getname(gfd))): [$(gettype(gfd))]"
        if length(display) > 75
            println(io, "$display[1:70]...")
            continue
        end
        if ngeomdisplay == 1 # only support printing of a single geom column
            for f in layer
                geomwkt = toWKT(getgeom(f))
                length(geomwkt) > 25 && (geomwkt = "$(geomwkt[1:20])...)")
                newdisplay = "$display, $geomwkt"
                if length(newdisplay) > 75
                    display = "$display, ..."
                    break
                else
                    display = newdisplay
                end
            end
        end
        println(io, display)
        resetreading!(layer)
    end
    n > 3 && println(io, "  ...\n  Number of Geometries: $n")

    # Print Features
    n = nfield(featuredefn)
    nfielddisplay = min(n, 5)
    for i in 1:nfielddisplay
        fd = getfielddefn(featuredefn, i - 1)
        display = "     Field $(i - 1) ($(getname(fd))): [$(getfieldtype(fd))]"
        if length(display) > 75
            println(io, "$display[1:70]...")
            continue
        end
        for f in layer
            field = string(getfield(f, i - 1))
            length(field) > 25 && (field = "$(field[1:20])...")
            newdisplay = "$display, $field"
            if length(newdisplay) > 75
                display = "$display, ..."
                break
            else
                display = newdisplay
            end
        end
        println(io, display)
        resetreading!(layer)
    end
    n > 5 && print(io, "...\n Number of Fields: $n")
    return nothing
end

function Base.show(io::IO, featuredefn::AbstractFeatureDefn)::Nothing
    if featuredefn.ptr == C_NULL
        print(io, "NULL FeatureDefn")
        return nothing
    end
    n = ngeom(featuredefn)
    ngeomdisplay = min(n, 3)
    for i in 1:ngeomdisplay
        gfd = getgeomdefn(featuredefn, i - 1)
        println(io, "  Geometry (index $(i - 1)): $gfd")
    end
    n > 3 && println(io, "  ...\n  Number of Geometries: $n")

    n = nfield(featuredefn)
    nfielddisplay = min(n, 5)
    for i in 1:nfielddisplay
        fd = getfielddefn(featuredefn, i - 1)
        println(io, "     Field (index $(i - 1)): $fd")
    end
    n > 5 && print(io, "...\n Number of Fields: $n")
    return nothing
end

function Base.show(io::IO, fd::AbstractFieldDefn)::Nothing
    if fd.ptr == C_NULL
        print(io, "NULL FieldDefn")
        return nothing
    end
    print(io, "$(getname(fd)) ($(gettype(fd)))")
    return nothing
end

function Base.show(io::IO, gfd::AbstractGeomFieldDefn)::Nothing
    if gfd.ptr == C_NULL
        print(io, "NULL GeomFieldDefn")
        return nothing
    end
    print(io, "$(getname(gfd)) ($(gettype(gfd)))")
    return nothing
end

function Base.show(io::IO, feature::AbstractFeature)::Nothing
    if feature.ptr == C_NULL
        print(io, "NULL Feature")
        return nothing
    end
    println(io, "Feature")
    n = ngeom(feature)
    for i in 1:min(n, 3)
        displayname = geomname(getgeom(feature, i - 1))
        println(io, "  (index $(i - 1)) geom => $displayname")
    end
    n > 3 && println(io, "...\n Number of geometries: $n")
    n = nfield(feature)
    for i in 1:min(n, 10)
        displayname = getname(getfielddefn(feature, i - 1))
        print(io, "  (index $(i - 1)) $displayname => ")
        println(io, "$(getfield(feature, i - 1))")
    end
    n > 10 && print(io, "...\n Number of Fields: $n")
    return nothing
end

function Base.show(io::IO, spref::AbstractSpatialRef)::Nothing
    if spref.ptr == C_NULL
        print(io, "NULL Spatial Reference System")
        return nothing
    end
    projstr = toPROJ4(spref)
    if length(projstr) > 45
        projstart = projstr[1:35]
        projend = projstr[(end-4):end]
        print(io, "Spatial Reference System: $projstart ... $projend")
    else
        print(io, "Spatial Reference System: $projstr")
    end
    return nothing
end

function Base.show(io::IO, geom::AbstractGeometry)::Nothing
    if geom.ptr == C_NULL
        print(io, "NULL Geometry")
        return nothing
    end
    compact = get(io, :compact, false)

    if !compact
        print(io, "Geometry: ")
        geomwkt = toWKT(geom)
        if length(geomwkt) > 60
            print(io, "$(geomwkt[1:50]) ... $(geomwkt[(end - 4):end])")
        else
            print(io, "$geomwkt")
        end
    else
        print(io, "Geometry: $(getgeomtype(geom))")
    end
    return nothing
end

function Base.show(io::IO, geom::AbstractPreparedGeometry)::Nothing
    if geom.ptr == C_NULL
        print(io, "NULL Geometry")
        return nothing
    end
    print(io, "Prepared Geometry")
    return nothing
end

function Base.show(io::IO, ct::ColorTable)::Nothing
    if ct.ptr == C_NULL
        print(io, "NULL ColorTable")
        return nothing
    end
    palette = paletteinterp(ct)
    print(io, "ColorTable[$palette]")
    return nothing
end

Base.show(io::IO, ::MIME"text/plain", ct::ColorTable)::Nothing = show(io, ct)
