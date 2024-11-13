module ArchGDALJLD2Ext

import ArchGDAL as AG
import GeoInterface as GI
import JLD2

struct ArchGDALSerializedGeometry
    # TODO: add spatial reference
    wkb::Vector{UInt8}
end


JLD2.writeas(::Type{<: AG.AbstractGeometry}) = ArchGDALSerializedGeometry

function JLD2.wconvert(::Type{<: ArchGDALSerializedGeometry}, x::AG.AbstractGeometry)
    return ArchGDALSerializedGeometry(AG.toWKB(x))
end

function JLD2.rconvert(::Type{<: AG.AbstractGeometry}, x::ArchGDALSerializedGeometry)
    return AG.fromWKB(x.wkb)
end

end