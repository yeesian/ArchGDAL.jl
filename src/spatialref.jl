"""
    importCRS(x::GeoFormatTypes.GeoFormat; [order=:compliant])

Import a coordinate reference system from a `GeoFormat` into GDAL,
returning an `ArchGDAL.AbstractSpatialRef`.

## Keyword Arguments
- `order`: Sets the axis mapping strategy. `:trad` will use traditional lon/lat
    axis ordering in any actions done with the crs. `:compliant` (the default)
    will use axis ordering compliant with the relevant CRS authority.
"""
importCRS(x::GFT.GeoFormat; kwargs...)::ISpatialRef =
    importCRS!(newspatialref(; kwargs...), x)

unsafe_importCRS(x::GFT.GeoFormat; kwargs...)::SpatialRef =
    importCRS!(unsafe_newspatialref(; kwargs...), x)

"""
    importCRS!(spref::AbstractSpatialRef, x::GeoFormatTypes.GeoFormat)

Import a coordinate reference system from a `GeoFormat` into the spatial ref.
"""
function importCRS! end

function importCRS!(spref::T, x::GFT.EPSG)::T where {T<:AbstractSpatialRef}
    importEPSG!(spref, GFT.val(x))
    return spref
end

function importCRS!(
    spref::T,
    x::GFT.AbstractWellKnownText,
)::T where {T<:AbstractSpatialRef}
    importWKT!(spref, GFT.val(x))
    return spref
end

function importCRS!(
    spref::T,
    x::GFT.ESRIWellKnownText,
)::T where {T<:AbstractSpatialRef}
    importESRI!(spref, GFT.val(x))
    return spref
end

function importCRS!(
    spref::T,
    x::GFT.ProjString,
)::T where {T<:AbstractSpatialRef}
    importPROJ4!(spref, GFT.val(x))
    return spref
end

function importCRS!(spref::T, x::GFT.GML)::T where {T<:AbstractSpatialRef}
    importXML!(spref, GFT.val(x))
    return spref
end

function importCRS!(spref::T, x::GFT.KML)::T where {T<:AbstractSpatialRef}
    importCRS!(spref, GFT.EPSG(4326))
    return spref
end

"""
    reproject(points, sourceproj::GeoFormat, destproj::GeoFormat;
        [order=:compliant])

Reproject points to a different coordinate reference system and/or format.

## Arguments
- `coord`: Vector of Geometry points
- `sourcecrs`: The current coordinate reference system, as a `GeoFormat`
- `targetcrs`: The coordinate reference system to transform to, using any CRS
    capable `GeoFormat`

## Keyword Arguments
- `order`: Sets the axis mapping strategy. `:trad` will use traditional lon/lat
    axis ordering in any actions done with the crs. `:compliant` (the default)
    will use axis  ordering compliant with the relevant CRS authority.

## Example
```julia-repl
julia> using ArchGDAL, GeoFormatTypes

julia> ArchGDAL.reproject(
    [[118, 34], [119, 35]],
    ProjString("+proj=longlat +datum=WGS84 +no_defs"),
    EPSG(2025)
)
2-element Array{Array{Float64,1},1}:
 [-2.60813482878655e6, 1.5770429674905164e7]
 [-2.663928675953517e6, 1.56208905951487e7]
```
"""
function reproject(
    coord::T,
    sourcecrs::GFT.GeoFormat,
    targetcrs::Nothing;
    kwargs...,
)::T where {T<:Any}
    return coord
end

# These should be better integrated with geometry packages or follow a standard
const ReprojectCoord =
    Union{<:NTuple{2,<:Number},<:NTuple{3,<:Number},AbstractVector{<:Number}}

# Vector/Tuple coordinate(s)
function reproject(
    coord::ReprojectCoord,
    sourcecrs::GFT.GeoFormat,
    targetcrs::GFT.GeoFormat;
    kwargs...,
)
    return GeoInterface.coordinates(
        reproject(createpoint(coord...), sourcecrs, targetcrs; kwargs...),
    )
