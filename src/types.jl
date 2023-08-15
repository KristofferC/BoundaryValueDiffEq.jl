# MIRK Method Tableaus
struct MIRKTableau{sType, cType, vType, bType, xType}
    """Discrete stages of MIRK formula"""
    s::sType
    c::cType
    v::vType
    b::bType
    x::xType

    function MIRKTableau(s, c, v, b, x)
        @assert eltype(c) == eltype(v) == eltype(b) == eltype(x)
        return new{typeof(s), typeof(c), typeof(v), typeof(b), typeof(x)}(s, c, v, b, x)
    end
end

@truncate_stacktrace MIRKTableau 1

struct MIRKInterpTableau{s, c, v, x, τ}
    s_star::s
    c_star::c
    v_star::v
    x_star::x
    τ_star::τ

    function MIRKInterpTableau(s_star, c_star, v_star, x_star, τ_star)
        @assert eltype(c_star) == eltype(v_star) == eltype(x_star)
        return new{typeof(s_star), typeof(c_star), typeof(v_star), typeof(x_star),
            typeof(τ_star)}(s_star,
            c_star, v_star, x_star, τ_star)
    end
end

@truncate_stacktrace MIRKInterpTableau 1

# ODE BVP problem system
## NOTE: We might want to decouple this type from MIRK sometime later
struct BVPSystem{F <: Function, B <: Union{Function, SciMLBase.TwoPointBVPFunction},
    tType <: AbstractVector}
    order::Int                  # The order of MIRK method
    stage::Int                  # The state of MIRK method
    M::Int                      # Number of equations in the ODE system
    N::Int                      # Number of nodes in the mesh
    f!::F                       # M -> M
    bc!::B                      # 2 -> 2
    tmp::tType                  # M
end

Base.eltype(S::BVPSystem) = eltype(S.tmp)

# Sparsity Detection
Base.@kwdef struct AutoMultiModeDifferentiation{D, S} <: AbstractADType
    dense::D = AutoFiniteDiff()
    sparse::S = AutoSparseFiniteDiff()
end

### TODO: Upstream
struct AutoFastDifferentiation <: AbstractADType end
struct AutoSparseFastDifferentiation <: AbstractADType end

_exploit_sparsity(::AbstractADType) = false
function _exploit_sparsity(::Union{AutoSparseFiniteDiff, AutoSparseForwardDiff,
    AutoSparseFastDifferentiation})
    return true
end
function _exploit_sparsity(mm::AutoMultiModeDifferentiation)
    return any(_exploit_sparsity, (mm.dense, mm.sparse))
end

_dense_mode(::AutoSparseFiniteDiff) = AutoFiniteDiff()
_dense_mode(::AutoSparseFastDifferentiation) = AutoFastDifferentiation()
_dense_mode(::AutoSparseForwardDiff) = AutoForwardDiff()
_dense_mode(::AutoSparseZygote) = AutoZygote()
_dense_mode(::AbstractADType) = nothing
