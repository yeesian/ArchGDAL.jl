using Test
import ArchGDAL;
const AG = ArchGDAL;
using Tables

@testset "test_tables.jl" begin
    @testset "Tables Support" begin
        dataset = AG.read(joinpath(@__DIR__, "data/point.geojson"))
        dataset1 = AG.read(
            joinpath(@__DIR__, "data/multi_geom.csv"),
            options = [
                "GEOM_POSSIBLE_NAMES=point,linestring",
                "KEEP_GEOM_COLUMNS=NO",
            ],
        )
        dataset2 = AG.read(
            joinpath(@__DIR__, "data/missing_testcase.csv"),
            options = [
                "GEOM_POSSIBLE_NAMES=point,linestring",
                "KEEP_GEOM_COLUMNS=NO",
            ],
        )
        @test dataset isa ArchGDAL.IDataset
        @test dataset1 isa ArchGDAL.IDataset
        @test dataset2 isa ArchGDAL.IDataset
        layer = AG.getlayer(dataset, 0)
        layer1 = AG.getlayer(dataset1, 0)
        layer2 = AG.getlayer(dataset2, 0)

        @testset "Tables methods" begin
            @test isnothing(Tables.schema(layer1))
            @test Tables.istable(typeof(layer)) == true
            @test Tables.rowaccess(typeof(layer)) == true

            features = collect(Tables.rows(layer1))
            @test length(features) == 2

            @test Tables.columnnames(features[1]) ==
                  (:point, :linestring, :id, :zoom, :location)
            @test ismissing(Tables.getcolumn(features[2], -5))
            @test ismissing(Tables.getcolumn(features[2], 0))
            @test Tables.getcolumn(features[1], 1) == "5.1"
            @test Tables.getcolumn(features[1], 2) == "1.0"
            @test Tables.getcolumn(features[1], 3) == "Mumbai"
            @test AG.toWKT(Tables.getcolumn(features[1], 4)) == "POINT (30 10)"
            @test AG.toWKT(Tables.getcolumn(features[1], 5)) ==
                  "LINESTRING (30 10,10 30,40 40)"
            @test Tables.getcolumn(features[1], :id) == "5.1"
            @test Tables.getcolumn(features[1], :zoom) == "1.0"
            @test Tables.getcolumn(features[1], :location) == "Mumbai"
            @test AG.toWKT(Tables.getcolumn(features[1], :point)) ==
                  "POINT (30 10)"
            @test AG.toWKT(Tables.getcolumn(features[1], :linestring)) ==
                  "LINESTRING (30 10,10 30,40 40)"
            @test ismissing(Tables.getcolumn(features[1], :fake))

            @test Tables.columnnames(features[2]) ==
                  (:point, :linestring, :id, :zoom, :location)
            @test ismissing(Tables.getcolumn(features[2], -5))
            @test ismissing(Tables.getcolumn(features[2], 0))
            @test Tables.getcolumn(features[2], 1) == "5.2"
            @test Tables.getcolumn(features[2], 2) == "2.0"
            @test Tables.getcolumn(features[2], 3) == "New Delhi"
            @test AG.toWKT(Tables.getcolumn(features[2], 4)) == "POINT (35 15)"
            @test AG.toWKT(Tables.getcolumn(features[2], 5)) ==
                  "LINESTRING (35 15,15 35,45 45)"
            @test Tables.getcolumn(features[2], :id) == "5.2"
            @test Tables.getcolumn(features[2], :zoom) == "2.0"
            @test Tables.getcolumn(features[2], :location) == "New Delhi"
            @test AG.toWKT(Tables.getcolumn(features[2], :point)) ==
                  "POINT (35 15)"
            @test AG.toWKT(Tables.getcolumn(features[2], :linestring)) ==
                  "LINESTRING (35 15,15 35,45 45)"
            @test ismissing(Tables.getcolumn(features[2], :fake))

            geom_names, field_names = AG.schema_names(AG.layerdefn(layer))
            @test collect(geom_names) == [Symbol("")]
            @test collect(field_names) == [:FID, :pointname]
            geom_names, field_names = AG.schema_names(AG.layerdefn(layer1))
            @test collect(geom_names) == [:point, :linestring]
            @test collect(field_names) == [:id, :zoom, :location]
        end

        @testset "Conversion to table for drivers: GeoJSON, ESRI Shapefile" begin
            """
                get_test_dataset(
                    drvshortname::AbstractString="ESRI shapefile", 
                    geomfamily::String="line"; 
                    withmissinggeom::Bool=true,
                    withmissingfield::Bool=true,
                    withmixedgeomtypes::Bool=true, 
                )::AG.IDataset

            # Build a test dataset from scratch
            with:
            - OGR driver: `drvshortname` ∈ `["ESRI Shapefile", "GeoJSON"]`
            - `"GeoJSON"` driver → 1 layer with 2 geometry columns
            - `"ESRI Shapefile"` driver → 2 layers with 1 geometry column
            1) with `wkbLineString` and `wkbMultiLineString` types
            2) with `wkbPolygon`, `wkbMultiPolygon` types  
            - Layers' geometry type set to `wkbUnknown` but modified by the OGR driver according to its specifications,
            - Each geometry has two additionnal fields `id::Int64` and `name::String`

            # Options
            - `withmissinggeom::Bool=true`: a missing geometry value per geom field
            - `withmissingfield::Bool=true`: a missing field value in `id` field
            - `withmixedgeomtypes::Bool=true`: a multi geometry value per geom field

            # Returns
            The corresponding dataset
            """
            function get_test_dataset(
                drvshortname::AbstractString="ESRI shapefile", 
                geomfamily::String="line"; 
                withmissinggeom::Bool=true,
                withmissingfield::Bool=true,
                withmixedgeomtypes::Bool=true, 
            )::AG.IDataset

                # Build dataset filename
                ds_file_extension = Dict(
                    "ESRI Shapefile" => "",
                    "GeoJSON" => ".geojson",
                    "CSV" => ".csv",
                    "GML" => ".gml",
                    "KML" => ".kml",
                    "GPKG" => ".gpkg",
                    "FlatGeobuf" => ".fgb",
                )
                filename_root = "test_dataset"
                filename = joinpath(@__DIR__, "tmp", filename_root * ds_file_extension[drvshortname])

                # Clean previously created files for new dataset
                for (drvshortname, file_extension) in ds_file_extension
                    isfile(joinpath(@__DIR__, "tmp", filename_root * file_extension)) && rm(joinpath(@__DIR__, "tmp", filename_root * file_extension))
                    isfile(joinpath(@__DIR__, "tmp", filename_root * ".xsd")) && rm(joinpath(@__DIR__, "tmp", filename_root * ".xsd"))
                    isfile(joinpath(@__DIR__, "tmp", filename_root * ".tmp")) && rm(joinpath(@__DIR__, "tmp", filename_root * ".tmp"))
                    isdir(joinpath(@__DIR__, "tmp", filename_root)) && rm(joinpath(@__DIR__, "tmp", filename_root), recursive=true)
                end

                # Prepare data for dataset building
                data = Dict(
                    "line" => (
                        simple1=(name="line1", geom=AG.createlinestring([(i,i+1) for i in 1.0:3.0])),
                        multi1=(name="multiline1", geom=AG.createmultilinestring([[(i,i+1) for i in j:j+3] for j in 1.0:5.0:6.0])),
                        simple2=(name="line2", geom=AG.createlinestring([(i,i+1) for i in 3.0:5.0])),
                        emptygeom=(name="emptygeom", geom=nothing),
                        emptyfield=(name="emptyid", geom=AG.createlinestring([(i,i+1) for i in 5.0:7.0]))
                        ),
                    "polygon" => (
                        simple1=(name="polygon1", geom=AG.createpolygon([(0.,0.), (0.,1.), (1.,1.)])),
                        multi1=(name="multipolygon1", geom=AG.createmultipolygon([[[(0.,0.), (0.,j), (j,j)]] for j in 1.0:-0.1:0.9])),
                        simple2=(name="polygon2", geom=AG.createpolygon([(0.,0.), (0.,-1.), (-1.,-1.)])),
                        emptygeom=(name="emptygeom", geom=nothing),
                        emptyfield=(name="emptyid", geom=AG.createpolygon([(0.,0.), (-1.,0.), (-1.,1.)]))
                    )
                )

                # Create dataset
                AG.create(
                    filename; 
                    driver=AG.getdriver(drvshortname), 
                ) do newdataset
                    AG.createlayer(
                        name="test_layer", 
                        dataset=newdataset, 
                        geom=AG.wkbUnknown
                    ) do newlayer
                        # Add geom and field defn
                        AG.addfielddefn!(newlayer, "id", AG.OFTInteger64)
                        AG.addfielddefn!(newlayer, "name", AG.OFTString)
                        id_idx = AG.findfieldindex(AG.layerdefn(newlayer), "id")
                        name_idx = AG.findfieldindex(AG.layerdefn(newlayer), "name")
                        # Add features
                        AG.addfeature(newlayer) do newfeature
                        AG.setfield!(newfeature, id_idx, 1)
                        AG.setfield!(newfeature, name_idx, data[geomfamily].simple1.name)
                        AG.setgeom!(newfeature, 0, data[geomfamily].simple1.geom)
                        end
                        if withmixedgeomtypes
                            AG.addfeature(newlayer) do newfeature
                                AG.setfield!(newfeature, id_idx, 2)
                                AG.setfield!(newfeature, name_idx, data[geomfamily].multi1.name)
                                AG.setgeom!(newfeature, 0, data[geomfamily].multi1.geom)
                            end
                        else
                            AG.addfeature(newlayer) do newfeature
                                AG.setfield!(newfeature, id_idx, 2)
                                AG.setfield!(newfeature, name_idx, data[geomfamily].simple2.name)
                                AG.setgeom!(newfeature, 0, data[geomfamily].simple2.geom)
                            end
                        end
                        if withmissinggeom
                            AG.addfeature(newlayer) do newfeature
                                AG.setfield!(newfeature, id_idx, 3)
                                AG.setfield!(newfeature, name_idx, data[geomfamily].emptygeom.name)
                                # No geom set
                            end
                        end
                        if withmissingfield
                            AG.addfeature(newlayer) do newfeature
                                # No Id field set
                                AG.setfield!(newfeature, name_idx, data[geomfamily].emptyfield.name)
                                AG.setgeom!(newfeature, 0, data[geomfamily].emptyfield.geom)
                            end
                        end
                    end
                end

                if drvshortname == "GML"
                    return AG.read(filename, 
                        options=[
                        "EXPOSE_GML_ID=NO"
                        "EXPOSE_FID=NO"
                        ])
                else
                    return AG.read(filename)
                end
            end

            """
                clean_test_files()

            Cleans test files generated by `get_test_dataset`
            """
            function clean_test_dataset_files()
                ds_file_extension = Dict(
                    "ESRI Shapefile" => "",
                    "GeoJSON" => ".geojson",
                    "CSV" => ".csv",
                    "GML" => ".gml",
                    "KML" => ".kml",
                    "GPKG" => ".gpkg",
                    "FlatGeobuf" => ".fgb",
                )
                filename_root = "test_dataset"

                # Clean previously created files for new dataset
                for (drvshortname, file_extension) in ds_file_extension
                    isfile(joinpath(@__DIR__, "tmp", filename_root * file_extension)) && rm(joinpath(@__DIR__, "tmp", filename_root * file_extension))
                    isfile(joinpath(@__DIR__, "tmp", filename_root * ".xsd")) && rm(joinpath(@__DIR__, "tmp", filename_root * ".xsd"))
                    isfile(joinpath(@__DIR__, "tmp", filename_root * ".tmp")) && rm(joinpath(@__DIR__, "tmp", filename_root * ".tmp"))
                    isdir(joinpath(@__DIR__, "tmp", filename_root)) && rm(joinpath(@__DIR__, "tmp", filename_root), recursive=true)
                end
            end

            toWKT_withmissings = (x -> ismissing(x) ? missing : AG.toWKT(x))
            columntablevalues_toWKT = (x -> (toWKT_withmissings.(x[1]), x[2], x[3]))
            tupleoftuples_equal = ((x, y) -> length(x) ==length(y) && all([all(x[i] .=== y[i]) for i in 1:length(x)]))
            
            """
                test_layer_to_table(
                    drvshortname::String, 
                    geomfamilly::String,
                    withmissinggeom::Bool,
                    withmissingfield::Bool,
                    withmixedgeomtypes::Bool,
                    reference_geotable::Tuple;
                    testing::Bool=true)

            Creates a dataset from scratch with `get_test_dataset` and converts it to a columntable

            If `testing = false`: returns a `NamedTuple` with:
            - names: layer geom and field names
            - types: expected types given by `Tables.buildcolumns`
            - values: expected Tables.columntable result values with geometries converted to WKT

            If `testing = true`: test Tables.columntable(::AG.IFeatureLayer) result against `reference_geotable`

            """
            function test_layer_to_table(
                drvshortname::String, 
                geomfamilly::String,
                withmissinggeom::Bool,
                withmissingfield::Bool,
                withmixedgeomtypes::Bool,
                reference_geotable::NamedTuple;
                testing::Bool=true
            )
                ds = get_test_dataset(
                    drvshortname,
                    geomfamilly; 
                    withmissinggeom=withmissinggeom,
                    withmissingfield=withmissingfield,
                    withmixedgeomtypes=withmixedgeomtypes,
                )
                layer = AG.getlayer(ds, 0)
                if !testing
                    return (
                        names = keys(Tables.columntable(layer)),
                        types = eltype.(values(Tables.columntable(layer))),
                        values = columntablevalues_toWKT(values(Tables.columntable(layer)))
                    )
                else
                    all([
                        keys(Tables.columntable(layer)) == reference_geotable.names,
                        eltype.(values(Tables.columntable(layer))) == reference_geotable.types,
                        tupleoftuples_equal(
                            columntablevalues_toWKT(values(Tables.columntable(layer))),
                            reference_geotable.values
                        )
                    ])
                end
            end

            @testset "Conversion to table for ESRI Shapefile driver" begin
                ESRI_Shapefile_polygon_reference_geotable = (
                    names = (Symbol(""), :id, :name),
                    types = (Union{Missing, ArchGDAL.IGeometry}, Int64, String),
                    values = (
                        Union{Missing, String}[
                            "POLYGON ((0 0,0 1,1 1))", 
                            "MULTIPOLYGON (((0 0,0 1,1 1)),((0.9 0.9,0.0 0.9,0 0)))", 
                            missing, 
                            "POLYGON ((0 0,-1 0,-1 1))"
                        ], 
                        [1, 2, 3, 0], 
                        ["polygon1", "multipolygon1", "emptygeom", "emptyid"]
                    )
                )
                @test test_layer_to_table("ESRI Shapefile", "polygon", true, true, true, ESRI_Shapefile_polygon_reference_geotable)

                ESRI_Shapefile_polygon_reference_geotable = (
                    names = (Symbol(""), :id, :name), 
                    types = (Union{Missing, ArchGDAL.IGeometry{ArchGDAL.wkbLineString}}, Int64, String), 
                    values = (
                        Union{Missing, String}[
                            "LINESTRING (1 2,2 3,3 4)", 
                            "LINESTRING (3 4,4 5,5 6)", 
                            missing, 
                            "LINESTRING (5 6,6 7,7 8)"
                        ], 
                        [1, 2, 3, 0], 
                        ["line1", "line2", "emptygeom", "emptyid"]
                    )
                )
                @test test_layer_to_table("ESRI Shapefile", "line", true, true, false, ESRI_Shapefile_polygon_reference_geotable)
            end


            @testset "Conversion to table for GeoJSON driver" begin
                GeoJSON_polygon_reference_geotable = (
                    names = (Symbol(""), :id, :name),
                    types = (Union{Missing, ArchGDAL.IGeometry}, Union{Missing, Int32}, String),
                    values = (
                        Union{Missing, String}[
                            "POLYGON ((0 0,0 1,1 1))",
                            "MULTIPOLYGON (((0 0,0 1,1 1)),((0 0,0.0 0.9,0.9 0.9)))", 
                            missing, 
                            "POLYGON ((0 0,-1 0,-1 1))"
                        ], 
                        Union{Missing, Int32}[1, 2, 3, missing], 
                        ["polygon1", "multipolygon1", "emptygeom", "emptyid"]
                    )
                )
                @test test_layer_to_table("GeoJSON", "polygon", true, true, true, GeoJSON_polygon_reference_geotable)

                GeoJSON_polygon_reference_geotable = (
                    names = (Symbol(""), :id, :name),
                    types = (Union{Missing, ArchGDAL.IGeometry{ArchGDAL.wkbLineString}}, Union{Missing, Int32}, String),
                    values = (
                        Union{Missing, String}[
                            "LINESTRING (1 2,2 3,3 4)", 
                            "LINESTRING (3 4,4 5,5 6)", 
                            missing, 
                            "LINESTRING (5 6,6 7,7 8)"
                        ], 
                        Union{Missing, Int32}[1, 2, 3, missing], 
                        ["line1", "line2", "emptygeom", "emptyid"]
                    )
                )
                @test test_layer_to_table("GeoJSON", "line", true, true, false, GeoJSON_polygon_reference_geotable)
            end

            clean_test_dataset_files()
        end
    end
end
