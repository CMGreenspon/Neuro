module Neuro
    # Dependencies
    using StatsBase
    using StatsPlots
    import RecipesBase: recipetype
    using RecipesPipeline
    using Distributions

    # Neuro.jl
    include("raster.jl")
    include("psth.jl")

end # module Neuro
