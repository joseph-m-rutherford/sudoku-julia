# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.

"""
    resolve_subarray!(test)

Traverse a portion of a SolvablePuzzle to reduce logical options.
"""
function resolve_subarray!(test::Array{Sudoku.PuzzleEntry})
    rank_squared = length(test)

    # Visit each element to determine new mask
    mask = BitVector(undef,rank_squared)
    mask .= true
    for i = 1:rank_squared
        value = get_value(test[i])
        if value != 0
            mask[value] = false
        end
    end
    
    # Apply mask to all unknowns
    for i = 1:rank_squared
        if get_value(test[i]) == 0
            update_possibilities = BitVector(undef,rank_squared)
            update_possibilities.chunks[1] = test[i].possibilities
            update_possibilities .&= mask
            update_value = 0
            # if we have exactly 1 possibility, it's not unknown!
            possibility_sum = 0
            possible_value = 0
            for j = 1:rank_squared
                if update_possibilities[j]
                    possibility_sum += 1
                    possible_value = j
                end
            end
            test[i] = Sudoku.PuzzleEntry(update_possibilities)
        end
    end
end

"""
    resolve_puzzle(puzzle)

Traverse a puzzle by row, column, and block to apply logical rules.
"""
function resolve_puzzle!(puzzle::SolvablePuzzle)
    rank=get_rank(puzzle)
    rank_squared = rank*rank
    # use logical AND throughout loops
    for rowcol = 1:rank_squared
        # check full row and col
        update = puzzle.grid[rowcol,:]
        resolve_subarray!(update)
        puzzle.grid[rowcol,:] .= update
        update = puzzle.grid[:,rowcol]
        resolve_subarray!(update)
        puzzle.grid[:,rowcol] .= update
    end
    # Check rank x rank blocks
    for row_block = 1:rank
        start_row = rank*(row_block-1)+1
        stop_row = rank*(row_block-1)+rank
        for col_block = 1:rank
            start_col = rank*(col_block-1)+1
            stop_col = rank*(col_block-1)+rank
            update = puzzle.grid[start_row:stop_row, start_col:stop_col]
            resolve_subarray!(update)
            puzzle.grid[start_row:stop_row, start_col:stop_col] .= update
        end
    end
end

"""
    solve_puzzle!(puzzle)

Iteratively resolve rows, columns, and blocks of a puzzle to drive uncertainty down to zero.
"""
function solve_puzzle!(puzzle::SolvablePuzzle)
    # Uncertainty is rank_squared*puzzle_size
    rank = get_rank(puzzle)
    rank_squared = rank*rank
    maximum_uncertainty = rank_squared*rank_squared*rank_squared
    
    iteration = 0
    previous_uncertainty = maximum_uncertainty
    current_uncertainty = uncertainty(puzzle)
    while current_uncertainty > 0
        if current_uncertainty > previous_uncertainty
            throw(DomainError("Solution diverging"))
        elseif current_uncertainty == previous_uncertainty
            throw(DomainError("Solution stuck"))
        else
            resolve_puzzle!(puzzle)
            previous_uncertainty = current_uncertainty
            current_uncertainty = uncertainty(puzzle)
        end
        iteration += 1
    end
    return [iteration,current_uncertainty]
end