using FactCheck
import ArchGDAL; const AG = ArchGDAL

AG.registerdrivers() do

AG.read("ospy/data1/sites.shp") do input
    #reference: http://www.gis.usu.edu/~chrisg/python/2009/lectures/ospy_hw1a.py
    facts("Homework 1(a)") do
        open("tmp/hw1a.txt", "w") do file
            for feature in AG.borrow_getlayer(input, 0)
                id = AG.getfield(feature, 0); cover = AG.getfield(feature, 1)
                (x,y) = AG.getpoint(AG.borrow_getgeomfield(feature, 0), 0)
                write(file, "$id $x $y $cover\n")
    end end end

    #reference: http://www.gis.usu.edu/~chrisg/python/2009/lectures/ospy_hw1b.py
    facts("Homework 1(b)") do
        # version 1
        AG.create("tmp/hw1b.shp", "ESRI Shapefile") do output
            inlayer = AG.borrow_getlayer(input, 0)
            outlayer = AG.createlayer(output, "hw1b", geom=GDAL.wkbPoint)
            inlayerdefn = AG.borrow_getlayerdefn(inlayer)
            AG.createfield!(outlayer, AG.borrow_getfielddefn(inlayerdefn, 0))
            AG.createfield!(outlayer, AG.borrow_getfielddefn(inlayerdefn, 1))
            for infeature in inlayer
                id = AG.getfield(infeature, 0)
                cover = AG.getfield(infeature, 1)
                if cover == "trees"
                    AG.createfeature(outlayer) do outfeature
                        AG.setgeom!(outfeature, AG.borrow_getgeom(infeature))
                        AG.setfield!(outfeature, 0, id)
                        AG.setfield!(outfeature, 1, cover)
        end end end end

        # version 2
        AG.create("tmp/hw1b.shp", "ESRI Shapefile") do output
            AG.executesql(input, """SELECT * FROM sites
                                    WHERE cover = 'trees' """) do results
                AG.copylayer(output, results, "hw1b")
end end end end
    
#reference: http://www.gis.usu.edu/~chrisg/python/2009/lectures/ospy_hw2a.py
facts("Homework 2(a)") do
    # We first create a "tmp/hw2a.shp" file that we use for Homework 2(b)
    open("ospy/data2/ut_counties.txt", "r") do file
        AG.create("tmp/hw2a.shp", "ESRI Shapefile") do output
            layer = AG.createlayer(output, "hw2a", geom=GDAL.wkbPolygon)
            AG.createfielddefn("name", GDAL.OFTString) do fielddefn
                AG.setwidth!(fielddefn, 30)
                AG.createfield!(layer, fielddefn)
            end
            for line in readlines(file)
                (name, coords) = split(line, ":")
                coordlist = split(coords, ",")
                AG.createfeature(layer) do feature
                    AG.setfield!(feature, 0, name)
                    AG.createpolygon() do poly
                        ring = AG.unsafe_createlinearring()
                        for xy in map(split, coordlist)
                            AG.addpoint!(ring, parse(Float64, xy[1]),
                                               parse(Float64, xy[2]))
                        end
                        AG.addgeomdirectly!(poly, ring)
                        AG.setgeom!(feature, poly)    
end end end end end end

# adapted from http://www.gis.usu.edu/~chrisg/python/2009/lectures/ospy_hw2b.py
facts("Homework 2(b)") do
    AG.fromEPSG(4269) do inspatialref
    AG.fromEPSG(26912) do outspatialref
    AG.createcoordtrans(inspatialref, outspatialref) do coordtrans
        AG.read("tmp/hw2a.shp") do input
        AG.create("tmp/hw2b.shp", "ESRI Shapefile") do output
            inlayer = AG.borrow_getlayer(input, 0)
            outlayer = AG.createlayer(output, "hw2b", geom=GDAL.wkbPolygon)
            infeaturedefn = AG.borrow_getlayerdefn(inlayer)
            nameindex = AG.getfieldindex(infeaturedefn, "name")
            fielddefn = AG.borrow_getfielddefn(infeaturedefn, nameindex)
            AG.createfield!(outlayer, fielddefn)
            for infeature in inlayer
                AG.createfeature(outlayer) do outfeature
                    geom = AG.borrow_getgeom(infeature)
                    AG.setgeom!(outfeature, AG.transform!(geom, coordtrans))
                    AG.setfield!(outfeature,0,AG.getfield(infeature, nameindex))
        end end end
        end
        open("tmp/hw2b.prj", "w") do file
            write(file, AG.toWKT(AG.morphtoESRI!(outspatialref)))
        end
    end
    end
    end
