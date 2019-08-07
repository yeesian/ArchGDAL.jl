"""
OGRStyleMgr factory.

### Parameters
* `styletable`: OGRStyleTable or NULL if not working with a style table.

### Returns
an handle to the new style manager object.
"""
unsafe_createstylemanager(styletable = GDALStyleTable(C_NULL)) =
    StyleManager(GDAL.sm_create(styletable))

"""
Destroy Style Manager.

### Parameters
* `stylemanager`: handle to the style manager to destroy.
"""
destroy(sm::StyleManager) = (GDAL.destroy(sm.ptr); sm.ptr = C_NULL)


"""
Initialize style manager from the style string of a feature.

### Parameters
* `stylemanager`: handle to the style manager.
* `feature`: handle to the new feature from which to read the style.

### Returns
the style string read from the feature, or NULL in case of error.
"""
initialize!(stylemanager::StyleManager, feature::Feature) =
    GDAL.initfromfeature(stylemanager.ptr, feature.ptr)

"""
Initialize style manager from the style string.

### Parameters
* `stylemanager`: handle to the style manager.
* `stylestring`: the style string to use (can be NULL).
### Returns
TRUE on success, FALSE on errors.
"""
initialize!(stylemanager::StyleManager, stylestring = C_NULL) =
    Bool(GDAL.initstylestring(stylemanager.ptr, stylestring))

"""
Get the number of parts in a style.

### Parameters
* `stylemanager`: handle to the style manager.
* `stylestring`: (optional) the style string on which to operate. If NULL then
                 the current style string stored in the style manager is used.

### Returns
the number of parts (style tools) in the style.
"""
npart(stylemanager::StyleManager) = GDAL.getpartcount(stylemanager.ptr, C_NULL)

npart(stylemanager::StyleManager, stylestring::AbstractString) =
    GDAL.getpartcount(stylemanager.ptr, stylestring)

"""
Fetch a part (style tool) from the current style.

### Parameters
* `stylemanager`: handle to the style manager.
* `id`: the part number (0-based index).
* `stylestring`: (optional) the style string on which to operate. If not
    provided, then the current style string stored in the style manager is used.

### Returns
OGRStyleToolH of the requested part (style tools) or NULL on error.
"""
unsafe_getpart(stylemanager::StyleManager, id::Integer, stylestring = C_NULL) =
    StyleTool(GDAL.getpart(stylemanager.ptr, id, stylestring))

"""
Add a part (style tool) to the current style.

### Parameters
* `stylemanager`: handle to the style manager.
* `styletool`: the style tool defining the part to add.

### Returns
TRUE on success, FALSE on errors.
"""
addpart!(stylemanager::StyleManager, styletool::StyleTool) =
    Bool(GDAL.addpart(stylemanager.ptr, styletool.ptr))

"""
Add a style to the current style table.

### Parameters
* `stylemanager`: handle to the style manager.
* `stylename`: the name of the style to add.
* `stylestring`: (optional) the style string to use, or (if not provided) to use
    the style stored in the manager.

### Returns
TRUE on success, FALSE on errors.
"""
function addstyle!(
        stylemanager::StyleManager,
        stylename::AbstractString,
        stylestring::AbstractString
    )
    Bool(GDAL.addstyle(stylemanager.ptr, stylename, stylestring))
end

addstyle!(stylemanager::StyleManager, stylename::AbstractString) =
    Bool(GDAL.addstyle(stylemanager.ptr, stylename, C_NULL))

"""
OGRStyleTool factory.

### Parameters
* `classid`: subclass of style tool to create. One of OGRSTCPen (1),
             OGRSTCBrush (2), OGRSTCSymbol (3) or OGRSTCLabel (4).

### Returns
an handle to the new style tool object or NULL if the creation failed.
"""
unsafe_createstyletool(classid::OGRSTClassId) =
    StyleTool(GDAL.st_create(classid))

"""
Destroy Style Tool.

### Parameters
* `styletool`: handle to the style tool to destroy.
"""
destroy(styletool::StyleTool) =
    (GDAL.destroy(styletool.ptr); styletool.ptr = C_NULL)

