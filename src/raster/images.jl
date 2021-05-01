function imread(
        colortable::ColorTable,
        dataset::AbstractDataset,
        indices::NTuple{1, <:Integer}
    )
	palette = getcolortable(getband(dataset,indices[1])) do ct
    	getpaletteinterp(ct)
    end
    colortype = if palette == GDAL.GPI_Gray;    ColorTypes.Gray
    elseif palette == GDAL.GPI_RGB;             ColorTypes.RGB
    elseif palette == GDAL.GPI_HLS;             ColorTypes.HSL
    elseif palette == GDAL.GPI_CMYK
        error("""
        CMYK not yet supported. Please file an issue at
        https://github.com/yeesian/ArchGDAL.jl/issues
        """)
    else; error("Unknown color palette: $palette")
    end
    return ImageCore.permuteddimsview(ImageCore.colorview(colortype,
        ImageCore.normedview(read(dataset, indices[1]))
    ), (2,1))
end

function imread(
        colortype::Type{ColorTypes.Gray},
        dataset::AbstractDataset,
        indices::NTuple{1, <:Integer}
    )
    return ImageCore.permuteddimsview(ImageCore.colorview(ColorTypes.Gray,
        ImageCore.normedview(read(dataset, indices[1]))
    ), (2,1))
end

function imread(
        colortype::Type{ColorTypes.RGB},
        dataset::AbstractDataset,
        indices::NTuple{3,<:Integer}
    )
    return ImageCore.permuteddimsview(ImageCore.colorview(ColorTypes.RGB,
        ImageCore.normedview(read(dataset, indices[1])),
        ImageCore.normedview(read(dataset, indices[2])),
        ImageCore.normedview(read(dataset, indices[3]))
    ), (2,1))
end

function imread(
        colortype::Type{ColorTypes.RGBA},
        dataset::Dataset,
        indices::NTuple{4,<:Integer}
    )
    return ImageCore.permuteddimsview(ImageCore.colorview(ColorTypes.RGBA,
        ImageCore.normedview(read(dataset, indices[1])),
        ImageCore.normedview(read(dataset, indices[2])),
        ImageCore.normedview(read(dataset, indices[3])),
        ImageCore.normedview(read(dataset, indices[4]))
    ), (2,1))
end

function imread(dataset::AbstractDataset, indices::Vector{<:Integer})
    gci = GDALColorInterp[getcolorinterp(getband(dataset, i)) for i in indices]
    gciorder = sort(gci)
    colortype = if gciorder == [GCI_GrayIndex]
    	ColorTypes.Gray
    elseif gciorder == [GCI_PaletteIndex]
    	ColorTable
    elseif gciorder == [GCI_RedBand, GCI_GreenBand, GCI_BlueBand]
    	ColorTypes.RGB
    elseif gciorder == [GCI_RedBand, GCI_GreenBand, GCI_BlueBand, GCI_AlphaBand]
    	ColorTypes.RGBA
    elseif gciorder == [GCI_HueBand, GCI_SaturationBand, GCI_LightnessBand]
    	ColorTypes.HSL
	elseif gciorder == [
			GCI_CyanBand, GCI_MagentaBand, GCI_YellowBand, GCI_BlackBand
		]
    else
        error("""
        Unknown GCI: $colororder. Please file an issue at
        https://github.com/yeesian/ArchGDAL.jl/issues
        """)
    end
    return imread(colortype, dataset, Tuple(indices[sortperm(gci)]))
end

imread(dataset::AbstractDataset) = imread(dataset, collect(1:nraster(dataset)))
