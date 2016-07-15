# """
#     OGR_SM_Create(OGRStyleTableH hStyleTable) -> OGRStyleMgrH
# OGRStyleMgr factory.
# ### Parameters
# * **hStyleTable**: pointer to OGRStyleTable or NULL if not working with a style table.
# ### Returns
# an handle to the new style manager object.
# """
# function create(hStyleTable::Ptr{OGRStyleTableH})
#     checknull(ccall((:OGR_SM_Create,libgdal),Ptr{OGRStyleMgrH},(Ptr{OGRStyleTableH},),hStyleTable))
# end


# """
#     OGR_SM_Destroy(OGRStyleMgrH hSM) -> void
# Destroy Style Manager.
# ### Parameters
# * **hSM**: handle to the style manager to destroy.
# """
# function destroy(hSM::Ptr{OGRStyleMgrH})
#     ccall((:OGR_SM_Destroy,libgdal),Void,(Ptr{OGRStyleMgrH},),hSM)
# end


# """
#     OGR_SM_InitFromFeature(OGRStyleMgrH hSM,
#                            OGRFeatureH hFeat) -> const char *
# Initialize style manager from the style string of a feature.
# ### Parameters
# * **hSM**: handle to the style manager.
# * **hFeat**: handle to the new feature from which to read the style.
# ### Returns
# a reference to the style string read from the feature, or NULL in case of error.
# """
# function initfromfeature(hSM::Ptr{OGRStyleMgrH},hFeat::Ptr{OGRFeatureH})
#     bytestring(ccall((:OGR_SM_InitFromFeature,libgdal),Cstring,(Ptr{OGRStyleMgrH},Ptr{OGRFeatureH}),hSM,hFeat))
# end


# """
#     OGR_SM_InitStyleString(OGRStyleMgrH hSM,
#                            const char * pszStyleString) -> int
# Initialize style manager from the style string.
# ### Parameters
# * **hSM**: handle to the style manager.
# * **pszStyleString**: the style string to use (can be NULL).
# ### Returns
# TRUE on success, FALSE on errors.
# """
# function initstylestring(hSM::Ptr{OGRStyleMgrH},pszStyleString)
#     ccall((:OGR_SM_InitStyleString,libgdal),Cint,(Ptr{OGRStyleMgrH},Cstring),hSM,pszStyleString)
# end


# """
#     OGR_SM_GetPartCount(OGRStyleMgrH hSM,
#                         const char * pszStyleString) -> int
# Get the number of parts in a style.
# ### Parameters
# * **hSM**: handle to the style manager.
# * **pszStyleString**: (optional) the style string on which to operate. If NULL then the current style string stored in the style manager is used.
# ### Returns
# the number of parts (style tools) in the style.
# """
# function getpartcount(hSM::Ptr{OGRStyleMgrH},pszStyleString)
#     ccall((:OGR_SM_GetPartCount,libgdal),Cint,(Ptr{OGRStyleMgrH},Cstring),hSM,pszStyleString)
# end


# """
#     OGR_SM_GetPart(OGRStyleMgrH hSM,
#                    int nPartId,
#                    const char * pszStyleString) -> OGRStyleToolH
# Fetch a part (style tool) from the current style.
# ### Parameters
# * **hSM**: handle to the style manager.
# * **nPartId**: the part number (0-based index).
# * **pszStyleString**: (optional) the style string on which to operate. If NULL then the current style string stored in the style manager is used.
# ### Returns
# OGRStyleToolH of the requested part (style tools) or NULL on error.
# """
# function getpart(hSM::Ptr{OGRStyleMgrH},nPartId::Integer,pszStyleString)
#     checknull(ccall((:OGR_SM_GetPart,libgdal),Ptr{OGRStyleToolH},(Ptr{OGRStyleMgrH},Cint,Cstring),hSM,nPartId,pszStyleString))
# end


