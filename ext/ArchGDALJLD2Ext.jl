module ArchGDALJLD2Ext

import ArchGDAL as AG
import GeoInterface as GI
import JLD2

struct ArchGDALSerializedGeometry
    wkbtype::AG.OGRwkbGeometryType
    coords::Vector
end


JLD2.writeas(::Type{<: AG.AbstractGeometry{WKBType}}) where WKBType = ArchGDALSerializedGeometry{WKBType}

function JLD2.wconvert(::Type{<: ArchGDALSerializedGeometry{WKBType}}, x::AG.AbstractGeometry{WKBType}) where WKBType
    return ArchGDALSerializedGeometry{WKBType}(GI.coordinates(x))
end

function JLD2.rconvert(::Type{<: AG.AbstractGeometry{WKBType}}, x::ArchGDALSerializedGeometry{WKBType}) where WKBType
    return AG.lookup_method[typeof(x.trait)](x.coords)
end

end