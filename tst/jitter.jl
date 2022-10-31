# Jitter testing
using StatsBase, StatsPlots, NaNStatistics, Neuro, Random, BenchmarkTools, Base.Threads
gr(fmt = :png)

function JitterTrains(spike_times::Vector{Vector{Float64}},
                      num_trials::Int,
                      jitter::Float64;
                      time_window::Vector{Float64} = [0.0,1.0],
                      match_rates::Bool = true,
                      match_ratio::Float64 = 0.25)

    num_classes = length(spike_times)
    num_spikes = length(spike_times[1])
    match_num = Int(round(num_spikes * match_ratio))
    # Create jittered trains from base trains
    println("Jittering trains with $(jitter*1000) ms")
    jittered_times  = Array{Vector{Float64}}(undef, num_classes, num_trials)
    jittered_hist = Array{Vector{Float64}}(undef, num_classes, num_trials)
    for c = 1:num_classes, t = 1:num_trials
         # Add amount of jitter to each time point
        if match_rates # Subsample within time window an equal number of spikes
            temp_jt = spike_times[c] .+ (jitter .* randn(num_spikes)) # Perform the jittering
            in_window_idx = findall((temp_jt .>= time_window[1]) .& (temp_jt .<= time_window[2])) # Find times in window
            sampled_indices = in_window_idx[sort(randperm(length(in_window_idx))[1:match_num])] # Randomly sample N of them
            jittered_times[c,t] = temp_jt[sampled_indices] # Assign
        else
            jittered_times[c,t] = spike_times[c] .+ (jitter .* randn(num_spikes)) # Jitter all
        end
        # Make histogram of each jittered_times
        jittered_hist[c,t] = vec(Neuro.ComputeSpikeRates([jittered_times[c,t]], time))
    end

    return jittered_times, jittered_hist
end

function TimingClassification(spike_hist::Matrix{Vector{Float64}},
                              smoothing_windows::Vector{Float64};
                              num_folds::Int = 5,
                              max_lag_prop::Float64 = 0.05)
    # Workout fold indices
    (num_classes, num_trials) = size(spike_hist)
    fold_indices = Array{Vector{Int}}(undef, num_classes, num_folds)
    for c = 1:num_classes
        cf_idx = fill(NaN, Int(ceil(num_trials/num_folds)) * num_folds)
        cf_idx[1:num_trials] = randperm(num_trials)
        cf_idx = reshape(cf_idx, (Int(ceil(num_trials/num_folds)), num_folds))
        for f = 1:num_folds
            fold_indices[c,f] = Int.(cf_idx[findall(isnan.(cf_idx[:,f]) .== 0), f])
        end
    end

    # Smooth and classify
    max_lag = Int(round(length(spike_hist[1,1]) * max_lag_prop))
    classification_performance = fill(NaN, length(smoothing_windows), num_folds)
    covariance_matrices = Vector{Array{Float64}}(undef, length(smoothing_windows))
    for w = axes(smoothing_windows,1)
        println("Classifying with $(smoothing_windows[w]*1000) ms smoothing ($w of $(length(smoothing_windows)))")
        # First smooth histograms appropriately
        smoothing_window_size = Int(round(smoothing_windows[w] / time_resolution))
        smoothed_spike_hist = Array{Vector{Float64}}(undef, num_classes, num_trials)
        for c = 1:num_classes, t = 1:num_trials
            smoothed_spike_hist[c,t] = Neuro.SmoothRates(spike_hist[c,t], method = :gaussian, windowsize = smoothing_window_size, gauss_range = 1)
        end

        # For each fold: pairwise cross-covariance of all in-fold against out-fold textures
        pw_xcov_mat = fill(NaN, num_classes, num_classes, num_folds)
        for f = 1:num_folds
            println("   Fold $f of $num_folds")
            for ci = 1:num_classes
                out_fold_idx = fold_indices[ci,f] # Indices to compare with all others
                for cj = 1:num_classes
                    if !isnan(pw_xcov_mat[cj,ci,f]) # Skip reverse-pair correlations
                        pw_xcov_mat[ci,cj,f] = pw_xcov_mat[cj,ci,f]
                        continue
                    end

                    in_fold_idx = collect(Iterators.flatten(fold_indices[ci,1:num_folds .!= f]))
                    # Get all possible combinations of in and out fold indices
                    combs = vec(collect(Iterators.product(out_fold_idx, in_fold_idx)))
                    combs_max_cov = fill(NaN, size(combs,1))
                    Threads.@threads for cij = axes(combs,1)
                        combs_max_cov[cij] = maximum(crosscov(smoothed_spike_hist[ci, combs[cij][1]],
                                                                smoothed_spike_hist[cj,combs[cij][2]], -max_lag:max_lag))
                    end
                    pw_xcov_mat[ci,cj,f] = mean(combs_max_cov)
                end
            end
        end
        covariance_matrices[w] = pw_xcov_mat

        # Then perform nearest neighbor classification within each fold
        for f = 1:num_folds
            num_classes_correct = 0
            for ci = 1:num_classes
                (_, idx) = findmax(pw_xcov_mat[ci,:,1])
                if idx == ci
                    num_classes_correct += 1
                end
            end
            classification_performance[w,f] = num_classes_correct / num_classes
        end
    end

    return covariance_matrices, classification_performance
end


## Settings
    train_duration = 2 # seconds
    time_resolution = 1e-3 # 1/10 of a millisecond
    time = -(train_duration/2):time_resolution:(train_duration*1.5)
    time_window = [0.0, 1.0] # Time to rate match within
    num_time_points = length(time)

    num_classes = 25 # For classification
    num_trials = 5 # Trials per class 
    num_spikes = 200 # Spikes in whole train_duration
    num_folds = 5 # Should be divisor of num_trials

    match_rates = true # Whether or not to rate match jittered trains
    match_ratio = 0.1 # Proportion of num_spikes to subsample

    jitter = 50 ./ 1e3 # Milliseconds
    smoothing_windows = collect(Iterators.flatten(
                        [.1:.1:1, 2:10, 20:10:100, 200:25:500])) ./ 1e3 # Milliseconds

## Trains
    # Create num_classes base trains
    base_times = Vector{Vector{Float64}}(undef, num_classes)
    for c = 1:num_classes
        base_times[c] = time[sort(randperm(num_time_points)[1:num_spikes])]
    end
    
    # Jitter trains and make histograms
    jittered_times, jittered_hist = JitterTrains(base_times, num_trials, jitter, time_window = time_window, match_rates = true, match_ratio = match_ratio)
    
    # Perform timing classification
    @btime covariance_matrices, classification_performance = TimingClassification(jittered_hist, smoothing_windows, num_folds = 5)

## plot the classification classification_performance
