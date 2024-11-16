using Base.Test
import ArchGDAL; const AG = ArchGDAL

function read(f, filename)
    return AG.registerdrivers() do
        AG.read(filename) do dataset
            f(dataset)
end end end

@testset "Testing Displays for different objects" begin
    read("data/point.geojson") do dataset
        print(dataset)
    end;

    read("data/point.geojson") do dataset
        print(AG.getlayer(dataset, 0))
    end;

    read("data/point.geojson") do dataset
        AG.getfeature(AG.getlayer(dataset, 0), 2) do feature
           print(feature)
        end
    end;

    read("gdalworkshop/world.tif") do dataset
        print(dataset)
    end;

    read("gdalworkshop/world.tif") do dataset
        print(AG.getband(dataset, 1))
    end;
end