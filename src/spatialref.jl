"""
    importCRS(x::GeoFormatTypes.GeoFormat; [order=nothing])

Import a coordinate reference system from a `GeoFormat` into GDAL,
returning an `ArchGDAL.AbstractSpatialRef`.

`x` may itself be an `AbstractSpatialRef`, in which case it is cloned. The clone
keeps the axis mapping strategy of the original unless `order` is given.

## Keyword Arguments
- `order`: Sets the axis mapping strategy. `:trad` uses traditional lon/lat
    axis ordering in any actions done with the crs, and `:compliant` uses the
    axis ordering of the relevant CRS authority. The default, `nothing`, leaves
    GDAL's own default in place: authority-compliant, unless the
    `OSR_DEFAULT_AXIS_MAPPING_STRATEGY` config option says otherwise.
"""
importCRS(x::GFT.GeoFormat; kwargs...)::ISpatialRef =
    importCRS!(newspatialref(; kwargs...), x)

unsafe_importCRS(x::GFT.GeoFormat; kwargs...)::SpatialRef =
    importCRS!(unsafe_newspatialref(; kwargs...), x)

# A spatial ref is already a GDAL SRS, so clone it instead of round-tripping
# through a string. Cloning is not optional: `crs2transform` reaches these
# through the `unsafe_` form and destroys the result, which would otherwise
# free the caller's own spatial ref.
importCRS(x::AbstractSpatialRef; order = nothing)::ISpatialRef =
    maybesetaxisorder!(clone(x), order)

unsafe_importCRS(x::AbstractSpatialRef; order = nothing)::SpatialRef =
    maybesetaxisorder!(unsafe_clone(x), order)

"""
    importCRS!(spref::AbstractSpatialRef, x::GeoFormatTypes.GeoFormat)

Import a coordinate reference system from a `GeoFormat` into the spatial ref.
"""
function importCRS! end

function importCRS!(spref::T, x::GFT.EPSG{1})::T where {T<:AbstractSpatialRef}
    importEPSG!(spref, GFT.val(x))
    return spref
end

function importCRS!(spref::T, x::GFT.EPSG{2})::T where {T<:AbstractSpatialRef}
    importUserInput!(spref, convert(String, x))
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

function importCRS!(spref::T, ::GFT.KML)::T where {T<:AbstractSpatialRef}
    importCRS!(spref, GFT.EPSG(4326))
    return spref
end

function importCRS!(spref::T, x::GFT.ProjJSON) where {T<:AbstractSpatialRef}
    json = GFT.val(x)
    isa(json, Dict) && error("ProjJSON must be provided as a String.")
    importUserInput!(spref, json)
    return spref
end

function importCRS!(
    spref::T,
    x::AbstractSpatialRef,
)::T where {T<:AbstractSpatialRef}
    importWKT!(spref, toWKT2(x))
    # WKT carries neither of these, but `==` (OSRIsSame) compares the epoch
    # and transforms depend on the mapping, so copy them across rather than
    # silently dropping them.
    strategy = GDAL.osrgetaxismappingstrategy(x)
    GDAL.osrsetaxismappingstrategy(spref, strategy)
    if strategy == GDAL.OAMS_CUSTOM
        setaxismapping!(spref, getaxismapping(x))
    end
    setcoordinateepoch!(spref, getcoordinateepoch(x))
    return spref
end

