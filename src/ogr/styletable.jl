"""
    unsafe_createstylemanager(styletable = C_NULL)

OGRStyleMgr factory.

### Parameters
* `styletable`: OGRStyleTable or NULL if not working with a style table.

### Returns
an handle to the new style manager object.
"""
function unsafe_createstylemanager(styletable::StyleTable = StyleTable())::StyleManager
    return StyleManager(GDAL.ogr_sm_create(styletable.ptr))
end

"""
Destroy Style Manager.

### Parameters
* `stylemanager`: handle to the style manager to destroy.
"""
function destroy(sm::StyleManager)::Nothing
    GDAL.ogr_sm_destroy(sm.ptr)
    sm.ptr = C_NULL
    return nothing
end

"""
    initialize!(stylemanager::StyleManager, stylestring = C_NULL)

Initialize style manager from the style string.

### Parameters
* `stylemanager`: handle to the style manager.
* `stylestring`: the style string to use (can be NULL).
### Returns
`true` on success, `false` on error.
"""
initialize!(stylemanager::StyleManager, stylestring::String)::Bool =
    Bool(GDAL.ogr_sm_initstylestring(stylemanager.ptr, stylestring))

initialize!(stylemanager::StyleManager)::Bool =
    Bool(GDAL.ogr_sm_initstylestring(stylemanager.ptr, C_NULL))

"""
    npart(stylemanager::StyleManager)
    npart(stylemanager::StyleManager, stylestring::AbstractString)

Get the number of parts in a style.

### Parameters
* `stylemanager`: handle to the style manager.
* `stylestring`: (optional) the style string on which to operate. If NULL then
                 the current style string stored in the style manager is used.

### Returns
the number of parts (style tools) in the style.
"""
function npart end

npart(stylemanager::StyleManager)::Integer =
    GDAL.ogr_sm_getpartcount(stylemanager.ptr, C_NULL)

npart(stylemanager::StyleManager, stylestring::AbstractString)::Integer =
    GDAL.ogr_sm_getpartcount(stylemanager.ptr, stylestring)

"""
    unsafe_getpart(stylemanager::StyleManager, id::Integer,
        stylestring = C_NULL)

Fetch a part (style tool) from the current style.

### Parameters
* `stylemanager`: handle to the style manager.
* `id`: the part number (0-based index).
* `stylestring`: (optional) the style string on which to operate. If not
    provided, then the current style string stored in the style manager is used.

### Returns
OGRStyleToolH of the requested part (style tools) or NULL on error.
"""
function unsafe_getpart(
    stylemanager::StyleManager,
    id::Integer,
    stylestring = C_NULL,
)::StyleTool
    StyleTool(GDAL.ogr_sm_getpart(stylemanager.ptr, id, stylestring))
end

"""
    addpart!(stylemanager::StyleManager, styletool::StyleTool)

Add a part (style tool) to the current style.

### Parameters
* `stylemanager`: handle to the style manager.
* `styletool`: the style tool defining the part to add.

### Returns
`true` on success, `false` on error.
"""
addpart!(stylemanager::StyleManager, styletool::StyleTool)::Bool =
    Bool(GDAL.ogr_sm_addpart(stylemanager.ptr, styletool.ptr))

"""
    addstyle!(stylemanager::StyleManager, stylename, stylestring)

Add a style to the current style table.

### Parameters
* `stylemanager`: handle to the style manager.
* `stylename`: the name of the style to add.
* `stylestring`: (optional) the style string to use, or (if not provided) to use
    the style stored in the manager.

### Returns
`true` on success, `false` on error.
"""
function addstyle!(
    stylemanager::StyleManager,
    stylename::AbstractString,
    stylestring::AbstractString,
)::Bool
    return Bool(GDAL.ogr_sm_addstyle(stylemanager.ptr, stylename, stylestring))
end

addstyle!(stylemanager::StyleManager, stylename::AbstractString)::Bool =
    Bool(GDAL.ogr_sm_addstyle(stylemanager.ptr, stylename, C_NULL))

"""
    unsafe_createstyletool(classid::OGRSTClassId)

OGRStyleTool factory.

### Parameters
* `classid`: subclass of style tool to create. One of OGRSTCPen (1),
             OGRSTCBrush (2), OGRSTCSymbol (3) or OGRSTCLabel (4).

### Returns
an handle to the new style tool object or NULL if the creation failed.
"""
unsafe_createstyletool(classid::OGRSTClassId)::StyleTool =
    StyleTool(GDAL.ogr_st_create(classid))

"""
Destroy Style Tool.

### Parameters
* `styletool`: handle to the style tool to destroy.
"""
function destroy(styletool::StyleTool)::Nothing
    GDAL.ogr_st_destroy(styletool.ptr)
    styletool.ptr = C_NULL
    return nothing
