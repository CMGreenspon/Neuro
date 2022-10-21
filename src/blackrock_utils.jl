# function OpenNEV(filepath::String;
#                  load_waveforms::Bool = false,
#                  show_report::Bool = false,
#                  verbose::Bool = true,
#                  digital_bits::Int = 16,
#                  time_range::Vector{Float64},
#                  cereplex_direct::Bool = false)


# end

function LoadUtahArrayMap(cmp_path::String; header_row::Int = 0)
    if !isfile(cmp_path)
        error("Could not find '$cmp_path'")
    end
    raw_df = DataFrame(CSV.File(cmp_path))
    num_columns = size(raw_df,2)

    if header_row == 0
        header_found = false
        for r = axes(raw_df,1)
            # skip missing rows but keep track of row number
            if ismissing(raw_df[r,num_columns])
                continue
            end

            # search for label string in last column
            if raw_df[r,num_columns] == "label"
                header_row = r
                header_found = true
                break
            end
        end
        
        if !header_found
            error("Could not find header row, consider declaring header_row = Int as argument")
        end
    elseif raw_df[header_row, num_columns] !== "label"
        printstyled("WARNING:"; color = :yellow)
        println(" Column $num_columns, row $header_row  does not contain the 'label' string.")
        stacktrace()
    end
    headless_df = raw_df[header_row+1:end,:]

    # Determine how many arrays are included in map file
    if contains(headless_df[1,end], "-") # Single array maps have format elecXX, multi aray have format elecN-XX
        array_num = fill(0, size(headless_df,1))
        for r = axes(headless_df,1)
            array_num[r] = parse(Int, headless_df[r,num_columns][5]) # Take N from each row (assumes N < 10)
        end
        num_arrays = length(unique(array_num))
    else
        num_arrays = 1
        array_num = fill(1, size(headless_df,1))
    end
    headless_df = hcat(headless_df, array_num) # Append array number as it makes filtering by row easier

    # Build array map
    array_vec = Vector{Dict}(undef,num_arrays)
    for a = 1:num_arrays
        # Get array specific values
        array_df = filter(row -> row["x1"] == a, headless_df)

        # Determine size of array
        num_electrodes = size(array_df,1)
        u_cols = parse.(Int, unique(array_df[:,1]))
        u_rows = parse.(Int, unique(array_df[:,2]))
        array_size = (length(u_rows), length(u_cols))

        col_offset = minimum(u_cols)
        row_offset = minimum(u_rows)

        # Prepare outputs
        # Prepare outputs
        bank_matrix = fill("", array_size)
        row_matrix = fill(0, array_size)
        col_matrix = fill(0, array_size)
        electrode_matrix = fill(0, array_size)
        label_matrix = fill("", array_size)

        # Iterate through df to get info
        for e = 1:num_electrodes
            # Get row & column
            c = parse(Int,array_df[e,1]) + 1 - col_offset
            r = parse(Int,array_df[e,2]) + 1 - row_offset
            # Assign
            col_matrix[r,c] = parse(Int, array_df[e,1])
            row_matrix[r,c] = parse(Int, array_df[e,2])
            bank_matrix[r,c] = array_df[e,3]
            electrode_matrix[r,c] = parse(Int, array_df[e,4])
            label_matrix[r,c] = array_df[e,5]
        end

        array_vec[a] = Dict("SubArray" => a,
                            "NumElectrodes" => num_electrodes,
                            "Bank" => bank_matrix,
                            "Electrode" => electrode_matrix,
                            "Label" => label_matrix,
                            "Row" => row_matrix,
                            "Column" => col_matrix)
    end

    return array_vec
end