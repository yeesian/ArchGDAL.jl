"""
OGRStyleMgr factory.

### Parameters
* `styletable`: OGRStyleTable or NULL if not working with a style table.

### Returns
an handle to the new style manager object.
"""
unsafe_createstylemanager(styletable::StyleTable = StyleTable(C_NULL)) =
    GDAL.create(styletable)

"""
Destroy Style Manager.

### Parameters
* `stylemanager`: handle to the style manager to destroy.
"""
destroy(stylemanager::StyleManager) = GDAL.destroy(stylemanager)

"""
Initialize style manager from the style string of a feature.

### Parameters
* `stylemanager`: handle to the style manager.
* `feature`: handle to the new feature from which to read the style.

### Returns
the style string read from the feature, or NULL in case of error.
"""
initialize!(stylemanager::StyleManager, feature::Feature) =
    GDAL.initfromfeature(stylemanager, feature)

"""
Initialize style manager from the style string.

### Parameters
* `stylemanager`: handle to the style manager.
* `stylestring`: the style string to use (can be NULL).
### Returns
TRUE on success, FALSE on errors.
"""
initialize!(stylemanager::StyleManager, stylestring::AbstractString) =
    Bool(GDAL.initstylestring(stylemanager, stylestring))

initialize!(stylemanager::StyleManager) =
    Bool(ccall((:OGR_SM_InitStyleString,GDAL.libgdal),Cint,(StyleManager,
                Ptr{UInt8}),stylemanager,Ptr{UInt8}(C_NULL)))

"""
Get the number of parts in a style.

### Parameters
* `stylemanager`: handle to the style manager.
* `stylestring`: (optional) the style string on which to operate. If NULL then
                 the current style string stored in the style manager is used.

### Returns
the number of parts (style tools) in the style.
"""
npart(stylemanager::StyleManager,stylestring::AbstractString) =
    ccall((:OGR_SM_GetPartCount,GDAL.libgdal),Cint,(StyleManager,Ptr{UInt8}),
          stylemanager,stylestring)

"""
Fetch a part (style tool) from the current style.

### Parameters
* `stylemanager`: handle to the style manager.
* `nPartId`: the part number (0-based index).
* `stylestring`: (optional) the style string on which to operate. If not
    provided, then the current style string stored in the style manager is used.

### Returns
OGRStyleToolH of the requested part (style tools) or NULL on error.
"""
getpart(stylemanager::StyleManager,id::Integer,stylestring::AbstractString) =
    GDAL.getpart(stylemanager, id, stylestring)

getpart(stylemanager::StyleManager,id::Integer) =
    GDAL.checknull(ccall((:OGR_SM_GetPart,GDAL.libgdal),StyleTool,(StyleManager,
                         Cint,Ptr{UInt8}),stylemanager,id,C_NULL))

"""
Add a part (style tool) to the current style.

### Parameters
* `stylemanager`: handle to the style manager.
* `styletool`: the style tool defining the part to add.

### Returns
TRUE on success, FALSE on errors.
"""
addpart!(stylemanager::StyleManager,styletool::StyleTool) =
    Bool(GDAL.addpart(stylemanager, styletool))

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
addstyle!(stylemanager::StyleManager,
          stylename::AbstractString,
          stylestring::AbstractString) =
    Bool(GDAL.addstyle(stylemanager, stylename, stylestring))

addstyle!(stylemanager::StyleManager, stylename::AbstractString) =
    Bool(ccall((:OGR_SM_AddStyle,GDAL.libgdal),Cint,(StyleManager,Cstring,
                Ptr{UInt8}),stylemanager,stylename,C_NULL))

"""
OGRStyleTool factory.

### Parameters
* `classid`: subclass of style tool to create. One of OGRSTCPen (1),
             OGRSTCBrush (2), OGRSTCSymbol (3) or OGRSTCLabel (4).

### Returns
an handle to the new style tool object or NULL if the creation failed.
"""
unsafe_createstyletool(classid::OGRSTClassId) =
    GDAL.checknull(ccall((:OGR_ST_Create,GDAL.libgdal),StyleTool,
                         (GDAL.OGRSTClassId,),classid))

"""
Destroy Style Tool.

### Parameters
* `styletool`: handle to the style tool to destroy.
"""
destroy(styletool::StyleTool) = GDAL.destroy(styletool)

"""
Determine type of Style Tool.

### Parameters
* `styletool`: handle to the style tool.

### Returns
the style tool type, one of OGRSTCPen (1), OGRSTCBrush (2), OGRSTCSymbol (3) or
OGRSTCLabel (4). Returns OGRSTCNone (0) if the OGRStyleToolH is invalid.
"""
gettype(styletool::StyleTool) = OGRSTClassId(GDAL.gettype(styletool))

"""
Get Style Tool units.

### Parameters
* `styletool`: handle to the style tool.

### Returns
the style tool units.
"""
getunit(styletool::StyleTool) = OGRSTUnitId(GDAL.getunit(styletool))

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
    ccall((:OGR_ST_SetUnit,GDAL.libgdal),Void,(StyleTool,GDAL.OGRSTUnitId,
          Cdouble),styletool,newunit,scale)

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
asstring(styletool::StyleTool,id::Integer,nullflag::Ref{Cint}) =
    GDAL.getparamstr(styletool, id, nullflag)