"""
Determine type of Style Tool.

### Parameters
* `styletool`: handle to the style tool.

### Returns
the style tool type, one of OGRSTCPen (1), OGRSTCBrush (2), OGRSTCSymbol (3) or
OGRSTCLabel (4). Returns OGRSTCNone (0) if the OGRStyleToolH is invalid.
"""
gettype(styletool::StyleTool) = GDAL.gettype(styletool.ptr)

"""
Get Style Tool units.

### Parameters
* `styletool`: handle to the style tool.

### Returns
the style tool units.
"""
getunit(styletool::StyleTool) = GDAL.getunit(styletool.ptr)

"""
    OGR_ST_SetUnit(OGRStyleToolH styletool,
                   OGRSTUnitId eUnit,
                   double scale) -> void
Set Style Tool units.
### Parameters
* `styletool`: handle to the style tool.
* `newunit`: the new unit.
* `scale`: ground to paper scale factor.
"""
setunit!(styletool::StyleTool, newunit::OGRSTUnitId, scale::Real) =
    GDAL.setunit(styletool.ptr, newunit, scale)

"""
Get Style Tool parameter value as a string.

### Parameters
* `styletool`: handle to the style tool.
* `id`: the parameter id from the enumeration corresponding to the type of this
        style tool (one of the OGRSTPenParam, OGRSTBrushParam, OGRSTSymbolParam
        or OGRSTLabelParam enumerations)
* `nullflag`: pointer to an integer that will be set to TRUE or FALSE to 
        indicate whether the parameter value is NULL.

### Returns
the parameter value as a string and sets `nullflag`.
"""
asstring(styletool::StyleTool, id::Integer, nullflag::Ref{Cint}) =
    GDAL.getparamstr(styletool.ptr, id, nullflag)

asstring(styletool::StyleTool, id::Integer) =
    asstring(styletool, id, Ref{Cint}(0))

"""
Get Style Tool parameter value as an integer.

### Parameters
* `styletool`: handle to the style tool.
* `id`: the parameter id from the enumeration corresponding to the type of this
        style tool (one of the OGRSTPenParam, OGRSTBrushParam, OGRSTSymbolParam
        or OGRSTLabelParam enumerations)
* `nullflag`: pointer to an integer that will be set to TRUE or FALSE to 
        indicate whether the parameter value is NULL.

### Returns
the parameter value as an integer and sets `nullflag`.
"""
asint(styletool::StyleTool, id::Integer, nullflag::Ref{Cint}) =
    GDAL.getparamnum(styletool.ptr, id, nullflag)

asint(styletool::StyleTool, id::Integer) =
    asint(styletool, id, Ref{Cint}(0))

"""
Get Style Tool parameter value as a double.

### Parameters
* `styletool`: handle to the style tool.
* `id`: the parameter id from the enumeration corresponding to the type of this
        style tool (one of the OGRSTPenParam, OGRSTBrushParam, OGRSTSymbolParam
        or OGRSTLabelParam enumerations)
* `nullflag`: pointer to an integer that will be set to TRUE or FALSE to 
        indicate whether the parameter value is NULL.

### Returns
the parameter value as a double and sets `nullflag`.
"""
asdouble(styletool::StyleTool, id::Integer, nullflag::Ref{Cint}) =
    GDAL.getparamdbl(styletool.ptr, id, nullflag)

asdouble(styletool::StyleTool, id::Integer) =
    asdouble(styletool, id, Ref{Cint}(0))

"""
Set Style Tool parameter value from a string.

### Parameters
* `styletool`: handle to the style tool.
* `id`: the parameter id from the enumeration corresponding to the type of this
        style tool (one of the OGRSTPenParam, OGRSTBrushParam, OGRSTSymbolParam
        or OGRSTLabelParam enumerations)
* `value`: the new parameter value
"""
setparam!(styletool::StyleTool, id::Integer, value::AbstractString) =
    GDAL.setparamstr(styletool.ptr, id, value)

"""
Set Style Tool parameter value from an integer.

### Parameters
* `styletool`: handle to the style tool.
* `id`: the parameter id from the enumeration corresponding to the type of this
        style tool (one of the OGRSTPenParam, OGRSTBrushParam, OGRSTSymbolParam
        or OGRSTLabelParam enumerations)
* `value`: the new parameter value
"""
setparam!(styletool::StyleTool, id::Integer, value::Integer) =
    GDAL.setparamnum(styletool.ptr, id, value)

