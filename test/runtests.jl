using BoundaryValueDiffEq
using DiffEqBase, OrdinaryDiffEq, DiffEqDevTools
using Test

@testset "Boundary Value Problem Tests" begin
    @time @testset "Shooting Method Tests" begin
        include("shooting_tests.jl")
        include("orbital.jl")
        include("ensemble.jl")
        include("vectorofvector_initials.jl")
    end

    @time @testset "Collocation Method (MIRK) Tests" begin
        include("mirk_convergence_tests.jl")
    end
end
