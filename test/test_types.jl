using FactCheck
import ArchGDAL; const AG = ArchGDAL

@fact AG.OF_ReadOnly | 0x04 --> 0x04
@fact 0x06 | AG.OF_ReadOnly --> 0x06
@fact AG.OF_ReadOnly | AG.OF_GNM --> GDAL.GDAL_OF_READONLY | GDAL.GDAL_OF_GNM

for dt in (AG.GDT_Byte, AG.GDT_Float64, AG.GDT_Unknown, AG.GDT_Int16, 
           AG.GDT_UInt16, AG.GDT_Float32, AG.GDT_Int32, AG.GDT_UInt32)
    print("size: $(AG.typesize(dt)), name: $(AG.typename(dt)), ")
    println("type: $(AG.gettype(AG.typename(dt)))")
end

@fact AG.typeunion(AG.GDT_UInt16, AG.GDT_Byte) --> AG.GDT_UInt16
@fact AG.iscomplex(AG.GDT_Float32) --> false

for name in (AG.GARIO_COMPLETE,AG.GARIO_ERROR,AG.GARIO_PENDING,AG.GARIO_UPDATE)
    println("$(AG.getname(name)) $(AG.asyncstatustype(AG.getname(name)))")
end

for color in (:Alpha,:Green,:Palette,:YCbCr,:Black,:Hue,:Red,:Blue,:Gray,
              :LightnessBand,:Saturation,:Yellow,:Cyan,:Magenta,:Undefined,
              :alpha,:black,:blackband,:hueband,:GrayIndex,:saturation)
    println("$color: $(AG.colorinterp(string(color)))")
end

for p in (AG.GPI_Gray, AG.GPI_RGB, AG.GPI_CMYK, AG.GPI_HLS)
    println("$p: $(AG.getname(p))")
end

for ft in (AG.OFTDate,AG.OFTStringList,AG.OFTWideString,AG.OFTBinary,
           AG.OFTString,AG.OFTIntegerList,AG.OFTRealList,AG.OFTInteger64,
           AG.OFTInteger,AG.OFTReal,AG.OFTWideStringList,AG.OFTInteger64List,
           AG.OFTDateTime,AG.OFTTime)
    println("$ft: $(AG.getname(ft))")
    for fst in (AG.OFSTNone, AG.OFSTBoolean, AG.OFSTInt16, AG.OFSTFloat32)
        print("  $fst: $(AG.getname(fst)), ")
        println("compatible: $(AG.arecompatible(ft,fst))")
    end
end