end

facts("Homework 3(a)") do
    #reference: http://www.gis.usu.edu/~chrisg/python/2009/lectures/ospy_hw3a.py
    AG.read("ospy/data3/sites.shp") do sitesDS
        AG.read("ospy/data3/cache_towns.shp") do townsDS
            siteslayer = AG.borrow_getlayer(sitesDS, 0)
            townslayer = AG.borrow_getlayer(townsDS, 0)
            AG.setattributefilter!(townslayer, "NAME = 'Nibley'")
            AG.getfeature(townslayer, 0) do nibleyFeature
                AG.buffer(AG.borrow_getgeom(nibleyFeature), 1500) do bufferGeom
                    AG.setspatialfilter!(siteslayer, bufferGeom)
                    for sitefeature in siteslayer
                        id_index = AG.getfieldindex(sitefeature, "ID")
                        println(AG.getfield(sitefeature, id_index))
end end end end end end

facts("Homework 3(b)") do
    """
    function to copy fields (not the data) from one layer to another
    parameters:
      fromLayer: layer object that contains the fields to copy
      toLayer: layer object to copy the fields into
    """
    function copyfields(fromlayer, tolayer)
        featuredefn = AG.borrow_getlayerdefn(fromlayer)
        for i in 0:(AG.nfield(featuredefn)-1)
            fd = AG.borrow_getfielddefn(featuredefn, i)
            if AG.gettype(fd) == GDAL.OFTReal
                # to deal with errors like
                # ERROR: GDALError (Warning, code 1):
                # Value 18740682.1600000001 of field SHAPE_AREA of
                # feature 1 not successfully written. Possibly due
                # to too larger number with respect to field width
                fwidth = AG.getwidth(fd)
                if fwidth != 0
                    AG.setwidth!(fd, fwidth+1)
            end end
            AG.createfield!(tolayer, fd)
        end
    end

    """
    function to copy attributes from one feature to another
    (this assumes the features have the same attribute fields!)
    parameters:
      fromFeature: feature object that contains the data to copy
      toFeature: feature object that the data is to be copied into
    """
    function copyattributes(fromfeature, tofeature)
        for i in 0:(AG.nfield(fromfeature)-1)
            if AG.isfieldset(fromfeature, i)
                try
                    AG.setfield!(tofeature, i, AG.getfield(fromfeature, i))
                catch
                    println(fromfeature)
                    println(tofeature)
                    println("$i: $(AG.getfield(fromfeature, i))")
        end end end
    end

    function reproject(inFN, inEPSG, outFN, outEPSG)
        AG.fromEPSG(inEPSG) do inspatialref
        AG.fromEPSG(outEPSG) do outspatialref
        AG.createcoordtrans(inspatialref, outspatialref) do coordtrans
        AG.read(inFN) do inDS
        AG.create(outFN, "ESRI Shapefile") do outDS
            inlayer = AG.borrow_getlayer(inDS, 0)
            outlayer = AG.createlayer(outDS,
                            split(split(outFN, "/")[end], ".")[1],
                            geom = AG.getgeomtype(AG.borrow_getlayerdefn(inlayer)))
            copyfields(inlayer, outlayer)
            featuredefn = AG.borrow_getlayerdefn(outlayer)
            for infeature in inlayer
                geom = AG.borrow_getgeom(infeature)
                AG.createfeature(featuredefn) do outfeature
                    AG.setgeom!(outfeature, AG.transform!(geom, coordtrans))
                    copyattributes(infeature, outfeature)
                    AG.createfeature(outlayer, outfeature)
        end end end
        end
        end
        open(replace(outFN, ".shp", ".prj"), "w") do file
            write(file, AG.toWKT(AG.morphtoESRI!(outspatialref)))
        end
        end
        end
    end

    for inFN in readdir("./ospy/data3/")
        if endswith(inFN, ".shp")
            outFN = replace(inFN, ".shp", "_proj.shp")
            reproject("./ospy/data3/$(inFN)", 26912, "tmp/$(outFN)", 4269)
    end end