"""
Set Style Tool parameter value from a double.

### Parameters
* `styletool`: handle to the style tool.
* `id`: the parameter id from the enumeration corresponding to the type of this
        style tool (one of the OGRSTPenParam, OGRSTBrushParam, OGRSTSymbolParam
        or OGRSTLabelParam enumerations)
* `value`: the new parameter value
"""
setparam!(styletool::StyleTool, id::Integer, value::Float64) =
    GDAL.setparamdbl(styletool.ptr, id, value)

"""
Get the style string for this Style Tool.

### Parameters
* `styletool`: handle to the style tool.

### Returns
the style string for this style tool or "" if the styletool is invalid.
"""
getstylestring(styletool::StyleTool) = GDAL.getstylestring(styletool.ptr)

"""
Return the r,g,b,a components of a color encoded in #RRGGBB[AA] format.

### Parameters
* `styletool`: handle to the style tool.
* `pszColor`: the color to parse

### Returns
(R,G,B,A) tuple of Cints.
"""
function toRGBA(styletool::StyleTool, color::AbstractString)
    red = Ref{Cint}(0); green = Ref{Cint}(0)
    blue = Ref{Cint}(0); alpha = Ref{Cint}(0)
    result = Bool(GDAL.getrgbfromstring(styletool.ptr, color, 
        red, green,
        blue, alpha
    ))
    result || error("Error in getting RGBA from Styletool")
    (red[], green[], blue[], alpha[])
end

"""
OGRStyleTable factory.

### Returns
an handle to the new style table object.
"""
unsafe_createstyletable() = StyleTable(GDAL.stbl_create())

"""
Destroy Style Table.

### Parameters
* `styletable`: handle to the style table to destroy.
"""
destroy(st::StyleTable) = (GDAL.destroy(st.ptr); st.ptr = C_NULL)

"""
Add a new style in the table.

### Parameters
* `styletable`: handle to the style table.
* `name`: the name the style to add.
* `stylestring`: the style string to add.

### Returns
TRUE on success, FALSE on error
"""
function addstyle!(
        styletable::StyleTable,
        stylename::AbstractString,
        stylestring::AbstractString
    )
    Bool(GDAL.addstyle(styletable.ptr, stylename, stylestring))
end

"""
Save a style table to a file.
### Parameters
* `styletable`: handle to the style table.
* `filename`: the name of the file to save to.
### Returns
TRUE on success, FALSE on error
"""
savestyletable(styletable::StyleTable, filename::AbstractString) =
    Bool(GDAL.savestyletable(styletable.ptr, filename))

"""
Load a style table from a file.

### Parameters
* `styletable`: handle to the style table.
* `filename`: the name of the file to load from.

### Returns
TRUE on success, FALSE on error
"""
loadstyletable!(styletable::StyleTable, filename::AbstractString) =
    Bool(GDAL.loadstyletable(styletable.ptr, filename))

"""
Get a style string by name.

### Parameters
* `styletable`: handle to the style table.
* `name`: the name of the style string to find.

### Returns
the style string matching the name or NULL if not found or error.
"""
findstylestring(styletable::StyleTable, name::AbstractString) =
    GDAL.find(styletable.ptr, name)

"""
Reset the next style pointer to 0.

### Parameters
* `styletable`: handle to the style table.
"""
resetreading!(styletable::StyleTable) =
    GDAL.resetstylestringreading(styletable.ptr)

"""
Get the next style string from the table.

### Parameters
* `styletable`: handle to the style table.

### Returns
the next style string or NULL on error.
"""
nextstyle(styletable::StyleTable) = GDAL.getnextstyle(styletable.ptr)

"""
Get the style name of the last style string fetched with OGR_STBL_GetNextStyle.

### Parameters
* `styletable`: handle to the style table.

### Returns
the Name of the last style string or NULL on error.
"""
laststyle(styletable::StyleTable) = GDAL.getlaststylename(styletable.ptr)