# """
#     OGR_SM_AddPart(OGRStyleMgrH hSM,
#                    OGRStyleToolH hST) -> int
# Add a part (style tool) to the current style.
# ### Parameters
# * **hSM**: handle to the style manager.
# * **hST**: the style tool defining the part to add.
# ### Returns
# TRUE on success, FALSE on errors.
# """
# function addpart(hSM::Ptr{OGRStyleMgrH},hST::Ptr{OGRStyleToolH})
#     ccall((:OGR_SM_AddPart,libgdal),Cint,(Ptr{OGRStyleMgrH},Ptr{OGRStyleToolH}),hSM,hST)
# end


# """
#     OGR_SM_AddStyle(OGRStyleMgrH hSM,
#                     const char * pszStyleName,
#                     const char * pszStyleString) -> int
# Add a style to the current style table.
# ### Parameters
# * **hSM**: handle to the style manager.
# * **pszStyleName**: the name of the style to add.
# * **pszStyleString**: the style string to use, or NULL to use the style stored in the manager.
# ### Returns
# TRUE on success, FALSE on errors.
# """
# function addstyle(hSM::Ptr{OGRStyleMgrH},pszStyleName,pszStyleString)
#     ccall((:OGR_SM_AddStyle,libgdal),Cint,(Ptr{OGRStyleMgrH},Cstring,Cstring),hSM,pszStyleName,pszStyleString)
# end


# """
#     OGR_ST_Create(OGRSTClassId eClassId) -> OGRStyleToolH
# OGRStyleTool factory.
# ### Parameters
# * **eClassId**: subclass of style tool to create. One of OGRSTCPen (1), OGRSTCBrush (2), OGRSTCSymbol (3) or OGRSTCLabel (4).
# ### Returns
# an handle to the new style tool object or NULL if the creation failed.
# """
# function create(eClassId::OGRSTClassId)
#     checknull(ccall((:OGR_ST_Create,libgdal),Ptr{OGRStyleToolH},(OGRSTClassId,),eClassId))
# end


# """
#     OGR_ST_Destroy(OGRStyleToolH hST) -> void
# Destroy Style Tool.
# ### Parameters
# * **hST**: handle to the style tool to destroy.
# """
# function destroy(hST::Ptr{OGRStyleToolH})
#     ccall((:OGR_ST_Destroy,libgdal),Void,(Ptr{OGRStyleToolH},),hST)
# end


# """
#     OGR_ST_GetType(OGRStyleToolH hST) -> OGRSTClassId
# Determine type of Style Tool.
# ### Parameters
# * **hST**: handle to the style tool.
# ### Returns
# the style tool type, one of OGRSTCPen (1), OGRSTCBrush (2), OGRSTCSymbol (3) or OGRSTCLabel (4). Returns OGRSTCNone (0) if the OGRStyleToolH is invalid.
# """
# function gettype(hST::Ptr{OGRStyleToolH})
#     ccall((:OGR_ST_GetType,libgdal),OGRSTClassId,(Ptr{OGRStyleToolH},),hST)
# end


# """
#     OGR_ST_GetUnit(OGRStyleToolH hST) -> OGRSTUnitId
# Get Style Tool units.
# ### Parameters
# * **hST**: handle to the style tool.
# ### Returns
# the style tool units.
# """
# function getunit(hST::Ptr{OGRStyleToolH})
#     ccall((:OGR_ST_GetUnit,libgdal),OGRSTUnitId,(Ptr{OGRStyleToolH},),hST)
# end


# """
#     OGR_ST_SetUnit(OGRStyleToolH hST,
#                    OGRSTUnitId eUnit,
#                    double dfGroundPaperScale) -> void
# Set Style Tool units.
# ### Parameters
# * **hST**: handle to the style tool.
# * **eUnit**: the new unit.
# * **dfGroundPaperScale**: ground to paper scale factor.
# """
# function setunit(hST::Ptr{OGRStyleToolH},eUnit::OGRSTUnitId,dfGroundPaperScale::Real)
#     ccall((:OGR_ST_SetUnit,libgdal),Void,(Ptr{OGRStyleToolH},OGRSTUnitId,Cdouble),hST,eUnit,dfGroundPaperScale)
# end


