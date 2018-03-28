import ArchGDAL; const AG = ArchGDAL

@test AG.OF_ReadOnly | 0x04 == 0x04
@test 0x06 | AG.OF_ReadOnly == 0x06
@test AG.OF_ReadOnly | AG.OF_GNM == GDAL.GDAL_OF_READONLY | GDAL.GDAL_OF_GNM

for dt in (GDAL.GDT_Byte, GDAL.GDT_Float64, GDAL.GDT_Unknown, GDAL.GDT_Int16, 
           GDAL.GDT_UInt16, GDAL.GDT_Float32, GDAL.GDT_Int32, GDAL.GDT_UInt32)
    print("size: $(AG.typesize(dt)), name: $(AG.typename(dt)), ")
    println("type: $(AG.gettype(AG.typename(dt)))")
end

@test AG.typeunion(GDAL.GDT_UInt16, GDAL.GDT_Byte) == GDAL.GDT_UInt16
@test AG.iscomplex(GDAL.GDT_Float32) == false

for name in (GDAL.GARIO_COMPLETE,GDAL.GARIO_ERROR,GDAL.GARIO_PENDING,GDAL.GARIO_UPDATE)
    println("$(AG.getname(name)) $(AG.asyncstatustype(AG.getname(name)))")
end

for color in (:Alpha,:Green,:Palette,:YCbCr,:Black,:Hue,:Red,:Blue,:Gray,
              :LightnessBand,:Saturation,:Yellow,:Cyan,:Magenta,:Undefined,
              :alpha,:black,:blackband,:hueband,:GrayIndex,:saturation)
    println("$color: $(AG.colorinterp(string(color)))")
end

for p in (GDAL.GPI_Gray, GDAL.GPI_RGB, GDAL.GPI_CMYK, GDAL.GPI_HLS)
    println("$p: $(AG.getname(p))")
end

for ft in (GDAL.OFTDate,GDAL.OFTStringList,GDAL.OFTWideString,GDAL.OFTBinary,
           GDAL.OFTString,GDAL.OFTIntegerList,GDAL.OFTRealList,GDAL.OFTInteger64,
           GDAL.OFTInteger,GDAL.OFTReal,GDAL.OFTWideStringList,GDAL.OFTInteger64List,
           GDAL.OFTDateTime,GDAL.OFTTime)
    println("$ft: $(AG.getname(ft))")
    for fst in (GDAL.OFSTNone, GDAL.OFSTBoolean, GDAL.OFSTInt16, GDAL.OFSTFloat32)
        print("  $fst: $(AG.getname(fst)), ")
        println("compatible: $(AG.arecompatible(ft,fst))")
    end
end