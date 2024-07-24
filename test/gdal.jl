using Test
import ArchGDAL as AG

using GDAL

# using GDAL_jll
# `$(GDAL_jll.gdalinfo_path()) --format Zarr` |> run
# `$(GDAL_jll.gdalmdiminfo_exe()) data.zarr` |> run

function check_last_error()
    error = GDAL.cplgetlasterrormsg()
    isempty(error) && return nothing
    println(error)
    throw(ErrorException(error))
    return nothing
end

function make_data()
    ndishes = 64
    npolarizations = 2
    #TODO nfrequencies = 384
    #TODO ntimes = 8192
    #TODO data = Float32[
    #TODO     1000 * t + 100 * f + 10 * p + 1 * d for d in 0:(ndishes - 1), p in 0:(npolarizations - 1), f in 0:(nfrequencies - 1),
    #TODO     t in 0:(ntimes - 1)
    #TODO ]
    data = Float32[
        10 * p + 1 * d for d in 0:(ndishes-1), p in 0:(npolarizations-1)
    ]
    return data
end

function write_attribute(
    mdarrayh::GDAL.GDALMDArrayH,
    name::AbstractString,
    value::AbstractString,
)
    datatypeh = GDAL.gdalextendeddatatypecreatestring(length(value))
    check_last_error()
    @assert datatypeh != C_NULL
    attributeh = GDAL.gdalmdarraycreateattribute(
        mdarrayh,
        name,
        0,
        C_NULL,
        datatypeh,
        C_NULL,
    )
    check_last_error()
    @assert attributeh != C_NULL
    noerr = GDAL.gdalattributewritestring(attributeh, value)
    check_last_error()
    @assert noerr == true
    GDAL.gdalattributerelease(attributeh)
    check_last_error()
    GDAL.gdalextendeddatatyperelease(datatypeh)
    check_last_error()
    return nothing
end

function write_attribute(
    mdarrayh::GDAL.GDALMDArrayH,
    name::AbstractString,
    value::Integer,
)
    datatypeh = GDAL.gdalextendeddatatypecreate(GDAL.GDT_Int64)
    check_last_error()
    @assert datatypeh != C_NULL
    attributeh = GDAL.gdalmdarraycreateattribute(
        mdarrayh,
        name,
        0,
        C_NULL,
        datatypeh,
        C_NULL,
    )
    check_last_error()
    @assert attributeh != C_NULL
    noerr =
        GDAL.gdalattributewriteraw(attributeh, Ref(Int64(value)), sizeof(Int64))
    check_last_error()
    @assert noerr == true
    GDAL.gdalattributerelease(attributeh)
    check_last_error()
    GDAL.gdalextendeddatatyperelease(datatypeh)
    check_last_error()
    return nothing
end

function write_attribute(
    mdarrayh::GDAL.GDALMDArrayH,
    name::AbstractString,
    value::Real,
)
    datatypeh = GDAL.gdalextendeddatatypecreate(GDAL.GDT_Float64)
    check_last_error()
    @assert datatypeh != C_NULL
    attributeh = GDAL.gdalmdarraycreateattribute(
        mdarrayh,
        name,
        0,
        C_NULL,
        datatypeh,
        C_NULL,
    )
    check_last_error()
    @assert attributeh != C_NULL
    noerr = GDAL.gdalattributewriteraw(
        attributeh,
        Ref(Float64(value)),
        sizeof(Float64),
    )
    check_last_error()
    @assert noerr == true
    GDAL.gdalattributerelease(attributeh)
    check_last_error()
    GDAL.gdalextendeddatatyperelease(datatypeh)
    check_last_error()
    return nothing
end

