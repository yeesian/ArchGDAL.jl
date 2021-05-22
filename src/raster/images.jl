function imview(colortype::Type{<:ColorTypes.Colorant}, imgvalues...)
    return ImageCore.PermutedDimsArray(
        ImageCore.colorview(
            colortype,
            (ImageCore.normedview(img) for img in imgvalues)...,
        ),
        (2, 1),
    )
end

function imview(gci::GDALColorInterp, imgvalues::Matrix)
    return if gci == GCI_GrayIndex
        imview(ColorTypes.Gray, imgvalues)
    elseif gci == GCI_Undefined
        imview(ColorTypes.Gray, imgvalues)
    elseif gci == GCI_RedBand
        zerovalues = zeros(eltype(imgvalues), size(imgvalues))
        imview(GPI_RGB, imgvalues, zerovalues, zerovalues)
    elseif gci == GCI_GreenBand
        zerovalues = zeros(eltype(imgvalues), size(imgvalues))
        imview(GPI_RGB, zerovalues, imgvalues, zerovalues)
    elseif gci == GCI_BlueBand
        zerovalues = zeros(eltype(imgvalues), size(imgvalues))
        imview(GPI_RGB, zerovalues, zerovalues, imgvalues)
    else
        error(
            """
      Unknown GCI: $gci. Please file an issue at
      https://github.com/yeesian/ArchGDAL.jl/issues if it should be supported.
      """,
        )
    end
end

function imview(gpi::GDALPaletteInterp, imgvalues::Matrix)
    return if gpi == GPI_Gray
        imview(ColorTypes.Gray, imgvalues)
    else
        error(
            """
      Unsupported GPI: $gpi. Please file an issue at
      https://github.com/yeesian/ArchGDAL.jl/issues if it should be supported.
      """,
        )
    end
end

function imview(gpi::GDALPaletteInterp, c1::Matrix, c2::Matrix, c3::Matrix)
    return if gpi == GPI_Gray
        imview(ColorTypes.Gray, c1, c2, c3)
    elseif gpi == GPI_RGB
        imview(ColorTypes.RGB, c1, c2, c3)
    else
        error(
            """
      Unsupported GPI: $gpi. If it should be supported, please file an issue at
      https://github.com/yeesian/ArchGDAL.jl/issues with the desired output.
      """,
        )
    end
end

function imview(
    gpi::GDALPaletteInterp,
    c1::Matrix,
    c2::Matrix,
    c3::Matrix,
    c4::Matrix,
)
    return if gpi == GPI_Gray
        imview(ColorTypes.Gray, c1, c2, c3, c4)
    elseif gpi == GPI_RGB
        imview(ColorTypes.RGBA, c1, c2, c3, c4)
    else
        error(
            """
      Unsupported GPI: $gpi. If it should be supported, please file an issue at
      https://github.com/yeesian/ArchGDAL.jl/issues with the desired output.
      """,
        )
    end
end

function imread(
    colortype::Union{GDALPaletteInterp,GDALColorInterp},
    rb::AbstractRasterBand,
    xoffset::Integer,
    yoffset::Integer,
    xsize::Integer,
    ysize::Integer,
)
    return imview(colortype, read(rb, xoffset, yoffset, xsize, ysize))
end

function imread(
    colortype::Union{GDALPaletteInterp,GDALColorInterp},
    dataset::AbstractDataset,
    i::Integer,
    xoffset::Integer,
    yoffset::Integer,
    xsize::Integer,
    ysize::Integer,
)
    return imread(
        colortype,
        getband(dataset, i),
        xoffset,
        yoffset,
        xsize,
        ysize,
    )
end

function imread(
    colortype::Union{GDALPaletteInterp,GDALColorInterp},
    rb::AbstractRasterBand,
    rows::UnitRange{<:Integer},
    cols::UnitRange{<:Integer},
)
    return imview(colortype, read(rb, rows, cols))
end