end

function reproject(
    coords::AbstractArray{<:ReprojectCoord},
    sourcecrs::GFT.GeoFormat,
    targetcrs::GFT.GeoFormat;
    kwargs...,
)
    return GeoInterface.coordinates.(
        reproject(
            [createpoint(c...) for c in coords],
            sourcecrs,
            targetcrs;
            kwargs...,
        ),
    )
end

# GeoFormat
function reproject(
    geom::GFT.GeoFormat,
    sourcecrs::GFT.GeoFormat,
    targetcrs::GFT.GeoFormat;
    kwargs...,
)
    return convert(
        typeof(geom),
        reproject(convert(IGeometry, geom), sourcecrs, targetcrs; kwargs...),
    )
end

# Geometries
function reproject(
    geom::AbstractGeometry,
    sourcecrs::GFT.GeoFormat,
    targetcrs::GFT.GeoFormat;
    kwargs...,
)
    return crs2transform(sourcecrs, targetcrs; kwargs...) do transform
        return transform!(geom, transform)
    end
end

function reproject(
    geoms::AbstractArray{<:AbstractGeometry},
    sourcecrs::GFT.GeoFormat,
    targetcrs::GFT.GeoFormat;
    kwargs...,
)
    return crs2transform(sourcecrs, targetcrs; kwargs...) do transform
        return transform!.(geoms, Ref(transform))
    end
end

"""
    crs2transform(f::Function, sourcecrs::GeoFormat, targetcrs::GeoFormat;
        kwargs...)

Run the function `f` on a coord transform generated from the source and target
crs definitions. These can be any `GeoFormat` (from GeoFormatTypes) that holds
a coordinate reference system.

`kwargs` are passed through to `importCRS`.
"""
function crs2transform(
    f::Function,
    sourcecrs::GFT.GeoFormat,
    targetcrs::GFT.GeoFormat;
    kwargs...,
)
    return importCRS(sourcecrs; kwargs...) do sourcecrs_ref
        importCRS(targetcrs; kwargs...) do targetcrs_ref
            createcoordtrans(sourcecrs_ref, targetcrs_ref) do transform
                return f(transform)
            end
        end
    end
end

"""
    newspatialref(wkt::AbstractString = ""; order=:compliant)

Construct a Spatial Reference System from its WKT.

# Keyword Arguments
- `order`: Sets the axis mapping strategy. `:trad` will use traditional lon/lat
    axis ordering in any actions done with the crs. `:compliant`, will use axis
    ordering compliant with the relevant CRS authority.
"""
function newspatialref(wkt::AbstractString = ""; order::Symbol = :compliant)
    return maybesetaxisorder!(
        ISpatialRef(GDAL.osrnewspatialreference(wkt)),
        order,
    )
end

function unsafe_newspatialref(
    wkt::AbstractString = "";
    order::Symbol = :compliant,
)
    return maybesetaxisorder!(
        SpatialRef(GDAL.osrnewspatialreference(wkt)),
        order,
    )
end

function maybesetaxisorder!(
    spref::T,
    order::Symbol,
)::T where {T<:AbstractSpatialRef}
    if order == :trad
        GDAL.osrsetaxismappingstrategy(spref, GDAL.OAMS_TRADITIONAL_GIS_ORDER)
    elseif order != :compliant
        throw(
            ArgumentError(
                "order $order is not supported. Use :trad or :compliant",
            ),
        )
    end
    return spref
end

function destroy(spref::AbstractSpatialRef)::Nothing
    GDAL.osrdestroyspatialreference(spref)
    spref.ptr = C_NULL
    return nothing
end

"""
    clone(spref::AbstractSpatialRef)

Makes a clone of the Spatial Reference System. May return NULL.
"""
function clone(spref::AbstractSpatialRef)::ISpatialRef
    return if spref.ptr == C_NULL
        ISpatialRef()
    else
        ISpatialRef(GDAL.osrclone(spref))
    end
