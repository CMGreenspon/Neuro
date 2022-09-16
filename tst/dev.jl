using Neuro, StatsBase, StatsPlots, BenchmarkTools, Distributions
gr(fmt = :png)
## RasterPlot
    max_spikes = 1000
    num_trials = 10
    spike_times = [rand(rand(1:max_spikes)) for i in 1:num_trials]
    spike_times[5] = []
    raster(spike_times, skip_empty=true)

# ## PSTH
    max_spikes = 100
    num_trials = 500
    groups = [rand(1:4)  for i in 1:num_trials]
    spike_times = [randn(rand(1:max_spikes)) .+ groups[i] for i in 1:num_trials]
    psth(spike_times, groupidx = groups, subsamplemethod=:Bootstrap, numbootstraps = 100, errormode=:STD,
     smoothingmethod=:gaussian, smoothingbins=5)

# ## Spike Rates
#     max_spikes = 1000
#     num_trials = 100
#     spike_times = [randn(rand(1:max_spikes)) for i in 1:num_trials]
#     time_windows = [-1 0; 0 .5; .5 1]
#     spike_rates = Neuro.ComputeSpikeRate(spike_times, time_windows)