# """
#     OGR_ST_GetParamStr(OGRStyleToolH hST,
#                        int eParam,
#                        int * bValueIsNull) -> const char *
# Get Style Tool parameter value as string.
# ### Parameters
# * **hST**: handle to the style tool.
# * **eParam**: the parameter id from the enumeration corresponding to the type of this style tool (one of the OGRSTPenParam, OGRSTBrushParam, OGRSTSymbolParam or OGRSTLabelParam enumerations)
# * **bValueIsNull**: pointer to an integer that will be set to TRUE or FALSE to indicate whether the parameter value is NULL.
# ### Returns
# the parameter value as string and sets bValueIsNull.
# """
# function getparamstr(hST::Ptr{OGRStyleToolH},eParam::Integer,bValueIsNull)
#     bytestring(ccall((:OGR_ST_GetParamStr,libgdal),Cstring,(Ptr{OGRStyleToolH},Cint,Ptr{Cint}),hST,eParam,bValueIsNull))
# end


# """
#     OGR_ST_GetParamNum(OGRStyleToolH hST,
#                        int eParam,
#                        int * bValueIsNull) -> int
# Get Style Tool parameter value as an integer.
# ### Parameters
# * **hST**: handle to the style tool.
# * **eParam**: the parameter id from the enumeration corresponding to the type of this style tool (one of the OGRSTPenParam, OGRSTBrushParam, OGRSTSymbolParam or OGRSTLabelParam enumerations)
# * **bValueIsNull**: pointer to an integer that will be set to TRUE or FALSE to indicate whether the parameter value is NULL.
# ### Returns
# the parameter value as integer and sets bValueIsNull.
# """
# function getparamnum(hST::Ptr{OGRStyleToolH},eParam::Integer,bValueIsNull)
#     ccall((:OGR_ST_GetParamNum,libgdal),Cint,(Ptr{OGRStyleToolH},Cint,Ptr{Cint}),hST,eParam,bValueIsNull)
# end


# """
#     OGR_ST_GetParamDbl(OGRStyleToolH hST,
#                        int eParam,
#                        int * bValueIsNull) -> double
# Get Style Tool parameter value as a double.
# ### Parameters
# * **hST**: handle to the style tool.
# * **eParam**: the parameter id from the enumeration corresponding to the type of this style tool (one of the OGRSTPenParam, OGRSTBrushParam, OGRSTSymbolParam or OGRSTLabelParam enumerations)
# * **bValueIsNull**: pointer to an integer that will be set to TRUE or FALSE to indicate whether the parameter value is NULL.
# ### Returns
# the parameter value as double and sets bValueIsNull.
# """
# function getparamdbl(hST::Ptr{OGRStyleToolH},eParam::Integer,bValueIsNull)
#     ccall((:OGR_ST_GetParamDbl,libgdal),Cdouble,(Ptr{OGRStyleToolH},Cint,Ptr{Cint}),hST,eParam,bValueIsNull)
# end


# """
#     OGR_ST_SetParamStr(OGRStyleToolH hST,
#                        int eParam,
#                        const char * pszValue) -> void
# Set Style Tool parameter value from a string.
# ### Parameters
# * **hST**: handle to the style tool.
# * **eParam**: the parameter id from the enumeration corresponding to the type of this style tool (one of the OGRSTPenParam, OGRSTBrushParam, OGRSTSymbolParam or OGRSTLabelParam enumerations)
# * **pszValue**: the new parameter value
# """
# function setparamstr(hST::Ptr{OGRStyleToolH},eParam::Integer,pszValue)
#     ccall((:OGR_ST_SetParamStr,libgdal),Void,(Ptr{OGRStyleToolH},Cint,Cstring),hST,eParam,pszValue)
# end