end

function unsafe_clone(spref::AbstractSpatialRef)::SpatialRef
    return if spref.ptr == C_NULL
        SpatialRef()
    else
        SpatialRef(GDAL.osrclone(spref))
    end
end

"""
    importEPSG!(spref::AbstractSpatialRef, code::Integer)

Initialize SRS based on EPSG GCS or PCS code.

This method will initialize the spatial reference based on the passed in
EPSG GCS or PCS code. It is relatively expensive, and generally involves quite a
bit of text file scanning. Reasonable efforts should be made to avoid calling it
many times for the same coordinate system.

### Additional Remarks
This method is similar to importFromEPSGA() except that EPSG preferred axis
ordering will not be applied for geographic coordinate systems. EPSG normally
defines geographic coordinate systems to use lat/long contrary to typical GIS
use). Since OGR 1.10.0, EPSG preferred axis ordering will also not be applied
for projected coordinate systems that use northing/easting order.

The coordinate system definitions are normally read from the EPSG derived
support files such as pcs.csv, gcs.csv, pcs.override.csv, gcs.override.csv and
falling back to search for a PROJ.4 epsg init file or a definition in epsg.wkt.

These support files are normally searched for in /usr/local/share/gdal or in the
directory identified by the GDAL_DATA configuration option. See CPLFindFile()
for details.
"""
function importEPSG!(spref::T, code::Integer)::T where {T<:AbstractSpatialRef}
    result = GDAL.osrimportfromepsg(spref, code)
    @ogrerr result "Failed to initialize SRS based on EPSG"
    return spref
end

"""
    importEPSG(code::Integer; [order=:compliant])

Construct a Spatial Reference System from its EPSG GCS or PCS code.

# Keyword Arguments
- `order`: Sets the axis mapping strategy. `:trad` will use traditional lon/lat
    axis ordering in any actions done with the crs. `:compliant`, will use axis
    ordering compliant with the relevant CRS authority.
"""
importEPSG(code::Integer; kwargs...)::ISpatialRef =
    importEPSG!(newspatialref(; kwargs...), code)

unsafe_importEPSG(code::Integer; kwargs...)::SpatialRef =
    importEPSG!(unsafe_newspatialref(; kwargs...), code)

"""
    importEPSGA!(spref::AbstractSpatialRef, code::Integer)

Initialize SRS based on EPSG CRS code.

This method is similar to `importFromEPSG()` except that EPSG preferred axis
ordering will be applied for geographic and projected coordinate systems. EPSG
normally defines geographic coordinate systems to use lat/long, and also there
are also a few projected coordinate systems that use northing/easting order
contrary to typical GIS use). See `importFromEPSG()` for more
details on operation of this method.
"""
function importEPSGA!(spref::T, code::Integer)::T where {T<:AbstractSpatialRef}
    result = GDAL.osrimportfromepsga(spref, code)
    @ogrerr result "Failed to initializ SRS based on EPSGA"
    return spref
end

"""
    importEPSGA(code::Integer; [order=:compliant])

Construct a Spatial Reference System from its EPSG CRS code.

This method is similar to `importFromEPSG()` except that EPSG preferred axis
ordering will be applied for geographic and projected coordinate systems. EPSG
normally defines geographic coordinate systems to use lat/long, and also there
are also a few projected coordinate systems that use northing/easting order
contrary to typical GIS use). See `importFromEPSG()` for more
details on operation of this method.

# Keyword Arguments
- `order`: Sets the axis mapping strategy. `:trad` will use traditional lon/lat
    axis  ordering in any actions done with the crs. `:compliant`, will use axis
    ordering compliant with the relevant CRS authority.
"""
importEPSGA(code::Integer; kwargs...)::ISpatialRef =
    importEPSGA!(newspatialref(; kwargs...), code)

unsafe_importEPSGA(code::Integer; kwargs...)::SpatialRef =
    importEPSGA!(unsafe_newspatialref(; kwargs...), code)

