using Neuro, StatsBase, StatsPlots, BenchmarkTools, Distributions
gr(fmt = :png)
## RasterPlot
    max_spikes = 1000
    num_trials = 10
    spike_times = [rand(rand(1:max_spikes)) for i in 1:num_trials]
    raster!(spike_times, group_offset = 1)

# ## PSTH
    max_spikes = 100
    num_trials = 500
    groups = [rand(1:4)  for i in 1:num_trials]
    spike_times = [randn(rand(1:max_spikes)) .+ groups[i] for i in 1:num_trials]
    psth(spike_times, groupidx = groups, subsamplemethod=:Bootstrap, numbootstraps = 100, errormode=:STD,
     smoothingmethod=:gaussian, smoothingbins=5)

## Spike Rates
    max_spikes = 1000
    num_trials = 100
    spike_times = [randn(rand(1:max_spikes)) for i in 1:num_trials]
    time_windows = [-1 0; 0 .5; .5 1]
    spike_rates = Neuro.ComputeSpikeRate(spike_times, time_windows)

## Import blackrock utah array map
    # Declare serial number for
    anterior_serial = "4566-002368"
    posterior_serial = "4566-002318"
    
    # File names for loading - check drive mapping
    anterior_map_path = raw"Z:\BCI02\SurgicalData\4566-002368\SN 4566-002368.cmp"
    posterior_map_path = raw"Z:\BCI02\SurgicalData\4566-002318\SN 4566-002318.cmp"
    
    anterior_map = Neuro.LoadUtahArrayMap(anterior_map_path)
    
        