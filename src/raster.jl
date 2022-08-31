@recipe function f(e::RasterPlot;  group = nothing, groupby = nothing, groupcolor = nothing, y_offset = 0)
    # Ensure that only one argument is given
    spike_times = e.args[1]
    num_trials = size(spike_times,1)

    # Determine if a single trial or multiple trials are given
    if isa(spike_times, Union{Vector{Float32}, Vector{Float64}})
        spike_times = [spike_times] # Assert Vector{Vector}
    elseif !isa(spike_times,Union{Vector{Vector{Float64}}, Vector{Vector{Float32}}})
        error("Spike times must be a Vector{Float} or Vector{Vector{Float}}.")
    end

    # If group !== nothing then make sure it has the same #trials as spike_times
    if group !== nothing && length(group) != length(spike_times)
        error("length(spike_times) != length(group).")
    elseif group !== nothing && typeof(group) <: Integer # Also check it's an int
        error("The group variable must be an integer.")
    end

    # Check groupcolor format
    if groupcolor === nothing
        groupcolor = repeat([:gray20], num_trials)
    elseif isa(groupcolor, Union{Symbol, RGB{Float64}, RGBA{Float64}})
        groupcolor = repeat([groupcolor], num_trials)
    elseif isa(groupcolor, Union{Vector{Symbol}, Vector{RGB{Float64}}, Vector{RGBA{Float64}}})
        if group === nothing && length(groupcolor) != num_trials
            error("Number of trials != number of colors, consider defining groups")
        elseif group !== nothing length(unique(group)) != length(groupcolor)
            error("Number of groups != number of group colors")
        end
    end

    if groupcolor !== nothing
        groupcolor = repeat(groupcolor, size(y,3)) # Use the same color for all groups
    elseif (groupcolor !== nothing && ndims(y) > 2) && length(groupcolor) < size(y,3)
        error("$(length(groupcolor)) colors given for a matrix with $(size(y,3)) groups")
    end

    # Determine if a color palette is being used so it can be passed to secondary lines
    if :color_palette ∉ keys(plotattributes)
        color_palette = :default
    else
        color_palette = plotattributes[:color_palette]
    end

    # Begin the plot
    seriestype := :line
    for t = 1:num_trials
        # Background paths
        @series begin
            num_trial_spikes = length(spike_times[t])
            x := vec(transpose(cat(spike_times[t],
                                   spike_times[t],
                                   fill(NaN, num_trial_spikes), dims = 2)))
            y := vec(transpose(cat(fill(t-tick_height+y_offset, num_trial_spikes),
                                   fill(t+tick_height+y_offset, num_trial_spikes),
                                   fill(NaN, num_trial_spikes), dims = 2)))
            # line
            if groupcolor === nothing
                linecolor := palette(color_palette)[plotattributes[:plot_object][1][end][:series_index]+1]
            elseif groupcolor !== nothing
                linecolor := groupcolor[g]
            end
            () # Supress implicit return
        end
    end

end