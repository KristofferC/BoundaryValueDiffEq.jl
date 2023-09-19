module BoundaryValueDiffEq

using Adapt, LinearAlgebra, PreallocationTools, Reexport, Setfield, SparseArrays, SciMLBase,
    RecursiveArrayTools
@reexport using ADTypes, DiffEqBase, NonlinearSolve, SparseDiffTools, SciMLBase

import ADTypes: AbstractADType
import ArrayInterface: matrix_colors, parameterless_type
import ConcreteStructs: @concrete
import DiffEqBase: solve
import ForwardDiff: pickchunksize
import RecursiveArrayTools: ArrayPartition, DiffEqArray
import SciMLBase: AbstractDiffEqInterpolation
import SparseDiffTools: AbstractSparseADType
import TruncatedStacktraces: @truncate_stacktrace
import UnPack: @unpack

function SciMLBase.__solve(prob::BVProblem, alg; kwargs...)
    # If dispatch not directly defined
    cache = init(prob, alg; kwargs...)
    return solve!(cache)
end

include("types.jl")
include("utils.jl")
include("algorithms.jl")
include("alg_utils.jl")
include("mirk_tableaus.jl")
include("cache.jl")
include("collocation.jl")
include("nlprob.jl")
include("solve/single_shooting.jl")
include("solve/mirk.jl")
include("adaptivity.jl")
include("interpolation.jl")

export Shooting
export MIRK2, MIRK3, MIRK4, MIRK5, MIRK6
export MIRKJacobianComputationAlgorithm
# From ODEInterface.jl
export BVPM2, BVPSOL

end