"""
    importWKT!(spref::AbstractSpatialRef, wktstr::AbstractString)

Import from WKT string.

This method will wipe the existing SRS definition, and reassign it based on the
contents of the passed WKT string. Only as much of the input string as needed to
construct this SRS is consumed from the input string, and the input string
pointer is then updated to point to the remaining (unused) input.
"""
function importWKT!(
    spref::T,
    wktstr::AbstractString,
)::T where {T<:AbstractSpatialRef}
    result = GDAL.osrimportfromwkt(spref, [wktstr])
    @ogrerr result "Failed to initialize SRS based on WKT string"
    return spref
end

"""
    importWKT(wktstr::AbstractString; [order=:compliant])

Create SRS from its WKT string.

# Keyword Arguments
- `order`: Sets the axis mapping strategy. `:trad` will use traditional lon/lat
    axis  ordering in any actions done with the crs. `:compliant`, will use axis
    ordering compliant with the relevant CRS authority.
"""
importWKT(wktstr::AbstractString; kwargs...)::ISpatialRef =
    newspatialref(wktstr; kwargs...)

unsafe_importWKT(wktstr::AbstractString; kwargs...)::SpatialRef =
    unsafe_newspatialref(wktstr; kwargs...)

"""
    importPROJ4!(spref::AbstractSpatialRef, projstr::AbstractString)

Import PROJ.4 coordinate string.

The OGRSpatialReference is initialized from the passed PROJ.4 style coordinate
system string. In addition to many `+proj` formulations which have OGC
equivalents, it is also possible to import `"+init=epsg:n"` style definitions.
These are passed to `importFromEPSG()`. Other init strings (such as the state
plane zones) are not currently supported.

Example: `pszProj4 = \"+proj=utm +zone=11 +datum=WGS84\"`

Some parameters, such as grids, recognized by PROJ.4 may not be well understood
and translated into the OGRSpatialReference model. It is possible to add the
`+wktext` parameter which is a special keyword that OGR recognized as meaning
\"embed the entire PROJ.4 string in the WKT and use it literally when converting
back to PROJ.4 format\".

For example: `\"+proj=nzmg +lat_0=-41 +lon_0=173 +x_0=2510000 +y_0=6023150
+ellps=intl +units=m +nadgrids=nzgd2kgrid0005.gsb +wktext\"`
"""
function importPROJ4!(
    spref::T,
    projstr::AbstractString,
)::T where {T<:AbstractSpatialRef}
    result = GDAL.osrimportfromproj4(spref, projstr)
    @ogrerr result "Failed to initialize SRS based on PROJ4 string"
    return spref
end

"""
    importPROJ4(projstr::AbstractString; [order=:compliant])

Create SRS from its PROJ.4 string.

# Keyword Arguments
- `order`: Sets the axis mapping strategy. `:trad` will use traditional lon/lat
    axis ordering in any actions done with the crs. `:compliant`, will use axis
    ordering compliant with the relevant CRS authority.
"""
importPROJ4(projstr::AbstractString; kwargs...)::ISpatialRef =
    importPROJ4!(newspatialref(; kwargs...), projstr)

unsafe_importPROJ4(projstr::AbstractString; kwargs...)::SpatialRef =
    importPROJ4!(unsafe_newspatialref(; kwargs...), projstr)