"""
    reproject(points, sourceproj::GeoFormat, destproj::GeoFormat;
        [order=nothing])

Reproject points to a different coordinate reference system and/or format.

## Arguments
- `coord`: Vector of Geometry points
- `sourcecrs`: The current coordinate reference system, as a `GeoFormat`
- `targetcrs`: The coordinate reference system to transform to, using any CRS
    capable `GeoFormat`

## Keyword Arguments
- `order`: Sets the axis mapping strategy. `:trad` uses traditional lon/lat
    axis ordering in any actions done with the crs, and `:compliant` uses the
    axis ordering of the relevant CRS authority. The default, `nothing`, leaves
    GDAL's own default in place: authority-compliant, unless the
    `OSR_DEFAULT_AXIS_MAPPING_STRATEGY` config option says otherwise.

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

# GeoFormat. Restricted to the formats that can actually hold a geometry, so
# that passing a crs here by mistake is a MethodError rather than a failure
# inside `convert`.
function reproject(
    geom::Union{GFT.GeometryFormat,GFT.MixedFormat},
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
a coordinate reference system, including an `ArchGDAL.AbstractSpatialRef`.

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
    newspatialref(wkt::AbstractString = ""; order=nothing)

Construct a Spatial Reference System from its WKT.

# Keyword Arguments
- `order`: Sets the axis mapping strategy. `:trad` uses traditional lon/lat
    axis ordering in any actions done with the crs, and `:compliant` uses the
    axis ordering of the relevant CRS authority. The default, `nothing`, leaves
    GDAL's own default in place: authority-compliant, unless the
    `OSR_DEFAULT_AXIS_MAPPING_STRATEGY` config option says otherwise.
"""
function newspatialref(
    wkt::AbstractString = "";
    order::Union{Symbol,Nothing} = nothing,
)
    return maybesetaxisorder!(
        ISpatialRef(GDAL.osrnewspatialreference(wkt)),
        order,
    )
end

function unsafe_newspatialref(
    wkt::AbstractString = "";
    order::Union{Symbol,Nothing} = nothing,
)
    return maybesetaxisorder!(
        SpatialRef(GDAL.osrnewspatialreference(wkt)),
        order,
    )
end

# `nothing` leaves whatever strategy GDAL applied, which is not the same as
# `:compliant`: GDAL honours the OSR_DEFAULT_AXIS_MAPPING_STRATEGY config
# option when constructing an SRS, so forcing authority-compliant order here
# would silently override anyone who set it to TRADITIONAL_GIS_ORDER.
function maybesetaxisorder!(
    spref::T,
    ::Nothing,
)::T where {T<:AbstractSpatialRef}
    return spref
end

function maybesetaxisorder!(
    spref::T,
    order::Symbol,
)::T where {T<:AbstractSpatialRef}
    if order === :trad
        GDAL.osrsetaxismappingstrategy(spref, GDAL.OAMS_TRADITIONAL_GIS_ORDER)
    elseif order === :compliant
        GDAL.osrsetaxismappingstrategy(spref, GDAL.OAMS_AUTHORITY_COMPLIANT)
    else
        throw(
            ArgumentError(
                "order $order is not supported. Use :trad or :compliant",
            ),
        )
    end
    return spref
end

"""
    getaxismapping(spref::AbstractSpatialRef)

Return the data axis to CRS axis mapping, as 1-based axis indices.
"""
function getaxismapping(spref::AbstractSpatialRef)::Vector{Cint}
    count = Ref{Cint}(0)
    ptr = GDAL.osrgetdataaxistosrsaxismapping(spref, count)
    ptr == C_NULL && return Cint[]
    # The array belongs to GDAL, so read it out rather than wrapping it.
    return [unsafe_load(ptr, i) for i in 1:count[]]
end

"""
    setaxismapping!(spref::AbstractSpatialRef, mapping)

Set a custom data axis to CRS axis mapping, which also sets the axis mapping
strategy to `OAMS_CUSTOM`.
"""
function setaxismapping!(
    spref::T,
    mapping::AbstractVector{<:Integer},
)::T where {T<:AbstractSpatialRef}
    result = GDAL.osrsetdataaxistosrsaxismapping(
        spref,
        length(mapping),
        convert(Vector{Cint}, mapping),
    )
    @ogrerr result "Failed to set the data axis to CRS axis mapping"
    return spref
end

"""
    getcoordinateepoch(spref::AbstractSpatialRef)

Return the coordinate epoch as a decimal year, or `0.0` if none is set.
"""
getcoordinateepoch(spref::AbstractSpatialRef)::Float64 =
    GDAL.osrgetcoordinateepoch(spref)

