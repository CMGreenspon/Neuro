@userplot Raster
"""
Testing
"""
raster

@recipe function f(r::Raster;  groupidx = nothing,  groupcolor = nothing, y_offset = 0, tick_height = .475)
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
    if groupcolor === nothing
        if groupidx !== nothing
            groupcolor = palette(color_palette)[repeat(collect(1:16),Int(ceil(num_groups/length(palette(color_palette)))))]
        else groupidx === nothing
            groupcolor = palette(color_palette)[repeat(collect(1:16),Int(ceil(num_trials/length(palette(color_palette)))))]
        end
    elseif isa(groupcolor, Union{Symbol, RGB{Float64}, RGBA{Float64}})
        groupcolor = repeat([groupcolor], num_trials)
    elseif isa(groupcolor, Union{Vector{Symbol}, Vector{RGB{Float64}}, Vector{RGBA{Float64}}})
        if groupidx === nothing && length(groupcolor) != num_trials
            error("Number of trials != number of colors, consider defining groupidx")
        elseif groupidx !== nothing && num_groups != length(groupcolor)
            error("Number of groupidx != number of group colors")
        end
    end

    # Begin the plot
    seriestype := :path
    legend --> false
    ti = 1
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
            group_y[t] = vec(transpose(cat(fill(ti-tick_height+y_offset, num_trial_spikes),
                                           fill(ti+tick_height+y_offset, num_trial_spikes),
                                           fill(NaN, num_trial_spikes), dims = 2)))
            ti += 1
        end

        @series begin
            # Make ticks
            x := collect(Iterators.flatten(group_x))
            y := collect(Iterators.flatten(group_y))
            # Set color
            if groupcolor === nothing
                linecolor := palette(color_palette)[g]
            else
                if length(groupcolor) == num_groups
                    linecolor := groupcolor[g]
                else
                    linecolor := groupcolor[t]
                end
            end
            linewidth --> .5
            () # Supress implicit return
        end
    end
end