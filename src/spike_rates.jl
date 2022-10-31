function ComputeSpikeRates(spike_times::Union{Vector{Float64}, Vector{Vector{Float64}}},
                           time_windows::Union{AbstractMatrix, AbstractRange};
                           inclusive_edge::Symbol = :right)
    
    # Convert single vector to vector{vector}
    if spike_times isa Vector{Float64}
        spike_times = [spike_times]
    end 
    num_trials = length(spike_times)

    # Determine time windows/bin edges
    if time_windows isa AbstractMatrix
        if size(time_windows,2) > 2
            error("time_windows{AbstractMatrix} must be an Nx2 matrix")
        end

    elseif time_windows isa AbstractRange
        time_window_vec = collect(time_windows)
        time_windows = hcat(time_window_vec[1:end-1], time_window_vec[2:end])
    else
        error("Unsupported time_windows. Must be an AbstractMatrix (Nx2) or an AbstractRange")
    end
    num_periods = size(time_windows,1)

    # Compute durations ahead of time
    durations = mapslices(diff, time_windows, dims=2)
    
    # Iterate through each trial and compute rate in each period
    rate_output = fill(0.0, num_periods, num_trials)
    for t = 1:num_trials
        if all(isnan.(spike_times[t]))
            continue
        end
        for p = 1:num_periods
            if inclusive_edge == :right
                rate_output[p,t] = sum((spike_times[t] .> time_windows[p,1]) .& (spike_times[t] .<= time_windows[p,2])) / durations[p]
            elseif inclusive_edge == :left
                rate_output[p,t] = sum((spike_times[t] .>= time_windows[p,1]) .& (spike_times[t] .< time_windows[p,2])) / durations[p]
            end
        end
    end

    return rate_output
end


function SmoothRates(spike_hist::Vector{<:Number};
                     method::Symbol = :gaussian,
                     windowsize::Int = 5,
                     gauss_range::Int = 3)

    # Initalize output to be the same size as the input
    smoothed_hist = zeros(length(spike_hist))

    # Ensure window_size is odd-valued
    if !iseven(windowsize)
        windowsize = windowsize + 1
    end
    half_win_idx = Int(floor(round(windowsize/2)))
    if half_win_idx == 0
        error("Window size $window_size is too small")
    end

    # Use desired smoothing method
    # Though it's cleaner to allocate indices and then apply it's ~30% slower
    if method == :mean
        for i = 1:length(spike_hist)
            if i <= half_win_idx
                smoothed_hist[i] = mean(spike_hist[1:i+half_win_idx])
            elseif i >= length(spike_hist) - half_win_idx
                smoothed_hist[i] = mean(spike_hist[i-half_win_idx:end])
            else
                smoothed_hist[i] = mean(spike_hist[i-half_win_idx:i+half_win_idx])
            end
        end

    elseif method == :median
        for i = 1:length(spike_hist)
            if i <= half_win_idx
                smoothed_hist[i] = median(spike_hist[1:i+half_win_idx])
            elseif i >= length(spike_hist) - half_win_idx
                smoothed_hist[i] = median(spike_hist[i-half_win_idx:end])
            else
                smoothed_hist[i] = median(spike_hist[i-half_win_idx:i+half_win_idx])
            end
        end

    elseif method == :gaussian
        # Create the smoothing kernel
        hw_x = LinRange(-gauss_range,gauss_range,(half_win_idx*2)+1)
        gauss_pdf = pdf.(Normal(0,1), hw_x)
        gauss_mult = gauss_pdf ./ sum(gauss_pdf) # Adjust for gauss_range parameter where values don't necessarily sum to 1
        # Convolve
        for i = 1:length(spike_hist)
            if i <= half_win_idx # Partial left tail gauss - normalized by amount of gauss overlapping
                smoothed_hist[i] = sum(spike_hist[1:i+half_win_idx] .* gauss_mult[end-(half_win_idx+i-1):end]) * 1/sum(gauss_mult[end-(half_win_idx+i-1):end])
            elseif i >= length(spike_hist) - half_win_idx # Partial right tail gauss - normalized by amount of gauss overlapping
                smoothed_hist[i] = sum(spike_hist[i-half_win_idx:end] .* gauss_mult[1:length(i-half_win_idx:length(spike_hist))]) * 1/sum(gauss_mult[1:length(i-half_win_idx:length(spike_hist))])
            else # Full gauss
                smoothed_hist[i] = sum(spike_hist[i-half_win_idx:i+half_win_idx] .* gauss_mult)
            end
        end
    else
        error("Invalid method: must be :mean, :median, :gaussian")
    end

    return smoothed_hist
end