"""
    setcoordinateepoch!(spref::AbstractSpatialRef, epoch::Real)

Set the coordinate epoch, as a decimal year. `0` unsets it.
"""
function setcoordinateepoch!(
    spref::T,
    epoch::Real,
)::T where {T<:AbstractSpatialRef}
    GDAL.osrsetcoordinateepoch(spref, epoch)
    return spref
end

"""
    isempty(spref::AbstractSpatialRef)

Whether the spatial reference holds no coordinate reference system definition.

This is `true` both for a NULL handle and for a live but unpopulated SRS, such
as the one `newspatialref()` returns before a CRS has been imported into it.
Exporting an empty SRS to any format is an error, so check this first when the
spatial ref may not have been filled in.
"""
function isempty(spref::AbstractSpatialRef)::Bool
    spref.ptr == C_NULL && return true
    # GDAL has no OSRIsEmpty, but an SRS with nothing in it has no name.
    return GDAL.osrgetname(spref) === nothing
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

# `deepcopy` otherwise copies the `ptr` field verbatim and bypasses the inner
# constructor, so the copy would alias GDAL's object without owning it, and
# read freed memory once the original is destroyed or finalized. Clone the
# underlying SRS instead. Like every `SpatialRef`, the copy `deepcopy` hands
# back for one is not finalized and has to be `destroy`ed by the caller.
function Base.deepcopy_internal(spref::ISpatialRef, stackdict::IdDict)
    haskey(stackdict, spref) && return stackdict[spref]
    copied = clone(spref)
    stackdict[spref] = copied
    return copied
end

function Base.deepcopy_internal(spref::SpatialRef, stackdict::IdDict)
    haskey(stackdict, spref) && return stackdict[spref]
    copied = unsafe_clone(spref)
    stackdict[spref] = copied
    return copied
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
    importEPSG(code::Integer; [order=nothing])

Construct a Spatial Reference System from its EPSG GCS or PCS code.

# Keyword Arguments
- `order`: Sets the axis mapping strategy. `:trad` uses traditional lon/lat
    axis ordering in any actions done with the crs, and `:compliant` uses the
    axis ordering of the relevant CRS authority. The default, `nothing`, leaves
    GDAL's own default in place: authority-compliant, unless the
    `OSR_DEFAULT_AXIS_MAPPING_STRATEGY` config option says otherwise.
"""
importEPSG(code::Integer; kwargs...)::ISpatialRef =
    importEPSG!(newspatialref(; kwargs...), code)

unsafe_importEPSG(code::Integer; kwargs...)::SpatialRef =
    importEPSG!(unsafe_newspatialref(; kwargs...), code)

"""
    importUserInput(code::AbstractString; [order=nothing])

Construct a Spatial Reference System from a user provided code that is parsed by GDAL.
This is useful when the input code is in an unknown format or a shortcut not covered by more constrained methods.
An example is the code "EPSG:4326+3855", the shortest way to describe a combination of a horizontal and vertical crs.

# Keyword Arguments
- `order`: Sets the axis mapping strategy. `:trad` uses traditional lon/lat
    axis ordering in any actions done with the crs, and `:compliant` uses the
    axis ordering of the relevant CRS authority. The default, `nothing`, leaves
    GDAL's own default in place: authority-compliant, unless the
    `OSR_DEFAULT_AXIS_MAPPING_STRATEGY` config option says otherwise.
"""
importUserInput(code::AbstractString; kwargs...)::ISpatialRef =
    importUserInput!(newspatialref(; kwargs...), code)

unsafe_importUserInput(code::AbstractString; kwargs...)::SpatialRef =
    importUserInput!(unsafe_newspatialref(; kwargs...), code)

"""
    ISpatialRef(input::AbstractString; [order=nothing])

Construct a Spatial Reference System from any string GDAL can parse: WKT1, WKT2,
a PROJ.4 string, `"EPSG:4326"`, a URN, or PROJJSON. Equivalent to
[`importUserInput`](@ref).

