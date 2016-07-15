"Construct empty table."
unsafe_createRAT() = GDAL.createrasterattributetable()

"Construct table from an existing colortable."
unsafe_createRAT(ct::ColorTable) =
    initializeRAT!(GDAL.createrasterattributetable(), ct)

"Destroys a RAT."
destroy(rat::RasterAttributeTable) = GDAL.destroyrasterattributetable(rat)

"Fetch table column count."
ncolumn(rat::RasterAttributeTable) = GDAL.ratgetcolumncount(rat)

"""
Fetch name of indicated column.

### Parameters
* `i`  the column index (zero based).

### Returns
the column name or an empty string for invalid column numbers.
"""
getcolumnname(rat::RasterAttributeTable, i::Integer) = 
    GDAL.ratgetnameofcol(rat, i)

"Fetch column usage value."
getcolumnusage(rat::RasterAttributeTable, i::Integer) =
    GDALRATFieldUsage(GDAL.ratgetusageofcol(rat, i))

"""
Fetch column type.

### Parameters
* `col`  the column index (zero based).

### Returns
column type or `GFT_Integer` if the column index is illegal.
"""
getcolumntype(rat::RasterAttributeTable, i::Integer) =
    GDALRATFieldType(GDAL.ratgettypeofcol(rat, i))

"""
Returns the index of the first column of the requested usage type, or -1 if no
match is found.

### Parameters
* `usage`  usage type to search for.
"""
getcolumnindex(rat::RasterAttributeTable, usage::GDALRATFieldUsage) =
    ccall((:GDALRATGetColOfUsage,GDAL.libgdal),Cint,(RasterAttributeTable,
          GDAL.GDALRATFieldUsage),rat,usage)

"Fetch row count."
nrow(rat::RasterAttributeTable) = GDAL.ratgetrowcount(rat)

"""
Fetch field value as a string.

The value of the requested column in the requested row is returned as a string.
If the field is numeric, it is formatted as a string using default rules, so 
some precision may be lost.

### Parameters
* `row`  row to fetch (zero based).
* `col`  column to fetch (zero based).
"""
asstring(rat::RasterAttributeTable, row::Integer, col::Integer) =
    GDAL.ratgetvalueasstring(rat, row, col)
    
"""
Fetch field value as a integer.

The value of the requested column in the requested row is returned as an int.
Non-integer fields will be converted to int with the possibility of data loss.

### Parameters
* `row`  row to fetch (zero based).
* `col`  column to fetch (zero based).
"""
asint(rat::RasterAttributeTable, row::Integer, col::Integer) =
    GDAL.ratgetvalueasint(rat, row, col)

"""
Fetch field value as a double.

The value of the requested column in the requested row is returned as a double.
Non double fields will be converted to double with the possibility of data loss.

### Parameters
* `row`  row to fetch (zero based).
* `col`  column to fetch (zero based).
"""
asdouble(rat::RasterAttributeTable, row::Integer, col::Integer) =
    GDAL.ratgetvalueasdouble(rat, row, col)

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
setvalue!(rat::RasterAttributeTable, row::Integer, col::Integer, 
          val::AbstractString) = GDAL.ratsetvalueasstring(rat, row, col, val)

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
setvalue!(rat::RasterAttributeTable, row::Integer, col::Integer, 
          val::Integer) = GDAL.ratsetvalueasint(rat, row, col, val)

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
setvalue!(rat::RasterAttributeTable, row::Integer, col::Integer, 
          val::Float64) = GDAL.ratsetvalueasdouble(rat, row, col, val)

"""
Determine whether changes made to this RAT are reflected directly in the dataset

If this returns FALSE then GDALRasterBand.SetDefaultRAT() should be called. 
Otherwise this is unnecessary since changes to this object are reflected in the 
dataset.
"""
changesarewrittentofile(rat::RasterAttributeTable) =
    Bool(GDAL.ratchangesarewrittentofile(rat))

