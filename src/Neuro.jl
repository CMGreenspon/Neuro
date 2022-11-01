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

    # Neuro.jl
    include("psth.jl")
    include("raster.jl")
    include("spike_rates.jl")
    # include("train_metrics.jl")
    include("blackrock_utils.jl")

end # module Neuro
