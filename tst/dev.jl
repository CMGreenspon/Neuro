using StatsPlots

## Generate random spike times
    tick_height = .95 / 2
    max_spikes = 100
    spike_times = map(sort, [rand(rand(1:max_spikes)),rand(rand(1:max_spikes))])
    # Check how plotting works
    num_trials = size(spike_times,1)
    RasterPlot = plot(xlabel = "Time",ylabel = "Trial", xlim=(0, 1), ylim=(tick_height, num_trials+tick_height))
    for t = 1:num_trials
        num_trial_spikes = length(spike_times[t])
        x = vec(transpose(cat(spike_times[t], spike_times[t], fill(NaN, num_trial_spikes), dims = 2)))
        y = vec(transpose(cat(fill(t-tick_height, num_trial_spikes), fill(t+tick_height, num_trial_spikes), fill(NaN, num_trial_spikes), dims = 2)))

        plot!(RasterPlot, x,y)
    end
    display(RasterPlot)
