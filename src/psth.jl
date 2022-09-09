@userplot PSTH
"""
Testing
"""
psth

@recipe function f(p::PSTH; binresolution = .05, windowedges = nothing, groupidx = nothing,  groupcolor = nothing,
     subsamplemethod = nothing, numfolds = 5, numbootstraps = 100, bootstrapprop = 0.1, errormode=:STD,
     smoothingmethod = nothing, smoothingbins = nothing)
    # Ensure that only one argument is given
    spike_times = p.args[1]
    num_trials = size(spike_times,1)

    # Get range of spike times
    if windowedges === nothing
        min_time = round(minimum(minimum.(spike_times))/binresolution) * binresolution
        max_time = round(maximum(maximum.(spike_times))/binresolution) * binresolution
        histedges = min_time:binresolution:max_time
    else
        if windowedges isa Vector{T} where T<:Number && length(windowedges) == 2
            histedges = windowedges[1]:binresolution:windowedges[2]
        else
            error("Window edges must be a 2-element vector with ints or floats")
        end
    end
    # For the x-values of the plot
    histcenters = histedges[1:end-1] .+ (binresolution/2)
    
    # Determine if a single trial or multiple trials are given
    if spike_times isa Vector{AbstractFloat}
        spike_times = [spike_times] # Assert Vector{Vector}
    elseif !(spike_times isa Vector{Vector{T}} where T<:AbstractFloat)
        error("Spike times must be a Vector{Float} or Vector{Vector{Float}}.")
    end

    # If groupidx !== nothing then make sure it has the same #trials as spike_times
    if groupidx === nothing
        num_groups = 1
    elseif groupidx !== nothing && length(groupidx) != length(spike_times)
        error("length(spike_times) != length(groupidx).")
    elseif groupidx !== nothing && typeof(groupidx) <: Integer # Also check it's an int
        error("The groupidx variable must be an integer.")
    elseif groupidx !== nothing
        num_groups = length(unique(groupidx))
    end

    # Determine if a color palette is being used
    if :color_palette ∉ keys(plotattributes)
        color_palette = :default
    else
        color_palette = plotattributes[:color_palette]
    end

    # Check groupcolor format
    if groupidx === nothing
        if isa(groupcolor, Union{Symbol, RGB{Float64}, RGBA{Float64}})
            groupcolor = [groupcolor]
        elseif groupcolor !== nothing
            error("Invalid groupcolor type. Must be Union{Symbol, RGB{Float64}, RGBA{Float64}}) or nothing")
        end
    elseif groupidx !== nothing && groupcolor !== nothing && num_groups != length(groupcolor)
        error("Number of groupidx ≠ number of group colors")
    end

    # Check groupcolor format
    if groupcolor === nothing
            groupcolor = palette(color_palette)[repeat(collect(1:16),Int(ceil(num_groups/length(palette(color_palette)))))]
    elseif isa(groupcolor, Union{Symbol, RGB{Float64}, RGBA{Float64}})
        groupcolor = repeat([groupcolor], num_trials)
    elseif isa(groupcolor, Union{Vector{Symbol}, Vector{RGB{Float64}}, Vector{RGBA{Float64}}})
        if groupidx !== nothing && num_groups != length(groupcolor)
            error("Number of groupidx != number of group colors")
        end
    end

    # Set subsampling defaults if in use
    if (subsamplemethod == :NFold || subsamplemethod == :Bootstrap)
        min_trials = num_trials
        if num_groups > 1 # Need to find the group with the fewest trials and base off that
            for g = 1:num_groups
                group_trial_idx = findall(groupidx .== g)
                if length(group_trial_idx) < min_trials
                    min_trials = length(group_trial_idx)
                end
            end
        end

        if subsamplemethod == :NFold && min_trials < numfolds * 3
            printstyled("WARNING:"; color = :yellow)
            println(" $numfolds folds are requested but the smallest group only has $min_trials trials.")
        elseif subsamplemethod == :Bootstrap && min_trials <sqrt(numbootstraps)
            printstyled("WARNING:"; color = :yellow)
            println(" $numbootstraps bootstraps are requested but the smallest group only has $min_trials trials.")
        end

    elseif subsamplemethod !== nothing
        error("Invalid subsamplemethod. Must be nothing, :Bootstrap, or :NFold")
    end

    # Check if smoothing is enabled
    if smoothingmethod !== nothing && smoothingbins === nothing
        error("If smoothingmethod is defined you must also define smoothingbins.")
    end

    # Begin the plot
    seriestype := :path
    legend --> false
    for g = 1:num_groups
        # Get group indices
        if num_groups == 1
            group_trial_idx = collect(1:num_trials)
        else
            group_trial_idx = findall(groupidx .== g)
        end

        # Check if subsampling
        if subsamplemethod === nothing
            # Combine all 
            group_spike_times = collect(Iterators.flatten(spike_times[group_trial_idx]))
            group_hist = fit(Histogram, group_spike_times, histedges)
            @series begin
                x := histcenters
                if smoothingmethod === nothing
                    y := group_hist.weights
                else
                    y := smoothhist(group_hist.weights, method = smoothingmethod, windowsize = smoothingbins)
                end
                # line
                linecolor := groupcolor[g]
                () # Supress implicit return
            end
        elseif subsamplemethod == :Bootstrap || subsamplemethod == :NFold
            # Sample with appropriate method
            if subsamplemethod == :Bootstrap
                trials_per_strap = Int(floor(bootstrapprop * length(group_trial_idx)))
                group_hist = fill(0,numbootstraps, length(histcenters))
                for f = 1:numbootstraps
                    boot_idx = sample(group_trial_idx, trials_per_strap, replace=false)
                    strap_spike_times = collect(Iterators.flatten(spike_times[boot_idx]))
                    strap_hist = fit(Histogram, strap_spike_times, histedges)
                    group_hist[f,:] = strap_hist.weights
                end

            elseif subsamplemethod == :NFold
                group_hist = fill(0,numfolds, length(histcenters))
                tperfold = Int(floor(length(group_trial_idx) / numfolds))
                group_fold_idx = reshape(sample(group_trial_idx, tperfold*numfolds, replace=false), tperfold, numfolds)
                for f = 1:numfolds
                    fold_spike_times = collect(Iterators.flatten(spike_times[group_fold_idx[:,f]]))
                    fold_hist = fit(Histogram, fold_spike_times, histedges)
                    group_hist[f,:] = fold_hist.weights
                end
            end

            # Compute center and bounds for ribbon plot
            if errormode == :SEM || errormode == :STD
                y_center = vec(mean(group_hist, dims=1))
                y_error = vec(std(group_hist, dims=1))
                if errormode == :SEM
                    y_error = y_error ./ numfolds
                end
            elseif errormode == :IQR
                y_center = vec(median(group_hist, dims=1))
                y_lower = vec(mapslices(Y -> percentile(Y, 25), group_hist, dims=1))
                y_upper = vec(mapslices(Y -> percentile(Y, 75), group_hist, dims=1))
                y_error = (y_center .- y_lower, y_upper .- y_center) # Difference from center value
            end

            # Make ribbon plot 
            @series begin
                x := histcenters
                if smoothingmethod === nothing
                    y := y_center
                    ribbon := y_error
                else
                    y := smoothhist(y_center, method = smoothingmethod, windowsize = smoothingbins)
                    ribbon := smoothhist(y_error, method = smoothingmethod, windowsize = smoothingbins)
                end
                fillalpha --> .1
                linecolor := groupcolor[g]
                fillcolor := groupcolor[g]
                () # Supress implicit return
            end
        end
    end
