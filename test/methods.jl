using DimensionalData, Statistics, Test, Unitful, SparseArrays, Dates
using DimensionalData.LookupArrays, DimensionalData.Dimensions

using LinearAlgebra: Transpose

xs = (1, X, X(), :X)
ys = (2, Y, Y(), :Y)
xys = ((1, 2), (X, Y), (X(), Y()), (:X, :Y))

@testset "map" begin
    a = [1 2; 3 4]
    dimz = X(143:2:145), Y(Sampled(-38:2:-36; span=Explicit([-38 -36; -36 -34])))
    da = DimArray(a, dimz)
    @test map(x -> 2x, da) == [2 4; 6 8]
    @test map(x -> 2x, da) isa DimArray{Int64,2}
    @test map(*, da, da) == [1 4; 9 16]
    @test map(*, da, da) isa DimArray{Int64,2}
end

@testset "dimension reducing methods" begin

    # Test some reducing methods with Explicit spans
    a = [1 2; 3 4]
    dimz = X(143:2:145), Y(Sampled(-38:2:-36; span=Explicit([-38 -36; -36 -34])))
    da = DimArray(a, dimz)

    # Test all dime combinations with maxium
    for dims in xs
        @test sum(da; dims) == [4 6]
        @test minimum(da; dims) == [1 2]

        testdims = (X(Sampled(144.0:2.0:144.0, ForwardOrdered(), Regular(4.0), Points(), NoMetadata())),
                    Y(Sampled(-38:2:-36, ForwardOrdered(), Explicit([-38 -36; -36 -34]), Intervals(Center()), NoMetadata())))
        @test typeof(DimensionalData.dims(minimum(da; dims))) == typeof(testdims)
        @test val.(span(minimum(da; dims))) == val.(span(testdims))
    end
    for dims in ys
        @test minimum(da; dims) == [1 3]'
        @test maximum(da; dims) == [2 4]'
        @test maximum(x -> 2x, da; dims) == [4 8]'
        testdims = (X(Sampled(143:2:145, ForwardOrdered(), Regular(2), Points(), NoMetadata())),
             Y(Sampled(-37.0:4.0:-37.0, ForwardOrdered(), Explicit(reshape([-38, -34], 2, 1)), Intervals(Center()), NoMetadata())))
        @test typeof(DimensionalData.dims(sum(da; dims))) == typeof(testdims)
        @test index(sum(da; dims)) == index.(testdims)
        @test val.(span(sum(da; dims))) == val.(span(testdims))
    end
    for dims in xys
        @test maximum(da; dims) == [4]'
        @test maximum(x -> 2x, da; dims) == [8]'
    end

    @test minimum(da; dims=:) == 1
    @test maximum(da; dims=:) == 4
    @test sum(da; dims=:) == 10
    @test sum(x -> 2x, da; dims=:) == 20

    a = [1 2; 3 4]
    dimz = X(143:2:145), Y(-38:2:-36)
    da = DimArray(a, dimz)

    @test reduce(+, da) == reduce(+, a)
    @test mapreduce(x -> x > 3, +, da; dims=:) == 1
    @test std(da) === std(a)

    for dims in xs
        @test prod(da; dims) == [3 8]
        @test mean(da; dims) == [2.0 3.0]
        @test mean(x -> 2x, da; dims) == [4.0 6.0]
        @test reduce(+, da; dims) == [4 6]
        @test mapreduce(x -> x > 3, +, da; dims) == [0 1]
        @test var(da; dims) == [2.0 2.0]
        @test std(da; dims) == [1.4142135623730951 1.4142135623730951]
        @test extrema(da; dims) == [(1, 3) (2, 4)]
        resultdimz =
            (X(Sampled(144.0:2.0:144.0, ForwardOrdered(), Regular(4.0), Points(), NoMetadata())),
             Y(Sampled(-38:2:-36, ForwardOrdered(), Regular(2), Points(), NoMetadata())))
        @test typeof(DimensionalData.dims(prod(da; dims))) == typeof(resultdimz)
        @test bounds(DimensionalData.dims(prod(da; dims))) == bounds(resultdimz)
    end
    for dims in ys
        @test prod(da; dims=2) == [2 12]'
        @test mean(da; dims) == [1.5 3.5]'
        @test mean(x -> 2x, da; dims) == [3.0 7.0]'
        @test DimensionalData.dims(mean(da; dims)) ==
            (X(Sampled(143:2:145, ForwardOrdered(), Regular(2), Points(), NoMetadata())),
             Y(Sampled(-37.0:4.0:-37.0, ForwardOrdered(), Regular(4.0), Points(), NoMetadata())))
        @test DimensionalData.dims(reduce(+, da; dims)) ==
            (X(Sampled(143:2:145, ForwardOrdered(), Regular(2), Points(), NoMetadata())),
             Y(Sampled(-37.0:2.0:-37.0, ForwardOrdered(), Regular(4.0), Points(), NoMetadata())))
        @test DimensionalData.dims(mapreduce(x -> x > 3, +, da; dims)) ==
            (X(Sampled(143:2:145, ForwardOrdered(), Regular(2), Points(), NoMetadata())),
             Y(Sampled(-37.0:2:-37.0, ForwardOrdered(), Regular(4.0), Points(), NoMetadata())))
        @test std(da; dims) == [0.7071067811865476 0.7071067811865476]'
        @test var(da; dims) == [0.5 0.5]'
        @test DimensionalData.dims(var(da; dims)) ==
            (X(Sampled(143:2:145, ForwardOrdered(), Regular(2), Points(), NoMetadata())),
             Y(Sampled(-37.0:4.0:-37.0, ForwardOrdered(), Regular(4.0), Points(), NoMetadata())))
        @test extrema(da; dims) == permutedims([(1, 2) (3, 4)])
    end
    for dims in xys
        @test mean(da; dims=dims) == [2.5]'
        @test mean(x -> 2x, da; dims=dims) == [5.0]'
        @test reduce(+, da; dims) == [10]'
        @test mapreduce(x -> x > 3, +, da; dims)  == [1]'
        @test extrema(da; dims) == reshape([(1, 4)], 1, 1)
    end

    a = [1 2 3; 4 5 6]
    dimz = X(143:2:145), Y(-38:-36)
    da = DimArray(a, dimz)
    @test median(da) == 3.5
    @test median(da; dims=X()) == [2.5 3.5 4.5]
    @test median(da; dims=2) == [2.0 5.0]'

    a = Bool[0 1 1; 0 0 0]
    da = DimArray(a, dimz)
    @test any(da) === true
    @test any(da; dims=Y) == reshape([true, false], 2, 1)
    @test all(da) === false
    @test all(da; dims=Y) == reshape([false, false], 2, 1)
    @test all(da; dims=(X, Y)) == reshape([false], 1, 1)

