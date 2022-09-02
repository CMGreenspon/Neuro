using Neuro
## RasterPlot
    max_spikes = 100
    num_trials = 100
    groups = [rand(1:2)  for i in 1:num_trials]
    spike_times = [randn(rand(1:max_spikes)) for i in 1:num_trials]
    rasterplot(spike_times, groupidx = groups, groupcolor = [:blue, :gray])


## PSTH
    max_spikes = 100
    num_trials = 1000
    spike_times = [randn(rand(1:max_spikes)) for i in 1:num_trials]
    groups = [rand(1:2)  for i in 1:num_trials]
    psth(spike_times, groupidx = groups, subsamplemethod = :NFold)