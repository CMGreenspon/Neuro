
"""
# Neuro.CompareSpikeRates
Convenient calling of Distances.jl for spike rate comparisons

Common functions include:
```julia
euclidean, cityblock, sqeuclidean, chebyshev, minkowski, hamming, jaccard, chisq_dist, kl_divergence,
js_divergence, mahalanobis, meanad (mean abs deviation), msd (mean square deviation),
rmsd (rms deviation), and nrmsd (range normalized rms deviation).
```
Full list of rate comparisons at: https://github.com/JuliaStats/Distances.jl
"""
function CompareSpikeRates(train1::Vector{<:Real}, # Compare two spike trains
                           train2::Vector{<:Real},
                           method::PreMetric;
                           p::Int = 1,
                           q::AbstractMatrix = Matrix{Float64}(undef,1,1))
    
    if length(train1) !== length(train2)
        error("The length of train1 must equal that of train2")
    end

    distance = Float64[]
    if method == minkowski
        distance = method(train1, train2, p)
    elseif method == mahalanobis
        distance = method(train1, train2, q)
    else
        distance = method(train1, train2)
    end
    return distance
end

# Compare all of group 1 spike trains with all of group 2 spike trains - need to test comprehensive for loop vs temporary pairwise matrix
function CompareSpikeRates(train_group1::Matrix{<:Real},
                           train_group2::Matrix{<:Real},
                           method)

    distance = pairwise(method, trains, dims)

end

# All pairwise combinations of spike trains
function CompareSpikeRates(trains::Matrix{<:Real},
                           method::PreMetric;
                           dims::Int = 1,
                           p::Int = 1,
                           q::AbstractMatrix = Matrix{Float64}(undef,1,1))

    distance = Matrix[]
    if method == minkowski
        distance = pairwise(method, trains, p, dims=dims)
    elseif method == mahalanobis
        distance = pairwise(method, trains, q, dims=dims)
    else
        distance = pairwise(method, trains, dims=dims)
    end
    return distance
    
    return distance
end