end

@testset "dimension dropping methods" begin
    a = [1 2 3; 4 5 6]
    dimz = X(143:2:145), Y(-38:-36)
    da = DimArray(a, dimz)
    # Dimensions must have length 1 to be dropped
    @test dropdims(da[X(1:1)]; dims=X) == [1, 2, 3]
    @test dropdims(da[2:2, 1:1]; dims=(X(), Y()))[] == 4
    @test typeof(dropdims(da[2:2, 1:1]; dims=(X(), Y()))) <: DimArray{Int,0,Tuple{}}
    @test refdims(dropdims(da[X(1:1)]; dims=X)) == 
        (X(Sampled(143:2:143, ForwardOrdered(), Regular(2), Points(), NoMetadata())),)
    dropped = dropdims(da[X(1:1)]; dims=X)
    @test dropped[1:2] == [1, 2]
    @test length.(dims(dropped[1:2])) == size(dropped[1:2])
end

@testset "eachslice" begin
    a = [1 2 3 4
         3 4 5 6
         5 6 7 8]
    y = Y(10:10:30)
    ti = Ti(1:4)
    da = DimArray(a, (y, ti))
    ys = (1, Y, Y(), :Y, y)
    ys2 = (ys..., map(tuple, ys)...)
    tis = (2, Ti, Ti(), :Ti, ti)
    tis2 = (tis..., map(tuple, tis)...)

    @testset "type-inferrable due to const-propagation" begin
        f(x, dims) = eachslice(x; dims=dims)
        f2(x, dims) = eachslice(x; dims=dims, drop=false)
        @testset for dims in (y, ti, (y,), (ti,), (y, ti), (ti, y))
            @inferred f(da, dims)
            VERSION ≥ v"1.9-alpha1" && @inferred f2(da, dims)
        end
    end

    @testset "error thrown if dimensions invalid" begin
        @test_throws DimensionMismatch eachslice(da; dims=3)
        @test_throws DimensionMismatch eachslice(da; dims=X)
        @test_throws DimensionMismatch eachslice(da; dims=(4,))
        @test_throws DimensionMismatch eachslice(da; dims=(Z,))
        @test_throws DimensionMismatch eachslice(da; dims=(y, ti, Z))
    end

    @testset "slice over last dimension" begin
        @testset for dims in tis2
            da2 = map(mean, eachslice(da; dims=dims)) == DimArray([3.0, 4.0, 5.0, 6.0], ti)
            slices = map(x -> x*2, eachslice(da; dims=dims))
            @test slices isa DimArray
            @test Dimensions.dims(slices) == (ti,)
            @test slices[1] == DimArray([2, 6, 10], y)
            if VERSION ≥ v"1.9-alpha1"
                @test eachslice(da; dims=dims) isa Slices
                slices = eachslice(da; dims=dims, drop=false)
                @test slices isa Slices
                @test slices == eachslice(parent(da); dims=dimnum(da, dims), drop=false)
                @test axes(slices) == axes(sum(da; dims=otherdims(da, Dimensions.dims(da, dims))))
                @test slices[1] == DimArray([1, 3, 5], y)
            end
        end
    end

    @testset "slice over first dimension" begin
        @testset for dims in ys2
            slices = map(x -> x*2, eachslice(da; dims=dims))
            @test slices isa DimArray
            @test Dimensions.dims(slices) == (y,)
            @test slices[1] == DimArray([2, 4, 6, 8], ti)
            @test slices[2] == DimArray([6, 8, 10, 12], ti)
            @test slices[3] == DimArray([10, 12, 14, 16], ti)
            if VERSION ≥ v"1.9-alpha1"
                @test eachslice(da; dims=dims) isa Slices
                slices = eachslice(da; dims=dims, drop=false)
                @test slices isa Slices
                @test slices == eachslice(parent(da); dims=dimnum(da, dims), drop=false)
                @test axes(slices) == axes(sum(da; dims=otherdims(da, Dimensions.dims(da, dims))))
                @test slices[1] == DimArray([1, 2, 3, 4], ti)
            end
        end
    end

    @testset "slice over all permutations of both dimensions" begin
        @testset for dims in Iterators.flatten((Iterators.product(ys, tis), Iterators.product(tis, ys)))
            # mixtures of integers and dimensions are not supported
            rem(sum(d -> isa(d, Int), dims), length(dims)) == 0 || continue
            slices = map(x -> x*3, eachslice(da; dims=dims))
            @test slices isa DimArray
            @test Dimensions.dims(slices) == Dimensions.dims(da, dims)
            @test size(slices) == map(x -> size(da, x), dims)
            @test axes(slices) == map(x -> axes(da, x), dims)
            @test eltype(slices) <: DimArray{Int, 0}
            @test map(first, slices) == permutedims(da * 3, dims)
            if VERSION ≥ v"1.9-alpha1"
                @test eachslice(da; dims=dims) isa Slices
                slices = eachslice(da; dims=dims, drop=false)
                @test slices isa Slices
                @test slices == eachslice(parent(da); dims=dimnum(da, dims), drop=false)
                @test axes(slices) == axes(sum(da; dims=otherdims(da, Dimensions.dims(da, dims))))
            end
        end
    end