# """
#     OGR_ST_SetParamNum(OGRStyleToolH hST,
#                        int eParam,
#                        int nValue) -> void
# Set Style Tool parameter value from an integer.
# ### Parameters
# * **hST**: handle to the style tool.
# * **eParam**: the parameter id from the enumeration corresponding to the type of this style tool (one of the OGRSTPenParam, OGRSTBrushParam, OGRSTSymbolParam or OGRSTLabelParam enumerations)
# * **nValue**: the new parameter value
# """
# function setparamnum(hST::Ptr{OGRStyleToolH},eParam::Integer,nValue::Integer)
#     ccall((:OGR_ST_SetParamNum,libgdal),Void,(Ptr{OGRStyleToolH},Cint,Cint),hST,eParam,nValue)
# end


# """
#     OGR_ST_SetParamDbl(OGRStyleToolH hST,
#                        int eParam,
#                        double dfValue) -> void
# Set Style Tool parameter value from a double.
# ### Parameters
# * **hST**: handle to the style tool.
# * **eParam**: the parameter id from the enumeration corresponding to the type of this style tool (one of the OGRSTPenParam, OGRSTBrushParam, OGRSTSymbolParam or OGRSTLabelParam enumerations)
# * **dfValue**: the new parameter value
# """
# function setparamdbl(hST::Ptr{OGRStyleToolH},eParam::Integer,dfValue::Real)
#     ccall((:OGR_ST_SetParamDbl,libgdal),Void,(Ptr{OGRStyleToolH},Cint,Cdouble),hST,eParam,dfValue)
# end


# """
#     OGR_ST_GetStyleString(OGRStyleToolH hST) -> const char *
# Get the style string for this Style Tool.
# ### Parameters
# * **hST**: handle to the style tool.
# ### Returns
# the style string for this style tool or "" if the hST is invalid.
# """
# function getstylestring(hST::Ptr{OGRStyleToolH})
#     bytestring(ccall((:OGR_ST_GetStyleString,libgdal),Cstring,(Ptr{OGRStyleToolH},),hST))
# end


# """
#     OGR_ST_GetRGBFromString(OGRStyleToolH hST,
#                             const char * pszColor,
#                             int * pnRed,
#                             int * pnGreen,
#                             int * pnBlue,
#                             int * pnAlpha) -> int
# Return the r,g,b,a components of a color encoded in #RRGGBB[AA] format.
# ### Parameters
# * **hST**: handle to the style tool.
# * **pszColor**: the color to parse
# * **pnRed**: pointer to an int in which the red value will be returned
# * **pnGreen**: pointer to an int in which the green value will be returned
# * **pnBlue**: pointer to an int in which the blue value will be returned
# * **pnAlpha**: pointer to an int in which the (optional) alpha value will be returned
# ### Returns
# TRUE if the color could be successfully parsed, or FALSE in case of errors.
# """
# function getrgbfromstring(hST::Ptr{OGRStyleToolH},pszColor,pnRed,pnGreen,pnBlue,pnAlpha)
#     ccall((:OGR_ST_GetRGBFromString,libgdal),Cint,(Ptr{OGRStyleToolH},Cstring,Ptr{Cint},Ptr{Cint},Ptr{Cint},Ptr{Cint}),hST,pszColor,pnRed,pnGreen,pnBlue,pnAlpha)
# end


# """
#     OGR_STBL_Create(void) -> OGRStyleTableH
# OGRStyleTable factory.
# ### Returns
# an handle to the new style table object.
# """
# function create()
#     checknull(ccall((:OGR_STBL_Create,libgdal),Ptr{OGRStyleTableH},()))
# end


# """
#     OGR_STBL_Destroy(OGRStyleTableH hSTBL) -> void
# Destroy Style Table.
# ### Parameters
# * **hSTBL**: handle to the style table to destroy.
# """
# function destroy(hSTBL::Ptr{OGRStyleTableH})
#     ccall((:OGR_STBL_Destroy,libgdal),Void,(Ptr{OGRStyleTableH},),hSTBL)
# end


