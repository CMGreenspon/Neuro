@userplot PSTH
"""
Testing
"""
psth

@recipe function f(p::PSTH; binresolution = .05, windowedges = nothing,groupidx = nothing,  groupcolor = nothing,
     subsamplemethod = nothing, numfolds = 5, numbootstraps = 100)
    # Ensure that only one argument is given
    spike_times = p.args[1]
    num_trials = size(spike_times,1)

    # Get range of spike times
    if windowedges === nothing
        min_time = round(minimum(minimum.(spike_times))/binresolution) * binresolution
        max_time = round(maximum(maximum.(spike_times))/binresolution) * binresolution
        histedges = min_time:binresolution:max_time
    else
        if isa(windowedges, Union{Vector{Float32}, Vector{Float64}, Vector{Int}}) && length(windowedges) == 2
            histedges = windowedges[1]:binresolution:windowedges[2]
        else
            error("Window edges must be a 2-element vector with ints or floats")
        end
    end
    # For the x-values of the plot
    histcenters = histedges[1:end-1] .+ (binresolution/2)
    
    # Determine if a single trial or multiple trials are given
    if isa(spike_times, Union{Vector{Float32}, Vector{Float64}})
        spike_times = [spike_times] # Assert Vector{Vector}
    elseif !isa(spike_times,Union{Vector{Vector{Float64}}, Vector{Vector{Float32}}})
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

    # Determine if a color palette is being used
    if :color_palette ∉ keys(plotattributes)
        color_palette = :default
    else
        color_palette = plotattributes[:color_palette]
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
                y := group_hist.weights
                # line
                if groupcolor === nothing
                    linecolor := palette(color_palette)[g]
                elseif groupcolor !== nothing
                    linecolor := groupcolor[g]
                end
                () # Supress implicit return
            end
        elseif subsamplemethod == :Bootstrap
            for f = 1:numbootstraps
                temp = 0;
            end

        elseif subsamplemethod == :NFold
            for f = 1:numfolds
                temp = 0;
            end
        end
    end
end