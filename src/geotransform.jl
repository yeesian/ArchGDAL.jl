"""
    invgeotransform!(gt_in::Vector{Float64}, gt_out::Vector{Float64})

Invert Geotransform.

This function will invert a standard 3x2 set of GeoTransform coefficients. This
converts the equation from being pixel to geo to being geo to pixel.

### Parameters
* `gt_in`       Input geotransform (six doubles - unaltered).
* `gt_out`      Output geotransform (six doubles - updated).

### Returns
`gt_out`
"""
function invgeotransform!(
        gt_in::Vector{Float64},
        gt_out::Vector{Float64}
    )::Vector{Float64}
    result = Bool(GDAL.gdalinvgeotransform(pointer(gt_in), pointer(gt_out)))
    result || error("Geotransform coefficients is uninvertable")
    return gt_out
end

invgeotransform(gt_in::Vector{Float64})::Vector{Float64} =
    invgeotransform!(gt_in, Array{Float64}(undef, 6))

"""
    applygeotransform(geotransform::Vector{Float64}, pixel::Float64,
        line::Float64)

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
        geotransform::Vector{Float64},
        pixel::Float64,
        line::Float64
    )::Vector{Float64}
    geo_xy = Vector{Float64}(undef, 2)
    geo_x = pointer(geo_xy)
    geo_y = geo_x + sizeof(Float64)
    GDAL.gdalapplygeotransform(pointer(geotransform), pixel, line, geo_x, geo_y)
    return geo_xy
end

"""
    composegeotransform!(gt1::Vector{Float64}, gt2::Vector{Float64},
        gtout::Vector{Float64})

Compose two geotransforms.

The resulting geotransform is the equivalent to `padfGT1` and then `padfGT2`
being applied to a point.

### Parameters
* `gt1`     the first geotransform, six values.
* `gt2`     the second geotransform, six values.
* `gtout`   the output geotransform, six values.
"""
function composegeotransform!(
        gt1::Vector{Float64},
        gt2::Vector{Float64},
        gtout::Vector{Float64}
    )::Vector{Float64}
    GDAL.gdalcomposegeotransforms(pointer(gt1), pointer(gt2), pointer(gtout))
    return gtout
end

function composegeotransform(
        gt1::Vector{Float64},
        gt2::Vector{Float64}
    )::Vector{Float64}
    return composegeotransform!(gt1, gt2, Vector{Float64}(undef, 6))
end