asstring(styletool::StyleTool,id::Integer) =
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
asint(styletool::StyleTool,id::Integer,nullflag::Ref{Cint}) =
    GDAL.getparamnum(styletool, id, nullflag)

asint(styletool::StyleTool,id::Integer) =
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
asdouble(styletool::StyleTool,id::Integer,nullflag::Ref{Cint}) =
    GDAL.getparamdbl(styletool, id, nullflag)

asdouble(styletool::StyleTool,id::Integer) =
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
setparam!(styletool::StyleTool,id::Integer,value::AbstractString) =
    GDAL.setparamstr(styletool, id, value)

"""
Set Style Tool parameter value from an integer.

### Parameters
* `styletool`: handle to the style tool.
* `id`: the parameter id from the enumeration corresponding to the type of this
        style tool (one of the OGRSTPenParam, OGRSTBrushParam, OGRSTSymbolParam
        or OGRSTLabelParam enumerations)
* `value`: the new parameter value
"""
setparam!(styletool::StyleTool,id::Integer,value::Integer) =
    GDAL.setparamnum(styletool, id, value)

"""
Set Style Tool parameter value from a double.

### Parameters
* `styletool`: handle to the style tool.
* `id`: the parameter id from the enumeration corresponding to the type of this
        style tool (one of the OGRSTPenParam, OGRSTBrushParam, OGRSTSymbolParam
        or OGRSTLabelParam enumerations)
* `value`: the new parameter value
"""
setparam!(styletool::StyleTool,id::Integer,value::Float64) =
    GDAL.setparamdbl(styletool, id, value)

"""
Get the style string for this Style Tool.

### Parameters
* `styletool`: handle to the style tool.

### Returns
the style string for this style tool or "" if the styletool is invalid.
"""
getstylestring(styletool::StyleTool) = GDAL.getstylestring(styletool)

"""
Return the r,g,b,a components of a color encoded in #RRGGBB[AA] format.

### Parameters
* `styletool`: handle to the style tool.
* `pszColor`: the color to parse

### Returns
(R,G,B,A) tuple of Cints.
"""
function getrgba(styletool::StyleTool,color::AbstractString)
    red = Ref{Cint}(0); green = Ref{Cint}(0)
    blue = Ref{Cint}(0); alpha = Ref{Cint}(0)
    result = getrgbfromstring(styletool, color, red, rgeen, blue, alpha)
    Bool(result) || error("Error in getting RGBA from Styletool")
    (red[], green[], blue[], alpha[])
end

"""
OGRStyleTable factory.

### Returns
an handle to the new style table object.
"""
unsafe_createstyletable() =
    GDAL.checknull(ccall((:OGR_STBL_Create,GDAL.libgdal),StyleTable,()))

"""
Destroy Style Table.

### Parameters
* `styletable`: handle to the style table to destroy.
"""
destroy(styletable::StyleTable) = GDAL.destroy(styletable)

"""
Add a new style in the table.

### Parameters
* `styletable`: handle to the style table.
* `name`: the name the style to add.
* `stylestring`: the style string to add.

### Returns
TRUE on success, FALSE on error
"""
addstyle!(styletable::StyleTable, stylename::AbstractString,
          stylestring::AbstractString) =
    Bool(GDAL.addstyle(styletable, stylename, stylestring))

"""
Save a style table to a file.
### Parameters
* `styletable`: handle to the style table.
* `filename`: the name of the file to save to.
### Returns
TRUE on success, FALSE on error
"""
savestyletable(styletable::StyleTable, filename::AbstractString) =
    Bool(GDAL.savestyletable(styletable, filename))

"""
Load a style table from a file.

### Parameters
* `styletable`: handle to the style table.
* `filename`: the name of the file to load from.

### Returns
TRUE on success, FALSE on error
"""
loadstyletable!(styletable::StyleTable, filename::AbstractString) =
    Bool(GDAL.loadstyletable(styletable, filename))

"""
Get a style string by name.

### Parameters
* `styletable`: handle to the style table.
* `name`: the name of the style string to find.

### Returns
the style string matching the name or NULL if not found or error.
"""
find(styletable::StyleTable, name::AbstractString) = GDAL.find(styletable, name)

"""
Reset the next style pointer to 0.

### Parameters
* `styletable`: handle to the style table.
"""
resetreading!(styletable::StyleTable) = GDAL.resetstylestringreading(styletable)

"""
Get the next style string from the table.

### Parameters
* `styletable`: handle to the style table.

### Returns
the next style string or NULL on error.
"""
nextstyle(styletable::StyleTable) = GDAL.getnextstyle(styletable)

"""
Get the style name of the last style string fetched with OGR_STBL_GetNextStyle.

### Parameters
* `styletable`: handle to the style table.

### Returns
the Name of the last style string or NULL on error.
"""
laststyle(styletable::StyleTable) = GDAL.getlaststylename(styletable)