# """
#     OGR_STBL_AddStyle(OGRStyleTableH hStyleTable,
#                       const char * pszName,
#                       const char * pszStyleString) -> int
# Add a new style in the table.
# ### Parameters
# * **hStyleTable**: handle to the style table.
# * **pszName**: the name the style to add.
# * **pszStyleString**: the style string to add.
# ### Returns
# TRUE on success, FALSE on error
# """
# function addstyle(hStyleTable::Ptr{OGRStyleTableH},pszName,pszStyleString)
#     ccall((:OGR_STBL_AddStyle,libgdal),Cint,(Ptr{OGRStyleTableH},Cstring,Cstring),hStyleTable,pszName,pszStyleString)
# end


# """
#     OGR_STBL_SaveStyleTable(OGRStyleTableH hStyleTable,
#                             const char * pszFilename) -> int
# Save a style table to a file.
# ### Parameters
# * **hStyleTable**: handle to the style table.
# * **pszFilename**: the name of the file to save to.
# ### Returns
# TRUE on success, FALSE on error
# """
# function savestyletable(hStyleTable::Ptr{OGRStyleTableH},pszFilename)
#     ccall((:OGR_STBL_SaveStyleTable,libgdal),Cint,(Ptr{OGRStyleTableH},Cstring),hStyleTable,pszFilename)
# end


# """
#     OGR_STBL_LoadStyleTable(OGRStyleTableH hStyleTable,
#                             const char * pszFilename) -> int
# Load a style table from a file.
# ### Parameters
# * **hStyleTable**: handle to the style table.
# * **pszFilename**: the name of the file to load from.
# ### Returns
# TRUE on success, FALSE on error
# """
# function loadstyletable(hStyleTable::Ptr{OGRStyleTableH},pszFilename)
#     ccall((:OGR_STBL_LoadStyleTable,libgdal),Cint,(Ptr{OGRStyleTableH},Cstring),hStyleTable,pszFilename)
# end


# """
#     OGR_STBL_Find(OGRStyleTableH hStyleTable,
#                   const char * pszName) -> const char *
# Get a style string by name.
# ### Parameters
# * **hStyleTable**: handle to the style table.
# * **pszName**: the name of the style string to find.
# ### Returns
# the style string matching the name or NULL if not found or error.
# """
# function find(hStyleTable::Ptr{OGRStyleTableH},pszName)
#     bytestring(ccall((:OGR_STBL_Find,libgdal),Cstring,(Ptr{OGRStyleTableH},Cstring),hStyleTable,pszName))
# end


# """
#     OGR_STBL_ResetStyleStringReading(OGRStyleTableH hStyleTable) -> void
# Reset the next style pointer to 0.
# ### Parameters
# * **hStyleTable**: handle to the style table.
# """
# function resetstylestringreading(hStyleTable::Ptr{OGRStyleTableH})
#     ccall((:OGR_STBL_ResetStyleStringReading,libgdal),Void,(Ptr{OGRStyleTableH},),hStyleTable)
# end


# """
#     OGR_STBL_GetNextStyle(OGRStyleTableH hStyleTable) -> const char *
# Get the next style string from the table.
# ### Parameters
# * **hStyleTable**: handle to the style table.
# ### Returns
# the next style string or NULL on error.
# """
# function getnextstyle(hStyleTable::Ptr{OGRStyleTableH})
#     bytestring(ccall((:OGR_STBL_GetNextStyle,libgdal),Cstring,(Ptr{OGRStyleTableH},),hStyleTable))
# end


# """
#     OGR_STBL_GetLastStyleName(OGRStyleTableH hStyleTable) -> const char *
# Get the style name of the last style string fetched with OGR_STBL_GetNextStyle.
# ### Parameters
# * **hStyleTable**: handle to the style table.
# ### Returns
# the Name of the last style string or NULL on error.
# """
# function getlaststylename(hStyleTable::Ptr{OGRStyleTableH})
#     bytestring(ccall((:OGR_STBL_GetLastStyleName,libgdal),Cstring,(Ptr{OGRStyleTableH},),hStyleTable))
# end