end

@testset "simple dimension permuting methods" begin
    da = DimArray(zeros(5, 4), (Y(LinRange(10, 20, 5)), X(1:4)))
    tda = transpose(da)
    @test tda == transpose(parent(da))
    resultdims = (X(Sampled(1:4, ForwardOrdered(), Regular(1), Points(), NoMetadata())),
                  Y(Sampled(LinRange(10.0, 20.0, 5), ForwardOrdered(), Regular(2.5), Points(), NoMetadata())))
    @test typeof(dims(tda)) == typeof(resultdims) 
    @test dims(tda) == resultdims
    @test size(tda) == (4, 5)

    tda = Transpose(da)
    @test tda == Transpose(parent(da))
    @test dims(tda) == (X(Sampled(1:4, ForwardOrdered(), Regular(1), Points(), NoMetadata())),
                        Y(Sampled(LinRange(10.0, 20.0, 5), ForwardOrdered(), Regular(2.5), Points(), NoMetadata())))
    @test size(tda) == (4, 5)
    @test typeof(tda) <: DimArray

    ada = adjoint(da)
    @test ada == adjoint(parent(da))
    @test dims(ada) == (X(Sampled(1:4, ForwardOrdered(), Regular(1), Points(), NoMetadata())),
                        Y(Sampled(LinRange(10.0, 20.0, 5), ForwardOrdered(), Regular(2.5), Points(), NoMetadata())))
    @test size(ada) == (4, 5)

    dsp = permutedims(da)
    @test permutedims(parent(da)) == parent(dsp)
    @test dims(dsp) == reverse(dims(da))
