# GDALExtendedDataType

function unsafe_extendeddatatypecreate(
    ::Type{T},
)::AbstractExtendedDataType where {T}
    type = convert(GDALDataType, T)
    return ExtendedDataType(GDAL.gdalextendeddatatypecreate(type))
end

function extendeddatatypecreate(::Type{T})::AbstractExtendedDataType where {T}
    type = convert(GDALDataType, T)
    return IExtendedDataType(GDAL.gdalextendeddatatypecreate(type))
end