function write_attribute(
    mdarrayh::GDAL.GDALMDArrayH,
    name::AbstractString,
    values::AbstractArray{<:Integer},
)
    datatypeh = GDAL.gdalextendeddatatypecreate(GDAL.GDT_Int64)
    check_last_error()
    @assert datatypeh != C_NULL
    rank = ndims(values)
    sizes = collect(GDAL.GUInt64.(reverse(size(values))))
    attributeh = GDAL.gdalmdarraycreateattribute(
        mdarrayh,
        name,
        rank,
        sizes,
        datatypeh,
        C_NULL,
    )
    check_last_error()
    @assert attributeh != C_NULL
    noerr = GDAL.gdalattributewriteraw(
        attributeh,
        Int64.(values),
        sizeof(Int64) * length(values),
    )
    check_last_error()
    @assert noerr == true
    GDAL.gdalattributerelease(attributeh)
    check_last_error()
    GDAL.gdalextendeddatatyperelease(datatypeh)
    check_last_error()
    return nothing
end

function write_attribute(
    mdarrayh::GDAL.GDALMDArrayH,
    name::AbstractString,
    values::AbstractArray{<:Real},
)
    datatypeh = GDAL.gdalextendeddatatypecreate(GDAL.GDT_Float64)
    check_last_error()
    @assert datatypeh != C_NULL
    rank = ndims(values)
    sizes = collect(GDAL.GUInt64.(reverse(size(values))))
    attributeh = GDAL.gdalmdarraycreateattribute(
        mdarrayh,
        name,
        rank,
        sizes,
        datatypeh,
        C_NULL,
    )
    check_last_error()
    @assert attributeh != C_NULL
    noerr = GDAL.gdalattributewriteraw(
        attributeh,
        Float64.(values),
        sizeof(Float64) * length(values),
    )
    check_last_error()
    @assert noerr == true
    GDAL.gdalattributerelease(attributeh)
    check_last_error()
    GDAL.gdalextendeddatatyperelease(datatypeh)
    check_last_error()
    return nothing
end

function read_attribute(mdarrayh::GDAL.GDALMDArrayH, name::AbstractString)
    attributeh = GDAL.gdalmdarraygetattribute(mdarrayh, name)
    check_last_error()
    @assert attributeh != C_NULL
    datatypeh = GDAL.gdalattributegetdatatype(attributeh)
    check_last_error()
    dimensioncount = GDAL.gdalattributegetdimensioncount(attributeh)
    check_last_error()
    @assert dimensioncount in (0, 1)
    class = GDAL.gdalextendeddatatypegetclass(datatypeh)
    check_last_error()
    if class === GDAL.GEDTC_STRING
        @assert dimensioncount == 0
        value = GDAL.gdalattributereadasstring(attributeh)
        value::AbstractString
    elseif class === GDAL.GEDTC_NUMERIC
        attributesizeref = Ref(~Csize_t(0))
        valueptr = GDAL.gdalattributereadasraw(attributeh, attributesizeref)
        numericdatatype = GDAL.gdalextendeddatatypegetnumericdatatype(datatypeh)
        check_last_error()
        if numericdatatype === GDAL.GDT_Int64
            @assert attributesizeref[] % sizeof(Int64) == 0
            nvalues = attributesizeref[] ÷ sizeof(Int64)
            if dimensioncount == 0
                @assert nvalues == 1
                value = unsafe_load(Ptr{Int64}(valueptr))
                value::Int64
            else
                value =
                    [unsafe_load(Ptr{Int64}(valueptr), n) for n in 1:nvalues]
                value::Vector{Int64}
            end
        elseif numericdatatype === GDAL.GDT_Float64
            @assert attributesizeref[] % sizeof(Float64) == 0
            nvalues = attributesizeref[] ÷ sizeof(Float64)
            if dimensioncount == 0
                @assert nvalues == 1
                value = unsafe_load(Ptr{Float64}(valueptr))
                value::Float64
            else
                value =
                    [unsafe_load(Ptr{Float64}(valueptr), n) for n in 1:nvalues]
                value::Vector{Float64}
            end
        else
            @assert false
        end
        GDAL.gdalattributefreerawresult(
            attributeh,
            valueptr,
            attributesizeref[],
        )
        check_last_error()
    else
        @assert false
    end
    GDAL.gdalextendeddatatyperelease(datatypeh)
    check_last_error()
    GDAL.gdalattributerelease(attributeh)
    check_last_error()
    return value