end


@testset "dimension permuting methods with specified permutation" begin
    da = DimArray(ones(5, 2, 4), (Y(LinRange(10, 20, 5)), Ti(10:11), X(1:4)))
    dsp = permutedims(da, [3, 1, 2])
    @test permutedims(da, [X, Y, Ti]) == permutedims(da, (X, Y, Ti))
    @test permutedims(da, [X(), Y(), Ti()]) == permutedims(da, (X(), Y(), Ti()))
    dsp = permutedims(da, (X(), Y(), Ti()))
    @test dsp == permutedims(parent(da), (3, 1, 2))
    @test dims(dsp) == (X(Sampled(1:4, ForwardOrdered(), Regular(1), Points(), NoMetadata())),
                        Y(Sampled(LinRange(10.0, 20.0, 5), ForwardOrdered(), Regular(2.5), Points(), NoMetadata())),
                        Ti(Sampled(10:11, ForwardOrdered(), Regular(1), Points(), NoMetadata())))

    dsp = PermutedDimsArray(da, (3, 1, 2))
    @test dsp == PermutedDimsArray(parent(da), (3, 1, 2))
    @test typeof(dsp) <: DimArray

    dims_perm = dims(da, (3, 2, 1))
    dsp2 = @inferred PermutedDimsArray(da, dims_perm)
    @test dsp2 == PermutedDimsArray(parent(da), (3, 2, 1))
    @test typeof(dsp2) <: DimArray
end


@testset "dimension rotating methods" begin
    da = DimArray([1 2; 3 4], (X([:a, :b]), Y([1.0, 2.0])))

    l90 = rotl90(da)
    r90 = rotr90(da)
    r180_1 = rot180(da)
    r180_2 = rotl90(da, 2)
    r180_3 = rotr90(da, 2)
    r270 = rotl90(da, 3)
    r270_2 = rotl90(da, -1)
    r360 = rotr90(da, 4)
    r360_2 = rotr90(da, 40)

    da[X(At(:a)), Y(At(2.0))]
    @test l90[X(At(:a)), Y(At(2.0))] == 2
    @test r90[X(At(:a)), Y(At(2.0))] == 2
    @test r180_1[X(At(:a)), Y(At(2.0))] == 2
    @test r180_2[X(At(:a)), Y(At(2.0))] == 2
    @test r180_3[X(At(:a)), Y(At(2.0))] == 2
    @test r270[X(At(:a)), Y(At(2.0))] == 2
    @test r270_2[X(At(:a)), Y(At(2.0))] == 2
    @test r360[X(At(:a)), Y(At(2.0))] == 2
    @test r360_2[X(At(:a)), Y(At(2.0))] == 2

end

@testset "dimension mirroring methods" begin
    a = rand(5, 4)
    da = DimArray(a, (Y(LinRange(10, 20, 5)), X(1:4)))
    xs = (X, X(), :X)
    ys = (Y, Y(), :Y)
    for dims in xs
        cvda = cov(da; dims=X)
        @test cvda == cov(a; dims=2)
        @test DimensionalData.dims(cvda) == 
            (Y(Sampled(LinRange(10.0, 20.0, 5), ForwardOrdered(), Regular(2.5), Points(), NoMetadata())),
             Y(Sampled(LinRange(10.0, 20.0, 5), ForwardOrdered(), Regular(2.5), Points(), NoMetadata())))
    end
    for dims in ys
        crda = cor(da; dims)
        @test crda == cor(a; dims=1)
        @test DimensionalData.dims(crda) == 
            (X(Sampled(1:4, ForwardOrdered(), Regular(1), Points(), NoMetadata())),
             X(Sampled(1:4, ForwardOrdered(), Regular(1), Points(), NoMetadata())))
    end
end

