@userplot Raster
"""
raster(spike_times; groupidx = nothing,  groupcolor = nothing, tick_height = .475)

Creates a raster plot from spike times.

Input arguments: (Required type, *default value*)

spike_times (Vector{Vector{AbstractFloat}}) - Vector of vectors where each element contains spike times for a given trial
        with a common reference. Will accept a Vector{AbstractFloat} and treat as a single trial. 

groupidx (Vector{Int}, *nothing*) - The group identity of each vector in spike_times. All trials with the same group ID will
    be grouped together. If no value is given (*nothing*) then it is assumed that all trials are from the same group.

tick_height (AbstractFloat, *.95*) - how much of a row each tick should take up.
"""
raster

@recipe function f(r::Raster;  groupidx = nothing,  groupcolor = nothing, tick_height = .95)
    # Ensure that only one argument is given
    spike_times = r.args[1]
    num_trials = size(spike_times,1)

    # Determine if a single trial or multiple trials are given
    if isa(spike_times, Vector{AbstractFloat})
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
    if groupcolor !== nothing
        if isa(groupcolor, Union{Symbol, RGB{Float64}, RGBA{Float64}})
            groupcolor = repeat([groupcolor], num_trials)
        elseif isa(groupcolor, Union{Vector{Symbol}, Vector{RGB{Float64}}, Vector{RGBA{Float64}}})
            if groupidx === nothing && length(groupcolor) != num_trials
                error("Number of trials != number of colors, consider defining groupidx")
            elseif groupidx !== nothing && num_groups != length(groupcolor)
                error("Number of groupidx != number of group colors")
            end
        end
    end

    # Compute y_offset
    num_series = length(plotattributes[:plot_object].series_list)
    if num_series == 0
        ti = 1
    else
        y_max = 0
        for s = 1:num_series
            s_y_max = maximum(filter(!isnan,plotattributes[:plot_object].series_list[s][:y]))
            if s_y_max > y_max
                y_max = s_y_max
            end
        end
        ti = y_max + 1;
    end

    # Begin the plot
    seriestype := :path
    legend --> false
    half_tick_height = tick_height / 2
    for g = 1:num_groups
        # Work out wich spike times belong to which group
        if num_groups == 1
            num_group_trials = num_trials 
            group_trial_idx = collect(1:num_group_trials)
        else
            group_trial_idx = findall(groupidx .== g)
            num_group_trials = length(group_trial_idx)
        end
        # Plot each trial of the group
        group_x = Vector{Vector{Float64}}(undef,num_group_trials)
        group_y = Vector{Vector{Float64}}(undef,num_group_trials)
        for t = 1:num_group_trials
            num_trial_spikes = length(spike_times[group_trial_idx[t]])
            group_x[t] = vec(transpose(cat(spike_times[group_trial_idx[t]],
                                           spike_times[group_trial_idx[t]],
                                           fill(NaN, num_trial_spikes), dims = 2)))
            group_y[t] = vec(transpose(cat(fill(ti-half_tick_height, num_trial_spikes),
                                           fill(ti+half_tick_height, num_trial_spikes),
                                           fill(NaN, num_trial_spikes), dims = 2)))
            ti += 1
        end

        @series begin
            # Make ticks
            x := collect(Iterators.flatten(group_x))
            y := collect(Iterators.flatten(group_y))
            # Set color
            if groupcolor !== nothing
                linecolor := groupcolor[g]
            end
            linewidth --> .5
            () # Supress implicit return
        end
    end
end