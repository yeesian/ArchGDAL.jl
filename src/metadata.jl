"Fetch list of (non-empty) metadata domains. (Since: GDAL 1.11)"
metadatadomainlist{T <: GDAL.GDALMajorObjectH}(obj::Ptr{T}) =
    unsafe_loadstringlist(GDAL.C.GDALGetMetadataDomainList(obj))

"Fetch metadata. Note that relatively few formats return any metadata."
metadata{T <: GDAL.GDALMajorObjectH}(obj::Ptr{T}; domain::AbstractString="") =
    unsafe_loadstringlist(GDAL.C.GDALGetMetadata(obj, pointer(domain)))