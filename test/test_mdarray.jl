using Test
import ArchGDAL as AG

# There should be more drivers... Anyone willing to update GDAL?
# Possible drivers: at least HDF4, HDF5, TileDB
const mdarray_drivers = [
    (
        drivername = "MEM",
        drivercreateoptions = nothing,
        mdarraycreateoptions = nothing,
    ),
    (
        drivername = "netCDF",
        drivercreateoptions = ["FORMAT=NC4"],
        mdarraycreateoptions = ["COMPRESS=DEFLATE", "ZLEVEL=9"],
    ),
    (
        drivername = "Zarr",
        drivercreateoptions = ["FORMAT=ZARR_V3"],
        mdarraycreatoptions = [
            "COMPRESS=BLOSC",
            "BLOSC_CLEVEL=9",
            "BLOSC_SHUFFLE=BIT",
        ],
    ),
]

@testset "test_mdarray.jl" begin
    @testset "$drivername" for (
        drivername,
        drivercreateoptions,
        mdarraycreateoptions,
    ) in mdarray_drivers
        driver = AG.getdriver(drivername)

        @testset "interactive" begin
            filename = tempname(; cleanup = false)
            memory_dataset = nothing

            @testset "writing" begin
                dataset = AG.createmultidimensional(
                    driver,
                    filename,
                    nothing,
                    drivercreateoptions,
                )
                @test !AG.isnull(dataset)

                files = AG.filelist(dataset)
                if drivername in ["MEM"]
                    @test length(files) == 0
                elseif drivername in ["netCDF", "Zarr"]
                    @test length(files) == 1
                else
                    @assert false
                end

                root = AG.getrootgroup(dataset)
                @test !AG.isnull(root)
                rootname = AG.getname(root)
                @test rootname == "/"
                rootfullname = AG.getfullname(root)
                @test rootfullname == "/"

                group = AG.creategroup(root, "group")
                @test !AG.isnull(group)
                @test AG.getname(group) == "group"
                @test AG.getfullname(group) == "/group"

                @test AG.getgroupnames(root) == ["group"]
                @test AG.getgroupnames(group) == []

                nx, ny = 3, 4
                dimx = AG.createdimension(group, "x", "", "", nx)
                @test !AG.isnull(dimx)
                dimy = AG.createdimension(group, "y", "", "", ny)
                @test !AG.isnull(dimy)

                datatype = AG.extendeddatatypecreate(Float32)
                @test !AG.isnull(datatype)

                mdarray = AG.createmdarray(
                    group,
                    "mdarray",
                    [dimx, dimy],
                    datatype,
                    mdarraycreateoptions,
                )
                @test !AG.isnull(mdarray)

                @test AG.getmdarraynames(root) == []
                @test AG.getmdarraynames(group) == ["mdarray"]

                @test AG.getvectorlayernames(root) == []
                @test AG.getvectorlayernames(group) == []

                @test AG.getstructuralinfo(group) == []

                # @test AG.iswritable(mdarray)

                data = Float32[100 * x + y for y in 1:ny, x in 1:nx]

                success = AG.write(mdarray, data)
                @test success

                if drivername != "MEM"
                    err = AG.close(dataset)
                    @test err == GDAL.CE_None
                else
                    memory_dataset = dataset
                end

                # Trigger all finalizers
                for i in 1:10
                    GC.gc()
                end
            end

            @testset "reading" begin
                if drivername != "MEM"
                    dataset = AG.open(
                        filename,
                        AG.OF_MULTIDIM_RASTER |
                        AG.OF_READONLY |
                        AG.OF_SHARED |
                        AG.OF_VERBOSE_ERROR,
                        nothing,
                        nothing,
                        nothing,
                    )
                else
                    dataset = memory_dataset
                end
                @test !AG.isnull(dataset)

                root = AG.getrootgroup(dataset)
                @test !AG.isnull(root)

                group = AG.opengroup(root, "group")
                @test !AG.isnull(group)

                mdarray = AG.openmdarray(group, "mdarray")
                @test !AG.isnull(mdarray)

                # @test !AG.iswritable(mdarray)

                dimensions = AG.getdimensions(mdarray)
                @test length(dimensions) == 2
                dimx, dimy = dimensions
                @test all(!AG.isnull(dim) for dim in dimensions)
                @test AG.getname(dimx) == "x"
                @test AG.getname(dimy) == "y"
                nx, ny = AG.getsize(dimx), AG.getsize(dimy)
                @test (nx, ny) == (3, 4)
                @test AG.getfullname(dimx) == "/group/x"
                @test AG.gettype(dimx) == ""
                @test AG.getdirection(dimx) == ""
                xvar = AG.getindexingvariable(dimx)
                @test AG.isnull(xvar)
                # TODO: setindexingvariable!
                # TODO: rename!

                mdarray1 = AG.openmdarrayfromfullname(root, "/group/mdarray")
                @test !AG.isnull(mdarray1)
                @test AG.getfullname(mdarray1) == "/group/mdarray"
                @test AG.isnull(
                    AG.openmdarrayfromfullname(root, "/group/doesnotexist"),
                )

                mdarray2 = AG.resolvemdarray(group, "mdarray", "")
                @test !AG.isnull(mdarray2)
                @test AG.getfullname(mdarray2) == "/group/mdarray"
                @test AG.isnull(AG.resolvemdarray(group, "doesnotexist", ""))

                group1 = AG.opengroupfromfullname(root, "/group")
                @test !AG.isnull(group1)
                @test AG.getfullname(group1) == "/group"
                @test AG.isnull(
                    AG.opengroupfromfullname(group, "/doesnotexist"),
                )

                datatype = AG.getdatatype(mdarray)
                @test !AG.isnull(datatype)
                # TODO: Check class

                data = Array{Float32}(undef, ny, nx)
                success = AG.read!(mdarray, data)
                @test success
                @test data == Float32[100 * x + y for y in 1:ny, x in 1:nx]

                err = AG.close(dataset)
                @test err == GDAL.CE_None

                # Trigger all finalizers
                for i in 1:10
                    GC.gc()
                end
            end
        end

        @testset "context handlers" begin
            filename = tempname(; cleanup = false)
            memory_dataset = nothing

            @testset "writing" begin
                AG.createmultidimensional(
                    driver,
                    filename,
                    nothing,
                    drivercreateoptions,
                ) do dataset
                    @test !AG.isnull(dataset)

                    root = AG.getrootgroup(dataset)
                    @test !AG.isnull(root)

                    rootname = AG.getname(root)
                    @test rootname == "/"
                    rootfullname = AG.getfullname(root)
                    @test rootfullname == "/"

                    AG.creategroup(root, "group") do group
                        @test !AG.isnull(group)
                        @test AG.getname(group) == "group"
                        @test AG.getfullname(group) == "/group"

                        @test AG.getgroupnames(root) == ["group"]
                        @test AG.getgroupnames(group) == []

                        nx, ny = 3, 4
                        AG.createdimension(group, "x", "", "", nx) do dimx
                            @test !AG.isnull(dimx)
                            AG.createdimension(group, "y", "", "", ny) do dimy
                                @test !AG.isnull(dimy)

                                AG.getdimensions(root) do dims
                                    @test dims == []
                                end
                                AG.getdimensions(group) do dimensions
                                    @test length(dimensions) == 2
                                end

                                AG.extendeddatatypecreate(Float32) do datatype
                                    @test !AG.isnull(datatype)

                                    AG.createmdarray(
                                        group,
                                        "mdarray",
                                        [dimx, dimy],
                                        datatype,
                                        mdarraycreateoptions,
                                    ) do mdarray
                                        @test !AG.isnull(mdarray)

                                        @test AG.getmdarraynames(root) == []
                                        @test AG.getmdarraynames(group) ==
                                              ["mdarray"]

                                        @test AG.getvectorlayernames(root) == []
                                        @test AG.getvectorlayernames(group) ==
                                              []

                                        @test AG.getstructuralinfo(group) == []

                                        # @test AG.iswritable(mdarray)

                                        data = Float32[
                                            100 * x + y for y in 1:ny, x in 1:nx
                                        ]

                                        success = AG.write(mdarray, data)
                                        @test success
                                    end
                                end
                            end
                        end
                    end
                end

                # Trigger all finalizers
                for i in 1:10
                    GC.gc()
                end
            end

            if drivername != "MEM"
                @testset "reading" begin
                    AG.open(
                        filename,
                        AG.OF_MULTIDIM_RASTER |
                        AG.OF_READONLY |
                        AG.OF_SHARED |
                        AG.OF_VERBOSE_ERROR,
                        nothing,
                        nothing,
                        nothing,
                    ) do dataset
                        @test !AG.isnull(dataset)

                        AG.getrootgroup(dataset) do root
                            @test !AG.isnull(root)

                            AG.opengroup(root, "group") do group
                                @test !AG.isnull(group)

                                AG.openmdarray(group, "mdarray") do mdarray
                                    @test !AG.isnull(mdarray)

                                    # @test !AG.iswritable(mdarray)

                                    AG.getdimensions(mdarray) do dimensions
                                        @test length(dimensions) == 2
                                        dimx, dimy = dimensions
                                        @test all(
                                            !AG.isnull(dim) for
                                            dim in dimensions
                                        )
                                        @test AG.getname(dimx) == "x"
                                        @test AG.getname(dimy) == "y"
                                        nx, ny =
                                            AG.getsize(dimx), AG.getsize(dimy)
                                        @test (nx, ny) == (3, 4)
                                        @test AG.getfullname(dimx) == "/group/x"
                                        @test AG.gettype(dimx) == ""
                                        @test AG.getdirection(dimx) == ""
                                        AG.getindexingvariable(dimx) do xvar
                                            @test AG.isnull(xvar)
                                        end
                                        # TODO: setindexingvariable!
                                        # TODO: rename!

                                        datatype = AG.getdatatype(mdarray)
                                        @test !AG.isnull(datatype)
                                        # TODO: Check class

                                        AG.openmdarrayfromfullname(
                                            root,
                                            "/group/mdarray",
                                        ) do mdarray1
                                            @test !AG.isnull(mdarray1)
                                            @test AG.getfullname(mdarray1) ==
                                                  "/group/mdarray"
                                        end
                                        AG.openmdarrayfromfullname(
                                            root,
                                            "/group/doesnotexist",
                                        ) do doesnotexist
                                            @test AG.isnull(doesnotexist)
                                        end

                                        AG.resolvemdarray(
                                            root,
                                            "mdarray",
                                            "",
                                        ) do mdarray2
                                            @test !AG.isnull(mdarray2)
                                            @test AG.getfullname(mdarray2) ==
                                                  "/group/mdarray"
                                        end
                                        AG.resolvemdarray(
                                            root,
                                            "doesnotexist",
                                            "",
                                        ) do doesnotexist
                                            @test AG.isnull(doesnotexist)
                                        end

                                        AG.opengroupfromfullname(
                                            root,
                                            "/group",
                                        ) do group1
                                            @test !AG.isnull(group1)
                                            @test AG.getfullname(group1) ==
                                                  "/group"
                                        end
                                        AG.opengroupfromfullname(
                                            root,
                                            "/doesnotexist",
                                        ) do doesnotexist
                                            @test AG.isnull(doesnotexist)
                                        end

                                        data = Array{Float32}(undef, ny, nx)
                                        success = AG.read!(mdarray, data)
                                        @test success
                                        @test data == Float32[
                                            100 * x + y for y in 1:ny, x in 1:nx
                                        ]
                                    end
                                end
                            end
                        end
                    end

                    # Trigger all finalizers
                    for i in 1:10
                        GC.gc()
                    end
                end
            end
        end
    end
end
