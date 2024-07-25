using Test
import ArchGDAL as AG

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
        @test AG.writeattribute(loc, name, name)
    end
    for T in attribute_types
        @test AG.writeattribute(loc, "$T", get_attribute_value(T))
    end
    return nothing
end
function test_attributes(loc::Union{AG.AbstractGroup,AG.AbstractMDArray})
    for name in attribute_names
        @test isequal(AG.readattribute(loc, name), name)
        if !isequal(AG.readattribute(loc, name), name)
            @show loc name
            @assert false
        end
    end
    for T in attribute_types
        @test isequal(AG.readattribute(loc, "$T"), get_attribute_value(T))
        if !isequal(AG.readattribute(loc, "$T"), get_attribute_value(T))
            @show loc T
            @assert false
        end
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

                write_attributes(group)

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

                write_attributes(mdarray)

                success =
                    AG.writemdarray(group, "primes", UInt8[2, 3, 5, 7, 251])
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
                @test AG.getclass(datatype) == GDAL.GEDTC_NUMERIC
                @test AG.getnumericdatatype(datatype) == AG.GDT_Float32

                data = Array{Float32}(undef, ny, nx)
                success = AG.read!(mdarray, data)
                @test success
                @test data == Float32[100 * x + y for y in 1:ny, x in 1:nx]

                data = AG.read(mdarray)
                @test data !== nothing
                @test data == Float32[100 * x + y for y in 1:ny, x in 1:nx]

                test_attributes(mdarray)

                primes = AG.readmdarray(group, "primes")
                @test primes == UInt8[2, 3, 5, 7, 251]

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

                        write_attributes(group)

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

                                        write_attributes(mdarray)

                                        success = AG.writemdarray(
                                            group,
                                            "primes",
                                            UInt8[2, 3, 5, 7, 251],
                                        )
                                        @test success

                                        return
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
                                            @test AG.isnull(xvar)
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

                                        data = AG.read(mdarray)
                                        @test data !== nothing
                                        @test data == Float32[
                                            100 * x + y for y in 1:ny, x in 1:nx
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
