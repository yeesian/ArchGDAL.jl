using Test
import ArchGDAL as AG
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
        @test dataset isa AG.IDataset
        @test dataset1 isa AG.IDataset
        @test dataset2 isa AG.IDataset
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
            TEST_DS_DRIVERS_FILE_EXTENSIONS = Dict(
                "ESRI Shapefile" => "",
                "GeoJSON" => ".geojson",
                "CSV" => ".csv",
                "GML" => ".gml",
                "KML" => ".kml",
                "GPKG" => ".gpkg",
                "FlatGeobuf" => ".fgb",
            )

            TEST_DS_FILENAME_STEM = "test_ds"

            """
                clean_test_files()

            Cleans test files generated by `get_test_dataset`
            """
            function clean_test_dataset_files()
                for (drvshortname, file_extension) in
                    TEST_DS_DRIVERS_FILE_EXTENSIONS
                    isfile(
                        joinpath(
                            @__DIR__,
                            "tmp",
                            TEST_DS_FILENAME_STEM * file_extension,
                        ),
                    ) && rm(
                        joinpath(
                            @__DIR__,
                            "tmp",
                            TEST_DS_FILENAME_STEM * file_extension,
                        ),
                    )
                    isfile(
                        joinpath(
                            @__DIR__,
                            "tmp",
                            TEST_DS_FILENAME_STEM * ".xsd",
                        ),
                    ) && rm(
                        joinpath(
                            @__DIR__,
                            "tmp",
                            TEST_DS_FILENAME_STEM * ".xsd",
                        ),
                    )
                    isfile(
                        joinpath(
                            @__DIR__,
                            "tmp",
                            TEST_DS_FILENAME_STEM * ".tmp",
                        ),
                    ) && rm(
                        joinpath(
                            @__DIR__,
                            "tmp",
                            TEST_DS_FILENAME_STEM * ".tmp",
                        ),
                    )
                    isdir(joinpath(@__DIR__, "tmp", TEST_DS_FILENAME_STEM)) &&
                        rm(
                            joinpath(@__DIR__, "tmp", TEST_DS_FILENAME_STEM),
                            recursive = true,
                        )
                end
            end

            """
                get_test_dataset(
                    drvshortname::AbstractString = "ESRI shapefile",
                    geomfamily::String = "line";
                    withmissinggeom::Bool = true,
                    withmissingfield::Bool = true,
                    withmixedgeomtypes::Bool = true,
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
            The corresponding IDataset

            """
            function get_test_dataset(
                drvshortname::AbstractString = "ESRI shapefile",
                geomfamily::String = "line";
                withmissinggeom::Bool = true,
                withmissingfield::Bool = true,
                withmixedgeomtypes::Bool = true,
            )::AG.IDataset

                # Build dataset filename
                filename = joinpath(
                    @__DIR__,
                    "tmp",
                    TEST_DS_FILENAME_STEM *
                    TEST_DS_DRIVERS_FILE_EXTENSIONS[drvshortname],
                )

                # Clean previously created files for new dataset
                clean_test_dataset_files()

                # Prepare data for dataset building
                data = Dict(
                    "line" => (
                        simple1 = (
                            name = "line1",
                            geom = AG.createlinestring([
                                (i, i + 1) for i in 1.0:3.0
                            ]),
                        ),
                        multi1 = (
                            name = "multiline1",
                            geom = AG.createmultilinestring([
                                [(i, i + 1) for i in j:j+3] for j in 1.0:5.0:6.0
                            ]),
                        ),
                        simple2 = (
                            name = "line2",
                            geom = AG.createlinestring([
                                (i, i + 1) for i in 3.0:5.0
                            ]),
                        ),
                        emptygeom = (name = "emptygeom", geom = missing),
                        emptyfield = (
                            name = "emptyid",
                            geom = AG.createlinestring([
                                (i, i + 1) for i in 5.0:7.0
                            ]),
                        ),
                    ),
                    "polygon" => (
                        simple1 = (
                            name = "polygon1",
                            geom = AG.createpolygon([
                                (0.0, 0.0),
                                (0.0, 1.0),
                                (1.0, 1.0),
                            ]),
                        ),
                        multi1 = (
                            name = "multipolygon1",
                            geom = AG.createmultipolygon([
                                [[(0.0, 0.0), (0.0, j), (j, j)]] for
                                j in 1.0:-0.1:0.9
                            ]),
                        ),
                        simple2 = (
                            name = "polygon2",
                            geom = AG.createpolygon([
                                (0.0, 0.0),
                                (0.0, -1.0),
                                (-1.0, -1.0),
                            ]),
                        ),
                        emptygeom = (name = "emptygeom", geom = missing),
                        emptyfield = (
                            name = "emptyid",
                            geom = AG.createpolygon([
                                (0.0, 0.0),
                                (-1.0, 0.0),
                                (-1.0, 1.0),
                            ]),
                        ),
                    ),
                )

                # Create dataset
                AG.create(
                    filename;
                    driver = AG.getdriver(drvshortname),
                ) do newdataset
                    AG.createlayer(
                        name = "test_layer",
                        dataset = newdataset,
                        geom = AG.wkbUnknown,
                    ) do newlayer
                        # Add geom and field defn
                        AG.addfielddefn!(newlayer, "id", AG.OFTInteger64)
                        AG.addfielddefn!(newlayer, "name", AG.OFTString)
                        id_idx = AG.findfieldindex(AG.layerdefn(newlayer), "id")
                        name_idx =
                            AG.findfieldindex(AG.layerdefn(newlayer), "name")
                        # Add features
                        AG.addfeature(newlayer) do newfeature
                            AG.setfield!(newfeature, id_idx, 1)
                            AG.setfield!(
                                newfeature,
                                name_idx,
                                data[geomfamily].simple1.name,
                            )
                            return AG.setgeom!(
                                newfeature,
                                0,
                                data[geomfamily].simple1.geom,
                            )
                        end
                        if withmixedgeomtypes
                            AG.addfeature(newlayer) do newfeature
                                AG.setfield!(newfeature, id_idx, 2)
                                AG.setfield!(
                                    newfeature,
                                    name_idx,
                                    data[geomfamily].multi1.name,
                                )
                                return AG.setgeom!(
                                    newfeature,
                                    0,
                                    data[geomfamily].multi1.geom,
                                )
                            end
                        else
                            AG.addfeature(newlayer) do newfeature
                                AG.setfield!(newfeature, id_idx, 2)
                                AG.setfield!(
                                    newfeature,
                                    name_idx,
                                    data[geomfamily].simple2.name,
                                )
                                return AG.setgeom!(
                                    newfeature,
                                    0,
                                    data[geomfamily].simple2.geom,
                                )
                            end
                        end
                        if withmissinggeom
                            AG.addfeature(newlayer) do newfeature
                                AG.setfield!(newfeature, id_idx, 3)
                                return AG.setfield!(
                                    newfeature,
                                    name_idx,
                                    data[geomfamily].emptygeom.name,
                                )
                                # No geom set
                            end
                        end
                        if withmissingfield
                            AG.addfeature(newlayer) do newfeature
                                AG.setfieldnull!(newfeature, id_idx)
                                AG.setfield!(
                                    newfeature,
                                    name_idx,
                                    data[geomfamily].emptyfield.name,
                                )
                                return AG.setgeom!(
                                    newfeature,
                                    0,
                                    data[geomfamily].emptyfield.geom,
                                )
                            end
                        end
                    end
                end

                return AG.read(filename)
            end

            """
                map_on_test_dataset(
                    f::Function,
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
            The result of `f` applied on the corresponding dataset

            """
            function map_on_test_dataset(
                f::Function,
                drvshortname::AbstractString = "ESRI shapefile",
                geomfamily::String = "line";
                withmissinggeom::Bool = true,
                withmissingfield::Bool = true,
                withmixedgeomtypes::Bool = true,
            )

                # Build dataset
                ds = get_test_dataset(
                    drvshortname,
                    geomfamily;
                    withmissinggeom = withmissinggeom,
                    withmissingfield = withmissingfield,
                    withmixedgeomtypes = withmixedgeomtypes,
                )

                return try
                    f(ds)
                finally
                    (@isdefined ds) && AG.destroy(ds)
                end
            end

            # Helper functions
            wellknownvalue(obj::Any) = obj
            wellknownvalue(obj::AG.AbstractGeometry) = AG.toWKT(obj)
            wellknownvalue(obj::AG.AbstractSpatialRef) = AG.toWKT(obj)
            wellknownvalue(obj::Missing)::Missing = missing
            wellknownvalue(obj::Nothing)::Nothing = nothing
            function wellknownvalues(x)::Tuple
                return Tuple(wellknownvalue.(x[i]) for i in 1:length(x))
            end
            tupleoftuples_equal = (
                (x, y) ->
                    length(x) == length(y) &&
                        all([all(x[i] .=== y[i]) for i in 1:length(x)])
            )

            """
                layer_to_columntable_with_WKT(
                    drvshortname::String, 
                    geomfamilly::String,
                    withmissinggeom::Bool,
                    withmissingfield::Bool,
                    withmixedgeomtypes::Bool,
                )::NamedTuple

            Convenience function to build new test results for `test_layer_to_table`  
            Creates a dataset from scratch with `get_test_dataset` and converts it to a columntable  
            Returns a `NamedTuple` with:
            - names: layer geom and field names
            - types: expected types given by `Tables.buildcolumns`
            - values: expected Tables.columntable result values with geometries converted to WKT

            """
            function layer_to_columntable_with_WKT(
                drvshortname::String,
                geomfamilly::String,
                withmissinggeom::Bool,
                withmissingfield::Bool,
                withmixedgeomtypes::Bool,
            )::NamedTuple
                map_on_test_dataset(
                    drvshortname,
                    geomfamilly;
                    withmissinggeom = withmissinggeom,
                    withmissingfield = withmissingfield,
                    withmixedgeomtypes = withmixedgeomtypes,
                ) do ds
                    layer = AG.getlayer(ds, 0)
                    return (
                        names = keys(Tables.columntable(layer)),
                        types = eltype.(values(Tables.columntable(layer)),),
                        values = wellknownvalues(
                            values(Tables.columntable(layer)),
                        ),
                    )
                end
            end

            """
                test_layer_to_table(
                    drvshortname::String, 
                    geomfamilly::String,
                    withmissinggeom::Bool,
                    withmissingfield::Bool,
                    withmixedgeomtypes::Bool,
                    reference_geotable::Tuple)

            Creates a dataset from scratch with `get_test_dataset` and converts it to a columntable  
            And test Tables.columntable(::AG.IFeatureLayer) result against `reference_geotable`

            """
            function test_layer_to_table(
                drvshortname::String,
                geomfamilly::String,
                withmissinggeom::Bool,
                withmissingfield::Bool,
                withmixedgeomtypes::Bool,
                reference_geotable::NamedTuple,
            )
                map_on_test_dataset(
                    drvshortname,
                    geomfamilly;
                    withmissinggeom = withmissinggeom,
                    withmissingfield = withmissingfield,
                    withmixedgeomtypes = withmixedgeomtypes,
                ) do ds
                    layer = AG.getlayer(ds, 0)
                    @test keys(Tables.columntable(layer)) ==
                          reference_geotable.names
                    @test eltype.(values(Tables.columntable(layer))) ==
                          reference_geotable.types
                    @test tupleoftuples_equal(
                        wellknownvalues(values(Tables.columntable(layer))),
                        reference_geotable.values,
                    )
                end
            end

            """
                test_layer_to_table(
                    layer::AG.AbstractFeatureLayer,
                    reference_geotable::NamedTuple,
                )::Bool

            test Tables.columntable(::AG.AbstractFeatureLayer) result against `reference_geotable`

            """
            function test_layer_to_table(
                layer::AG.AbstractFeatureLayer,
                reference_geotable::NamedTuple,
            )
                @test keys(Tables.columntable(layer)) ==
                      reference_geotable.names
                @test eltype.(values(Tables.columntable(layer))) ==
                      reference_geotable.types
                @test tupleoftuples_equal(
                    wellknownvalues(values(Tables.columntable(layer))),
                    reference_geotable.values,
                )
            end

            @testset "Conversion to table for ESRI Shapefile driver" begin
                ESRI_Shapefile_test_reference_geotable = (
                    names = (Symbol(""), :id, :name),
                    types = (
                        Union{Missing,AG.IGeometry},
                        Union{Missing,Int64},
                        String,
                    ),
                    values = (
                        Union{Missing,String}[
                            "POLYGON ((0 0,0 1,1 1))",
                            "MULTIPOLYGON (((0 0,0 1,1 1)),((0.9 0.9,0.0 0.9,0 0)))",
                            missing,
                            "POLYGON ((0 0,-1 0,-1 1))",
                        ],
                        [1, 2, 3, missing],
                        ["polygon1", "multipolygon1", "emptygeom", "emptyid"],
                    ),
                )
                test_layer_to_table(
                    "ESRI Shapefile",
                    "polygon",
                    true,
                    true,
                    true,
                    ESRI_Shapefile_test_reference_geotable,
                )

                ESRI_Shapefile_test_reference_geotable = (
                    names = (Symbol(""), :id, :name),
                    types = (
                        Union{Missing,AG.IGeometry{AG.wkbLineString}},
                        Union{Missing,Int64},
                        String,
                    ),
                    values = (
                        Union{Missing,String}[
                            "LINESTRING (1 2,2 3,3 4)",
                            "LINESTRING (3 4,4 5,5 6)",
                            missing,
                            "LINESTRING (5 6,6 7,7 8)",
                        ],
                        [1, 2, 3, missing],
                        ["line1", "line2", "emptygeom", "emptyid"],
                    ),
                )
                test_layer_to_table(
                    "ESRI Shapefile",
                    "line",
                    true,
                    true,
                    false,
                    ESRI_Shapefile_test_reference_geotable,
                )
            end

            @testset "Conversion to table for GeoJSON driver" begin
                GeoJSON_test_reference_geotable = (
                    names = (Symbol(""), :id, :name),
                    types = (
                        Union{Missing,AG.IGeometry},
                        Union{Missing,Int32},
                        String,
                    ),
                    values = (
                        Union{Missing,String}[
                            "POLYGON ((0 0,0 1,1 1))",
                            "MULTIPOLYGON (((0 0,0 1,1 1)),((0 0,0.0 0.9,0.9 0.9)))",
                            missing,
                            "POLYGON ((0 0,-1 0,-1 1))",
                        ],
                        Union{Missing,Int32}[1, 2, 3, missing],
                        ["polygon1", "multipolygon1", "emptygeom", "emptyid"],
                    ),
                )
                test_layer_to_table(
                    "GeoJSON",
                    "polygon",
                    true,
                    true,
                    true,
                    GeoJSON_test_reference_geotable,
                )

                GeoJSON_test_reference_geotable = (
                    names = (Symbol(""), :id, :name),
                    types = (
                        Union{Missing,AG.IGeometry{AG.wkbLineString}},
                        Union{Missing,Int32},
                        String,
                    ),
                    values = (
                        Union{Missing,String}[
                            "LINESTRING (1 2,2 3,3 4)",
                            "LINESTRING (3 4,4 5,5 6)",
                            missing,
                            "LINESTRING (5 6,6 7,7 8)",
                        ],
                        Union{Missing,Int32}[1, 2, 3, missing],
                        ["line1", "line2", "emptygeom", "emptyid"],
                    ),
                )
                test_layer_to_table(
                    "GeoJSON",
                    "line",
                    true,
                    true,
                    false,
                    GeoJSON_test_reference_geotable,
                )
            end

            @testset "Conversion to table for GML driver" begin
                GML_test_reference_geotable = (
                    names = (:geometryProperty, :gml_id, :id, :name),
                    types = (
                        Union{Missing,AG.IGeometry},
                        String,
                        Union{Missing,Int64},
                        String,
                    ),
                    values = (
                        Union{Missing,String}[
                            "LINESTRING (1 2,2 3,3 4)",
                            "MULTILINESTRING ((1 2,2 3,3 4,4 5),(6 7,7 8,8 9,9 10))",
                            missing,
                            "LINESTRING (5 6,6 7,7 8)",
                        ],
                        [
                            "test_layer.0",
                            "test_layer.1",
                            "test_layer.2",
                            "test_layer.3",
                        ],
                        Union{Missing,Int64}[1, 2, 3, missing],
                        ["line1", "multiline1", "emptygeom", "emptyid"],
                    ),
                )
                test_layer_to_table(
                    "GML",
                    "line",
                    true,
                    true,
                    true,
                    GML_test_reference_geotable,
                )
            end

            @testset "Conversion to table for GPKG driver" begin
                GPKG_test_reference_geotable = (
                    names = (:geom, :id, :name),
                    types = (
                        Union{Missing,AG.IGeometry},
                        Union{Missing,Int64},
                        String,
                    ),
                    values = (
                        Union{Missing,String}[
                            "LINESTRING (1 2,2 3,3 4)",
                            "MULTILINESTRING ((1 2,2 3,3 4,4 5),(6 7,7 8,8 9,9 10))",
                            missing,
                            "LINESTRING (5 6,6 7,7 8)",
                        ],
                        Union{Missing,Int64}[1, 2, 3, missing],
                        ["line1", "multiline1", "emptygeom", "emptyid"],
                    ),
                )
                test_layer_to_table(
                    "GPKG",
                    "line",
                    true,
                    true,
                    true,
                    GPKG_test_reference_geotable,
                )
            end

            @testset "Conversion to table for KML driver" begin
                KML_test_reference_geotable = (
                    names = (Symbol(""), :Name, :Description),
                    types = (AG.IGeometry, String, String),
                    values = (
                        [
                            "LINESTRING (1 2,2 3,3 4)",
                            "MULTILINESTRING ((1 2,2 3,3 4,4 5),(6 7,7 8,8 9,9 10))",
                            "LINESTRING (5 6,6 7,7 8)",
                        ],
                        ["line1", "multiline1", "emptyid"],
                        ["", "", ""],
                    ),
                )
                test_layer_to_table(
                    "KML",
                    "line",
                    true,
                    true,
                    true,
                    KML_test_reference_geotable,
                )
            end

            @testset "Conversion to table for FlatGeobuf driver" begin
                FlatGeobuf_test_reference_geotable = (
                    names = (Symbol(""), :id, :name),
                    types = (AG.IGeometry, Union{Nothing,Int64}, String),
                    values = (
                        [
                            "LINESTRING (5 6,6 7,7 8)",
                            "MULTILINESTRING ((1 2,2 3,3 4,4 5),(6 7,7 8,8 9,9 10))",
                            "LINESTRING (1 2,2 3,3 4)",
                        ],
                        Union{Nothing,Int64}[nothing, 2, 1],
                        ["emptyid", "multiline1", "line1"],
                    ),
                )
                test_layer_to_table(
                    "FlatGeobuf",
                    "line",
                    true,
                    true,
                    true,
                    FlatGeobuf_test_reference_geotable,
                )
            end

            @testset "Conversion to table for CSV driver" begin
                AG.read(
                    joinpath(@__DIR__, "data/multi_geom.csv"),
                    options = [
                        "GEOM_POSSIBLE_NAMES=point,linestring",
                        "KEEP_GEOM_COLUMNS=NO",
                    ],
                ) do multigeom_test_ds
                    multigeom_test_layer = AG.getlayer(multigeom_test_ds, 0)
                    CSV_multigeom_test_reference_geotable = (
                        names = (:point, :linestring, :id, :zoom, :location),
                        types = (
                            AG.IGeometry{AG.wkbPoint},
                            AG.IGeometry{AG.wkbLineString},
                            String,
                            String,
                            String,
                        ),
                        values = (
                            ["POINT (30 10)", "POINT (35 15)"],
                            [
                                "LINESTRING (30 10,10 30,40 40)",
                                "LINESTRING (35 15,15 35,45 45)",
                            ],
                            ["5.1", "5.2"],
                            ["1.0", "2.0"],
                            ["Mumbai", "New Delhi"],
                        ),
                    )
                    return test_layer_to_table(
                        multigeom_test_layer,
                        CSV_multigeom_test_reference_geotable,
                    )
                end
            end

            clean_test_dataset_files()
        end
    end
end
