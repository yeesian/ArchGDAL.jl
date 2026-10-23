using Test
import ArchGDAL as AG
using GDAL

# TODO: Test vsizip driver

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

# Attributes with complex values are not supported by Zarr (?)
const scalar_attribute_types = [
    String,
    Int8,
    Int16,
    Int32,
    Int64,
    UInt8,
    UInt16,
    UInt32,
    UInt64,
    Float32,
    Float64,
    # Complex{Int16},
    # Complex{Int32},
    # Complex{Float32},
    # Complex{Float64},
]
const attribute_types =
    [scalar_attribute_types..., [Vector{T} for T in scalar_attribute_types]...]

# Can't have `\0` or `/` in attribute names
# For netCDF:
# - first character must be alphanumeric or underscore or >= 128,
# - next characters cannot be iscontrol or DEL,
# - last character cannot be isspace
const attribute_names = [
    "attribute",
    "αβγ",
    # [string(ch) for ch in Char(1):Char(256) if ch != '/']...,
    [
        string(ch) for ch in [
            ('A':'Z')...,
            ('a':'z')...,
            ('0':'9')...,
            '_',
            (Char(128):Char(256))...,
        ]
    ]...,
]

get_attribute_value(::Type{String}) = "string"
get_attribute_value(::Type{T}) where {T<:Real} = T(32)
get_attribute_value(::Type{T}) where {T<:Complex} = T(32, 33)
get_attribute_value(::Type{Vector{String}}) = String["string", "", "αβγ"]
function get_attribute_value(::Type{Vector{T}}) where {T<:Integer}
    # Can't store large Int64 values (JSON...)
    tmin =
        T == Int64 ? 1000 * T(typemin(Int32)) :
        T == UInt64 ? 1000 * T(typemin(UInt32)) : typemin(T)
    tmax =
        T == Int64 ? 1000 * T(typemax(Int32)) :
        T == UInt64 ? 1000 * T(typemax(UInt32)) : typemax(T)
    return T[32, tmin, tmax, 0]
end
function get_attribute_value(::Type{Vector{T}}) where {T<:Real}
    return T[
        32,
        typemin(T),
        typemax(T),
        T(+0.0),
        T(-0.0),
        eps(T),
        prevfloat(T(1)),
        nextfloat(T(1)),
        T(Inf),
        T(-Inf),
        T(NaN),
    ]
end
function get_attribute_value(::Type{Vector{T}}) where {T<:Complex{<:Integer}}
    return T[T(32, 33), T(typemin(real(T)), typemax(real(T))), T(0)]
end
function get_attribute_value(::Type{Vector{T}}) where {T<:Complex{<:Real}}
    return T[
        T(32, 33),
        T(typemin(real(T)), typemax(real(T))),
        T(0),
        T(+0.0, -0.0),
        T(eps(real(T))),
        T(prevfloat(real(T)(1)), nextfloat(real(T)(1))),
        T(Inf, -Inf),
        T(NaN),
    ]
end

function write_attributes(loc::Union{AG.AbstractGroup,AG.AbstractMDArray})
    for name in attribute_names
        AG.writeattribute(loc, name, name)
    end
    for T in attribute_types
        AG.writeattribute(loc, "$T", get_attribute_value(T))
    end
    return nothing
end
function test_attributes(loc::Union{AG.AbstractGroup,AG.AbstractMDArray})
    for name in attribute_names
        @test isequal(AG.readattribute(loc, name), name)
    end
    for T in attribute_types
        @test isequal(AG.readattribute(loc, "$T"), get_attribute_value(T))
    end
    return nothing
