"Construct empty table."
unsafe_createRAT() = RasterAttrTable(GDAL.createrasterattributetable())

"Construct table from an existing colortable."
unsafe_createRAT(ct::ColorTable) =
    initializeRAT!(unsafe_createRAT(), ct)

"Destroys a RAT."
function destroy(rat::RasterAttrTable)
    GDAL.destroyrasterattributetable(rat.ptr)
    rat.ptr = C_NULL
end

"Fetch table column count."
ncolumn(rat::RasterAttrTable) = GDAL.ratgetcolumncount(rat.ptr)

"""
Fetch name of indicated column.

### Parameters
* `i`  the column index (zero based).

### Returns
the column name or an empty string for invalid column numbers.
"""
getcolumnname(rat::RasterAttrTable, i::Integer) = 
    GDAL.ratgetnameofcol(rat.ptr, i)

"Fetch column usage value."
getcolumnusage(rat::RasterAttrTable, i::Integer) = GDAL.ratgetusageofcol(rat.ptr, i)

"""
Fetch column type.

### Parameters
* `col`  the column index (zero based).

### Returns
column type or `GFT_Integer` if the column index is illegal.
"""
getcolumntype(rat::RasterAttrTable, i::Integer) = GDAL.ratgettypeofcol(rat.ptr, i)

"""
Returns the index of the first column of the requested usage type, or -1 if no
match is found.

### Parameters
* `usage`  usage type to search for.
"""
getcolumnindex(rat::RasterAttrTable, usage::GDALRATFieldUsage) =
    GDAL.ratgetcolofusage(rat.ptr, usage)

"Fetch row count."
nrow(rat::RasterAttrTable) = GDAL.ratgetrowcount(rat.ptr)

"""
Fetch field value as a string.

The value of the requested column in the requested row is returned as a string.
If the field is numeric, it is formatted as a string using default rules, so 
some precision may be lost.

### Parameters
* `row`  row to fetch (zero based).
* `col`  column to fetch (zero based).
"""
asstring(rat::RasterAttrTable, row::Integer, col::Integer) =
    GDAL.ratgetvalueasstring(rat.ptr, row, col)
    
"""
Fetch field value as a integer.

The value of the requested column in the requested row is returned as an int.
Non-integer fields will be converted to int with the possibility of data loss.

### Parameters
* `row`  row to fetch (zero based).
* `col`  column to fetch (zero based).
"""
asint(rat::RasterAttrTable, row::Integer, col::Integer) =
    GDAL.ratgetvalueasint(rat.ptr, row, col)

"""
Fetch field value as a double.

The value of the requested column in the requested row is returned as a double.
Non double fields will be converted to double with the possibility of data loss.

### Parameters
* `row`  row to fetch (zero based).
* `col`  column to fetch (zero based).
"""
asdouble(rat::RasterAttrTable, row::Integer, col::Integer) =
    GDAL.ratgetvalueasdouble(rat.ptr, row, col)

"""
Set field value from string.

The indicated field (column) on the indicated row is set from the passed value.
The value will be automatically converted for other field types, with a possible
loss of precision.

### Parameters
* `row`  row to fetch (zero based).
* `col`  column to fetch (zero based).
* `val`  the value to assign.
"""
function setvalue!(
        rat::RasterAttrTable,
        row::Integer,
        col::Integer,
        val::AbstractString
    )
    GDAL.ratsetvalueasstring(rat.ptr, row, col, val)
    rat
end

"""
Set field value from integer.

The indicated field (column) on the indicated row is set from the passed value.
The value will be automatically converted for other field types, with a possible
loss of precision.

### Parameters
* `row`  row to fetch (zero based).
* `col`  column to fetch (zero based).
* `val`  the value to assign.
"""
function setvalue!(
        rat::RasterAttrTable,
        row::Integer,
        col::Integer, 
        val::Integer
    )
    GDAL.ratsetvalueasint(rat.ptr, row, col, val)
    rat
end

"""
Set field value from double.

The indicated field (column) on the indicated row is set from the passed value.
The value will be automatically converted for other field types, with a possible
loss of precision.

### Parameters
* `row`  row to fetch (zero based).
* `col`  column to fetch (zero based).
* `val`  the value to assign.
"""
function setvalue!(
        rat::RasterAttrTable,
        row::Integer,
        col::Integer, 
        val::Float64
    )
    GDAL.ratsetvalueasdouble(rat.ptr, row, col, val)
    rat
end

"""
Determine whether changes made to this RAT are reflected directly in the dataset

If this returns FALSE then GDALRasterBand.SetDefaultRAT() should be called. 
Otherwise this is unnecessary since changes to this object are reflected in the 
dataset.
"""
changesarewrittentofile(rat::RasterAttrTable) =
    Bool(GDAL.ratchangesarewrittentofile(rat.ptr))

"""
Read or Write a block of doubles to/from the Attribute Table.

### Parameters
* `access`      Either `GF_Read` or `GF_Write`
* `col`         Column of the Attribute Table
* `startrow`    Row to start reading/writing (zero based)
* `nrows`       Number of rows to read or write
* `data`        Array of doubles to read/write. Should be at least `nrows` long.
"""
function attributeio!(
        rat::RasterAttrTable,
        access::GDALRWFlag,
        col::Integer,
        startrow::Integer,
        nrows::Integer,
        data::Vector{Float64}
    )
    result = GDAL.ratvaluesioasdouble(rat.ptr, access, col, startrow, nrows,
        data)
    @cplerr result "Failed to $access at column $col starting at $startrow"
    data
end

