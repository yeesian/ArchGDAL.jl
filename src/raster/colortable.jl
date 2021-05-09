"""
    unsafe_createcolortable(palette::GDALPaletteInterp)

Construct a new color table.
"""
unsafe_createcolortable(palette::GDALPaletteInterp)::ColorTable =
    ColorTable(GDAL.gdalcreatecolortable(palette))

"Destroys a color table."
function destroy(ct::ColorTable)::Nothing
    GDAL.gdaldestroycolortable(ct.ptr)
    ct.ptr = C_NULL
    return nothing
end

"""
    unsafe_clone(ct::ColorTable)

Make a copy of a color table.
"""
function unsafe_clone(ct::ColorTable)::ColorTable
    return if ct.ptr == C_NULL
        ColorTable(C_NULL)
    else
        ColorTable(GDAL.gdalclonecolortable(ct.ptr))
    end
end

"""
    paletteinterp(ct::ColorTable)

Fetch palette interpretation.

### Returns
palette interpretation enumeration value, usually `GPI_RGB`.
"""
paletteinterp(ct::ColorTable)::GDALPaletteInterp =
    GDAL.gdalgetpaletteinterpretation(ct.ptr)
