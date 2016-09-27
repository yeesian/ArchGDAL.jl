## Installation
This package is currently unregistered, so add it using `Pkg.clone`, then find or get the GDAL dependencies using `Pkg.build`:

```julia
Pkg.clone("https://github.com/visr/GDAL.jl.git")
Pkg.build("GDAL")
Pkg.clone("https://github.com/yeesian/ArchGDAL.jl.git")
```

`Pkg.build("GDAL")` searches for a GDAL 2.1+ shared library on the path. If not found, it will download and install it. To test if it is installed correctly, use:

```julia
Pkg.test("GDAL")
Pkg.test("ArchGDAL")
```