end

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
                @test match(r"^GDAL Dataset", string(dataset)) !== nothing

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
                @test match(r"^ArchGDAL.IGroup", string(root)) !== nothing
                rootname = AG.getname(root)
                @test rootname == "/"
                rootfullname = AG.getfullname(root)
                @test rootfullname == "/"

                group = AG.creategroup(root, "group")
                @test !AG.isnull(group)
                @test match(r"^ArchGDAL.IGroup", string(group)) !== nothing
                @test AG.getname(group) == "group"
                @test AG.getfullname(group) == "/group"

                @test AG.getgroupnames(root) == ["group"]
                @test AG.getgroupnames(group) == []

                write_attributes(group)

                nx, ny = 3, 4
                dimx = AG.createdimension(group, "x", "", "", nx)
                @test !AG.isnull(dimx)
                @test match(r"^ArchGDAL.IDimension", string(dimx)) !== nothing
                dimy = AG.createdimension(group, "y", "", "", ny)
                @test !AG.isnull(dimy)

                datatype = AG.extendeddatatypecreate(Float32)
                @test !AG.isnull(datatype)
                @test match(
                    r"^ArchGDAL.IExtendedDataType",
                    string(datatype),
                ) !== nothing

                if drivername != "netCDF"
                    # netCDF does not support deleting MDArrays
                    mdarray0 = AG.createmdarray(
                        group,
                        "mdarray0",
                        [dimx, dimy],
                        datatype,
                        mdarraycreateoptions,
                    )
                    @test !AG.isnull(mdarray0)
                    success = AG.deletemdarray(group, "mdarray0")
                    @test success
                end

                mdarray = AG.createmdarray(
                    group,
                    "mdarray",
                    (dimx, dimy),
                    datatype,
                    mdarraycreateoptions,
                )
                @test !AG.isnull(mdarray)
                @test match(r"^3×4 ArchGDAL.IMDArray", string(mdarray)) !==
                      nothing

                @test AG.getmdarraynames(root) == []
                @test AG.getmdarraynames(group) == ["mdarray"]

                @test AG.getvectorlayernames(root) == []
                @test AG.getvectorlayernames(group) == []

                @test AG.getstructuralinfo(group) == []

                # @test AG.iswritable(mdarray)

                data = Float32[x + 100 * y for x in 1:nx, y in 1:ny]
                AG.write(mdarray, data)

                # Only interactive objects are tracked by the dataset;
                # internal and scoped objects must not accumulate there
                nchildren = length(dataset.children)

                write_attributes(mdarray)

                AG.writemdarray(group, "primes", UInt8[2, 3, 5, 7, 251])

                @test all(size(mdarray) == (nx, ny) for i in 1:100)
                @test length(dataset.children) == nchildren

                if drivername != "MEM"
                    @test AG.force_close_mdarray_dataset!(dataset) === nothing
                    @test AG.isnull(dataset)
                    @test isempty(dataset.children)
                    # Interactive children have been released
                    @test AG.isnull(root)
                    @test AG.isnull(group)
                    @test AG.isnull(dimx)
                    @test AG.isnull(mdarray)
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
                    dataset = AG.openmultidimensional(
                        filename;
                        flags = AG.OF_READONLY | AG.OF_SHARED |
                                AG.OF_VERBOSE_ERROR,
                    )
                    # Read-only datasets do not track their children
                    @test dataset.children === nothing
                else
                    dataset = memory_dataset
                end
                @test !AG.isnull(dataset)

                root = AG.getrootgroup(dataset)
                @test !AG.isnull(root)

                group = AG.opengroup(root, "group")
                @test !AG.isnull(group)

                test_attributes(group)

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
                @test AG.getindexingvariable(dimx) === nothing
                # TODO: setindexingvariable!
                # TODO: rename!

                mdarray1 = AG.openmdarrayfromfullname(root, "/group/mdarray")
                @test !AG.isnull(mdarray1)
                @test AG.getfullname(mdarray1) == "/group/mdarray"
                @test_throws ErrorException AG.openmdarrayfromfullname(
                    root,
                    "/group/doesnotexist",
                )
                mdarray2 = AG.resolvemdarray(group, "mdarray", "")
                @test !AG.isnull(mdarray2)
                @test AG.getfullname(mdarray2) == "/group/mdarray"
                @test_throws ErrorException AG.resolvemdarray(
                    group,
                    "doesnotexist",
                    "",
                )

                group1 = AG.opengroupfromfullname(root, "/group")
                @test !AG.isnull(group1)
                @test AG.getfullname(group1) == "/group"
                @test_throws ErrorException AG.opengroupfromfullname(
                    group,
                    "/doesnotexist",
                )
                datatype = AG.getdatatype(mdarray)
                @test !AG.isnull(datatype)
                @test AG.getclass(datatype) == GDAL.GEDTC_NUMERIC
                @test AG.getnumericdatatype(datatype) == AG.GDT_Float32

                data = Array{Float32}(undef, nx, ny)
                AG.read!(mdarray, data)
                @test data == Float32[x + 100 * y for x in 1:nx, y in 1:ny]

                data = AG.read(mdarray)
                @test data == Float32[x + 100 * y for x in 1:nx, y in 1:ny]

                test_attributes(mdarray)

                primes = AG.readmdarray(group, "primes")
                @test primes == UInt8[2, 3, 5, 7, 251]

                @test AG.force_close_mdarray_dataset!(dataset) === nothing
                @test AG.isnull(dataset)

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

                    AG.getrootgroup(dataset) do root
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

                            write_attributes(group)

                            nx, ny = 3, 4
                            AG.createdimension(group, "x", "", "", nx) do dimx
                                @test !AG.isnull(dimx)
                                AG.createdimension(
                                    group,
                                    "y",
                                    "",
                                    "",
                                    ny,
                                ) do dimy
                                    @test !AG.isnull(dimy)

                                    AG.getdimensions(root) do dims
                                        @test dims == []
                                    end
                                    AG.getdimensions(group) do dimensions
                                        @test length(dimensions) == 2
                                    end

                                    AG.extendeddatatypecreate(
                                        Float32,
                                    ) do datatype
                                        @test !AG.isnull(datatype)

                                        if drivername != "netCDF"
                                            # netCDF does not support deleting MDArrays
                                            AG.createmdarray(
                                                group,
                                                "mdarray0",
                                                [dimx, dimy],
                                                datatype,
                                                mdarraycreateoptions,
                                            ) do mdarray0
                                                @test !AG.isnull(mdarray0)
                                            end
                                            success = AG.deletemdarray(
                                                group,
                                                "mdarray0",
                                            )
                                            @test success
                                        end

                                        AG.createmdarray(
                                            group,
                                            "mdarray",
                                            (dimx, dimy),
                                            datatype,
                                            mdarraycreateoptions,
                                        ) do mdarray
                                            @test !AG.isnull(mdarray)

                                            @test AG.getmdarraynames(root) == []
                                            @test AG.getmdarraynames(group) ==
                                                  ["mdarray"]

                                            @test AG.getvectorlayernames(
                                                root,
                                            ) == []
                                            @test AG.getvectorlayernames(
                                                group,
                                            ) == []

                                            @test AG.getstructuralinfo(group) ==
                                                  []

                                            # @test AG.iswritable(mdarray)

                                            data = Float32[
                                                x + 100 * y for
                                                x in 1:nx, y in 1:ny
                                            ]
                                            AG.write(mdarray, data)

                                            write_attributes(mdarray)

                                            AG.writemdarray(
                                                group,
                                                "primes",
                                                UInt8[2, 3, 5, 7, 251],
                                            )

                                            return
                                        end
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
                    AG.openmultidimensional(
                        filename;
                        flags = AG.OF_READONLY | AG.OF_SHARED |
                                AG.OF_VERBOSE_ERROR,
                    ) do dataset
                        @test !AG.isnull(dataset)

                        AG.getrootgroup(dataset) do root
                            @test !AG.isnull(root)

                            AG.opengroup(root, "group") do group
                                @test !AG.isnull(group)

                                test_attributes(group)

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
                                            @test xvar === nothing
                                        end
                                        # TODO: setindexingvariable!
                                        # TODO: rename!

                                        datatype = AG.getdatatype(mdarray)
                                        @test !AG.isnull(datatype)
                                        @test AG.getclass(datatype) ==
                                              GDAL.GEDTC_NUMERIC
                                        @test AG.getnumericdatatype(datatype) ==
                                              AG.GDT_Float32

                                        AG.openmdarrayfromfullname(
                                            root,
                                            "/group/mdarray",
                                        ) do mdarray1
                                            @test !AG.isnull(mdarray1)
                                            @test AG.getfullname(mdarray1) ==
                                                  "/group/mdarray"
                                        end
                                        @test_throws ErrorException AG.openmdarrayfromfullname(
                                            root,
                                            "/group/doesnotexist",
                                        ) do doesnotexist
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
                                        @test_throws ErrorException AG.resolvemdarray(
                                            root,
                                            "doesnotexist",
                                            "",
                                        ) do doesnotexist
                                        end

                                        AG.opengroupfromfullname(
                                            root,
                                            "/group",
                                        ) do group1
                                            @test !AG.isnull(group1)
                                            @test AG.getfullname(group1) ==
                                                  "/group"
                                        end
                                        @test_throws ErrorException AG.opengroupfromfullname(
                                            root,
                                            "/doesnotexist",
                                        ) do doesnotexist
                                        end

                                        data = Array{Float32}(undef, nx, ny)
                                        AG.read!(mdarray, data)
                                        @test data == Float32[
                                            x + 100 * y for x in 1:nx, y in 1:ny
                                        ]

                                        data = AG.read(mdarray)
                                        @test data == Float32[
                                            x + 100 * y for x in 1:nx, y in 1:ny
                                        ]

                                        test_attributes(mdarray)

                                        primes = AG.readmdarray(group, "primes")
                                        @test primes == UInt8[2, 3, 5, 7, 251]

                                        return
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

