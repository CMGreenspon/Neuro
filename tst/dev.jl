using Neuro, StatsBase, StatsPlots, BenchmarkTools, Distributions
include(raw"..\src\spikerates.jl")
## RasterPlot
    max_spikes = 1000
    num_trials = 100
    groups = [rand(1:2)  for i in 1:num_trials]
    spike_times = [rand(rand(1:max_spikes)) for i in 1:num_trials]
    @time raster(spike_times, groupidx = groups)


## PSTH
    max_spikes = 100
    num_trials = 5
    groups = [rand(1:4)  for i in 1:num_trials]
    spike_times = [randn(rand(1:max_spikes)) .+ groups[i] for i in 1:num_trials]
    @time psth(spike_times, groupidx = groups, subsamplemethod=:Bootstrap, numbootstraps = 100, errormode=:STD,
     smoothingmethod=:gaussian, smoothingbins=5)

## Spike Rates
    max_spikes = 1000
    num_trials = 100
    spike_times = [randn(rand(1:max_spikes)) for i in 1:num_trials]
    time_windows = [-1 0; 0 .5; .5 1]
    spike_rates = ComputeSpikeRate(spike_times, time_windows)