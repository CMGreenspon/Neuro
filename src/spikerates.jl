function ComputeSpikeRate(spike_times::Vector{Vector{Float64}}, time_windows::AbstractMatrix; inclusive_edge = :right)
    num_trials = length(spike_times)
    num_periods = size(time_windows,1)
    if size(time_windows,2) > 2
        error("time_windows must be an Nx2 matrix")
    end

    # Compute durations ahead of time
    durations = mapslices(diff, time_windows, dims=2)
    
    # Iterate through each trial and compute rate in each period
    rate_output = fill(NaN, num_trials, num_periods)
    for t = 1:num_trials
        if all(isnan.(spike_times[t]))
            continue
        end
        for p = 1:num_periods
            if inclusive_edge == :right
                rate_output[t,p] = sum((spike_times[t] .> time_windows[p,1]) .& (spike_times[t] .<= time_windows[p,2])) / durations[p]
            elseif inclusive_edge == :left
                rate_output[t,p] = sum((spike_times[t] .>= time_windows[p,1]) .& (spike_times[t] .< time_windows[p,2])) / durations[p]
            end
        end
    end

    return rate_output
end