using Test
using Statistics
import GDAL
import ArchGDAL; const AG = ArchGDAL

"""
function to copy fields (not the data) from one layer to another
parameters:
  fromLayer: layer object that contains the fields to copy
  toLayer: layer object to copy the fields into
"""
function copyfields(fromlayer, tolayer)
    featuredefn = AG.layerdefn(fromlayer)
    for i in 0:(AG.nfield(featuredefn)-1)
        fd = AG.getfielddefn(featuredefn, i)
        if AG.gettype(fd) == OFTReal
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

# function reproject(inFN, inEPSG, outEPSG)
#     AG.fromEPSG(inEPSG) do inspatialref
#     AG.fromEPSG(outEPSG) do outspatialref
#     AG.createcoordtrans(inspatialref, outspatialref) do coordtrans
#     AG.read(inFN) do inDS
#     AG.create("", "MEMORY") do outDS
#         inlayer = AG.getlayer(inDS, 0)
#         outlayer = AG.createlayer(
#                         name = "outlayer",
#                         dataset = outDS,
#                         geom = AG.getgeomtype(AG.layerdefn(inlayer)))
#         copyfields(inlayer, outlayer)
#         featuredefn = AG.layerdefn(outlayer)
#         for infeature in inlayer
#             geom = AG.getgeom(infeature)
#             AG.createfeature(featuredefn) do outfeature
#                 AG.setgeom!(outfeature, AG.transform!(geom, coordtrans))
#                 copyattributes(infeature, outfeature)
#                 AG.createfeature(outlayer, outfeature)
#         end end
#         println(outlayer)
#     end
#     end
#     end
#     println(AG.toWKT(AG.morphtoESRI!(outspatialref)))
#     end
#     end
# end

@testset "Homework 1" begin
AG.read("ospy/data1/sites.shp") do input
    #reference: http://www.gis.usu.edu/~chrisg/python/2009/lectures/ospy_hw1a.py
    for (i,feature) in enumerate(AG.getlayer(input, 0))
        id = AG.getfield(feature, 0); cover = AG.getfield(feature, 1)
        (x,y) = AG.getpoint(AG.getgeom(feature, 0), 0)
        @test id == i
        @test 4e5 <= x <= 5e5
        @test 4.5e6 <= y <= 5e6
        @test cover in ("shrubs", "trees", "rocks", "grass", "bare", "water")
    end

    #reference: http://www.gis.usu.edu/~chrisg/python/2009/lectures/ospy_hw1b.py
    # version 1
    AG.create(AG.getdriver("MEMORY")) do output
        inlayer = AG.getlayer(input, 0)
        outlayer = AG.createlayer(
            name = "hw1b",
            dataset = output,
            geom = GDAL.wkbPoint
        )
        inlayerdefn = AG.layerdefn(inlayer)
        AG.addfielddefn!(outlayer, AG.getfielddefn(inlayerdefn, 0))
        AG.addfielddefn!(outlayer, AG.getfielddefn(inlayerdefn, 1))
        for infeature in inlayer
            id = AG.getfield(infeature, 0)
            @test AG.asint64(infeature, 0) == id
            cover = AG.getfield(infeature, 1)
            if cover == "trees"
                AG.createfeature(outlayer) do outfeature
                    AG.setgeom!(outfeature, AG.getgeom(infeature))
                    AG.setfield!(outfeature, 0, id)
                    AG.setfield!(outfeature, 1, cover)
        end end end
        @test sprint(print, output) == """
        GDAL Dataset (Driver: Memory/Memory)
        File(s): 

        Number of feature layers: 1
          Layer 0: hw1b (wkbPoint)
        """
    end

    # version 2
    AG.create(AG.getdriver("MEMORY")) do output
        AG.executesql(input, """SELECT * FROM sites
                                WHERE cover = 'trees' """) do results
            @test sprint(print, results) == """
            Layer: sites
              Geometry 0 (_ogr_geometry_): [wkbPoint], POINT (449959.840851...), ...
                 Field 0 (ID): [OFTInteger], 2, 6, 9, 14, 19, 20, 22, 26, 34, 36, 41
                 Field 1 (COVER): [OFTString], trees, trees, trees, trees, trees, trees, ...
            """
            AG.copy(results, name = "hw1b", dataset = output)
        end
        @test sprint(print, output) == """
        GDAL Dataset (Driver: Memory/Memory)
        File(s): 

        Number of feature layers: 1
          Layer 0: hw1b (wkbPoint)
        """
    end
