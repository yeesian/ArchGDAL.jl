"""
    unsafe_createRAT()

Construct empty table.
"""
unsafe_createRAT()::RasterAttrTable =
    RasterAttrTable(GDAL.gdalcreaterasterattributetable())

"""
    unsafe_createRAT(ct::ColorTable)

Construct table from an existing colortable.
"""
unsafe_createRAT(ct::ColorTable)::RasterAttrTable =
    initializeRAT!(unsafe_createRAT(), ct)

"Destroys a RAT."
function destroy(rat::RasterAttrTable)::Nothing
    GDAL.gdaldestroyrasterattributetable(rat)
    rat.ptr = C_NULL
    return nothing
end

"""
    ncolumn(rat::RasterAttrTable)

Fetch table column count.
"""
ncolumn(rat::RasterAttrTable)::Integer = GDAL.gdalratgetcolumncount(rat)

"""
    columnname(rat::RasterAttrTable, i::Integer)

Fetch name of indicated column.

### Parameters
* `i`  the column index (zero based).

### Returns
the column name or an empty string for invalid column numbers.
"""
columnname(rat::RasterAttrTable, i::Integer)::String =
    GDAL.gdalratgetnameofcol(rat, i)

"""
    columnusage(rat::RasterAttrTable, i::Integer)

Fetch column usage value.
"""
columnusage(rat::RasterAttrTable, i::Integer)::GDALRATFieldUsage =
    GDAL.gdalratgetusageofcol(rat, i)

"""
    columntype(rat::RasterAttrTable, i::Integer)

Fetch column type.

### Parameters
* `col`  the column index (zero based).

### Returns
column type or `GFT_Integer` if the column index is illegal.
"""
columntype(rat::RasterAttrTable, i::Integer)::GDALRATFieldType =
    GDAL.gdalratgettypeofcol(rat, i)

"""
    findcolumnindex(rat::RasterAttrTable, usage::GDALRATFieldUsage)

Returns the index of the first column of the requested usage type, or -1 if no
match is found.

### Parameters
* `usage`  usage type to search for.
"""
findcolumnindex(rat::RasterAttrTable, usage::GDALRATFieldUsage)::Integer =
    GDAL.gdalratgetcolofusage(rat, usage)

"""
    nrow(rat::RasterAttrTable)

Fetch row count.
"""
nrow(rat::RasterAttrTable)::Integer = GDAL.gdalratgetrowcount(rat)

"""
    asstring(rat::RasterAttrTable, row::Integer, col::Integer)

Fetch field value as a string.

The value of the requested column in the requested row is returned as a string.
If the field is numeric, it is formatted as a string using default rules, so
some precision may be lost.

### Parameters
* `row`  row to fetch (zero based).
* `col`  column to fetch (zero based).
"""
asstring(rat::RasterAttrTable, row::Integer, col::Integer)::String =
    GDAL.gdalratgetvalueasstring(rat, row, col)

"""
    asint(rat::RasterAttrTable, row::Integer, col::Integer)

Fetch field value as a integer.

The value of the requested column in the requested row is returned as an int.
Non-integer fields will be converted to int with the possibility of data loss.

### Parameters
* `row`  row to fetch (zero based).
* `col`  column to fetch (zero based).
"""
asint(rat::RasterAttrTable, row::Integer, col::Integer)::Integer =
    GDAL.gdalratgetvalueasint(rat, row, col)

"""
    asdouble(rat::RasterAttrTable, row::Integer, col::Integer)

Fetch field value as a double.

The value of the requested column in the requested row is returned as a double.
Non double fields will be converted to double with the possibility of data loss.

### Parameters
* `row`  row to fetch (zero based).
* `col`  column to fetch (zero based).
"""
asdouble(rat::RasterAttrTable, row::Integer, col::Integer)::Float64 =
    GDAL.gdalratgetvalueasdouble(rat, row, col)