@testset "test_mdarray.jl: API" begin
    dataset = AG.createmultidimensional(AG.getdriver("MEM"), "api")
    root = AG.getrootgroup(dataset)
    dimx = AG.createdimension(root, "x", "", "", 3)
    dimy = AG.createdimension(root, "y", "", "", 4)
    datatype = AG.extendeddatatypecreate(Float32)
    mdarray = AG.createmdarray(root, "a", [dimx, dimy], datatype)
    data = Float32[x + 10 * y for x in 1:3, y in 1:4]
    AG.write(mdarray, data)

    @testset "DiskArrays" begin
        # MEM arrays are not chunked
        @test AG.getblocksize(mdarray) == (0, 0)
        @test AG.DiskArrays.haschunks(mdarray) isa AG.DiskArrays.Unchunked
        @test mdarray[2, 3] == data[2, 3]
        @test mdarray[:, 2] == data[:, 2]
        @test mdarray[2:3, 2:4] == data[2:3, 2:4]
        @test collect(mdarray) == data
        @test sum(mdarray) == sum(data)
        mdarray[1, 1] = 5
        @test mdarray[1, 1] == 5
        mdarray[:, 2] .= 0
        @test AG.read(mdarray)[:, 2] == zeros(Float32, 3)
        AG.write(mdarray, data)
        @test AG.read(mdarray) == data
    end

    @testset "read! and write" begin
        buffer = zeros(Float32, 2, 2)
        AG.read!(mdarray, CartesianIndices((2:3, 2:3)), buffer)
        @test buffer == data[2:3, 2:3]
        AG.read!(mdarray, (1:2:3, 1:3:4), buffer)
        @test buffer == data[1:2:3, 1:3:4]
        AG.write(mdarray, CartesianIndices((1:2, 1:2)), zeros(Float32, 2, 2))
        @test AG.read(mdarray)[1:2, 1:2] == zeros(Float32, 2, 2)
        AG.write(mdarray, data)
    end

    @testset "properties" begin
        @test AG.getname(mdarray) == "a"
        @test AG.getfullname(mdarray) == "/a"
        @test AG.gettotalelementscount(mdarray) == 12
        @test length(mdarray) == 12
        @test ndims(mdarray) == 2
        @test size(mdarray) == (3, 4)
        @test eltype(mdarray) == Float32
        @test AG.getname.(AG.getdimensions(mdarray)) == ("x", "y")
        @test AG.getdatatype(mdarray) == datatype
        @test AG.getstructuralinfo(mdarray) == []
        @test AG.getprocessingchunksize(mdarray, 1000) == [3, 4]
        @test AG.setunit!(mdarray, "m")
        @test AG.getunit(mdarray) == "m"
        @test AG.setspatialref!(mdarray, AG.importEPSG(4326))
        @test AG.toEPSG(AG.getspatialref(mdarray)) == 4326
    end

    @testset "nodata, offset, scale" begin
        @test AG.getnodatavalue(Float64, mdarray) === nothing
        @test AG.setnodatavalue!(mdarray, -1.0)
        @test AG.getnodatavalue(Float64, mdarray) == -1.0
        @test AG.getnodatavalue(Int64, mdarray) == -1
        @test AG.getrawnodatavalue(mdarray) != C_NULL
        @test AG.getoffset(mdarray) === nothing
        @test AG.getscale(mdarray) === nothing
        @test AG.getoffsetex(mdarray) === nothing
        @test AG.getscaleex(mdarray) === nothing
        @test AG.setoffset!(mdarray, 1.5)
        @test AG.setscale!(mdarray, 2.0, Float32)
        @test AG.getoffset(mdarray) == 1.5
        @test AG.getscaleex(mdarray) == (2.0, Float32)
        AG.getunscaled(mdarray) do unscaled
            @test AG.read(unscaled) == 2 .* data .+ 1.5
        end
    end

    @testset "derived arrays" begin
        # View expressions use GDAL's syntax: 0-based, end-exclusive,
        # and in GDAL's (reversed) axis order
        AG.getview(mdarray, "[1:3,...]") do view
            @test AG.read(view) == data[:, 2:3]
        end
        @test_throws GDAL.GDALError AG.getview(mdarray, "[[invalid")
        # Integer indices are 1-based, in Julia order, and fix the
        # trailing axes
        AG.getview(mdarray, 2) do slice
            @test size(slice) == (3,)
            @test AG.read(slice) == data[:, 2]
        end
        AG.getview(mdarray, 3, 2) do element
            @test ndims(element) == 0
            @test AG.read(element)[] == data[3, 2]
        end
        slice = AG.getview(mdarray, 4)
        @test slice[3] == data[3, 4]
        @test_throws AssertionError AG.getview(mdarray, 0)
        @test_throws AssertionError AG.getview(mdarray, 1, 1, 1)
        @test_throws GDAL.GDALError AG.getview(mdarray, 5)
        # Field access requires a compound data type
        @test_throws GDAL.GDALError AG.getfieldview(mdarray, "it's")
        AG.transpose(mdarray) do transposed
            @test AG.read(transposed) == permutedims(data)
        end
        AG.transpose(mdarray, [1, 2]) do transposed
            @test AG.read(transposed) == data
        end
        AG.getmask(mdarray) do mask
            @test AG.read(mask) == ones(UInt8, 3, 4)
        end
        AG.asclassicdataset(mdarray, 1, 2) do classic
            @test AG.width(classic) == 3
            @test AG.height(classic) == 4
            @test AG.read(AG.getband(classic, 1)) == data
        end
        @test AG.getcoordinatevariables(mdarray) == []
    end

    @testset "statistics" begin
        err, min, max, mean, stddev, count =
            AG.getstatistics(mdarray, false, true)
        @test err == GDAL.CE_None
        @test (min, max, count) == (11, 43, 12)
        @test mean ≈ 27
        success, min, max, mean, stddev, count =
            AG.computestatistics(mdarray, false)
        @test success
        @test (min, max, count) == (11, 43, 12)
        @test AG.adviseread(mdarray, nothing, nothing)
        @test AG.adviseread(mdarray, (1, 1), (2, 2))
    end

    @testset "indexing variables" begin
        xvar = AG.createmdarray(
            root,
            "xvar",
            [dimx],
            AG.extendeddatatypecreate(Float64),
        )
        AG.write(xvar, [0.0, 1.0, 2.0])
        yvar = AG.createmdarray(
            root,
            "yvar",
            [dimy],
            AG.extendeddatatypecreate(Float64),
        )
        AG.write(yvar, [0.0, 1.0, 2.0, 3.0])
        @test AG.getindexingvariable(dimx) === nothing
        AG.setindexingvariable!(dimx, xvar)
        AG.setindexingvariable!(dimy, yvar)
        @test AG.getname(AG.getindexingvariable(dimx)) == "xvar"
        AG.getindexingvariable(dimy) do indexingvariable
            @test AG.getname(indexingvariable) == "yvar"
        end

        AG.subsetdimensionfromselection(root, "/xvar=1") do subset
            AG.openmdarray(subset, "a") do subarray
                @test AG.read(subarray) == data[2:2, :]
            end
        end
        AG.getresampled(
            mdarray,
            nothing,
            GDAL.GRIORA_NearestNeighbour,
            nothing,
        ) do resampled
            # GDAL orients the y axis north-up
            @test AG.read(resampled) == data[:, end:-1:1]
        end
    end

    @testset "attributes" begin
        AG.writeattribute(mdarray, "values", Float64[1, 2, 3])
        AG.writeattribute(mdarray, "string", "hello")
        attribute = AG.getattribute(mdarray, "values")
        @test AG.read(attribute) == [1, 2, 3]
        @test AG.getdimensionssize(attribute) == (3,)
        @test length(AG.readasraw(attribute)) == 3 * sizeof(Float64)
        @test AG.getname(attribute) == "values"
        @test AG.getfullname(attribute) == "/a/values"
        @test length(attribute) == 3
        @test ndims(attribute) == 1
        @test AG.getclass(AG.getdatatype(attribute)) == GDAL.GEDTC_NUMERIC
        @test AG.rename!(attribute, "numbers")
        @test sort(AG.getname.(AG.getattributes(mdarray))) ==
              ["numbers", "string"]
        @test AG.deleteattribute(mdarray, "string")
        @test AG.getname.(AG.getattributes(mdarray)) == ["numbers"]

        # Attribute sizes are given in Julia order, for arrays and groups
        for location in (mdarray, root)
            AG.extendeddatatypecreate(Int16) do int16
                AG.createattribute(location, "matrix", [2, 3], int16) do matrix
                    @test AG.getdimensionssize(matrix) == (2, 3)
                    @test AG.writeraw(matrix, zeros(UInt8, 6 * sizeof(Int16)))
                    @test AG.readasraw(matrix) == zeros(UInt8, 12)
                end
            end
            @test AG.deleteattribute(location, "matrix")
        end
    end

    @testset "renaming and groups" begin
        @test AG.rename!(dimy, "yy")
        @test AG.getname(dimy) == "yy"
        group = AG.creategroup(root, "group")
        @test AG.rename!(group, "renamed")
        @test AG.getfullname(group) == "/renamed"
        @test AG.getname(AG.opengroupfromfullname(root, "/renamed")) ==
              "renamed"
        @test AG.rename!(mdarray, "b")
        @test AG.getname(AG.openmdarrayfromfullname(root, "/b")) == "b"
        @test AG.getname(AG.resolvemdarray(root, "b", "")) == "b"
        @test AG.deletegroup(root, "renamed")
        @test AG.getgroupnames(root) == []
    end

    @testset "resize!" begin
        dimr = AG.createdimension(root, "r", "", "", 2)
        resizable = AG.createmdarray(
            root,
            "resizable",
            [dimr],
            AG.extendeddatatypecreate(Int32),
        )
        @test AG.resize!(resizable, [5])
        @test size(resizable) == (5,)
    end

    @testset "extended data types" begin
        stringtype = AG.extendeddatatypecreatestring(10)
        @test AG.getclass(datatype) == GDAL.GEDTC_NUMERIC
        @test AG.getnumericdatatype(datatype) == AG.GDT_Float32
        @test AG.getsize(datatype) == 4
        @test AG.getclass(stringtype) == GDAL.GEDTC_STRING
        @test AG.getmaxstringlength(stringtype) == 10
        @test AG.getsubtype(stringtype) == GDAL.GEDTST_NONE
        @test datatype != stringtype
        @test AG.canconvertto(datatype, stringtype)
        @test AG.getcomponents(datatype) == []
    end

    @testset "rasterband as mdarray" begin
        AG.create(
            AG.getdriver("MEM");
            width = 2,
            height = 3,
            nbands = 1,
            dtype = UInt8,
        ) do classic
            AG.asmdarray(AG.getband(classic, 1)) do band
                @test size(band) == (2, 3)
                @test eltype(band) == UInt8
            end
        end
    end

    @test AG.flushcache!(dataset) == GDAL.CE_None
    @test AG.force_close_mdarray_dataset!(dataset) === nothing
    @test AG.isnull(mdarray)
