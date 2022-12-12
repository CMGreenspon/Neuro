
"""
# Neuro.CompareSpikeRates
Convenient calling of Distances.jl for spike rate comparisons

Common functions include:
```julia
euclidean, cityblock, sqeuclidean, chebyshev, hamming, jaccard, chisq_dist, kl_divergence,
js_divergence, meanad (mean abs deviation), msd (mean square deviation),
rmsd (rms deviation), and nrmsd (range normalized rms deviation).
Note that mahalanobis and minkowski are not supported.
```
Full list of rate comparisons at: https://github.com/JuliaStats/Distances.jl
"""
function CompareSpikeRates(train1::Vector{<:Real}, # Compare two spike trains
                           train2::Vector{<:Real},
                           method::PreMetric)
    
    if length(train1) !== length(train2)
        error("The length of train1 must equal that of train2")
    end

    distance = method(train1, train2)
    return distance
end

# Compare all of group 1 spike trains with all of group 2 spike train_metrics
function CompareSpikeRates(train_group1::Matrix{<:Real},
                           train_group2::Matrix{<:Real},
                           method::PreMetric;
                           dims::Int = 2)

    distance = colwise(method, train_group1, train_group2, dims=dims)
    return distance
end

# All pairwise combinations of spike trains
function CompareSpikeRates(trains::Matrix{<:Real},
                           method::PreMetric;
                           dims::Int = 2)

    distance = colwise(method, trains, dims=dims)
    return distance
end