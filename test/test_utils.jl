using Test
import GDAL
import ArchGDAL as AG

"Test both that an ErrorException is thrown and that the message is as expected"
function eval_ogrerr(err, expected_message, placeholder = "")
    @test (@test_throws ErrorException AG.@ogrerr err "e $(placeholder):").value.msg ==
          "e $(placeholder): ($expected_message)"
end

@testset "test_utils.jl" begin
    @testset "metadataitem" begin
        driver = AG.getdriver("DERIVED")
        @test AG.metadataitem(driver, "DMD_EXTENSIONS") == ""
        driver = AG.getdriver("GTiff")
        @test AG.metadataitem(driver, "DMD_EXTENSIONS") == "tif tiff"
    end

    @testset "subdatasets" begin
        AG.create(AG.getdriver("MEM"), width = 1, height = 1) do dataset
            @test isempty(AG.subdatasets(dataset))

            GDAL.gdalsetmetadataitem(
                dataset,
                "SUBDATASET_1_NAME",
                "subdataset-1?token=a=b",
                "SUBDATASETS",
            )
            GDAL.gdalsetmetadataitem(
                dataset,
                "SUBDATASET_1_DESC",
                "first subdataset",
                "SUBDATASETS",
            )
            GDAL.gdalsetmetadataitem(
                dataset,
                "SUBDATASET_2_NAME",
                "subdataset-2",
                "SUBDATASETS",
            )

            @test AG.subdatasets(dataset) ==
                  ["subdataset-1?token=a=b", "subdataset-2"]
        end
    end

    @testset "string lists" begin
        # Arrays and pointers are converted by `ccall` itself
        options = ["A=1", "B=2"]
        @test AG._stringlist(options) === options
        @test AG._stringlist(AG.StringList(C_NULL)) == C_NULL
        # Other arrays are copied into a `Vector{String}`
        @test AG._stringlist(view(["A=1", "B=2", "C=3"], 1:2)) == options
        @test AG._stringlist(view(split("A=1,B=2", ","), :)) == options
        @test AG._stringlist(view(split("A=1,B=2", ","), :)) isa Vector{String}

        # The view excludes a third, conflicting option. GDAL must see exactly
        # the two options in the view, and nothing past its end.
        alloptions = [
            "GEOM_POSSIBLE_NAMES=point,linestring",
            "KEEP_GEOM_COLUMNS=NO",
            "GEOM_POSSIBLE_NAMES=nonexistent",
        ]
        AG.read(
            joinpath(@__DIR__, "data/multi_geom.csv"),
            options = view(alloptions, 1:2),
        ) do dataset
            layer = AG.getlayer(dataset, 0)
            @test AG.ngeom(layer) == 2
            @test AG.nfield(layer) == 3
        end

        AG.read(joinpath(@__DIR__, "data/utmsmall.tif")) do dataset
            @test AG.gdalinfo(dataset, view(["-json", "-nomd"], 1:1)) ==
                  AG.gdalinfo(dataset, ["-json"])
        end
    end

    @testset "OGR Errors" begin
        @test isnothing(AG.@ogrerr GDAL.OGRERR_NONE "not an error")
        eval_ogrerr(GDAL.OGRERR_NOT_ENOUGH_DATA, "Not enough data.", "foo")
        eval_ogrerr(GDAL.OGRERR_NOT_ENOUGH_MEMORY, "Not enough memory.")
        eval_ogrerr(
            GDAL.OGRERR_UNSUPPORTED_GEOMETRY_TYPE,
            "Unsupported geometry type.",
        )
        eval_ogrerr(GDAL.OGRERR_UNSUPPORTED_OPERATION, "Unsupported operation.")
        eval_ogrerr(GDAL.OGRERR_CORRUPT_DATA, "Corrupt data.")
        eval_ogrerr(GDAL.OGRERR_FAILURE, "Failure.")
        eval_ogrerr(
            GDAL.OGRERR_UNSUPPORTED_SRS,
            "Unsupported spatial reference system.",
        )
        eval_ogrerr(GDAL.OGRERR_INVALID_HANDLE, "Invalid handle.")
        eval_ogrerr(GDAL.OGRERR_NON_EXISTING_FEATURE, "Non-existing feature.")
        # OGRERR_NON_EXISTING_FEATURE is the highest error code currently in GDAL. If another one is
        # added this test will fail.
        eval_ogrerr(GDAL.OGRERR_NON_EXISTING_FEATURE + 1, "Unknown error.")
    end
end
