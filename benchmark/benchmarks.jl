using BenchmarkTools
using ZipFile
using ArchGDAL;
const AG = ArchGDAL;
using Tables
using Shapefile

include("remotefiles.jl")

const SUITE = BenchmarkGroup()

SUITE["shapefile_to_table"] = BenchmarkGroup()

# Data preparation
road_shapefile_ziparchive = joinpath(@__DIR__, "data/road.zip")
road_shapefile_dir = splitext(road_shapefile_ziparchive)[1]
!isdir(road_shapefile_dir) && mkdir(road_shapefile_dir)
ziparchive = ZipFile.Reader(road_shapefile_ziparchive)
for file in ziparchive.files
    extracted_file = joinpath(road_shapefile_dir, file.name)
    !isfile(extracted_file) && write(extracted_file, read(file))
end
close(ziparchive)
road_shapefile_file =
    joinpath(road_shapefile_dir, splitpath(road_shapefile_dir)[end] * ".shp")

# Benchmarks
SUITE["shapefile_to_table"]["frenchroads_ArchGDAL_vsizip"] =
    @benchmarkable Tables.columntable(
        AG.getlayer(AG.read("/vsizip/" * relpath($road_shapefile_ziparchive))), # relpath is a workaround in case there are spaces in local fullpath (incompatible with /vsizip usage) when benchmarkpkg is run locally
    )
SUITE["shapefile_to_table"]["frenchroads_ArchGDAL"] =
    @benchmarkable Tables.columntable(AG.getlayer(AG.read($road_shapefile_file), 0))
SUITE["shapefile_to_table"]["frenchroads_ArchGDAL_new_Tables_interface_vsizip"] =
    @benchmarkable Tables.columntable(
        AG.Table(AG.read("/vsizip/" * relpath($road_shapefile_ziparchive))), # relpath is a workaround in case there are spaces in local fullpath (incompatible with /vsizip usage) when benchmarkpkg is run locally
    )
SUITE["shapefile_to_table"]["frenchroads_ArchGDAL_new_Tables_interface"] =
    @benchmarkable Tables.columntable(AG.Table($road_shapefile_file))
SUITE["shapefile_to_table"]["frenchroads_Shapefile"] =
    @benchmarkable begin
        Tables.columntable(Shapefile.Table($road_shapefile_file))
    end