"""
Read or Write a block of doubles to/from the Attribute Table.

### Parameters
* `access`      Either `GF_Read` or `GF_Write`
* `col`         Column of the Attribute Table
* `startrow`    Row to start reading/writing (zero based)
* `nrows`       Number of rows to read or write
* `data`        Array of doubles to read/write. Should be at least `nrows` long.
"""
function attributeio!(rat::RasterAttributeTable,access::GDALRWFlag,col::Integer,
                      startrow::Integer,nrows::Integer,data::Vector{Float64})
    result = ccall((:GDALRATValuesIOAsDouble,GDAL.libgdal),GDAL.CPLErr,
                   (RasterAttributeTable,GDAL.GDALRWFlag,Cint,Cint,Cint,
                    Ptr{Cdouble}),rat,access,col,startrow,nrows,data)
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
function attributeio!(rat::RasterAttributeTable,access::GDALRWFlag,col::Integer,
                      startrow::Integer,nrows::Integer,data::Vector{Cint})
    result = ccall((:GDALRATValuesIOAsInteger,GDAL.libgdal),GDAL.CPLErr,
                   (RasterAttributeTable,GDAL.GDALRWFlag,Cint,Cint,Cint,
                    Ptr{Cint}),rat,access,col,startrow,nrows,data)
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
function attributeio!{T <: AbstractString}(rat::RasterAttributeTable,
                access::GDALRWFlag,col::Integer,startrow::Integer,
                nrows::Integer,data::Vector{T})
    result = ccall((:GDALRATValuesIOAsString,GDAL.libgdal),GDAL.CPLErr,
                   (RasterAttributeTable,GDAL.GDALRWFlag,Cint,Cint,Cint,
                    StringList),rat,access,col,startrow,nrows,data)
    @cplerr result "Failed to $access at column $col starting at $startrow"
    data
end

"""
Set row count.

Resizes the table to include the indicated number of rows. Newly created rows 
will be initialized to their default values - \"\" for strings, and zero for 
numeric fields.
"""
setrowcount!(rat::RasterAttributeTable, n::Integer) = GDAL.ratsetrowcount(rat,n)

"""
Create new column.

If the table already has rows, all row values for the new column will be 
initialized to the default value (\"\", or zero). The new column is always 
created as the last column, can will be column (field) \"GetColumnCount()-1\" 
after CreateColumn() has completed successfully.
"""
function createcolumn!(rat::RasterAttributeTable, name::AbstractString, 
            fieldtype::GDALRATFieldType, fieldusage::GDALRATFieldUsage)
    result = ccall((:GDALRATCreateColumn,GDAL.libgdal),GDAL.CPLErr,
                   (RasterAttributeTable,Cstring,GDAL.GDALRATFieldType,
                    GDAL.GDALRATFieldUsage),rat,name,fieldtype,fieldusage)
    @cplerr result "Failed to create column $name"
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
function setlinearbinning!(rat::RasterAttributeTable, row0min::Real,
                           binsize::Real)
    result = ccall((:GDALRATSetLinearBinning,GDAL.libgdal),GDAL.CPLErr,
                   (RasterAttributeTable,Cdouble,Cdouble),rat,row0min,binsize)
    @cplerr result "Fail to set linear binning: r0min=$row0min, width=$binsize"
end

"""
Get linear binning information.

### Returns
* `row0min` the lower bound (pixel value) of the first category.
* `binsize` the width of each category (in pixel value units).
"""
function getlinearbinning(rat::RasterAttributeTable)
    row0min = Ref{Cdouble}(); binsize = Ref{Cdouble}()
    result = GDAL.ratgetlinearbinning(rat, row0min, binsize)
    result == false || warn("There is no linear binning information.")
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
function initializeRAT!(rat::RasterAttributeTable, colortable::ColorTable)
    result = GDAL.ratinitializefromcolortable(rat, colortable)
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

toColorTable(rat::RasterAttributeTable, n::Integer=-1) = 
    GDAL.rattranslatetocolortable(rat, n)

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
unsafe_clone(rat::RasterAttributeTable) = GDAL.ratclone(rat)

"Serialize Raster Attribute Table in Json format."
serializeJSON(rat::RasterAttributeTable) = GDAL.ratserializejson(rat)

"""
Get row for pixel value.

Given a raw pixel value, the raster attribute table is scanned to determine 
which row in the table applies to the pixel value. The row index is returned.

### Parameters
* `pxvalue` the pixel value.

### Returns
The row index or -1 if no row is appropriate.
"""
getrowindex(rat::RasterAttributeTable, pxvalue::Real) =
    GDAL.ratgetrowofvalue(rat, pxvalue)
