# Dispatches on BVPSystem
function BVPSystem(fun, bc, p, x, M::Integer, alg::Union{GeneralMIRK, MIRK})
    T = eltype(x)
    N = size(x, 1)
    y = vector_alloc(T, M, N)
    order = alg_order(alg)
    s = alg_stage(alg)
    BVPSystem(order, M, N, fun, bc, p, s, x, y, vector_alloc(T, M, N),
        vector_alloc(T, M, N),
        eltype(y)(undef, M))
end

# If user offers an intial guess
function BVPSystem(fun, bc, p, x, y, alg::Union{GeneralMIRK, MIRK})
    T, U = eltype(x), eltype(y)
    M, N = size(y)
    order = alg_order(alg)
    s = alg_stage(alg)
    BVPSystem{T, U}(order, M, N, fun, bc, p, s, x, y, vector_alloc(T, M, N),
        vector_alloc(T, M, N), eltype(y)(M))
end

# Dispatch aware of eltype(x) != eltype(prob.u0)
function BVPSystem(prob::BVProblem, x, alg::Union{GeneralMIRK, MIRK})
    y = vector_alloc(prob.u0, x)
    M = length(y[1])
    N = size(x, 1)
    order = alg_order(alg)
    s = alg_stage(alg)
    BVPSystem(order, M, N, prob.f, prob.bc, prob.p, s, x, y, deepcopy(y),
        deepcopy(y), typeof(x)(undef, M))
end

# Auxiliary functions for evaluation
@inline function eval_fun!(S::BVPSystem)
    for i in 1:(S.N)
        S.fun!(S.f[i], S.y[i], S.p, S.x[i])
    end
end

@inline function eval_bc_residual!(::SciMLBase.StandardBVProblem, S::BVPSystem)
    S.bc!(S.residual[end], S.y, S.p, S.x)
end
@inline function eval_bc_residual!(::TwoPointBVProblem, S::BVPSystem)
    S.bc!(S.residual[end], (S.y[1], S.y[end]), S.p, (S.x[1], S.x[end]))
end

@views function Φ!(S::BVPSystem{T}, TU::MIRKTableau, cache::AbstractMIRKCache) where {T}
    M, N, residual, x, y, fun!, s = S.M, S.N, S.residual, S.x, S.y, S.fun!, S.s
    c, v, X, b = TU.c, TU.v, TU.x, TU.b
    temp = similar(first(y), S.M)
    for i in 1:(N - 1)
        K = cache.k_discrete[i, :]
        h = x[i + 1] - x[i]
        # Update K
        ## Separete out the first iteration: If the loop is not unrolled then we pay
        ## a conditional at every iteration
        x_new = x[i] + c[1] * h
        y_new = (1 - v[1]) * y[i] + v[1] * y[i + 1]
        fun!(temp, y_new, S.p, x_new)
        K[1] = copy(temp)

        for r in 2:s
            x_new = x[i] + c[r] * h
            y_new = (1 - v[r]) * y[i] + v[r] * y[i + 1]
            y_new += h * sum(j -> X[r, j] * K[j], 1:(r - 1))
            fun!(temp, y_new, S.p, x_new)
            K[r] = copy(temp)
        end

        # Update residual
        residual[i] = y[i + 1] - y[i] - h * sum(j -> b[j] * K[j], 1:s)
    end
end