"""
    setvalue!(rat::RasterAttrTable, row, col, val)

Set field value from string.

The indicated field (column) on the indicated row is set from the passed value.
The value will be automatically converted for other field types, with a possible
loss of precision.

### Parameters
* `row`  row to fetch (zero based).
* `col`  column to fetch (zero based).
* `val`  the value to assign, can be an AbstractString, Integer or Float64.
"""
function setvalue! end

function setvalue!(
    rat::RasterAttrTable,
    row::Integer,
    col::Integer,
    val::AbstractString,
)::RasterAttrTable
    GDAL.gdalratsetvalueasstring(rat, row, col, val)
    return rat
end

function setvalue!(
    rat::RasterAttrTable,
    row::Integer,
    col::Integer,
    val::Integer,
)::RasterAttrTable
    GDAL.gdalratsetvalueasint(rat, row, col, val)
    return rat
end

function setvalue!(
    rat::RasterAttrTable,
    row::Integer,
    col::Integer,
    val::Float64,
)::RasterAttrTable
    GDAL.gdalratsetvalueasdouble(rat, row, col, val)
    return rat
end

"""
    changesarewrittentofile(rat::RasterAttrTable)

Determine whether changes made to this RAT are reflected directly in the dataset

If this returns `false` then RasterBand.SetDefaultRAT() should be called.
Otherwise this is unnecessary since changes to this object are reflected in the
dataset.
"""
changesarewrittentofile(rat::RasterAttrTable)::Bool =
    Bool(GDAL.gdalratchangesarewrittentofile(rat))

"""
    attributeio!(rat::RasterAttrTable, access::GDALRWFlag, col, startrow, nrows,
        data::Vector)

Read or Write a block of data to/from the Attribute Table.

### Parameters
* `access`      Either `GF_Read` or `GF_Write`
* `col`         Column of the Attribute Table
* `startrow`    Row to start reading/writing (zero based)
* `nrows`       Number of rows to read or write
* `data`        Vector of Float64, Int32 or AbstractString to read/write. Should
                be at least `nrows` long.
"""
function attributeio! end

function attributeio!(
    rat::RasterAttrTable,
    access::GDALRWFlag,
    col::Integer,
    startrow::Integer,
    nrows::Integer,
    data::Vector{Float64},
)::Vector{Float64}
    result = GDAL.gdalratvaluesioasdouble(
        rat,
        access,
        col,
        startrow,
        nrows,
        data,
    )
    @cplerr result "Failed to $access at column $col starting at $startrow"
    return data
end

function attributeio!(
    rat::RasterAttrTable,
    access::GDALRWFlag,
    col::Integer,
    startrow::Integer,
    nrows::Integer,
    data::Vector{Cint},
)::Vector{Cint}
    result = GDAL.gdalratvaluesioasinteger(
        rat,
        access,
        col,
        startrow,
        nrows,
        data,
    )
    @cplerr result "Failed to $access at column $col starting at $startrow"
    return data
end

function attributeio!(
    rat::RasterAttrTable,
    access::GDALRWFlag,
    col::Integer,
    startrow::Integer,
    nrows::Integer,
    data::Vector{T},
)::Vector{T} where {T<:AbstractString}
    result = GDAL.gdalratvaluesioasstring(
        rat,
        access,
        col,
        startrow,
        nrows,
        data,
    )
    @cplerr result "Failed to $access at column $col starting at $startrow"
    return data
end

"""
    setrowcount!(rat::RasterAttrTable, n::Integer)

Set row count.

Resizes the table to include the indicated number of rows. Newly created rows
will be initialized to their default values - \"\" for strings, and zero for
numeric fields.
"""
function setrowcount!(rat::RasterAttrTable, n::Integer)::RasterAttrTable
    GDAL.gdalratsetrowcount(rat, n)
    return rat
end