end
end
    
@testset "Homework 2" begin
    # http://www.gis.usu.edu/~chrisg/python/2009/lectures/ospy_hw2a.py
    open("ospy/data2/ut_counties.txt", "r") do file
    AG.create(AG.getdriver("MEMORY")) do output
        layer = AG.createlayer(
            name = "hw2a",
            dataset = output,
            geom = GDAL.wkbPolygon
        )
        @test sprint(print, layer) == """
        Layer: hw2a
          Geometry 0 (): [wkbPolygon]
        """
        AG.createfielddefn("name", GDAL.OFTString) do fielddefn
            AG.setwidth!(fielddefn, 30)
            AG.addfielddefn!(layer, fielddefn)
        end
        @test sprint(print, layer) == """
        Layer: hw2a
          Geometry 0 (): [wkbPolygon]
             Field 0 (name): [OFTString]
        """
        for line in readlines(file)
            (name, coords) = split(line, ":")
            coordlist = split(coords, ",")
            AG.createfeature(layer) do feature
                AG.setfield!(feature, 0, name)
                AG.createpolygon() do poly
                    ring = AG.createlinearring()
                    for xy in map(split, coordlist)
                        AG.addpoint!(ring, parse(Float64, xy[1]),
                                           parse(Float64, xy[2]))
                    end
                    AG.addgeom!(poly, ring)
                    AG.setgeom!(feature, poly)    
        end end end
        @test sprint(print, layer) == """
        Layer: hw2a
          Geometry 0 (): [wkbPolygon], POLYGON ((-111.50278...), ...
             Field 0 (name): [OFTString], Cache, Box Elder, Rich, Weber, Morgan, ...
        """

        # input = output
        # # http://www.gis.usu.edu/~chrisg/python/2009/lectures/ospy_hw2b.py
        # AG.fromEPSG(4269) do inspatialref
        # AG.fromEPSG(26912) do outspatialref
        # AG.createcoordtrans(inspatialref, outspatialref) do coordtrans
        # AG.create("", "MEMORY") do output
        #     inlayer = AG.getlayer(input, 0)
        #     outlayer = AG.createlayer(
        #         name = "hw2b",
        #         dataset = output,
        #         geom = GDAL.wkbPolygon
        #     )
        #     infeaturedefn = AG.layerdefn(inlayer)
        #     nameindex = AG.findfieldindex(infeaturedefn, "name")
        #     fielddefn = AG.getfielddefn(infeaturedefn, nameindex)
        #     AG.createfield!(outlayer, fielddefn)
        #     for infeature in inlayer
        #         AG.createfeature(outlayer) do outfeature
        #             geom = AG.getgeom(infeature)
        #             AG.setgeom!(outfeature, AG.transform!(geom, coordtrans))
        #             AG.setfield!(outfeature,0,AG.getfield(infeature, nameindex))
        #             println(outfeature)
        #     end end
        #     println(layer)
        # end
        # end
        # println(AG.toWKT(AG.morphtoESRI!(outspatialref)))
        # end
        # end
    end
    end
end