@testset "mapslices" begin
    a = [1 2 3 4
         3 4 5 6
         5 6 7 8]
    y = Y(Sampled(10:10:30; sampling=Intervals())) 
    ti = Ti(Sampled(1:4; sampling=Intervals()))
    da = DimArray(a, (y, ti))
    ys = (1, Y, Y(), :Y, y)
    tis = (2, Ti, Ti(), :Ti, ti)
    for dims in ys
        ms = mapslices(sum, da; dims)
        @test ms == [9 12 15 18]
        @test DimensionalData.dims(ms) == 
            (Y(Sampled(10:10:30, ForwardOrdered(), Regular(10), Intervals(Center()), NoMetadata())),
             Ti(Sampled(1:4, ForwardOrdered(), Regular(1), Intervals(Start()), NoMetadata())))
        @test refdims(ms) == ()
    end
    for dims in tis
        ms = mapslices(sum, da; dims)
        @test parent(ms) == [10 18 26]'
    end
end

@testset "cat" begin
    a = [1 2 3; 4 5 6]
    da = DimArray(a, (X(4.0:5.0), Y(6.0:8.0)))
    b = [7 8 9; 10 11 12]
    db = DimArray(b, (X(6.0:7.0), Y(6.0:8.0)))

    @testset "Regular Sampled" begin
        @test cat(da, db; dims=X()) == [1 2 3; 4 5 6; 7 8 9; 10 11 12]
        testdims = (X(Sampled([4.0, 5.0, 6.0, 7.0], ForwardOrdered(), Regular(1.0), Points(), NoMetadata())),
                    Y(Sampled(6.0:8.0, ForwardOrdered(), Regular(1.0), Points(), NoMetadata())))
        @test cat(da, db; dims=(X(),)) == cat(da, db; dims=X()) == cat(da, db; dims=X) ==
              cat(da, db; dims=1) == cat(da, db; dims=(1,))
        @test typeof(dims(cat(da, db; dims=X()))) == typeof(testdims)
        @test val(cat(da, db; dims=X())) == val(testdims)
        @test lookup(cat(da, db; dims=X())) == lookup(testdims)
        @test cat(da, db; dims=Y()) == [1 2 3 7 8 9; 4 5 6 10 11 12]
        @test cat(da, db; dims=Z(1:2)) == cat(a, b; dims=3)
        @test cat(da, db; dims=(Z(1:2), Ti(1:2))) == cat(a, b; dims=(3, 4))
        @test cat(da, db; dims=(X(), Ti(1:2))) == cat(a, b; dims=(1, 3))
        dx = cat(da, db; dims=(X(), Ti(1:2)))
        @test all(map(==, index(dx), index(DimensionalData.format((X([4.0, 5.0, 6.0, 7.0]), Y(6:8), Ti(1:2)), dx))))
    end

    # https://github.com/rafaqz/DimensionalData.jl/issues/451
    @testset "dims passed as Symbols" begin
        Xcatdim = X(Sampled([4.0, 5.0, 6.0, 7.0], ForwardOrdered(), Regular(1.0), Points(), NoMetadata()))
        da2 = DimArray(a, (X(4.0:5.0), :y))
        db2 = DimArray(b, (X(6.0:7.0), :y))
        @test cat(da2, db2; dims=:y) == cat(da2, db2; dims=Dim{:y}) ==
        @inferred(cat(da2, db2; dims=Dim{:y}()))
        @test typeof(dims(cat(da2, db2; dims=:y))) === typeof(dims(da2))
        @test lookup(cat(da2, db2; dims=:y)) == (lookup(da2)[1], 1:6)
        @test cat(da2, db2; dims=(X(), :y)) == cat(da2, db2; dims=(X, Dim{:y})) ==
            @inferred(cat(da2, db2; dims=(X(), Dim{:y}())))
        @test typeof(dims(cat(da2, db2; dims=(X(), :y)))) ===
            typeof((Xcatdim, dims(da2, :y)))
        @test lookup(cat(da2, db2; dims=(X(), :y))) == (lookup(Xcatdim), 1:6)
    end

    @testset "Irregular Sampled" begin
        @testset "Intervals" begin
            iri_dim = vcat(X(Sampled([1, 3, 4], ForwardOrdered(), Irregular(1, 5), Intervals(), NoMetadata())), 
                           X(Sampled([7, 8], ForwardOrdered(), Irregular(7, 9), Intervals(), NoMetadata())))
            @test span(iri_dim) == Irregular(1, 9)
            @test index(iri_dim) == [1, 3, 4, 7, 8]
            @test lookup(iri_dim) == Sampled([1, 3, 4, 7, 8], ForwardOrdered(), Irregular(1, 9), Intervals(), NoMetadata())
            @test bounds(lookup(iri_dim)) == (1, 9)
        end
        @testset "Points" begin
            irp_dim = vcat(X(Sampled([1, 3, 4], ForwardOrdered(), Irregular(1, 5), Points(), NoMetadata())), 
                           X(Sampled([7, 8], ForwardOrdered(), Irregular(7, 9), Points(), NoMetadata())))
            @test span(irp_dim) == Irregular(nothing, nothing)
            @test index(irp_dim) == [1, 3, 4, 7, 8]
            @test lookup(irp_dim) == Sampled([1, 3, 4, 7, 8], ForwardOrdered(), Irregular(nothing, nothing), Points(), NoMetadata())
            @test bounds(irp_dim) == (1, 8)
        end
    end

    @testset "NoLookup" begin
        ni_dim = vcat(X(NoLookup(Base.OneTo(10))), X(NoLookup(Base.OneTo(10))))
        @test lookup(ni_dim) == NoLookup(Base.OneTo(20))
    end

    @testset "rebuild dim index from refdims" begin
        slices = map(i -> view(da, Y(i)), 1:3)
        cat_da = cat(slices...; dims=Y)
        @test all(cat_da .== da)
        # The range is rebuilt as a Vector during `cat`
        @test index(cat_da) == (4.0:5.0, [6.0, 7.0, 8.0])
        @test index(cat_da) isa Tuple{<:StepRangeLen,<:Vector{Float64}}
    end
