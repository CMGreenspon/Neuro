using Neuro, StatsBase, StatsPlots, BenchmarkTools, Distributions
## RasterPlot
    # max_spikes = 100
    # num_trials = 100
    # groups = [rand(1:2)  for i in 1:num_trials]
    # spike_times = [rand(rand(1:max_spikes)) for i in 1:num_trials]
    # rasterplot(spike_times, groupidx = groups)


# ## PSTH
    max_spikes = 100
    num_trials = 1000
    groups = [rand(1:4)  for i in 1:num_trials]
    spike_times = [randn(rand(1:max_spikes)) .+ groups[i] for i in 1:num_trials]
    @btime psth(spike_times, groupidx = groups, subsamplemethod=:Bootstrap, numbootstraps = 100, errormode=:SEM,
     smoothingmethod=:gaussian, smoothingbins=5)


# ## smoothingbins
#     max_spikes = 1000
#     num_trials = 100
#     groups = [rand(1:2)  for i in 1:num_trials]
#     spike_times = [randn(rand(1:max_spikes)) .+ groups[i] for i in 1:num_trials]
#     temp_hist = fit(Histogram, spike_times[1], nbins=30)
#     @btime smoothed_hist = Neuro.smoothhist(temp_hist.weights, method=:gaussian, windowsize=10);

#     plot(temp_hist.weights)
#     plot!(smoothed_hist)