"""
Read or Write a block of ints to/from the Attribute Table.

### Parameters
* `access`      Either `GF_Read` or `GF_Write`
* `col`         Column of the Attribute Table
* `startrow`    Row to start reading/writing (zero based)
* `nrows`       Number of rows to read or write
* `data`        Array of ints to read/write. Should be at least `nrows` long.
"""
function attributeio!(
        rat::RasterAttrTable,
        access::GDALRWFlag,
        col::Integer,
        startrow::Integer,
        nrows::Integer,
        data::Vector{Cint}
    )
    result = GDAL.ratvaluesioasinteger(rat.ptr, access, col, startrow, nrows,
        data)
    @cplerr result "Failed to $access at column $col starting at $startrow"
    data
end

"""
Read or Write a block of strings to/from the Attribute Table.

### Parameters
* `access`      Either `GF_Read` or `GF_Write`
* `col`         Column of the Attribute Table
* `startrow`    Row to start reading/writing (zero based)
* `nrows`       Number of rows to read or write
* `data`        Array of strings to read/write. Should be at least `nrows` long.
"""
function attributeio!(
        rat::RasterAttrTable,
        access::GDALRWFlag,
        col::Integer,
        startrow::Integer,
        nrows::Integer,
        data::Vector{T}
    ) where T <: AbstractString
    result = GDAL.ratvaluesioasstring(rat.ptr, access, col, startrow, nrows,
        data)
    @cplerr result "Failed to $access at column $col starting at $startrow"
    data
end

"""
Set row count.

Resizes the table to include the indicated number of rows. Newly created rows 
will be initialized to their default values - \"\" for strings, and zero for 
numeric fields.
"""
setrowcount!(rat::RasterAttrTable, n::Integer) =
    (GDAL.ratsetrowcount(rat.ptr, n); rat)

"""
Create new column.

If the table already has rows, all row values for the new column will be 
initialized to the default value (\"\", or zero). The new column is always 
created as the last column, can will be column (field) \"GetColumnCount()-1\" 
after CreateColumn() has completed successfully.
"""
function createcolumn!(
        rat::RasterAttrTable,
        name::AbstractString, 
        fieldtype::GDALRATFieldType,
        fieldusage::GDALRATFieldUsage
    )
    result = GDAL.ratcreatecolumn(rat.ptr, name, fieldtype, fieldusage)
    @cplerr result "Failed to create column $name"
    rat
end

"""
Set linear binning information.

For RATs with equal sized categories (in pixel value space) that are evenly 
spaced, this method may be used to associate the linear binning information with
the table.

### Parameters
* `row0min` the lower bound (pixel value) of the first category.
* `binsize` the width of each category (in pixel value units).
"""
function setlinearbinning!(rat::RasterAttrTable, row0min::Real, binsize::Real)
    result = GDAL.ratsetlinearbinning(rat.ptr, row0min, binsize)
    @cplerr result "Fail to set linear binning: r0min=$row0min, width=$binsize"
    rat
end

"""
Get linear binning information.

### Returns
* `row0min` the lower bound (pixel value) of the first category.
* `binsize` the width of each category (in pixel value units).
"""
function getlinearbinning(rat::RasterAttrTable)
    row0min = Ref{Cdouble}(); binsize = Ref{Cdouble}()
    result = GDAL.ratgetlinearbinning(rat.ptr, row0min, binsize)
    result == false || @warn("There is no linear binning information.")
    (row0min[], binsize[])
end

"""
Initialize from color table.

This method will setup a whole raster attribute table based on the contents of
the passed color table. The Value (GFU_MinMax), Red (GFU_Red),
Green (GFU_Green), Blue (GFU_Blue), and Alpha (GFU_Alpha) fields are created, 
and a row is set for each entry in the color table.

The raster attribute table must be empty before calling `initializeRAT!()`.

The Value fields are set based on the implicit assumption with color tables that
entry 0 applies to pixel value 0, 1 to 1, etc.
"""
function initializeRAT!(rat::RasterAttrTable, colortable::ColorTable)
    result = GDAL.ratinitializefromcolortable(rat.ptr, colortable.ptr)
    @cplerr result "Failed to initialize RAT from color table"
    rat
end

"""
Translate to a color table.

### Parameters
* `n` The number of entries to produce (`0` to `n-1`), or `-1` to auto-determine
    the number of entries.
### Returns
the generated color table or `NULL` on failure.
"""
toColorTable(rat::RasterAttrTable, n::Integer=-1) = 
    ColorTable(GDAL.rattranslatetocolortable(rat.ptr, n))

# """
#     GDALRATDumpReadable(GDALRasterAttributeTableH,
#                         FILE *) -> void
# Dump RAT in readable form.
# """
# function GDALRATDumpReadable(arg1::GDALRasterAttributeTableH,arg2)
#     ccall((:GDALRATDumpReadable,libgdal),Void,(GDALRasterAttributeTableH,
#           Ptr{FILE}),arg1,arg2)
# end

"""
Copy Raster Attribute Table.

Creates a new copy of an existing raster attribute table. The new copy becomes 
the responsibility of the caller to destroy. May fail (return `NULL`) if the 
attribute table is too large to clone:
    `(nrow() * ncolumn() > RAT_MAX_ELEM_FOR_CLONE)`
"""
unsafe_clone(rat::RasterAttrTable) = RasterAttrTable(GDAL.ratclone(rat.ptr))

"Serialize Raster Attribute Table in Json format."
serializeJSON(rat::RasterAttrTable) = GDAL.ratserializejson(rat.ptr)

"""
Get row for pixel value.

Given a raw pixel value, the raster attribute table is scanned to determine 
which row in the table applies to the pixel value. The row index is returned.

### Parameters
* `pxvalue` the pixel value.

### Returns
The row index or -1 if no row is appropriate.
"""
findrowindex(rat::RasterAttrTable, pxvalue::Real) =
    GDAL.ratgetrowofvalue(rat.ptr, pxvalue)
