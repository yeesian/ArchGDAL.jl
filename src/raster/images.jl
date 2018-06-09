function imread(
        colortype::Type{ColorTypes.Gray},
        dataset::Dataset,
        indices::NTuple{1,<:Integer}
    )
    ImageCore.permuteddimsview(ImageCore.colorview(ColorTypes.Gray,
        ImageCore.normedview(ArchGDAL.read(dataset, indices[1]))
    ), (2,1))
end

function imread(
        colortype::Type{ColorTypes.RGB},
        dataset::Dataset,
        indices::NTuple{3,<:Integer}
    )
    ImageCore.permuteddimsview(ImageCore.colorview(ColorTypes.RGB,
        ImageCore.normedview(ArchGDAL.read(dataset, indices[1])),
        ImageCore.normedview(ArchGDAL.read(dataset, indices[2])),
        ImageCore.normedview(ArchGDAL.read(dataset, indices[3]))
    ), (2,1))
end

function imread(
        colortype::Type{ColorTypes.RGBA},
        dataset::Dataset,
        indices::NTuple{4,<:Integer}
    )
    ImageCore.permuteddimsview(ImageCore.colorview(ColorTypes.RGBA,
        ImageCore.normedview(ArchGDAL.read(dataset, indices[1])),
        ImageCore.normedview(ArchGDAL.read(dataset, indices[2])),
        ImageCore.normedview(ArchGDAL.read(dataset, indices[3])),
        ImageCore.normedview(ArchGDAL.read(dataset, indices[4]))
    ), (2,1))
end

function imread(
        dataset::Dataset,
        indices::Vector{<:Integer}
    )
    println("HERE")
    gci = Int.(getcolorinterp.(getband.(dataset,indices)))
    colororder = sort(gci)
    @show colororder
    @assert colororder == [1]
    colortype = if colororder == [1];   ColorTypes.Gray
    elseif colororder == [3,4,5];       ColorTypes.RGB
    elseif colororder == [3,4,5,6];     ColorTypes.RGBA
    elseif colororder == [7,8,9];       ColorTypes.HSL
    elseif colororder == [10,11,12,13]  # CMYK
        error("""
        CMYK not yet supported. Please file an issue at
        https://github.com/yeesian/ArchGDAL.jl/issues
        """)
    else
        error("""
        Unknown GCI: $gci, $colororder
        """)
    end
    imread(colortype, dataset, Tuple(indices[sortperm(gci)]))
end

imread(dataset::Dataset) = imread(dataset, collect(1:nraster(dataset)))