@testset "Homework 3" begin
    #reference: http://www.gis.usu.edu/~chrisg/python/2009/lectures/ospy_hw3a.py
    AG.read("ospy/data1/sites.shp") do sitesDS
        AG.read("ospy/data3/cache_towns.shp") do townsDS
            siteslayer = AG.getlayer(sitesDS, 0)
            townslayer = AG.getlayer(townsDS, 0)
            AG.setattributefilter!(townslayer, "NAME = 'Nibley'")
            AG.getfeature(townslayer, 0) do nibleyFeature
                AG.buffer(AG.getgeom(nibleyFeature), 1500) do bufferGeom
                    AG.setspatialfilter!(siteslayer, bufferGeom)
                    @test [AG.getfield(f, "ID") for f in siteslayer] == [26]
    end end end end
    
    #reference: http://www.gis.usu.edu/~chrisg/python/2009/lectures/ospy_hw3b.py
    # commented out until https://github.com/visr/GDAL.jl/issues/30 is resolved
    # for inFN in readdir("./ospy/data3/")
    #     if endswith(inFN, ".shp")
    #         reproject("./ospy/data3/$(inFN)", 26912, 4269)
    # end end
end

AG.read("ospy/data4/aster.img") do ds
    #reference: http://www.gis.usu.edu/~chrisg/python/2009/lectures/ospy_hw4a.py
    @testset "Homework 4a" begin
        AG.read("ospy/data1/sites.shp") do shp
            shplayer = AG.getlayer(shp, 0)
            id = AG.findfieldindex(AG.layerdefn(shplayer), "ID")

            transform = AG.getgeotransform(ds)
            xOrigin = transform[1]; yOrigin = transform[4]
            pixelWidth = transform[2]; pixelHeight = transform[6]

            results = fill(0, 42, 3)
            for (i,feature) in enumerate(shplayer)
                geom = AG.getgeom(feature)
                x = AG.getx(geom, 0); y = AG.gety(geom, 0)
                # compute pixel offset
                xOffset = round(Int, (x - xOrigin) / pixelWidth)
                yOffset = round(Int, (y - yOrigin) / pixelHeight)
                # create a string to print out
                @test AG.getfield(feature, id) == i
                for j in 1:AG.nraster(ds)
                    data = AG.read(ds, j, xOffset, yOffset, 1, 1)
                    results[i,j] = data[1,1]
                end
            end
            @test maximum(results) == 100
            @test minimum(results) == 0
            @test mean(results) ≈ 64.98412698412699
            @test std(results) ≈ 22.327734905980627
        end
    end

    #reference: http://www.gis.usu.edu/~chrisg/python/2009/lectures/ospy_hw4b.py
    @testset "Homework 4b" begin
        @testset "version 1" begin
            count = 0
            total = 0
            data = AG.read(ds, 1)
            for (cols,rows) in AG.windows(AG.getband(ds, 1))
                window = data[cols, rows]
                count = count + sum(window .> 0)
                total = total + sum(window)
            end
            @test total / count ≈ 76.33891347095299
            @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
        end

        @testset "version 2" begin
            band = AG.getband(ds, 1)
            count = 0
            total = 0
            buffer = Array{AG.pixeltype(band)}(undef, AG.blocksize(band)...)
            for (cols,rows) in AG.windows(band)
                AG.rasterio!(band, buffer, rows, cols)
                data = buffer[1:length(cols),1:length(rows)]
                count += sum(data .> 0)
                total += sum(data)
            end
            @test total / count ≈ 76.33891347095299
            @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
        end

        @testset "version 3" begin
            count = 0
            total = 0
            # BufferIterator uses a single buffer, so this loop cannot be parallelized
            for data in AG.bufferwindows(AG.getband(ds, 1))
                count += sum(data .> 0)
                total += sum(data)
            end
            @test total / count ≈ 76.33891347095299
            @test total / (AG.height(ds) * AG.width(ds)) ≈ 47.55674749653172
        end
    end

    #reference: http://www.gis.usu.edu/~chrisg/python/2009/lectures/ospy_hw5a.py
    @testset "Homework 5a" begin
        @time begin
            rows = AG.height(ds); cols = AG.width(ds); bands = AG.nraster(ds)

            # get the band and block sizes
            inband2 = AG.getband(ds, 2); inband3 = AG.getband(ds, 3)
            (xbsize, ybsize) = AG.blocksize(inband2)

            buffer2 = Array{Float32}(undef, ybsize, xbsize)
            buffer3 = Array{Float32}(undef, ybsize, xbsize)
            ndvi    = Array{Float32}(undef, ybsize, xbsize)
            AG.create(
                    AG.getdriver("MEM"),
                    width   = cols,
                    height  = rows,
                    nbands  = 1,
                    dtype   = Float32
                ) do outDS
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
                    AG.write!(outDS, ndvi, 1, j, i, ncols, nrows)
                end
                @test sprint(print, outDS) == """
                GDAL Dataset (Driver: MEM/In Memory Raster)
                File(s): 

                Dataset (width x height): 5665 x 5033 (pixels)
                Number of raster bands: 1
                  [GA_Update] Band 1 (Undefined): 5665 x 5033 (Float32)
                """
                # flush data to disk, set the NoData value and calculate stats
                outband = AG.getband(outDS, 1)
                @test sprint(print, outband) == """
                [GA_Update] Band 1 (Undefined): 5665 x 5033 (Float32)
                    blocksize: 5665×1, nodata: 0.0, units: 1.0px + 0.0
                    overviews: """
                AG.setnodatavalue!(outband, -99)
                # georeference the image and set the projection
                AG.setgeotransform!(outDS, AG.getgeotransform(ds))
                AG.setproj!(outDS, AG.getproj(ds))

                # build pyramids
                # gdal.SetConfigOption('HFA_USE_RRD', 'YES')
                # AG.buildoverviews!(outDS,
                #                   Cint[2,4,8,16,32,64,128], # overview list
                #                   # bandlist (omit to include all bands)
                #                   resampling="NEAREST")     # resampling method
