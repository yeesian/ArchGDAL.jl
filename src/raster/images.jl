function imview(colortype::Type{<:ColorTypes.Colorant}, imgvalues...)
    return PermutedDimsArray(
        ImageCore.colorview(
            colortype,
            (
                ImageCore.normedview(
                    ImageCore.Normed{eltype(img),8 * sizeof(eltype(img))},
                    img,
                ) for img in imgvalues
            )...,
        ),
        (2, 1),
    )
end

function imview(
    gci::GDALColorInterp,
    imgvalues::AbstractMatrix;
    colortable::ColorTable = ColorTable(C_NULL),
)
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
    elseif gci == GCI_PaletteIndex
        if colortable.ptr == C_NULL
            error(
                """
                `imview` is only supported for `GCI_PaletteIndex` with non-null
                colortables.
                """,
            )
        end
        gpi = paletteinterp(colortable)
        if gpi == GPI_Gray
            imview(GPI_Gray, imgvalues)
        elseif gpi == GPI_RGB
            colorentries = GDAL.GDALColorEntry[
                getcolorentryasrgb(colortable, i - 1) for
                i in 1:GDAL.gdalgetcolorentrycount(colortable)
            ]
            c1 = Matrix{UInt8}(undef, size(imgvalues)...)
            c2 = Matrix{UInt8}(undef, size(imgvalues)...)
            c3 = Matrix{UInt8}(undef, size(imgvalues)...)
            c4 = Matrix{UInt8}(undef, size(imgvalues)...)
            for i in eachindex(imgvalues)
                c1[i] = UInt8(colorentries[imgvalues[i]+1].c1)
                c2[i] = UInt8(colorentries[imgvalues[i]+1].c2)
                c3[i] = UInt8(colorentries[imgvalues[i]+1].c3)
                c4[i] = UInt8(colorentries[imgvalues[i]+1].c4)
            end
            imview(GPI_RGB, c1, c2, c3, c4)
        else
            error("""
                  Unsupported GPI: $(paletteinterp(colortable)). Please file an
                  issue at https://github.com/yeesian/ArchGDAL.jl/issues if it
                  should be supported.
                  """)
        end
    else
        error("""
              Unknown GCI: $gci. Please file an issue at
              https://github.com/yeesian/ArchGDAL.jl/issues if it should be
              supported.
              """)
    end
end

function imview(gpi::GDALPaletteInterp, imgvalues::AbstractMatrix)
    return if gpi == GPI_Gray
        imview(ColorTypes.Gray, imgvalues)
    else
        error("""
              Unsupported GPI: $gpi. Please file an issue at
              https://github.com/yeesian/ArchGDAL.jl/issues if it should be
              supported.
              """)
    end
end

function imview(
    gpi::GDALPaletteInterp,
    c1::AbstractMatrix,
    c2::AbstractMatrix,
    c3::AbstractMatrix,
)
    return if gpi == GPI_Gray
        imview(ColorTypes.Gray, c1, c2, c3)
    elseif gpi == GPI_RGB
        imview(ColorTypes.RGB, c1, c2, c3)
    else
        error("""
              Unsupported GPI: $gpi. If it should be supported, please file an
              issue at https://github.com/yeesian/ArchGDAL.jl/issues with the
              desired output.
              """)
    end
end

function imview(
    gpi::GDALPaletteInterp,
    c1::AbstractMatrix,
    c2::AbstractMatrix,
    c3::AbstractMatrix,
    c4::AbstractMatrix,
)
    return if gpi == GPI_Gray
        imview(ColorTypes.Gray, c1, c2, c3, c4)
    elseif gpi == GPI_RGB
        imview(ColorTypes.RGBA, c1, c2, c3, c4)
    else
        error("""
              Unsupported GPI: $gpi. If it should be supported, please file an
              issue at https://github.com/yeesian/ArchGDAL.jl/issues with the
              desired output.
              """)
    end
end

function imread(
    colortype::Union{GDALPaletteInterp,GDALColorInterp},
    dataset::AbstractDataset,
    i::Integer,
    args...,
)
    return imread(colortype, getband(dataset, i), args...)
end

function imread(gpi::GDALPaletteInterp, rb::AbstractRasterBand, args...)
    return imview(gpi, read(rb, args...))
end

function imread(gci::GDALColorInterp, rb::AbstractRasterBand, args...)
    return getcolortable(rb) do colortable
        return imview(gci, read(rb, args...), colortable = colortable)
    end
end

function imread(rb::AbstractRasterBand, args...)
    return getcolortable(rb) do colortable
        return imview(
            getcolorinterp(rb),
            read(rb, args...),
            colortable = colortable,
        )
    end
end

function imread(dataset::AbstractDataset, i::Integer, args...)
    return imread(getband(dataset, i), args...)
end

function _colorindices(dataset::AbstractDataset, indices)
    gci = unique(
        GDALColorInterp[getcolorinterp(getband(dataset, i)) for i in indices],
    )
    gciorder = sort(gci)
    colortype = if gciorder == [GCI_GrayIndex]
        GCI_GrayIndex
    elseif gciorder == [GCI_PaletteIndex]
        GCI_PaletteIndex
    elseif gciorder == [GCI_RedBand, GCI_GreenBand, GCI_BlueBand]
        GPI_RGB
    elseif gciorder == [GCI_RedBand, GCI_GreenBand, GCI_BlueBand, GCI_AlphaBand]
        GPI_RGB
    else
        error("""
              Unknown GCI: $gciorder. Please file an issue at
              https://github.com/yeesian/ArchGDAL.jl/issues if it should be
              supported.
              """)
    end
    return colortype, Tuple(indices[sortperm(gci)])
end

function imread(dataset::AbstractDataset, indices, args...)
    colortype, idxs = _colorindices(dataset, indices)
    return if colortype == GCI_PaletteIndex
        getcolortable(getband(dataset, 1)) do colortable
            return imview(
                colortype,
                (read(getband(dataset, i), args...) for i in idxs)...,
                colortable = colortable,
            )
        end
    else
        imview(colortype, (read(getband(dataset, i), args...) for i in idxs)...)
    end
end

imread(dataset::AbstractDataset) = imread(dataset, 1:nraster(dataset))

function imread(filename::AbstractString)
    return read(filename) do dataset
        return imread(dataset)
    end
end