end

function setup()
    version = GDAL.gdalversioninfo("")
    println(version)

    # ndrivers = GDAL.gdalgetdrivercount()
    # println("GDAL drivers:")
    # for driver in 0:ndrivers-1
    #     driverh = GDAL.gdalgetdriver(driver)
    #     drivershortname = GDAL.gdalgetdrivershortname(driverh)
    #     println("$driver: $drivershortname")
    # end

    return nothing
end

function create_file(drivername::AbstractString, path::AbstractString)
    println("Creating file \"$(path)\" via $(drivername) driver...")

    # driverh = GDAL.gdalgetdriverbyname(drivername)
    # check_last_error()
    # @assert driverh != C_NULL

    driver = AG.getdriver(drivername)
    check_last_error()
    @assert !AG.isnull(driver)

    # driverlongname = GDAL.gdalgetdriverlongname(driverh)

    # drivercreationoptionlist = GDAL.gdalgetdrivercreationoptionlist(driverh)
    # println(drivercreationoptionlist)

    rm(path; force = true, recursive = true)

    rootgroupoptions = String[]
    if drivername == "HDF5"
        createoptions = ["FORMAT=NC4"]
    elseif drivername == "netCDF"
        createoptions = ["FORMAT=NC4"]
    elseif drivername == "Zarr"
        createoptions = ["FORMAT=ZARR_V3"]
    else
        @assert false
        createoptions = String[]
    end
    # rootgroupoptionptrs = Cstring[[pointer(opt) for opt in rootgroupoptions]; Cstring(C_NULL)]
    # createoptionptrs = Cstring[[pointer(opt) for opt in createoptions]; Cstring(C_NULL)]
    # dataseth = GDAL.gdalcreatemultidimensional(driverh, path, rootgroupoptionptrs, createoptionptrs)
    # check_last_error()
    # @assert dataseth != C_NULL

    dataset =
        AG.createmultidimensional(driver, path, rootgroupoptions, createoptions)
    @show typeof(dataset)
    @show dataset
    check_last_error()
    @assert !AG.isnull(dataset)

    # grouph = GDAL.gdaldatasetgetrootgroup(dataset.ptr)
    # check_last_error()
    # @assert grouph != C_NULL

    group = AG.getrootgroup(dataset)
    check_last_error()
    @assert !AG.isnull(group)

    data = make_data()
    #TODO dimensionnames = ["D", "P", "F", "T"]
    dimensionnames = ["D", "P"]
    @assert length(dimensionnames) == ndims(data)

    datatypeh = GDAL.gdalextendeddatatypecreate(GDAL.GDT_Float32)
    check_last_error()
    @assert datatypeh != C_NULL

    dimensionhs = GDAL.GDALDimensionH[
        let
            dimh = GDAL.gdalgroupcreatedimension(
                group.ptr,
                dimensionnames[d],
                "UNUSED",
                "UNUSED",
                size(data, d),
                GDAL.CSLConstList(),
            )
            check_last_error()
            @assert dimh != C_NULL
            dimh
        end for d in ndims(data):-1:1
    ]

    # blocksize = join(reverse(size(data)), ",")
    blocksize = "8192,1,2,64"
    if drivername == "Zarr"
        #TODO arrayoptions = ["COMPRESS=BLOSC", "BLOCKSIZE=$(blocksize)", "BLOSC_CLEVEL=9", "BLOSC_SHUFFLE=BIT"]
        arrayoptions = []
    elseif drivername == "netCDF"
        #TODO arrayoptions = ["COMPRESS=DEFLATE", "BLOCKSIZE=$(blocksize)", "ZLEVEL=9"]
        arrayoptions = []
    else
        @assert false
        arrayoptions = []
    end
    arrayoptionptrs =
        Cstring[[pointer(opt) for opt in arrayoptions]; Cstring(C_NULL)]

    mdarrayh = GDAL.gdalgroupcreatemdarray(
        group.ptr,
        "data",
        length(dimensionhs),
        dimensionhs,
        datatypeh,
        arrayoptionptrs,
    )
    check_last_error()
    @assert mdarrayh != C_NULL

    # write_attribute(mdarrayh, "string_attribute", "hello, world!")
    # write_attribute(mdarrayh, "int_attribute", 42)
    # write_attribute(mdarrayh, "float_attribute", pi)
    # write_attribute(mdarrayh, "int_array_attribute", [1, 2, 3])
    # write_attribute(mdarrayh, "float_array_attribute", [1.1, 1.2, 1.3])
    # write_attribute(mdarrayh, "large_array_attribute", collect(1:1000))

    noerr = GDAL.gdalmdarraywrite(
        mdarrayh,
        #TODO GDAL.GUIntBig[0, 0, 0, 0],
        GDAL.GUIntBig[0, 0],
        GDAL.GUIntBig[size(data, d) for d in ndims(data):-1:1],
        C_NULL,
        C_NULL,
        datatypeh,
        data,
        data,
        sizeof(data),
    )
    check_last_error()
    @assert noerr == true

    # GDAL.gdalmdarrayrelease(mdarrayh)
    # check_last_error()

    # GDAL.gdaldimensionrelease.(dimensionhs)
    # check_last_error()

    # GDAL.gdalextendeddatatyperelease(datatypeh)
    # check_last_error()

    # GDAL.gdalgrouprelease(group.ptr)
    # check_last_error()
    # group.ptr = C_NULL

    # AG.destroy(group)

    # err = GDAL.gdalclose(dataset.ptr)
    # check_last_error()
    # @assert err === GDAL.CE_None

    err = AG.close(dataset)
    check_last_error()
    @assert err === GDAL.CE_None

    AG.destroy(group)

    return nothing