"""
    createcolumn!(rat::RasterAttrTable, name, fieldtype::GDALRATFieldType,
        fieldusage::GDALRATFieldUsage)

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
    fieldusage::GDALRATFieldUsage,
)::RasterAttrTable
    result = GDAL.gdalratcreatecolumn(rat, name, fieldtype, fieldusage)
    @cplerr result "Failed to create column $name"
    return rat
end

"""
    setlinearbinning!(rat::RasterAttrTable, row0min::Real, binsize::Real)

Set linear binning information.

For RATs with equal sized categories (in pixel value space) that are evenly
spaced, this method may be used to associate the linear binning information with
the table.

### Parameters
* `row0min` the lower bound (pixel value) of the first category.
* `binsize` the width of each category (in pixel value units).
"""
function setlinearbinning!(
    rat::RasterAttrTable,
    row0min::Real,
    binsize::Real,
)::RasterAttrTable
    result = GDAL.gdalratsetlinearbinning(rat, row0min, binsize)
    @cplerr result "Fail to set linear binning: r0min=$row0min, width=$binsize"
    return rat
end

"""
    getlinearbinning(rat::RasterAttrTable)

Get linear binning information.

### Returns
* `row0min` the lower bound (pixel value) of the first category.
* `binsize` the width of each category (in pixel value units).
"""
function getlinearbinning(rat::RasterAttrTable)::Tuple{Cdouble,Cdouble}
    row0min = Ref{Cdouble}()
    binsize = Ref{Cdouble}()
    result = GDAL.gdalratgetlinearbinning(rat, row0min, binsize)
    result == false || @warn("There is no linear binning information.")
    return (row0min[], binsize[])
end

"""
    initializeRAT!(rat::RasterAttrTable, colortable::ColorTable)

Initialize from color table.

This method will setup a whole raster attribute table based on the contents of
the passed color table. The Value (GFU_MinMax), Red (GFU_Red),
Green (GFU_Green), Blue (GFU_Blue), and Alpha (GFU_Alpha) fields are created,
and a row is set for each entry in the color table.

The raster attribute table must be empty before calling `initializeRAT!()`.

The Value fields are set based on the implicit assumption with color tables that
entry 0 applies to pixel value 0, 1 to 1, etc.
"""
function initializeRAT!(
    rat::RasterAttrTable,
    colortable::ColorTable,
)::RasterAttrTable
    result = GDAL.gdalratinitializefromcolortable(rat, colortable)
    @cplerr result "Failed to initialize RAT from color table"
    return rat
end

"""
    toColorTable(rat::RasterAttrTable, n::Integer = -1)

Translate to a color table.

### Parameters
* `n` The number of entries to produce (`0` to `n-1`), or `-1` to auto-determine
    the number of entries.
### Returns
the generated color table or `NULL` on failure.
"""
toColorTable(rat::RasterAttrTable, n::Integer = -1)::ColorTable =
    ColorTable(GDAL.gdalrattranslatetocolortable(rat, n))

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
    unsafe_clone(rat::RasterAttrTable)

Copy Raster Attribute Table.

Creates a new copy of an existing raster attribute table. The new copy becomes
the responsibility of the caller to destroy. May fail (return `NULL`) if the
attribute table is too large to clone:
    `(nrow() * ncolumn() > RAT_MAX_ELEM_FOR_CLONE)`
"""
unsafe_clone(rat::RasterAttrTable)::RasterAttrTable =
    RasterAttrTable(GDAL.gdalratclone(rat))

# """
#     serializeJSON(rat::RasterAttrTable)
#
# Serialize Raster Attribute Table in Json format.
# """
# serializeJSON(rat::RasterAttrTable) = GDAL.gdalratserializejson(rat)

"""
    findrowindex(rat::RasterAttrTable, pxvalue::Real)

Get row for pixel value.

Given a raw pixel value, the raster attribute table is scanned to determine
which row in the table applies to the pixel value. The row index is returned.

### Parameters
* `pxvalue` the pixel value.

### Returns
The row index or -1 if no row is appropriate.
"""
findrowindex(rat::RasterAttrTable, pxvalue::Real)::Integer =
    GDAL.gdalratgetrowofvalue(rat, pxvalue)
