using Test, Documenter, ArchGDAL
DocMeta.setdocmeta!(ArchGDAL, :DocTestSetup, :(using ArchGDAL, GDAL); recursive=true)
doctest(ArchGDAL)
