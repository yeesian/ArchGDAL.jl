"""
    unsafe_createcolortable(palette::GDALPaletteInterp)

Construct a new color table.
"""
unsafe_createcolortable(palette::GDALPaletteInterp)::ColorTable =
    ColorTable(GDAL.gdalcreatecolortable(palette))

"Destroys a color table."
function destroy(ct::ColorTable)::Nothing
    GDAL.gdaldestroycolortable(ct)
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
        ColorTable(GDAL.gdalclonecolortable(ct))
    end
end

"""
    paletteinterp(ct::ColorTable)

Fetch palette interpretation.

### Returns
palette interpretation enumeration value, usually `GPI_RGB`.
"""
paletteinterp(ct::ColorTable)::GDALPaletteInterp =
    GDAL.gdalgetpaletteinterpretation(ct)

"""
    getcolorentryasrgb(ct::ColorTable, i::Integer)

Fetch a table entry in RGB format.

In theory this method should support translation of color palettes in non-RGB
color spaces into RGB on the fly, but currently it only works on RGB color
tables.

### Parameters
* `i`   entry offset from zero to GetColorEntryCount()-1.

### Returns
`true` on success, or `false` if the conversion isn't supported.
"""
function getcolorentryasrgb(ct::ColorTable, i::Integer)::GDAL.GDALColorEntry
    colorentry = Ref{GDAL.GDALColorEntry}(GDAL.GDALColorEntry(0, 0, 0, 0))
    result = Bool(GDAL.gdalgetcolorentryasrgb(ct, i, colorentry))
    result || @warn("The conversion to RGB isn't supported.")
    return colorentry[]
end

"""
    setcolorentry!(ct::ColorTable, i::Integer, entry::GDAL.GDALColorEntry)

Set entry in color table.

Note that the passed in color entry is copied, and no internal reference to it
is maintained. Also, the passed in entry must match the color interpretation of
the table to which it is being assigned.

The table is grown as needed to hold the supplied offset.

### Parameters
* `i`     entry offset from `0` to `ncolorentry()-1`.
* `entry` value to assign to table.
"""
function setcolorentry!(ct::ColorTable, i::Integer, entry::GDAL.GDALColorEntry)
    GDAL.gdalsetcolorentry(ct, i, Ref{GDAL.GDALColorEntry}(entry))
    return ct
end