This is also what `convert(ISpatialRef, ::AbstractString)` uses, so a spatial
ref round-trips through `GeoFormatTypes.val`.
"""
ISpatialRef(input::AbstractString; kwargs...)::ISpatialRef =
    importUserInput(input; kwargs...)

function importUserInput!(
    spref::T,
    code::AbstractString,
)::T where {T<:AbstractSpatialRef}
    result = GDAL.osrsetfromuserinput(spref, code)
    @ogrerr result "Failed to initialize SRS based on user input"
    return spref
end

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
    importEPSGA(code::Integer; [order=nothing])

Construct a Spatial Reference System from its EPSG CRS code.

This method is similar to `importFromEPSG()` except that EPSG preferred axis
ordering will be applied for geographic and projected coordinate systems. EPSG
normally defines geographic coordinate systems to use lat/long, and also there
are also a few projected coordinate systems that use northing/easting order
contrary to typical GIS use). See `importFromEPSG()` for more
details on operation of this method.

# Keyword Arguments
- `order`: Sets the axis mapping strategy. `:trad` uses traditional lon/lat
    axis ordering in any actions done with the crs, and `:compliant` uses the
    axis ordering of the relevant CRS authority. The default, `nothing`, leaves
    GDAL's own default in place: authority-compliant, unless the
    `OSR_DEFAULT_AXIS_MAPPING_STRATEGY` config option says otherwise.
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
    importWKT(wktstr::AbstractString; [order=nothing])

Create SRS from its WKT string.

# Keyword Arguments
- `order`: Sets the axis mapping strategy. `:trad` uses traditional lon/lat
    axis ordering in any actions done with the crs, and `:compliant` uses the
    axis ordering of the relevant CRS authority. The default, `nothing`, leaves
    GDAL's own default in place: authority-compliant, unless the
    `OSR_DEFAULT_AXIS_MAPPING_STRATEGY` config option says otherwise.
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
    importPROJ4(projstr::AbstractString; [order=nothing])

Create SRS from its PROJ.4 string.

# Keyword Arguments
- `order`: Sets the axis mapping strategy. `:trad` uses traditional lon/lat
    axis ordering in any actions done with the crs, and `:compliant` uses the
    axis ordering of the relevant CRS authority. The default, `nothing`, leaves
    GDAL's own default in place: authority-compliant, unless the
    `OSR_DEFAULT_AXIS_MAPPING_STRATEGY` config option says otherwise.
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
    importXML(xmlstr::AbstractString; [order=nothing])

Construct SRS from XML format (GML only currently).

Passing the keyword argument `order=:compliant` or `order=:trad` will set the
mapping strategy to return compliant axis order or traditional lon/lat order.

# Keyword Arguments
- `order`: Sets the axis mapping strategy. `:trad` uses traditional lon/lat
    axis ordering in any actions done with the crs, and `:compliant` uses the
    axis ordering of the relevant CRS authority. The default, `nothing`, leaves
    GDAL's own default in place: authority-compliant, unless the
    `OSR_DEFAULT_AXIS_MAPPING_STRATEGY` config option says otherwise.
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
    importURL(url::AbstractString; [order=nothing])

Construct SRS from a URL.

This method will download the spatial reference at a given URL and feed it into
SetFromUserInput for you.

# Keyword Arguments
- `order`: Sets the axis mapping strategy. `:trad` uses traditional lon/lat
    axis ordering in any actions done with the crs, and `:compliant` uses the
    axis ordering of the relevant CRS authority. The default, `nothing`, leaves
    GDAL's own default in place: authority-compliant, unless the
    `OSR_DEFAULT_AXIS_MAPPING_STRATEGY` config option says otherwise.
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

"Export this SRS through `OSRExportToWktEx`, which takes an explicit `FORMAT`."
function _exporttowkt(
    spref::AbstractSpatialRef,
    format::AbstractString,
    multiline::Bool,
)::String
    wktptr = Ref{Cstring}()
    options = ["FORMAT=$format", "MULTILINE=$(multiline ? "YES" : "NO")"]
    result = GDAL.osrexporttowktex(spref, wktptr, options)
    @ogrerr result "Failed to convert this SRS into $format format"
    return unsafe_string(wktptr[])
end

"""
    toWKT2(spref::AbstractSpatialRef; [format="WKT2_2019"], [multiline=false])

