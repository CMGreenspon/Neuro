using Neuro
max_spikes = 100
num_trials = 100
spike_times = [rand(rand(1:max_spikes)) for i in 1:num_trials]
groups = [rand(1:2)  for i in 1:num_trials]
rasterplot(spike_times, groupidx = groups)