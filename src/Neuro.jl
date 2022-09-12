module Neuro
    # Dependencies
    using StatsBase
    using StatsPlots
    import RecipesBase: recipetype
    using RecipesPipeline
    using Distributions

    # Neuro.jl
    include("psth.jl")
    include("raster.jl")
    include("spikerates.jl")

end # module Neuro