end

"""
    gettype(styletool::StyleTool)

Determine type of Style Tool.

### Parameters
* `styletool`: handle to the style tool.

### Returns
the style tool type, one of OGRSTCPen (1), OGRSTCBrush (2), OGRSTCSymbol (3) or
OGRSTCLabel (4). Returns OGRSTCNone (0) if the OGRStyleToolH is invalid.
"""
gettype(styletool::StyleTool)::OGRSTClassId = GDAL.ogr_st_gettype(styletool.ptr)

"""
    getunit(styletool::StyleTool)

Get Style Tool units.

### Parameters
* `styletool`: handle to the style tool.

### Returns
the style tool units.
"""
getunit(styletool::StyleTool)::OGRSTUnitId = GDAL.ogr_st_getunit(styletool.ptr)

"""
    setunit!(styletool::StyleTool, newunit::OGRSTUnitId, scale::Real)

Set Style Tool units.

### Parameters
* `styletool`: handle to the style tool.
* `newunit`: the new unit.
* `scale`: ground to paper scale factor.
"""
function setunit!(styletool::StyleTool, newunit::OGRSTUnitId, scale::Real)::StyleTool
    GDAL.ogr_st_setunit(styletool.ptr, newunit, scale)
    return styletool
end

"""
    asstring(styletool::StyleTool, id::Integer)
    asstring(styletool::StyleTool, id::Integer, nullflag::Ref{Cint})

Get Style Tool parameter value as a string.

### Parameters
* `styletool`: handle to the style tool.
* `id`: the parameter id from the enumeration corresponding to the type of this
        style tool (one of the OGRSTPenParam, OGRSTBrushParam, OGRSTSymbolParam
        or OGRSTLabelParam enumerations)
* `nullflag`: pointer to an integer that will be set to `true` or `false` to
        indicate whether the parameter value is NULL.

### Returns
the parameter value as a string and sets `nullflag`.
"""
asstring(styletool::StyleTool, id::Integer, nullflag::Ref{Cint})::String =
    GDAL.ogr_st_getparamstr(styletool.ptr, id, nullflag)

asstring(styletool::StyleTool, id::Integer)::String = asstring(styletool, id, Ref{Cint}(0))

"""
    asint(styletool::StyleTool, id::Integer, nullflag = Ref{Cint}(0))

Get Style Tool parameter value as an integer.

### Parameters
* `styletool`: handle to the style tool.
* `id`: the parameter id from the enumeration corresponding to the type of this
        style tool (one of the OGRSTPenParam, OGRSTBrushParam, OGRSTSymbolParam
        or OGRSTLabelParam enumerations)
* `nullflag`: pointer to an integer that will be set to `true` or `false` to
        indicate whether the parameter value is NULL.

### Returns
the parameter value as an integer and sets `nullflag`.
"""
function asint(styletool::StyleTool, id::Integer, nullflag::Ref{Cint} = Ref{Cint}(0))::Int32
    return GDAL.ogr_st_getparamnum(styletool.ptr, id, nullflag)
end

"""
    asdouble(styletool::StyleTool, id::Integer, nullflag = Ref{Cint}(0))

Get Style Tool parameter value as a double.

### Parameters
* `styletool`: handle to the style tool.
* `id`: the parameter id from the enumeration corresponding to the type of this
        style tool (one of the OGRSTPenParam, OGRSTBrushParam, OGRSTSymbolParam
        or OGRSTLabelParam enumerations)
* `nullflag`: pointer to an integer that will be set to `true` or `false` to
        indicate whether the parameter value is NULL.

### Returns
the parameter value as a double and sets `nullflag`.
"""
function asdouble(
    styletool::StyleTool,
    id::Integer,
    nullflag::Ref{Cint} = Ref{Cint}(0),
)::Float64
    return GDAL.ogr_st_getparamdbl(styletool.ptr, id, nullflag)
end

"""
    setparam!(styletool::StyleTool, id::Integer, value)

Set Style Tool parameter value.

### Parameters
* `styletool`: handle to the style tool.
* `id`: the parameter id from the enumeration corresponding to the type of this
        style tool (one of the OGRSTPenParam, OGRSTBrushParam, OGRSTSymbolParam
        or OGRSTLabelParam enumerations)
* `value`: the new parameter value, can be an Integer, Float64, or AbstactString
"""
function setparam! end

function setparam!(styletool::StyleTool, id::Integer, value::AbstractString)::StyleTool
    GDAL.ogr_st_setparamstr(styletool.ptr, id, value)
    return styletool
end

