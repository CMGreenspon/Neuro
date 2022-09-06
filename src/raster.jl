@userplot RasterPlot
"""
Testing
"""
rasterplot

@recipe function f(e::RasterPlot;  groupidx = nothing,  groupcolor = nothing, y_offset = 0, tick_height = .475)
    # Ensure that only one argument is given
    spike_times = e.args[1]
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

    # Check groupcolor format
    if groupcolor === nothing && groupidx === nothing
        groupcolor = repeat([:gray40], num_trials)
    elseif isa(groupcolor, Union{Symbol, RGB{Float64}, RGBA{Float64}})
        groupcolor = repeat([groupcolor], num_trials)
    elseif isa(groupcolor, Union{Vector{Symbol}, Vector{RGB{Float64}}, Vector{RGBA{Float64}}})
        if groupidx === nothing && length(groupcolor) != num_trials
            error("Number of trials != number of colors, consider defining groupidx")
        elseif groupidx !== nothing && num_groups != length(groupcolor)
            error("Number of groupidx != number of group colors")
        end
    end

    # Determine if a color palette is being used
    if :color_palette ∉ keys(plotattributes)
        color_palette = :default
    else
        color_palette = plotattributes[:color_palette]
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
        for t = 1:num_group_trials
            @series begin
                # Make ticks
                num_trial_spikes = length(spike_times[group_trial_idx[t]])
                x := vec(transpose(cat(spike_times[group_trial_idx[t]],
                                       spike_times[group_trial_idx[t]],
                                       fill(NaN, num_trial_spikes), dims = 2)))
                y := vec(transpose(cat(fill(ti-tick_height+y_offset, num_trial_spikes),
                                       fill(ti+tick_height+y_offset, num_trial_spikes),
                                       fill(NaN, num_trial_spikes), dims = 2)))
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
                () # Supress implicit return
            end
            ti += 1
        end
    end
end