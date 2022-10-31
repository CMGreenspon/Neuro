max_spikes = 1000
num_trials = 100
spike_times = [randn(rand(1:max_spikes)) for i in 1:num_trials]
time_windows = -.5:.5:1
spike_rates = Neuro.ComputeSpikeRates(spike_times, time_windows)