"""
    importESRI!(spref::AbstractSpatialRef, esristr::AbstractString)

Import coordinate system from ESRI .prj format(s).

This function will read the text loaded from an ESRI .prj file, and translate it
into an OGRSpatialReference definition. This should support many (but by no
means all) old style (Arc/Info 7.x) .prj files, as well as the newer pseudo-OGC
WKT .prj files. Note that new style .prj files are in OGC WKT format, but
require some manipulation to correct datum names, and units on some projection
parameters. This is addressed within `importFromESRI()` by an automatic call to
`morphFromESRI()`.

Currently only `GEOGRAPHIC`, `UTM`, `STATEPLANE`, `GREATBRITIAN_GRID`, `ALBERS`,
`EQUIDISTANT_CONIC`, `TRANSVERSE (mercator)`, `POLAR`, `MERCATOR` and
`POLYCONIC` projections are supported from old style files.

At this time there is no equivalent `exportToESRI()` method. Writing old style
.prj files is not supported by OGRSpatialReference. However the `morphToESRI()`
and `exportToWkt()` methods can be used to generate output suitable to write to
new style (Arc 8) .prj files.
"""
function importESRI!(
    spref::T,
    esristr::AbstractString,
)::T where {T<:AbstractSpatialRef}
    result = GDAL.osrimportfromesri(spref, [esristr])
    @ogrerr result "Failed to initialize SRS based on ESRI string"
    return spref
end

"""
    importESRI(esristr::AbstractString; kwargs...)

Create SRS from its ESRI .prj format(s).

Passing the keyword argument `order=:compliant` or `order=:trad` will set the
mapping strategy to return compliant axis order or traditional lon/lat order.
"""
importESRI(esristr::AbstractString; kwargs...)::ISpatialRef =
    importESRI!(newspatialref(; kwargs...), esristr)

unsafe_importESRI(esristr::AbstractString; kwargs...)::SpatialRef =
    importESRI!(unsafe_newspatialref(; kwargs...), esristr)

"""
    importXML!(spref::AbstractSpatialRef, xmlstr::AbstractString)

Import SRS from XML format (GML only currently).
"""
function importXML!(
    spref::T,
    xmlstr::AbstractString,
)::T where {T<:AbstractSpatialRef}
    result = GDAL.osrimportfromxml(spref, xmlstr)
    @ogrerr result "Failed to initialize SRS based on XML string"
    return spref
end

"""
    importXML(xmlstr::AbstractString; [order=:compliant])

Construct SRS from XML format (GML only currently).

Passing the keyword argument `order=:compliant` or `order=:trad` will set the
mapping strategy to return compliant axis order or traditional lon/lat order.

# Keyword Arguments
- `order`: Sets the axis mapping strategy. `:trad` will use traditional lon/lat
    axis ordering in any actions done with the crs. `:compliant`, will use axis
    ordering compliant with the relevant CRS authority.
"""
importXML(xmlstr::AbstractString; kwargs...)::ISpatialRef =
    importXML!(newspatialref(; kwargs...), xmlstr)

unsafe_importXML(xmlstr::AbstractString; kwargs...)::SpatialRef =
    importXML!(unsafe_newspatialref(; kwargs...), xmlstr)

"""
    importURL!(spref::AbstractSpatialRef, url::AbstractString)

Set spatial reference from a URL.

This method will download the spatial reference at a given URL and feed it into
SetFromUserInput for you.
"""
function importURL!(
    spref::T,
    url::AbstractString,
)::T where {T<:AbstractSpatialRef}
    result = GDAL.osrimportfromurl(spref, url)
    @ogrerr result "Failed to initialize SRS from URL"
    return spref
end

"""
    importURL(url::AbstractString; [order=:compliant])

Construct SRS from a URL.

This method will download the spatial reference at a given URL and feed it into
SetFromUserInput for you.

# Keyword Arguments
- `order`: Sets the axis mapping strategy. `:trad` will use traditional lon/lat
    axis ordering in any actions done with the crs. `:compliant`, will use axis
    ordering compliant with the relevant CRS authority.
"""
importURL(url::AbstractString; kwargs...)::ISpatialRef =
    importURL!(newspatialref(; kwargs...), url)

unsafe_importURL(url::AbstractString; kwargs...)::SpatialRef =
    importURL!(unsafe_newspatialref(; kwargs...), url)

"""
    toWKT(spref::AbstractSpatialRef)

Convert this SRS into WKT format.
"""
function toWKT(spref::AbstractSpatialRef)::String
    wktptr = Ref{Cstring}()
    result = GDAL.osrexporttowkt(spref, wktptr)
    @ogrerr result "Failed to convert this SRS into WKT format"
    return unsafe_string(wktptr[])
