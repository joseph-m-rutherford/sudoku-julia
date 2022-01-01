# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.
# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.
#
# This file depends upon sudoku_common.jl

function as_text_grid(puzzle::SolvablePuzzle)
    source = as_text(puzzle)
    rank = get_rank(puzzle)
    rank_squared = rank*rank
    # rows are each value in a block row separated by a spacer, 
    # and an extra spacer for blocks
    # e.g., "||1|2||3|4||" or "||1|2|3||4|5|6||7|8|9||"
    # for rank*rank numbers, rank*rank-1 spacers,rank doubled spacers, and 2 leading spacers =
    # 2*rank*rank + rank + 2 spaces
    column_count =2*rank*rank + rank + 2
    fill_columns = Array{Int8}(undef,(rank_squared,))
    next_column = 1
    for i = 1:rank # column block
        for j = 1:rank # block column
            fill_columns[next_column] = (i-1)*(2*rank+1)+3+(j-1)*2
            next_column += 1
        end
    end
            
    row_count = rank_squared+rank+1
    spacer = "|"
    horizontal_space = "-"
    interim = fill(spacer,(row_count,column_count))
    next_puzzle_row = 1
    # Now walk across all rows of output
    for i = 1:row_count
        if 1 + (i - 1) % (rank+1) == 1
            for j = 1:column_count
                interim[i,j] = horizontal_space
            end
        else
            puzzle_row = next_puzzle_row
            next_puzzle_row += 1
            # Now walk across all columns of output
            for j = 1:rank_squared # column block
                interim[i,fill_columns[j]] = source[puzzle_row,j]
            end
        end
    end
    
    # Convert interim set of strings to lines of text
    all_rows = Array{String}(undef,row_count)
    for i = 1:row_count
        # Concatenate columns of strings
        line = ""
        for j = 1:column_count
            line = line*interim[i,j]
        end
        all_rows[i] = line
    end
    
    # Accumulate lines with newline
    result = ""
    for i = 1:row_count
        result = result*all_rows[i]*"\n"
    end    
    return result   
end
