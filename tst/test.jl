using Neuro, BenchmarkTools, Revise
max_spikes = 1000
num_trials = 5
spike_times = [randn(rand(1:max_spikes)) for i in 1:num_trials]
time_windows = -.5:.01:1
@benchmark spike_rates = Neuro.ComputeSpikeRates(spike_times, time_windows)