end


function smoothhist(spike_hist::Vector{<:Number}; method = :mean, windowsize=5)
    # Initalize output to be the same size as the input
    smoothed_hist = zeros(length(spike_hist))

    # Ensure window_size is odd-valued
    if !iseven(windowsize)
        windowsize = windowsize + 1
    end
    half_win_idx = Int(floor(round(windowsize/2)))

    # Use desired smoothing method
    # Though it's cleaner to allocate indices and then apply it is 30% slower
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
        hw_x = LinRange(-3,3,(half_win_idx*2)+1)
        gauss_kernel = Normal(0,1)
        gauss_pdf = pdf.(gauss_kernel, hw_x)
        gauss_mult = gauss_pdf ./ sum(gauss_pdf)
        # Convolve
        for i = 1:length(spike_hist)
            if i <= half_win_idx
                smoothed_hist[i] = sum(spike_hist[1:i+half_win_idx] .* gauss_mult[end-(half_win_idx+i-1):end])
            elseif i >= length(spike_hist) - half_win_idx
                smoothed_hist[i] = sum(spike_hist[i-half_win_idx:end] .* gauss_mult[1:length(i-half_win_idx:length(spike_hist))])
            else
                smoothed_hist[i] = sum(spike_hist[i-half_win_idx:i+half_win_idx] .* gauss_mult)
            end
        end
    else
        error("Invalid method: must be :mean, :median, :gaussian")
    end

    return smoothed_hist
end