using Test
import ArchGDAL as AG

# Calling `destroy` twice, or on an object whose pointer is already `C_NULL`,
# must be a no-op rather than passing NULL to GDAL.
@testset "test_destroy.jl" begin
    @testset "Datasets" begin
        dataset = AG.unsafe_create(AG.getdriver("MEM"), width = 2, height = 2)
        AG.destroy(dataset)
        @test dataset.ptr == C_NULL
        AG.destroy(dataset)
        @test dataset.ptr == C_NULL

        # interactive datasets are also destroyed by their finalizer
        dataset = AG.read("data/utmsmall.tif")
        AG.destroy(dataset)
        AG.destroy(dataset)
        @test dataset.ptr == C_NULL
        finalize(dataset)
        @test dataset.ptr == C_NULL

        AG.destroy(AG.Dataset())
        AG.destroy(AG.IDataset())
    end

    @testset "Features and feature definitions" begin
        featuredefn = AG.unsafe_createfeaturedefn("featuredefn")
        # keep destroy(feature) from releasing the featuredefn (see
        # createfeature in src/context.jl)
        AG.reference(featuredefn)
        feature = AG.unsafe_createfeature(featuredefn)
        AG.destroy(feature)
        @test feature.ptr == C_NULL
        AG.destroy(feature)
        @test feature.ptr == C_NULL
        @test AG.dereference(featuredefn) == 0
        AG.destroy(featuredefn)
        @test featuredefn.ptr == C_NULL
        AG.destroy(featuredefn)
        @test featuredefn.ptr == C_NULL

        AG.destroy(AG.Feature())
        AG.destroy(AG.IFeature())
        AG.destroy(AG.FeatureDefn(C_NULL))
    end

    @testset "Field definitions" begin
        fielddefn = AG.unsafe_createfielddefn("field", AG.OFTInteger)
        AG.destroy(fielddefn)
        @test fielddefn.ptr == C_NULL
        AG.destroy(fielddefn)
        @test fielddefn.ptr == C_NULL

        geomdefn = AG.unsafe_creategeomdefn("geom", AG.wkbPoint)
        AG.destroy(geomdefn)
        @test geomdefn.ptr == C_NULL
        @test geomdefn.spatialref.ptr == C_NULL
        AG.destroy(geomdefn)
        @test geomdefn.ptr == C_NULL
        @test geomdefn.spatialref.ptr == C_NULL

        AG.destroy(AG.FieldDefn(C_NULL))
        AG.destroy(AG.GeomFieldDefn())
    end

    @testset "Geometries" begin
        geom = AG.unsafe_createpoint(1.0, 2.0)
        AG.destroy(geom)
        @test geom.ptr == C_NULL
        AG.destroy(geom)
        @test geom.ptr == C_NULL

        # interactive geometries are also destroyed by their finalizer
        geom = AG.createpoint(1.0, 2.0)
        AG.destroy(geom)
        AG.destroy(geom)
        @test geom.ptr == C_NULL
        finalize(geom)
        @test geom.ptr == C_NULL

        AG.destroy(AG.Geometry())
        AG.destroy(AG.IGeometry())
    end

    @testset "Prepared geometries" begin
        AG.createpolygon([
            (0.0, 0.0),
            (1.0, 0.0),
            (1.0, 1.0),
            (0.0, 0.0),
        ]) do poly
            prepared = AG.unsafe_preparegeom(poly)
            AG.destroy(prepared)
            @test prepared.ptr == C_NULL
            AG.destroy(prepared)
            @test prepared.ptr == C_NULL

            prepared = AG.preparegeom(poly)
            AG.destroy(prepared)
            AG.destroy(prepared)
            @test prepared.ptr == C_NULL
            finalize(prepared)
            @test prepared.ptr == C_NULL
        end
    end

    @testset "Style managers, tools and tables" begin
        sm = AG.unsafe_createstylemanager()
        AG.destroy(sm)
        @test sm.ptr == C_NULL
        AG.destroy(sm)
        @test sm.ptr == C_NULL

        st = AG.unsafe_createstyletool(AG.OGRSTCPen)
        AG.destroy(st)
        @test st.ptr == C_NULL
        AG.destroy(st)
        @test st.ptr == C_NULL

        stbl = AG.unsafe_createstyletable()
        AG.destroy(stbl)
        @test stbl.ptr == C_NULL
        AG.destroy(stbl)
        @test stbl.ptr == C_NULL

        AG.destroy(AG.StyleManager())
        AG.destroy(AG.StyleTable())
        AG.destroy(AG.StyleTool(C_NULL))
    end

    @testset "Color tables and raster attribute tables" begin
        ct = AG.unsafe_createcolortable(AG.GPI_RGB)
        AG.destroy(ct)
        @test ct.ptr == C_NULL
        AG.destroy(ct)
        @test ct.ptr == C_NULL

        rat = AG.unsafe_createRAT()
        AG.destroy(rat)
        @test rat.ptr == C_NULL
        AG.destroy(rat)
        @test rat.ptr == C_NULL

        AG.destroy(AG.ColorTable(C_NULL))
        AG.destroy(AG.RasterAttrTable(C_NULL))
    end

    @testset "Spatial references and coordinate transformations" begin
        spref = AG.unsafe_importEPSG(4326)
        AG.destroy(spref)
        @test spref.ptr == C_NULL
        AG.destroy(spref)
        @test spref.ptr == C_NULL

        # interactive spatial references are also destroyed by their finalizer
        spref = AG.importEPSG(4326)
        AG.destroy(spref)
        AG.destroy(spref)
        @test spref.ptr == C_NULL
        finalize(spref)
        @test spref.ptr == C_NULL

        AG.importEPSG(4326) do source
            AG.importEPSG(32618) do target
                transform = AG.unsafe_createcoordtrans(source, target)
                AG.destroy(transform)
                @test transform.ptr == C_NULL
                AG.destroy(transform)
                @test transform.ptr == C_NULL
            end
        end

        AG.destroy(AG.SpatialRef())
        AG.destroy(AG.ISpatialRef())
        AG.destroy(AG.CoordTransform(C_NULL))
    end
end
