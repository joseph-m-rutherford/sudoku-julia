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
    resolve_puzzle!(puzzle)

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
    iterative_solve!(puzzle, n)

Iteratively resolve rows, columns, and blocks of a puzzle.
Compound rules evaluation of n >= 0 are used; n == 0 is a no-op.
"""
function iterative_solve!(puzzle::SolvablePuzzle, n::Integer)
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

"""
    guess_solutions(puzzle)

Return a vector of single-entry guesses for the unknowns.
All guesses correspond to possible values of a single entry.
Each guessed new puzzle may be attempted for further solution.
If valid after solution, the guess must satisfy puzzle.
"""
function guess_solutions(puzzle::Sudoku.SolvablePuzzle)
    # Find the point of greatest uncertainty
    peak_possibility = 0
    peak_index = 0
    rank = Sudoku.get_rank(puzzle.grid)
    rank_squared = rank*rank
    for i = 1:length(puzzle.grid)
        temp = BitVector(undef,rank_squared)
        temp.chunks[1] = puzzle.grid[i].possibilities # Convert int to BitVector
        possibility_count = sum(temp)
        if possibility_count > peak_possibility
            peak_possibility = possibility_count
            peak_index = i
        end
    end
    if peak_possibility < 1
        throw(DomainError("Cannot solve an overdetermined puzzle"))
    end
    # Now make guesses from this this one entry
    results = Array{Sudoku.SolvablePuzzle}(undef,peak_possibility)
    for i in 1:peak_possibility
        results[i] = SolvablePuzzle(rank)
        results[i].grid .= puzzle.grid
    end
    next_result_index = 1
    entry = BitVector(undef,rank_squared)
    entry.chunks[1] = puzzle.grid[peak_index].possibilities
    for i = 1:rank_squared
        if entry[i]     
            # Attempt to solve with this guess
            guess_entry = BitVector(undef,rank_squared)
            guess_entry .= false
            guess_entry[i] = true
            results[next_result_index].grid[peak_index] = Sudoku.PuzzleEntry(guess_entry)
            next_result_index += 1
        end
    end
    return results
    if next_result_index != (peak_possibility+1)
        throw(ErrorException("Guessing solutions did not correctly traverse the uncertainty"))
    end
    return result
end

"""
    backtrack_solve(puzzle,n,r,c)

Attempt solution by guessing an instance of all unknown values.
Compound rule size n >= 0 are evaluated to reduce search space (n==0 means no reductions attempted).
Indeterminate solutions are recursed up to the given limit r.
Maximum solution count max at which evaluation will terminate.
"""
function backtrack_solve(puzzle::Sudoku.SolvablePuzzle,n::Integer,r::Integer,max::Integer)
    result = Array{SolvablePuzzle}(undef,0)
    if r < 1 || max < 1
        return result
    end
    # Gather a small volley of guesses from the single most unknown entry
    guesses = Sudoku.guess_solutions(puzzle)
    for guess in guesses
        if length(result) == max # Check for termination criteria
            break
        end
        try
            iterations, uncertainty = Sudoku.iterative_solve!(guess,n)
            if n > 0 && uncertainty == 0
                if Sudoku.valid_puzzle(Sudoku.as_values(guess))
                    push!(result,guess)
                end
            else # guaranteed above r > 0
                backtrack = backtrack_solve(guess,n,r-1,max-length(result))
                for b in backtrack
                    if Sudoku.valid_puzzle(Sudoku.as_values(b))
                        push!(result,b)
                    end
                    if length(result) == max # Check for termination criteria
                        break
                    end
                end
            end
        catch e
            # DomainErrors may occur with bad guesses
            if !isa(e,DomainError)
                throw(e)
            end
        end # try block
    end # loop over all guesses
    # Return whatever is found
    return result
end