end

"""
    toWKT(spref::AbstractSpatialRef, simplify::Bool)

Convert this SRS into a nicely formatted WKT string for display to a person.

### Parameters
* `spref`:      the SRS to be converted
* `simplify`:   `true` if the `AXIS`, `AUTHORITY` and `EXTENSION` nodes should
                be stripped off.
"""
function toWKT(spref::AbstractSpatialRef, simplify::Bool)::String
    wktptr = Ref{Cstring}()
    result = GDAL.osrexporttoprettywkt(spref, wktptr, simplify)
    @ogrerr result "Failed to convert this SRS into pretty WKT"
    return unsafe_string(wktptr[])
end

"""
    toPROJ4(spref::AbstractSpatialRef)

Export coordinate system in PROJ.4 format.
"""
function toPROJ4(spref::AbstractSpatialRef)::String
    projptr = Ref{Cstring}()
    result = GDAL.osrexporttoproj4(spref, projptr)
    @ogrerr result "Failed to export this SRS to PROJ.4 format"
    return unsafe_string(projptr[])
end

"""
    toXML(spref::AbstractSpatialRef)

Export coordinate system in XML format.

Converts the loaded coordinate reference system into XML format to the extent
possible. LOCAL_CS coordinate systems are not translatable. An empty string will
be returned along with OGRERR_NONE.
"""
function toXML(spref::AbstractSpatialRef)::String
    xmlptr = Ref{Cstring}()
    result = GDAL.osrexporttoxml(spref, xmlptr, C_NULL)
    @ogrerr result "Failed to convert this SRS into XML"
    return unsafe_string(xmlptr[])
end

"""
    toMICoordSys(spref::AbstractSpatialRef)

Export coordinate system in Mapinfo style CoordSys format.
"""
function toMICoordSys(spref::AbstractSpatialRef)::String
    ptr = Ref{Cstring}()
    result = GDAL.osrexporttomicoordsys(spref, ptr)
    @ogrerr result "Failed to convert this SRS into XML"
    return unsafe_string(ptr[])
end

"""
    morphtoESRI!(spref::AbstractSpatialRef)

Convert in place to ESRI WKT format.

The value nodes of this coordinate system are modified in various manners more
closely map onto the ESRI concept of WKT format. This includes renaming a
variety of projections and arguments, and stripping out nodes note recognised by
ESRI (like AUTHORITY and AXIS).
"""
function morphtoESRI!(spref::T)::T where {T<:AbstractSpatialRef}
    result = GDAL.osrmorphtoesri(spref)
    @ogrerr result "Failed to convert in place to ESRI WKT format"
    return spref
end

"""
    morphfromESRI!(spref::AbstractSpatialRef)

Convert in place from ESRI WKT format.

The value notes of this coordinate system are modified in various manners to
adhere more closely to the WKT standard. This mostly involves translating a
variety of ESRI names for projections, arguments and datums to "standard" names,
as defined by Adam Gawne-Cain's reference translation of EPSG to WKT for the CT
specification.

Missing parameters in `TOWGS84`, `DATUM` or `GEOGCS` nodes can be added to the
`WKT`, comparing existing `WKT` parameters to GDAL's databases. Note that this
optional procedure is very conservative and should not introduce false
information into the WKT definition (although caution should be advised when
activating it). Needs the Configuration Option `GDAL_FIX_ESRI_WKT` be set to one
of the following (`TOWGS84` recommended for proper datum shift calculations)

`GDAL_FIX_ESRI_WKT` values:

* `TOWGS84` Adds missing TOWGS84 parameters (necessary for datum
        transformations), based on named datum and spheroid values.
* `DATUM`   Adds EPSG AUTHORITY nodes and sets SPHEROID name to OGR spec.
* `GEOGCS`  Adds EPSG AUTHORITY nodes and sets `GEOGCS`, `DATUM` and `SPHEROID`
        names to OGR spec. Effectively replaces `GEOGCS` node with the result of
        `importFromEPSG(n)`, using `EPSG` code `n` corresponding to the existing
        `GEOGCS`. Does not impact `PROJCS` values.
"""
function morphfromESRI!(spref::T)::T where {T<:AbstractSpatialRef}
    result = GDAL.osrmorphfromesri(spref)
    @ogrerr result "Failed to convert in place from ESRI WKT format"
    return spref
