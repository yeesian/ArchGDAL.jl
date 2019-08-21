"""
    GDALCreateColorTable(GDALPaletteInterp eInterp) -> GDALColorTableH
Construct a new color table.
"""
unsafe_createcolortable(palette::GDALPaletteInterp) =
    ColorTable(GDAL.gdalcreatecolortable(palette))

"Destroys a color table."
function destroy(ct::ColorTable)
    GDAL.gdaldestroycolortable(ct.ptr)
    ct.ptr = C_NULL
end

"Make a copy of a color table."
unsafe_clone(ct::ColorTable) = ColorTable(GDAL.gdalclonecolortable(ct.ptr))

"""
Fetch palette interpretation.

### Returns
palette interpretation enumeration value, usually `GPI_RGB`.
"""
paletteinterp(ct::ColorTable) = GDAL.gdalgetpaletteinterpretation(ct.ptr)

"Get number of color entries in table."
ncolorentry(ct::ColorTable) = GDAL.gdalgetcolorentrycount(ct.ptr)

"Fetch a color entry from table."
getcolorentry(ct::ColorTable, i::Integer) =
    unsafe_load(GDAL.gdalgetcolorentry(ct.ptr, i))

"""
Fetch a table entry in RGB format.

In theory this method should support translation of color palettes in non-RGB
color spaces into RGB on the fly, but currently it only works on RGB color 
tables.

### Parameters
* `i`   entry offset from zero to GetColorEntryCount()-1.

### Returns
`true` on success, or `false` if the conversion isn't supported.
"""
function getcolorentryasrgb(ct::ColorTable, i::Integer)
    colorentry = Ref{GDAL.GDALColorEntry}(GDAL.GDALColorEntry(0, 0, 0, 0))
    result = Bool(GDAL.gdalgetcolorentryasrgb(ct.ptr, i, colorentry))
    result || @warn("The conversion to RGB isn't supported.")
    return colorentry[]
end

"""
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
    GDAL.gdalsetcolorentry(ct.ptr, i, Ref{GDAL.GDALColorEntry}(entry))
    return ct
end

"""
Create color ramp.

Automatically creates a color ramp from one color entry to another. It can be 
called several times to create multiples ramps in the same color table.

### Parameters
* `startindex` index to start the ramp on the color table [0..255]
* `startcolor` a color entry value to start the ramp
* `endindex`   index to end the ramp on the color table [0..255]
* `endcolor`   a color entry value to end the ramp

### Returns
total number of entries, -1 to report error
"""
function createcolorramp!(
        ct::ColorTable,
        startindex::Integer,
        startcolor::GDAL.GDALColorEntry,
        endindex::Integer,
        endcolor::GDAL.GDALColorEntry
    )
    return GDAL.gdalcreatecolorramp(
        ct.ptr,
        startindex,
        Ref{GDAL.GDALColorEntry}(startcolor),
        endindex,
        Ref{GDAL.GDALColorEntry}(endcolor)
    )
end
