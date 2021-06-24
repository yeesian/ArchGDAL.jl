# ArchGDAL.jl unit tests

This package uses the [standard library for unit testing](https://docs.julialang.org/en/v1/stdlib/Test/). To run the suite of tests in this directory,

```julia
pkg> test ArchGDAL
```

## Working with Data

In general, we prefer for unit tests to be written independently of the need for data to be fetched from remote files.

If you are introducing data to be used for unit testing, please be mindful for it to be released under an appropriate license, and for it to be pared down into a sufficiently small file that still exercises the corresponding logic to be tested.

The data used for testing in this package are fetched from https://github.com/yeesian/ArchGDALDatasets in [remotefiles.jl](https://github.com/yeesian/ArchGDAL.jl/blob/master/test/remotefiles.jl).

To add a file, please upload it to that repository with the corresponding license, and follow the below steps to generate the SHA:

```julia
julia> using SHA
julia> open(filepath/filename) do f
           bytes2hex(sha256(f))
       end
```