end

AG.read("ospy/data4/aster.img") do ds
    #reference: http://www.gis.usu.edu/~chrisg/python/2009/lectures/ospy_hw4a.py
    facts("Homework 4(a)") do
        AG.read("ospy/data4/sites.shp") do shp
            shplayer = AG.borrow_getlayer(shp, 0)
            id = AG.getfieldindex(AG.borrow_getlayerdefn(shplayer), "ID")

            transform = AG.getgeotransform(ds)
            xOrigin = transform[1]; yOrigin = transform[4]
            pixelWidth = transform[2]; pixelHeight = transform[6]

            for feature in shplayer
                geom = AG.borrow_getgeom(feature)
                x = AG.getx(geom, 0); y = AG.gety(geom, 0)
                # compute pixel offset
                xOffset = round(Int, (x - xOrigin) / pixelWidth)
                yOffset = round(Int, (y - yOrigin) / pixelHeight)
                # create a string to print out
                s = "$(AG.getfield(feature, id)) "
                for j in 1:AG.nraster(ds)
                    data = AG.fetch(ds, j, xOffset, yOffset, 1, 1)
                    s = "$s $(data[1,1]) "
                end
                println(s)
            end
        end
    end

    #reference: http://www.gis.usu.edu/~chrisg/python/2009/lectures/ospy_hw4b.py
    facts("Homework 4(b)") do
        # version 1
        @time begin
            count = 0
            total = 0
            data = AG.fetch(ds, 1)
            for (cols,rows) in AG.windows(AG.getband(ds, 1))
                window = data[cols, rows]
                count = count + sum(window .> 0)
                total = total + sum(window)
            end
            println("Ignoring 0:  $(total / count)")
            println("Including 0: $(total / (AG.height(ds) * AG.width(ds)))")
        end

        # version 2
        @time begin
            band = AG.getband(ds, 1)
            count = 0
            total = 0
            buffer = Array(AG.getdatatype(band), AG.getblocksize(band)...)
            for (cols,rows) in AG.windows(band)
                AG.rasterio!(band, buffer, rows, cols)
                data = buffer[1:length(cols),1:length(rows)]
                count += sum(data .> 0)
                total += sum(data)
            end
            println("Ignoring 0:  $(total / count)")
            println("Including 0: $(total / (AG.height(ds) * AG.width(ds)))")
        end

        # version 3
        @time begin
            count = 0
            total = 0
            # BufferIterator uses a single buffer, so this loop cannot be parallelized
            for data in AG.bufferwindows(AG.getband(ds, 1))
                count += sum(data .> 0)
                total += sum(data)
            end
            println("Ignoring 0:  $(total / count)")
            println("Including 0: $(total / (AG.height(ds) * AG.width(ds)))")
        end
    end

    #reference: http://www.gis.usu.edu/~chrisg/python/2009/lectures/ospy_hw5a.py
    facts("Homework 5(a)") do
        @time begin
            rows = AG.height(ds); cols = AG.width(ds); bands = AG.nraster(ds)

            # get the band and block sizes
            inband2 = AG.getband(ds, 2); inband3 = AG.getband(ds, 3)
            (xbsize, ybsize) = AG.getblocksize(inband2)

            buffer2 = Array(Float32, ybsize, xbsize)
            buffer3 = Array(Float32, ybsize, xbsize)
            ndvi    = Array(Float32, ybsize, xbsize)
            AG.create("tmp/ndvi.img", AG.getdriver(ds),
                      width=cols, height=rows, nbands=1, dtype=Float32) do outDS
                for ((i,j),(nrows,ncols)) in AG.blocks(inband2)
                    AG.rasterio!(inband2, buffer2, j, i, ncols, nrows)
                    AG.rasterio!(inband3, buffer3, j, i, ncols, nrows)
                    data2 = buffer2[1:nrows,1:ncols]
                    data3 = buffer3[1:nrows,1:ncols]
                    for row in 1:nrows, col in 1:ncols
                        denominator = data2[row, col] + data3[row, col]
                        if denominator > 0
                            numerator = data3[row, col] - data2[row, col]
                            ndvi[row, col] = numerator / denominator
                        else
                            ndvi[row, col] = -99
                        end
                    end
                    # write the data
                    AG.update!(outDS, ndvi, 1, j, i, ncols, nrows)
                end
                # flush data to disk, set the NoData value and calculate stats
                outband = AG.getband(outDS, 1)
                AG.flushcache!(outband); AG.setnodatavalue!(outband, -99)
                # georeference the image and set the projection
                AG.setgeotransform!(outDS, AG.getgeotransform(ds))
                AG.setproj(outDS, AG.getproj(ds))

                # build pyramids
                # gdal.SetConfigOption('HFA_USE_RRD', 'YES')
                AG.buildoverviews(outDS,
                                  Cint[2,4,8,16,32,64,128], # overview list
                                  # bandlist (omit to include all bands)
                                  resampling="NEAREST")     # resampling method
