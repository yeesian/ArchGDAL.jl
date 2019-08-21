"""
Invert Geotransform.

This function will invert a standard 3x2 set of GeoTransform coefficients. This
converts the equation from being pixel to geo to being geo to pixel.

### Parameters
* `gt_in`       Input geotransform (six doubles - unaltered).
* `gt_out`      Output geotransform (six doubles - updated).

### Returns
`gt_out`
"""
function invgeotransform!(gt_in::Vector{Cdouble}, gt_out::Vector{Cdouble})
    result = Bool(GDAL.gdalinvgeotransform(pointer(gt_in), pointer(gt_out)))
    result || error("Geotransform coefficients is uninvertable")
    gt_out
end

invgeotransform(gt_in::Vector{Cdouble}) =
    invgeotransform!(gt_in, Array{Cdouble}(undef, 6))

"""
Apply GeoTransform to x/y coordinate.

Applies the following computation, converting a (pixel,line) coordinate into a
georeferenced `(geo_x,geo_y)` location.
```
    geo_x = geotransform[1] + pixel*geotransform[2] + line*geotransform[3]
    geo_y = geotransform[4] + pixel*geotransform[5] + line*geotransform[6]
```
### Parameters
* `geotransform`  Six coefficient GeoTransform to apply.
* `pixel`           input pixel position.
* `line`            input line position.
"""
function applygeotransform(
        geotransform::Vector{Cdouble},
        pixel::Cdouble,
        line::Cdouble
    )
    geo_xy = Array{Cdouble}(undef, 2)
    geo_x = pointer(geo_xy)
    geo_y = geo_x + sizeof(Cdouble)
    GDAL.gdalapplygeotransform(pointer(geotransform), pixel, line, geo_x, geo_y)
    geo_xy
end 

"""
Compose two geotransforms.

The resulting geotransform is the equivelent to `padfGT1` and then `padfGT2`
being applied to a point.

### Parameters
* `gt1`     the first geotransform, six values.
* `gt2`     the second geotransform, six values.
* `gtout`   the output geotransform, six values, may safely be the same
array as `gt1` or `gt2`.
"""
function composegeotransform!(
        gt1::Vector{Cdouble},
        gt2::Vector{Cdouble},
        gtout::Vector{Cdouble}
    )
    GDAL.gdalcomposegeotransform(pointer(gt1), pointer(gt2), pointer(gtout))
    gtout
end

composegeotransform(gt1::Vector{Cdouble}, gt2::Vector{Cdouble}) =
    composegeotransform!(gt1, gt2, Array{Cdouble}(undef, 6))