function setparam!(styletool::StyleTool, id::Integer, value::Integer)::StyleTool
    GDAL.ogr_st_setparamnum(styletool.ptr, id, value)
    return styletool
end

function setparam!(styletool::StyleTool, id::Integer, value::Float64)::StyleTool
    GDAL.ogr_st_setparamdbl(styletool.ptr, id, value)
    return styletool
end

"""
    getstylestring(styletool::StyleTool)

Get the style string for this Style Tool.

### Parameters
* `styletool`: handle to the style tool.

### Returns
the style string for this style tool or "" if the styletool is invalid.
"""
getstylestring(styletool::StyleTool)::String = GDAL.ogr_st_getstylestring(styletool.ptr)

"""
    toRGBA(styletool::StyleTool, color::AbstractString)

Return the r,g,b,a components of a color encoded in #RRGGBB[AA] format.

### Parameters
* `styletool`: handle to the style tool.
* `pszColor`: the color to parse

### Returns
(R,G,B,A) tuple of Cints.
"""
function toRGBA(styletool::StyleTool, color::AbstractString)::Tuple{Int32,Int32,Int32,Int32}
    red = Ref{Int32}(0)
    green = Ref{Int32}(0)
    blue = Ref{Int32}(0)
    alpha = Ref{Int32}(0)
    result =
        Bool(GDAL.ogr_st_getrgbfromstring(styletool.ptr, color, red, green, blue, alpha))
    result || error("Error in getting RGBA from Styletool")
    return (red[], green[], blue[], alpha[])
end

"""
    unsafe_createstyletable()

OGRStyleTable factory.

### Returns
an handle to the new style table object.
"""
unsafe_createstyletable()::StyleTable = StyleTable(GDAL.ogr_stbl_create())

"""
Destroy Style Table.

### Parameters
* `styletable`: handle to the style table to destroy.
"""
function destroy(st::StyleTable)::Nothing
    GDAL.ogr_stbl_destroy(st.ptr)
    st.ptr = C_NULL
    return nothing
end

"""
    addstyle!(styletable::StyleTable, stylename, stylestring)

Add a new style in the table.

### Parameters
* `styletable`: handle to the style table.
* `name`: the name the style to add.
* `stylestring`: the style string to add.

### Returns
`true` on success, `false` on error
"""
function addstyle!(
    styletable::StyleTable,
    stylename::AbstractString,
    stylestring::AbstractString,
)::Bool
    return Bool(GDAL.ogr_stbl_addstyle(styletable.ptr, stylename, stylestring))
end

"""
    savestyletable(styletable::StyleTable, filename::AbstractString)

Save a style table to a file.

### Parameters
* `styletable`: handle to the style table.
* `filename`: the name of the file to save to.

### Returns
`true` on success, `false` on error
"""
savestyletable(styletable::StyleTable, filename::AbstractString)::Bool =
    Bool(GDAL.ogr_stbl_savestyletable(styletable.ptr, filename))

"""
    loadstyletable!(styletable::StyleTable, filename::AbstractString)

Load a style table from a file.

### Parameters
* `styletable`: handle to the style table.
* `filename`: the name of the file to load from.

### Returns
`true` on success, `false` on error
"""
loadstyletable!(styletable::StyleTable, filename::AbstractString)::Bool =
    Bool(GDAL.ogr_stbl_loadstyletable(styletable.ptr, filename))

"""
    findstylestring(styletable::StyleTable, name::AbstractString)

Get a style string by name.

### Parameters
* `styletable`: handle to the style table.
* `name`: the name of the style string to find.

### Returns
the style string matching the name or NULL if not found or error.
"""
findstylestring(styletable::StyleTable, name::AbstractString)::String =
    GDAL.ogr_stbl_find(styletable.ptr, name)

"""
    resetreading!(styletable::StyleTable)

Reset the next style pointer to 0.

### Parameters
* `styletable`: handle to the style table.
"""
function resetreading!(styletable::StyleTable)::StyleTable
    GDAL.ogr_stbl_resetstylestringreading(styletable.ptr)
    return styletable
end

"""
    nextstyle(styletable::StyleTable)

Get the next style string from the table.

### Parameters
* `styletable`: handle to the style table.

### Returns
the next style string or NULL on error.
"""
nextstyle(styletable::StyleTable)::String = GDAL.ogr_stbl_getnextstyle(styletable.ptr)

"""
    laststyle(styletable::StyleTable)

Get the style name of the last style string fetched with OGR_STBL_GetNextStyle.

### Parameters
* `styletable`: handle to the style table.

### Returns
the Name of the last style string or NULL on error.
"""
laststyle(styletable::StyleTable)::String = GDAL.ogr_stbl_getlaststylename(styletable.ptr)