end end end end

#reference: http://www.gis.usu.edu/~chrisg/python/2009/lectures/ospy_hw5b.py
facts("Homework 5(b)") do
    AG.read("ospy/data5/doq1.img") do ds1
        AG.read("ospy/data5/doq2.img") do ds2
            # read in doq1 and get info about it
            band1 = AG.getband(ds1, 1)
            rows1 = AG.height(ds1); cols1 = AG.width(ds1)
            
            # get the corner coordinates for doq1
            transform1 = AG.getgeotransform(ds1)
            minX1 = transform1[1]; maxY1 = transform1[4]
            pixelWidth1 = transform1[2]; pixelHeight1 = transform1[6]
            maxX1 = minX1 + (cols1 * pixelWidth1)
            minY1 = maxY1 + (rows1 * pixelHeight1)

            # read in doq2 and get info about it
            band2 = AG.getband(ds2, 1)
            rows2 = AG.height(ds2); cols2 = AG.width(ds2)
            
            # get the corner coordinates for doq1
            transform2 = AG.getgeotransform(ds2)
            minX2 = transform1[1]; maxY2 = transform1[4]
            pixelWidth2 = transform1[2]; pixelHeight2 = transform1[6]
            maxX2 = minX2 + (cols2 * pixelWidth2)
            minY2 = maxY2 + (rows2 * pixelHeight2)

            # get the corner coordinates for the output
            minX = min(minX1, minX2); maxX = max(maxX1, maxX2)
            minY = min(minY1, minY2); maxY = max(maxY1, maxY2)

            # get the number of rows and columns for the output
            cols = round(Int, (maxX - minX) / pixelWidth1)
            rows = round(Int, (maxY - minY) / abs(pixelHeight1))

            # compute the origin (upper left) offset for doq1
            xOffset1 = round(Int, (minX1 - minX) / pixelWidth1)
            yOffset1 = round(Int, (maxY1 - maxY) / pixelHeight1)

            # compute the origin (upper left) offset for doq2
            xOffset2 = round(Int, (minX2 - minX) / pixelWidth1)
            yOffset2 = round(Int, (maxY2 - maxY) / pixelHeight1)

            dtype = AG.getdatatype(band1)
            data1 = Array(dtype, rows, cols)
            data2 = Array(dtype, rows, cols)
            # create the output image
            AG.create("tmp/mosiac.img", AG.getdriver(ds1),
                      width=cols, height=rows, nbands=1,
                      dtype=AG.getdatatype(band1)) do dsout
                # read in doq1 and write it to the output
                AG.rasterio!(band1, data1, 0, 0, cols1, rows1)
                AG.update!(dsout, data1, 1, xOffset1, yOffset1, cols, rows)

                # read in doq2 and write it to the output
                AG.rasterio!(band2, data2, 0, 0, cols2, rows2)
                AG.update!(dsout, data2, 1, xOffset2, yOffset2, cols, rows)

                # compute statistics for the output
                bandout = AG.getband(dsout, 1)
                AG.flushcache!(bandout)
                # stats = bandOut.GetStatistics(0, 1)

                # set the geotransform and projection on the output
                geotransform = [minX, pixelWidth1, 0, maxY, 0, pixelHeight1]
                AG.setgeotransform!(dsout, geotransform)
                AG.setproj(dsout, AG.getproj(ds1))

                # build pyramids for the output
                # gdal.SetConfigOption('HFA_USE_RRD', 'YES')
                AG.buildoverviews(dsout,
                                  Cint[2,4,8,16],       # overview list
                                  # bandlist (omit to include all bands)
                                  resampling="NEAREST") # resampling method
end end end end

end # of AG.registerdrivers()