end

@testset "test_mdarray.jl: cache" begin
    # Caching requires an array stored in a file
    filename = tempname() * ".nc"
    AG.createmultidimensional(AG.getdriver("netCDF"), filename) do dataset
        AG.getrootgroup(dataset) do root
            AG.createdimension(root, "z", "", "", 2) do dimz
                AG.extendeddatatypecreate(Int16) do datatype
                    AG.createmdarray(root, "m", [dimz], datatype) do mdarray
                        AG.write(mdarray, Int16[1, 2])
                        @test AG.cache(mdarray)
                    end
                end
            end
        end
    end
    rm(filename; force = true)
end

@testset "test_mdarray.jl: openmultidimensional" begin
    filename = tempname() * ".nc"
    AG.createmultidimensional(AG.getdriver("netCDF"), filename) do dataset
        AG.getrootgroup(dataset) do root
            AG.writemdarray(root, "values", Float32[1, 2, 3])
            return nothing
        end
    end

    # Opening for writing tracks interactive children, so that the
    # file is complete after `force_close_mdarray_dataset!`
    dataset = AG.openmultidimensional(filename; update = true)
    @test dataset.children !== nothing
    root = AG.getrootgroup(dataset)
    mdarray = AG.openmdarray(root, "values")
    mdarray[2] = 20
    @test AG.force_close_mdarray_dataset!(dataset) === nothing
    @test AG.isnull(root)
    @test AG.isnull(mdarray)

    AG.openmultidimensional(filename; alloweddrivers = ["netCDF"]) do dataset
        @test dataset.children === nothing
        AG.getrootgroup(dataset) do root
            @test AG.readmdarray(root, "values") == Float32[1, 20, 3]
        end
    end

    # Tracking can be enabled explicitly, and plain integer flags work
    AG.openmultidimensional(
        filename;
        flags = Int(AG.OF_VERBOSE_ERROR),
        hard_close = true,
    ) do dataset
        @test dataset.children !== nothing
    end

    # Other drivers are rejected when requested
    @test_throws GDAL.GDALError AG.openmultidimensional(
        filename;
        alloweddrivers = ["Zarr"],
    )
    rm(filename; force = true)
end
