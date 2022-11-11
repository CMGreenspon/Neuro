# Compare two spike trains
function CompareSpikeTimes(train1::Vector{<:Number},
                           train2::Vector{<:Number},
                           method::Symbol;
                           optional_inputs)

end

# Compare all of group 1 spike trains with all of group 2 spike trains
function CompareSpikeTimes(train_group1::Vector{Vector{<:Number}},
                           train_group2::Vector{Vector{<:Number}},
                           method::Symbol;
                           optional_inputs)

end

# All pairwise combinations of spike trains
function CompareSpikeTimes(trains::Vector{Vector{<:Number}},
                           method::Symbol;
                           dims = 1)

end