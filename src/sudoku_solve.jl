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
    return nothing
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
    return nothing
end


"""
    resolve_subarray!(test,n)

Traverse a portion of a SolvablePuzzle to reduce logical options for n cells claiming n values.
"""
function resolve_subarray!(test::Array{Sudoku.PuzzleEntry},n::Integer)
    rank_squared = length(test)
    for i = 1:rank_squared
        p1 = BitVector(undef,rank_squared)
        p1.chunks[1] = test[i].possibilities
        if sum(p1) != n
            continue # nothing to do
        end
        # Fill a vector of values this cell claims
        possible_values = Set{Integer}()
        for j = 1:rank_squared
            if p1[j]
                possible_values = union(possible_values,Set([j]))
            end
        end # secondary loop over possible values
        # Track what array indices claim a size-n match
        match_indices = Set([i])
        for j = 1:rank_squared
            # Compare integers holding state of possibilities
            if i != j && test[i].possibilities == test[j].possibilities
                match_indices = union(match_indices,Set([j]))
            end
        end # secondary loop to find size-n matches to p1
        count_matches_found = length(match_indices)
        # If < n entries must have those n values, do nothing
        # If exactly n entries must have those n values, they cannot be in any others
        # If more than n entries must have n values, this is impossible
        if count_matches_found < n
            continue
        elseif count_matches_found > n
            throw(DomainError("Cannot match more than n times"))
        end
        #  elseif count_matches_found == n
        # remove these entries from other cell's possibilities
        for j = 1:rank_squared
            if j in match_indices
                continue
            else
                # Force values to zero 
                p2 = BitVector(undef,rank_squared)
                p2.chunks[1] = test[j].possibilities
                for v in possible_values
                    p2[v] = false
                end
                test[j] = PuzzleEntry(p2)
            end # branch 'remove possible values'
        end # secondary loop to remove entries
        # End of processing for matching possibilities for outermost chosen cell
    end # primary loop looking for n-size claims to possible value
    return nothing
end


"""
    resolve_puzzle!(puzzle,n)

Apply n-cell compound rule analyses to reduce uncertainty in puzzle.
"""
function resolve_puzzle!(puzzle::SolvablePuzzle, n::Integer)
    if n == 1
        resolve_puzzle!(puzzle)
        return nothing
    end
    # Handle shortcut for special case
    rank = get_rank(puzzle)
    rank_squared = rank*rank
    if n >= rank_squared
        throw(DomainError("Cannot evaluate compound resolve of size >= rank_squared"))
    end
    # use logical AND throughout loops
    for rowcol = 1:rank_squared
        # check full row and col
        update = puzzle.grid[rowcol,:]
        resolve_subarray!(update,n)
        puzzle.grid[rowcol,:] .= update
        update = puzzle.grid[:,rowcol]
        resolve_subarray!(update,n)
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
            resolve_subarray!(update,n)
            puzzle.grid[start_row:stop_row, start_col:stop_col] .= update
        end
    end
    # Compound resolve done for all rows, cols, and blocks
    return nothing
end

"""
    solve_puzzle!(puzzle, n)

Iteratively resolve rows, columns, and blocks of a puzzle with compound resolution n.
"""
function solve_puzzle!(puzzle::SolvablePuzzle, n::Integer)
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
            break # Stalled -- stop
        else
            for i in 1:n
                resolve_puzzle!(puzzle,i)
            end
            previous_uncertainty = current_uncertainty
            current_uncertainty = uncertainty(puzzle)
        end
        iteration += 1
    end
    return [iteration,current_uncertainty]
end