end end end end

#reference: http://www.gis.usu.edu/~chrisg/python/2009/lectures/ospy_hw5b.py
@testset "Homework 5b" begin
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

            dtype = AG.pixeltype(band1)
            data1 = Array{dtype}(undef, rows, cols)
            data2 = Array{dtype}(undef, rows, cols)
            # create the output image
            AG.create(
                    AG.getdriver("MEM"),
                    width   = cols,
                    height  = rows,
                    nbands  = 1,
                    dtype   = AG.pixeltype(band1)
                ) do dsout
                # read in doq1 and write it to the output
                AG.rasterio!(band1, data1, 0, 0, cols1, rows1)
                AG.write!(dsout, data1, 1, xOffset1, yOffset1, cols, rows)

                # read in doq2 and write it to the output
                AG.rasterio!(band2, data2, 0, 0, cols2, rows2)
                AG.write!(dsout, data2, 1, xOffset2, yOffset2, cols, rows)

                @test sprint(print, dsout) == """
                GDAL Dataset (Driver: MEM/In Memory Raster)
                File(s): 

                Dataset (width x height): 4500 x 3000 (pixels)
                Number of raster bands: 1
                  [GA_Update] Band 1 (Undefined): 4500 x 3000 (UInt8)
                """
                # compute statistics for the output
                bandout = AG.getband(dsout, 1)
                @test sprint(print, bandout) == """
                [GA_Update] Band 1 (Undefined): 4500 x 3000 (UInt8)
                    blocksize: 4500×1, nodata: 0.0, units: 1.0px + 0.0
                    overviews: """

                # set the geotransform and projection on the output
                geotransform = [minX, pixelWidth1, 0, maxY, 0, pixelHeight1]
                AG.setgeotransform!(dsout, geotransform)
                AG.setproj!(dsout, AG.getproj(ds1))

                # build pyramids for the output
                # gdal.SetConfigOption('HFA_USE_RRD', 'YES')
                # buildoverviews not supported for in-memory rasters
                # AG.buildoverviews!(dsout,
                #                    Cint[2,4,8,16],       # overview list
                #                   # bandlist (omit to include all bands)
                #                    resampling="NEAREST") # resampling method
end end end end