end

function read_file(path::AbstractString)
    println("Reading file \"$(path)\"...")

    dataseth = GDAL.gdalopenex(
        path,
        GDAL.GDAL_OF_MULTIDIM_RASTER |
        GDAL.GDAL_OF_READONLY |
        GDAL.GDAL_OF_SHARED |
        GDAL.GDAL_OF_VERBOSE_ERROR,
        C_NULL,
        C_NULL,
        C_NULL,
    )
    check_last_error()
    @assert dataseth != C_NULL

    # info = GDAL.gdalinfo(dataseth, C_NULL)
    # println("Info:\n", info)

    # multidiminfo = GDAL.gdalmultidiminfo(dataseth, C_NULL)
    # println("Info:\n", multidiminfo)

    grouph = GDAL.gdaldatasetgetrootgroup(dataseth)
    check_last_error()
    @assert grouph != C_NULL

    arraynames = GDAL.gdalgroupgetmdarraynames(grouph, C_NULL)
    check_last_error()
    println("Array names:")
    for arrayname in arraynames
        println("    \"$(arrayname)\"")
    end

    mdarrayh = GDAL.gdalgroupopenmdarray(grouph, "data", GDAL.CSLConstList())
    check_last_error()
    @assert mdarrayh != C_NULL

    attributescountref = Ref(~Csize_t(0))
    attributehptr =
        GDAL.gdalmdarraygetattributes(mdarrayh, attributescountref, C_NULL)
    check_last_error()
    attributehs = GDAL.GDALAttributeH[
        unsafe_load(attributehptr, d) for d in 1:attributescountref[]
    ]

    attributenames = [
        let
            name = GDAL.gdalattributegetname(attrh)
            check_last_error()
            name
        end for attrh in attributehs
    ]
    println("Attribute names:")
    for name in attributenames
        println("    $(name)")
    end

    GDAL.gdalreleaseattributes(attributehptr, attributescountref[])
    check_last_error()

    # @assert read_attribute(mdarrayh, "string_attribute") == "hello, world!"
    # # Zarr stores Int64 attributes as Float64 because JSON...
    # @assert read_attribute(mdarrayh, "int_attribute") == 42
    # @assert read_attribute(mdarrayh, "float_attribute") === Float64(pi)
    # @assert read_attribute(mdarrayh, "int_array_attribute") == [1, 2, 3]
    # @assert read_attribute(mdarrayh, "float_array_attribute") == [1.1, 1.2, 1.3]
    # @assert read_attribute(mdarrayh, "large_array_attribute") == 1:1000

    datatypeh = GDAL.gdalmdarraygetdatatype(mdarrayh)
    check_last_error()
    @assert datatypeh != C_NULL

    class = GDAL.gdalextendeddatatypegetclass(datatypeh)
    check_last_error()
    @assert class === GDAL.GEDTC_NUMERIC

    numericdatatype = GDAL.gdalextendeddatatypegetnumericdatatype(datatypeh)
    check_last_error()
    @assert numericdatatype === GDAL.GDT_Float32

    totalelementscount = GDAL.gdalmdarraygettotalelementscount(mdarrayh)
    check_last_error()
    println("Total elements: $(totalelementscount)")

    dimensioncount = GDAL.gdalmdarraygetdimensioncount(mdarrayh)
    check_last_error()
    println("Rank: $(dimensioncount)")

    dimensionscountref = Ref(~Csize_t(0))
    dimensionhptr = GDAL.gdalmdarraygetdimensions(mdarrayh, dimensionscountref)
    check_last_error()
    dimensionhs = GDAL.GDALDimensionH[
        unsafe_load(dimensionhptr, d) for d in 1:dimensionscountref[]
    ]
    @assert length(dimensionhs) == dimensioncount

    dimensionnames = [
        let
            name = GDAL.gdaldimensiongetname(dimh)
            check_last_error()
            name
        end for dimh in reverse(dimensionhs)
    ]
    println("Dimension names: $(dimensionnames)")

    # for dimh in dimensionhs
    #     @show GDAL.gdaldimensiongetfullname(dimh)
    # end
    # for dimh in dimensionhs
    #     @show GDAL.gdaldimensiongettype(dimh)
    # end
    # for dimh in dimensionhs
    #     @show GDAL.gdaldimensiongetdirection(dimh)
    # end

    sizes = Int[
        let
            size = GDAL.gdaldimensiongetsize(dimh)
            check_last_error()
            size
        end for dimh in reverse(dimensionhs)
    ]
    println("Size: $(sizes)")
    @assert prod(sizes) == totalelementscount

    data = Array{Float32}(undef, sizes...)

    noerr = GDAL.gdalmdarrayread(
        mdarrayh,
        GDAL.GUIntBig[0, 0, 0, 0],
        GDAL.GUIntBig[size(data, d) for d in ndims(data):-1:1],
        C_NULL,
        C_NULL,
        datatypeh,
        data,
        data,
        sizeof(data),
    )
    check_last_error()
    @assert noerr == true

    good_data = make_data()
    @assert data == good_data

    GDAL.gdalmdarrayrelease(mdarrayh)
    check_last_error()
    GDAL.gdalreleasedimensions(dimensionhptr, dimensionscountref[])
    check_last_error()
    GDAL.gdalextendeddatatyperelease(datatypeh)
    check_last_error()
    GDAL.gdalgrouprelease(grouph)
    check_last_error()

    err = GDAL.gdalclose(dataseth)
    check_last_error()
    @assert err === GDAL.CE_None

    return nothing
end

function main()
    println("Experiment with Zarr files via the GDAL library")
    drivername = "netCDF"
    path = "/tmp/dataset.nc"
    # drivername = "HDF5"
    # path = "/tmp/dataset.h5"
    # drivername = "Zarr"
    # path = "/tmp/dataset.zarr"
    setup()
    create_file(drivername, path)
    read_file(path)
    println("Done.")
    return nothing
end

main()