end

"""
    setattrvalue!(spref::AbstractSpatialRef, path::AbstractString,
        value::AbstractString)

Set attribute value in spatial reference.

Missing intermediate nodes in the path will be created if not already in
existence. If the attribute has no children one will be created and assigned
the value otherwise the zeroth child will be assigned the value.

### Parameters
* `path`: full path to attribute to be set. For instance "PROJCS|GEOGCS|UNIT".
* `value`: (optional) to be assigned to node, such as "meter". This may be left
            out if you just want to force creation of the intermediate path.
"""
function setattrvalue!(
    spref::T,
    path::AbstractString,
    value::AbstractString,
)::T where {T<:AbstractSpatialRef}
    result = GDAL.osrsetattrvalue(spref, path, value)
    @ogrerr result "Failed to set attribute path to value"
    return spref
end

function setattrvalue!(
    spref::T,
    path::AbstractString,
)::T where {T<:AbstractSpatialRef}
    result = GDAL.osrsetattrvalue(spref, path, C_NULL)
    @ogrerr result "Failed to set attribute path"
    return spref
end

"""
    getattrvalue(spref::AbstractSpatialRef, name::AbstractString, i::Integer)

Fetch indicated attribute of named node.

This method uses GetAttrNode() to find the named node, and then extracts the
value of the indicated child. Thus a call to `getattrvalue(spref,"UNIT",1)`
would return the second child of the UNIT node, which is normally the length of
the linear unit in meters.

Parameters
`name` the tree node to look for (case insensitive).
`i`    the child of the node to fetch (zero based).

Returns
the requested value, or `nothing` if it fails for any reason.
"""
function getattrvalue(
    spref::AbstractSpatialRef,
    name::AbstractString,
    i::Integer,
)::Union{String,Nothing}
    return GDAL.osrgetattrvalue(spref, name, i)
end

"""
    unsafe_createcoordtrans(source::AbstractSpatialRef,
        target::AbstractSpatialRef)

Create transformation object.

### Parameters
* `source`: source spatial reference system.
* `target`: target spatial reference system.

### Returns
NULL on failure or a ready to use transformation object.
"""
function unsafe_createcoordtrans(
    source::AbstractSpatialRef,
    target::AbstractSpatialRef,
)::CoordTransform
    return CoordTransform(GDAL.octnewcoordinatetransformation(source, target))
end

"OGRCoordinateTransformation destructor."
function destroy(obj::CoordTransform)::Nothing
    GDAL.octdestroycoordinatetransformation(obj)
    obj.ptr = C_NULL
    return nothing
end

"""
    transform!(xvertices, yvertices, zvertices, obj::CoordTransform)

Transform points from source to destination space.

### Parameters
* `xvertices`   array of nCount X vertices, modified in place.
* `yvertices`   array of nCount Y vertices, modified in place.
* `zvertices`   array of nCount Z vertices, modified in place.

### Returns
`true` on success, or `false` if some or all points fail to transform.
"""
function transform!(
    xvertices::Vector{Cdouble},
    yvertices::Vector{Cdouble},
    zvertices::Vector{Cdouble},
    obj::CoordTransform,
)::Bool
    # The method TransformEx() allows extended success information to be
    # captured indicating which points failed to transform.
    n = length(xvertices)
    @assert length(yvertices) == n
    @assert length(zvertices) == n
    return Bool(
        GDAL.octtransform(
            obj,
            n,
            pointer(xvertices),
            pointer(yvertices),
            pointer(zvertices),
        ),
    )
end