Convert this SRS into WKT2 format.

`format` selects the WKT2 revision, either `"WKT2_2019"` or `"WKT2_2015"`.

Unlike [`toWKT`](@ref), which emits WKT1, this is lossless for datum ensembles,
dynamic CRSs, coordinate epochs and compound CRSs.
"""
function toWKT2(
    spref::AbstractSpatialRef;
    format::AbstractString = "WKT2_2019",
    multiline::Bool = false,
)::String
    return _exporttowkt(spref, format, multiline)
end

"""
    toPROJJSON(spref::AbstractSpatialRef; [multiline=false])

Export coordinate system as a [PROJJSON](https://proj.org/specifications/projjson.html)
`String`.
"""
function toPROJJSON(spref::AbstractSpatialRef; multiline::Bool = false)::String
    jsonptr = Ref{Cstring}()
    options = ["MULTILINE=$(multiline ? "YES" : "NO")"]
    result = GDAL.osrexporttoprojjson(spref, jsonptr, options)
    @ogrerr result "Failed to convert this SRS into PROJJSON"
    return unsafe_string(jsonptr[])
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
    toEPSG(spref::AbstractSpatialRef)

Export EPSG code for this coordinate system if available.
"""
function toEPSG(spref::AbstractSpatialRef)::Int64
    result = GDAL.osrgetauthorityname(spref.ptr, "PROJCS")

    if !isnothing(result)
        projcs = "PROJCS"
    else
        result = GDAL.osrgetauthorityname(spref.ptr, "GEOGCS")
        projcs = "GEOGCS"
    end

    if isnothing(result)
        error("No PROJCS or GEOGCS Authority found")
    elseif result == "EPSG"
        epsg = GDAL.osrgetauthoritycode(spref.ptr, projcs)
        epsg = parse(Int64, epsg)
        return epsg
    else
        error("$result is not an EPSG authority")
    end
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
    GeoFormatTypes.val(spref::AbstractSpatialRef)

The WKT2 definition of `spref`, or `""` if it is empty.

`AbstractSpatialRef` is a `GeoFormatTypes.CoordinateReferenceSystemFormat`, and
this is the value behind that: it is what `convert(String, spref)` returns, and
what any consumer reaching a crs through `GeoFormatTypes.val` will see.

WKT carries no axis *mapping* strategy, so a consumer reached this way sees
authority axis order even for a spatial ref created with `order = :trad`.
"""
GFT.val(spref::AbstractSpatialRef)::String = isempty(spref) ? "" : toWKT2(spref)

"""
    ==(a::AbstractSpatialRef, b::AbstractSpatialRef)

Whether the two spatial references describe the same coordinate reference
system, via GDAL's `OSRIsSame`.

This is CRS equivalence rather than textual equality: a spatial ref compares
equal to its own PROJ.4 or WKT round-trip even though the names differ. The
data axis to CRS axis mapping *is* compared, so `importEPSG(4326)` and
`importEPSG(4326; order = :trad)` are not equal — they transform differently.
"""
function Base.:(==)(a::AbstractSpatialRef, b::AbstractSpatialRef)::Bool
    a.ptr == C_NULL && return b.ptr == C_NULL
    b.ptr == C_NULL && return false
    return GDAL.osrissame(a, b) != 0
end

# `OSRIsSame` ignores names, identifiers and WKT text, so no digest of the
# definition is a legal hash for it: two spatial refs that compare equal can
# have entirely different WKT. Hashing to a constant keeps `hash` consistent
# with `==`, at the cost of linear lookup in a `Dict` keyed on spatial refs;
# getting this wrong instead means silently missed keys.
Base.hash(::AbstractSpatialRef, h::UInt) = hash(:ArchGDAL_AbstractSpatialRef, h)

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
