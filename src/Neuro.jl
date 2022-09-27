module Neuro
    # Dependencies
    using StatsBase
    using StatsPlots
    import RecipesBase: recipetype
    using RecipesPipeline
    using Distributions
    using CSV
    using DataFrames

    # Neuro.jl
    include("psth.jl")
    include("raster.jl")
    include("spikerates.jl")
    include("blackrock_utils.jl")

end # module Neuro