function imread(
    colortype::Union{GDALPaletteInterp,GDALColorInterp},
    dataset::AbstractDataset,
    i::Integer,
    rows::UnitRange{<:Integer},
    cols::UnitRange{<:Integer},
)
    return imread(colortype, getband(dataset, i), rows, cols)
end

function imread(
    colortype::Union{GDALPaletteInterp,GDALColorInterp},
    rb::AbstractRasterBand,
)
    return imview(colortype, read(rb))
end

function imread(
    colortype::Union{GDALPaletteInterp,GDALColorInterp},
    dataset::AbstractDataset,
    i::Integer,
)
    return imread(colortype, getband(dataset, i))
end

function imread(
    rb::AbstractRasterBand,
    xoffset::Integer,
    yoffset::Integer,
    xsize::Integer,
    ysize::Integer,
)
    return imview(getcolorinterp(rb), read(rb, xoffset, yoffset, xsize, ysize))
end

function imread(
    dataset::AbstractDataset,
    i::Integer,
    xoffset::Integer,
    yoffset::Integer,
    xsize::Integer,
    ysize::Integer,
)
    return imread(getband(dataset, i), xoffset, yoffset, xsize, ysize)
end

function imread(
    rb::AbstractRasterBand,
    rows::UnitRange{<:Integer},
    cols::UnitRange{<:Integer},
)
    return imview(getcolorinterp(rb), read(rb, rows, cols))
end

function imread(
    dataset::AbstractDataset,
    i::Integer,
    rows::UnitRange{<:Integer},
    cols::UnitRange{<:Integer},
)
    return imread(getband(dataset, i), rows, cols)
end

function imread(rb::AbstractRasterBand)
    return imview(getcolorinterp(rb), read(rb))
end

function imread(dataset::AbstractDataset, i::Integer)
    return imread(getband(dataset, i))
end

function _paletteindices(dataset::AbstractDataset, indices)
    gci = unique(
        GDALColorInterp[getcolorinterp(getband(dataset, i)) for i in indices],
    )
    gciorder = sort(gci)
    return if gciorder == [GCI_GrayIndex]
        GPI_Gray, Tuple(indices[sortperm(gci)])
    elseif gciorder == [GCI_PaletteIndex]
        gpi = getcolortable(getband(dataset, indices[1])) do ct
            return paletteinterp(ct)
        end
        gpi, Tuple(indices)
    elseif gciorder == [GCI_RedBand, GCI_GreenBand, GCI_BlueBand]
        GPI_RGB, Tuple(indices[sortperm(gci)])
    elseif gciorder == [GCI_RedBand, GCI_GreenBand, GCI_BlueBand, GCI_AlphaBand]
        GPI_RGB, Tuple(indices[sortperm(gci)])
    else
        error(
            """
      Unknown GCI: $gciorder. Please file an issue at
      https://github.com/yeesian/ArchGDAL.jl/issues if it should be supported.
      """,
        )
    end
end

function imread(
    dataset::AbstractDataset,
    indices,
    xoffset::Integer,
    yoffset::Integer,
    xsize::Integer,
    ysize::Integer,
)
    gpi, idxs = _paletteindices(dataset, indices)
    return imview(
        gpi,
        (
            read(getband(dataset, i), xoffset, yoffset, xsize, ysize) for
            i in idxs
        )...,
    )
end

function imread(
    dataset::AbstractDataset,
    indices,
    rows::UnitRange{<:Integer},
    cols::UnitRange{<:Integer},
)
    gpi, idxs = _paletteindices(dataset, indices)
    return imview(gpi, (read(getband(dataset, i), rows, cols) for i in idxs)...)
end

function imread(dataset::AbstractDataset, indices)
    gpi, idxs = _paletteindices(dataset, indices)
    return imview(gpi, (read(getband(dataset, i)) for i in idxs)...)
end

imread(dataset::AbstractDataset) = imread(dataset, 1:nraster(dataset))

function imread(filename::String)
    return read(filename) do dataset
        return imread(dataset)
    end
end