end

@testset "vcat" begin
    a = [1 2 3; 4 5 6]
    da = DimArray(a, (X(4.0:5.0), Y(6.0:8.0)))
    b = [7 8 9; 10 11 12]
    db = DimArray(b, (X(6.0:7.0), Y(6.0:8.0)))
    c = [13 14 15; 16 17 18]
    dc = DimArray(c, (X(8.0:9.0), Y(6.0:8.0)))

    @test @inferred(vcat(da)) == da
    @test @inferred(vcat(da, db)) == cat(da, db; dims=1)
    @test @inferred(vcat(da, db, dc)) == cat(da, db, dc; dims=1)
end

@testset "hcat" begin
    a = [1 2 3; 4 5 6]
    da = DimArray(a, (X(4.0:5.0), Y(6.0:8.0)))
    b = [7 8 9; 10 11 12]
    db = DimArray(b, (X(4.0:5.0), Y(9.0:11.0)))
    c = [13 14 15; 16 17 18]
    dc = DimArray(c, (X(4.0:5.0), Y(12.0:14.0)))

    @test @inferred(hcat(da)) == da
    @test @inferred(hcat(da, db)) == cat(da, db; dims=2)
    @test @inferred(hcat(da, db, dc)) == cat(da, db, dc; dims=2)
end

@testset "unique" begin
    a = [1 1 6; 1 1 6]
    xs = (X, X(), :X)
    ys = (Y, Y(), :Y)
    da = DimArray(a, (X(1:2), Y(1:3)))
    for dims in xs
        @test unique(da; dims) == [1 1 6]
    end
    for dims in ys
        @test unique(da; dims) == [1 6; 1 6]
    end
    @test unique(da; dims=:) == [1, 6]
    @test unique(da[X(1)]) == [1, 6]
end

@testset "diff" begin
    @testset "Array 2D" begin
        y = Y(['a', 'b', 'c'])
        ti = Ti(DateTime(2021, 1):Month(1):DateTime(2021, 4))
        ys = (1, Y, Y(), :Y, y)
        tis = (2, Ti, Ti(), :Ti, ti)
        data = [-87  -49  107  -18
                24   44  -62  124
                122  -11   48   -7]
        A = DimArray(data, (y, ti))
        for dims in ys
            @test diff(A; dims) == DimArray([111 93 -169 142; 98 -55 110 -131], (Y(['a', 'b']), ti))
        end
        for dims in tis
            @test diff(A; dims) == 
                DimArray([38 156 -125; 20 -106 186; -133 59 -55], (y, Ti(DateTime(2021, 1):Month(1):DateTime(2021, 3))))
        end
        @test_throws ArgumentError diff(A; dims='X')
        @test_throws ArgumentError diff(A; dims=Z)
        @test_throws ArgumentError diff(A; dims=3)
    end
    @testset "Vector" begin
        x = DimArray([56, -123, -60, -44, -64, 70, 52, -48, -74, 86], X(2:2:20))
        for dims in xs
            @test diff(x) == diff(x; dims) ==
                DimArray([-179, 63, 16, -20, 134, -18, -100, -26, 160], X(2:2:18))
        end
    end
end
