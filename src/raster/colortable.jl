"""
    GDALCreateColorTable(GDALPaletteInterp eInterp) -> GDALColorTableH
Construct a new color table.
"""
unsafe_createcolortable(palette::GDALPaletteInterp) =
    ColorTable(GDAL.createcolortable(palette))

"Destroys a color table."
destroy(ct::ColorTable) = (GDAL.destroycolortable(ct.ptr); ct.ptr = C_NULL)

"Make a copy of a color table."
unsafe_clone(ct::ColorTable) = ColorTable(GDAL.clonecolortable(ct.ptr))

"""
Fetch palette interpretation.

### Returns
palette interpretation enumeration value, usually `GPI_RGB`.
"""
paletteinterp(ct::ColorTable) = GDAL.getpaletteinterpretation(ct.ptr)

"Get number of color entries in table."
ncolorentry(ct::ColorTable) = GDAL.getcolorentrycount(ct.ptr)

"Fetch a color entry from table."
getcolorentry(ct::ColorTable, i::Integer) =
    unsafe_load(GDAL.getcolorentry(ct.ptr, i))

"""
Fetch a table entry in RGB format.

In theory this method should support translation of color palettes in non-RGB
color spaces into RGB on the fly, but currently it only works on RGB color 
tables.

### Parameters
* `i`   entry offset from zero to GetColorEntryCount()-1.

### Returns
TRUE on success, or FALSE if the conversion isn't supported.
"""
function getcolorentryasrgb(ct::ColorTable, i::Integer)
    colorentry = Ref{GDAL.GDALColorEntry}(GDAL.GDALColorEntry(0, 0, 0, 0))
    result = Bool(GDAL.getcolorentryasrgb(ct.ptr, i, colorentry))
    result || @warn("The conversion to RGB isn't supported.")
    colorentry[]
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
setcolorentry!(ct::ColorTable, i::Integer, entry::GDAL.GDALColorEntry) =
    (GDAL.setcolorentry(ct.ptr, i, Ref{GDAL.GDALColorEntry}(entry)); ct)

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
    GDAL.createcolorramp(ct.ptr,
        startindex, Ref{GDAL.GDALColorEntry}(startcolor),
        endindex, Ref{GDAL.GDALColorEntry}(endcolor)
    )
end
