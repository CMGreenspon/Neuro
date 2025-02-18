@userplot PSTH
"""
# psth(spike_times, arg)

Takes previously aligned spike times from a single or multiple groups and constructs a peri-stimulus time
histogram from the times. Allows for variable binresolution, subsampling methods for estimates of variance, and smoothing.

## Input arguments: (Required type, *default value*)

    spike_times (Vector{Vector{AbstractFloat}}) - Vector of vectors where each element contains spike times for a given trial
        with a common reference. Will accept a Vector{AbstractFloat} and treat as a single trial. 

    groupidx (Vector{Int}, *nothing*) - The group identity of each vector in spike_times. All trials with the same group ID will
        be grouped together. If no value is given (*nothing*) then it is assumed that all trials are from the same group.

    binresolution (AbstractFloat, *0.05*) - time duration in units of spike times that the histogram will use for bin size.

    windowedges (Vector{Number} of length 2, *nothing*) - minimum and maximum spike times for histogram. Bin edges are created to be
        windowedges[1]:binresolution:windowedges[2]. If *nothing* then the minimum and maximum of spike_times is used.

    groupcolor (Symbol, RGB, Vector{Symbol or RGB}, *nothing") - the desired color for each group. If groupcolor is given then
        the number of inputs must match the number of groups (length(unique(groupidx))). If nothing then will use color_palette.

    subsamplemethod (:NFold or :Bootstrap, *nothing*) - method of subsampling to use to generate subgroups where the histogram computed
        for each subgroup, and the mean and error will be computed from those subgroups.
        If :NFold then each group will be split into *numfolds* equally sized subgroups.
        If :Bootstrap then *numbootstraps* subgroups of *bootstrapprop*% of the group trials will be made.

    numfolds (Int, *5*) - how many folds to create for each group.

    numbootstraps (Int, *100*) - how many bootstraps to draw for each group.

    bootstrapprop (AbstractFloat, *0.1*) - what proportion of the trials to draw for each bootstrap.

    errormode (*:STD*, :SEM, :IQR) - which error metric to use within group.

    smoothingmethod (:mean, :median, :gaussian, *nothing*) - whether to use movingmean, movingmedian or a gaussian smoothing kernel
            to smooth out the PSTH before plotting. If declared then *smoothingbins* must also be declared.

    smoothingbins (Int) - The number of bins over which to apply the smoothing operation.

### Example
```julia
max_spikes = 100
num_trials = 500
groups = [rand(1:4)  for i in 1:num_trials]
spike_times = [randn(rand(1:max_spikes)) .+ groups[i] for i in 1:num_trials]
psth(spike_times, groupidx = groups, subsamplemethod=:Bootstrap, numbootstraps = 100, errormode=:STD,
 smoothingmethod=:gaussian, smoothingbins=5)
```

"""
psth

@recipe function f(p::PSTH; groupidx = nothing,
                            binresolution = .05,
                            windowedges = nothing,
                            groupcolor = nothing,
                            subsamplemethod = nothing,
                            numfolds = 5,
                            numbootstraps = 100,
                            bootstrapprop = 0.1,
                            errormode=:STD,
                            smoothingmethod = nothing,
                            smoothingbins = nothing)
                            
    # Ensure that only one argument is given
    spike_times = p.args[1]
    num_trials = size(spike_times,1)

    # Get range of spike times
    if windowedges === nothing
        extrema = nanextrema(Iterators.flatten(spike_times))
        min_time = round(extrema[1]/binresolution) * binresolution
        max_time = round(extrema[2]/binresolution) * binresolution
        histedges = min_time:binresolution:max_time
    elseif windowedges isa Vector
        if eltype(windowedges) <: Number && length(windowedges) == 2 && windowedges[1] < windowedges[2]
            histedges = windowedges[1]:binresolution:windowedges[2]
        else
            error("Window edges must be a 2-element vector with ints or floats")
        end
    elseif windowedges isa AbstractRange
        histedges = collect(windowedges)
    end
    # For the x-values of the plot
    histcenters = histedges[1:end-1] .+ (binresolution/2)
    
    # Determine if a single trial or multiple trials are given
    if spike_times isa Vector{T} where T<:AbstractFloat
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
    if groupcolor !== nothing
        if isa(groupcolor, Union{Symbol, RGB{Float64}, RGBA{Float64}})
            groupcolor = repeat([groupcolor], num_trials)
        elseif isa(groupcolor, Union{Vector{Symbol}, Vector{RGB{Float64}}, Vector{RGBA{Float64}}})
            if groupidx !== nothing && num_groups != length(groupcolor)
                error("Number of groupidx != number of group colors")
            end
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
                if groupcolor !== nothing
                    linecolor := groupcolor[g]
                end
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
            else
                error("Invalid errormode - must be :STD, :SEM, or :IQR")
            end

            # Make ribbon plot 
            @series begin
                x := histcenters
                if smoothingmethod === nothing
                    y := y_center
                    ribbon := y_error
                else
                    y := SmoothRates(y_center, method = smoothingmethod, windowsize = smoothingbins)
                    ribbon := SmoothRates(y_error, method = smoothingmethod, windowsize = smoothingbins)
                end
                fillalpha --> .1
                if groupcolor !== nothing
                    linecolor := groupcolor[g]
                    fillcolor := groupcolor[g]
                end
                () # Supress implicit return
            end
        end
    end
end