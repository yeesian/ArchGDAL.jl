using Test
import ArchGDAL as AG

# TODO: Should this become part of ArchGDAL?u
Base.isempty(x::AG.AbstractAttribute) = x.ptr == C_NULL
Base.isempty(x::AG.AbstractDataset) = x.ptr == C_NULL
Base.isempty(x::AG.AbstractDimension) = x.ptr == C_NULL
Base.isempty(x::AG.AbstractEDTComponent) = x.ptr == C_NULL
Base.isempty(x::AG.AbstractExtendedDataType) = x.ptr == C_NULL
Base.isempty(x::AG.AbstractFeature) = x.ptr == C_NULL
Base.isempty(x::AG.AbstractFeatureDefn) = x.ptr == C_NULL
Base.isempty(x::AG.AbstractFeatureLayer) = x.ptr == C_NULL
Base.isempty(x::AG.AbstractFieldDefn) = x.ptr == C_NULL
Base.isempty(x::AG.AbstractGeomFieldDefn) = x.ptr == C_NULL
Base.isempty(x::AG.AbstractGeometry) = x.ptr == C_NULL
Base.isempty(x::AG.AbstractGroup) = x.ptr == C_NULL
Base.isempty(x::AG.AbstractMDArray) = x.ptr == C_NULL
Base.isempty(x::AG.AbstractRasterBand) = x.ptr == C_NULL
Base.isempty(x::AG.AbstractSpatialRef) = x.ptr == C_NULL
Base.isempty(x::AG.ColorTable) = x.ptr == C_NULL
Base.isempty(x::AG.CoordTransform) = x.ptr == C_NULL
Base.isempty(x::AG.Driver) = x.ptr == C_NULL
Base.isempty(x::AG.Field) = x.ptr == C_NULL
Base.isempty(x::AG.RasterAttrTable) = x.ptr == C_NULL
Base.isempty(x::AG.StyleManager) = x.ptr == C_NULL
Base.isempty(x::AG.StyleTable) = x.ptr == C_NULL
Base.isempty(x::AG.StyleTool) = x.ptr == C_NULL

# There should be more drivers... Anyone willing to update GDAL?
# Possible drivers: at least HDF4, HDF5, TileDB
const mdarray_drivers = [
    (
        drivername = "MEM",
        drivercreateoptions = String[],
        mdarraycreateoptions = String[],
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

        filename = tempname()
        dataset = AG.createmultidimensional(
            driver,
            filename,
            String[],
            drivercreateoptions,
        )
        @test !isempty(dataset)

        files = AG.filelist(dataset)
        if drivername in ["MEM"]
            @test length(files) == 0
        elseif drivername in ["netCDF", "Zarr"]
            @test length(files) == 1
        else
            @assert false
        end

        root = AG.getrootgroup(dataset)
        @test !isempty(root)
        rootname = AG.getname(root)
        @test rootname == "/"
        rootfullname = AG.getfullname(root)
        @test rootfullname == "/"

        group = AG.creategroup(root, "group")
        @test !isempty(group)
        @test AG.getname(group) == "group"
        @test AG.getfullname(group) == "/group"

        @test AG.getgroupnames(root) == ["group"]
        @test AG.getgroupnames(group) == []

        dimx = AG.createdimension(group, "x", "", "", 3)
        @test !isempty(dimx)
        dimy = AG.createdimension(group, "y", "", "", 4)
        @test !isempty(dimy)

        @test AG.getdimensions(root) == []
        dimensions = AG.getdimensions(group)
        @test length(dimensions) == 2

        type = AG.extendeddatatypecreate(Float32)
        @test !isempty(type)

        mdarray = AG.createmdarray(
            group,
            "mdarray",
            [dimx, dimy],
            type,
            mdarraycreateoptions,
        )
        @test !isempty(mdarray)

        @test AG.getmdarraynames(root) == []
        @test AG.getmdarraynames(group) == ["mdarray"]

        @test AG.getvectorlayernames(root) == []
        @test AG.getvectorlayernames(group) == []

        @test AG.getstructuralinfo(group) == []

        mdarray1 = AG.openmdarrayfromfullname(root, "/group/mdarray")
        @test !isempty(mdarray1)
        #TODO @test AG.getfullname(mdarray1) == "/group/mdarray"
        @test isempty(AG.openmdarrayfromfullname(root, "/group/doesnotexist"))

        mdarray2 = AG.resolvemdarray(root, "mdarray", "")
        @test !isempty(mdarray2)
        #TODO @test AG.getfullname(mdarray2) == "/group/mdarray"
        @test isempty(AG.resolvemdarray(root, "doesnotexist", ""))

        group1 = AG.opengroupfromfullname(root, "/group")
        @test !isempty(group1)
        @test AG.getfullname(group1) == "/group"
        @test isempty(AG.opengroupfromfullname(root, "/doesnotexist"))

        # dimx1 = AG.opendimensionfromfullname(root, "group/x")
        # @test !isempty(dimx1)
        # dimz = AG.opendimensionfromfullname(root, "group/z")
        # @test isempty(dimz)

        # TODO:
        # - createvectorlayer
        # - deletegroup
        # - deletemdarary
        # - openvecgtorlayer
        # - rename
        # - subsetdimensionfromselection
    end
end
