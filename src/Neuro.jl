module Neuro
    # Dependencies
    using StatsBase
    using StatsPlots
    import RecipesBase: recipetype
    using RecipesPipeline
    using Distributions
    using CSV
    using DataFrames
    using NaNStatistics
    using Distances

    export
        # Spike rates
        ComputeSpikeRates,
        SmoothRates,
        CompareSpikeRates,

        # Blackrock Utils
        LoadUtahArrayMap


    # Neuro.jl
    include("psth.jl")
    include("raster.jl")
    include("spike_rates.jl")
    # include("train_metrics.jl")
    include("blackrock_utils.jl")
    include("spike_rate_comparisons.jl")

end # module Neuro
