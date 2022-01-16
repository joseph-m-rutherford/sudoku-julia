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

"""
    guess_solutions(puzzle)

Return a vector of single-entry guesses for the unknowns.
Array length must equal the numerical uncertainty of the puzzle.
Each guessed new puzzle may be attempted for further solution.
If valid after solution, the guess must satisfy puzzle.
"""
function guess_solutions(puzzle::Sudoku.SolvablePuzzle)
    initial_uncertainty = Sudoku.uncertainty(puzzle)
    # For each possible value, 
    #    1. instantiate a puzzle with that value set
    #    2. try to solve the rest of the puzzle
    #    3. if uncertain, repeat
    running_uncertainty::Integer = 0
    result = Array{Sudoku.SolvablePuzzle}(undef,initial_uncertainty)
    rank = Sudoku.get_rank(puzzle.grid)
    rank_squared = rank*rank
    for i = 1:length(puzzle.grid)
        entry = BitVector(undef,rank_squared)
        entry.chunks[1] = puzzle.grid[i].possibilities # Convert int to BitVector
        possibility_count = sum(entry)
        if possibility_count > 1 # This is an unknown
            for j = 1:rank_squared
                if entry[j]
                    guess_entry = BitVector(undef,rank_squared)
                    guess_entry .= false
                    guess_entry[j] = true
                    # Push the guess into the work queue
                    running_uncertainty += 1
                    result[running_uncertainty] = Sudoku.SolvablePuzzle(rank)
                    result[running_uncertainty].grid .= puzzle.grid
                    result[running_uncertainty].grid[i] = Sudoku.PuzzleEntry(guess_entry)
                end
            end # finalize guess loop
        end # branch for evaluating an unknown
    end # loop over all entries in guess
    if running_uncertainty != initial_uncertainty
        throw(ErrorException("Guessing solutions did not correctly traverse the uncertainty"))
    end
    return result
end

"""
    backtrack_solve(puzzle,n,r)

Attempt solution by guessing an instance of all unknown values.
Solutions with compound rule size n are evaluated.
Indeterminate solutions are recursed up to the given limit r.
"""
function backtrack_solve(puzzle::Sudoku.SolvablePuzzle,n::Integer,r::Integer)
    guesses = Sudoku.guess_solutions(puzzle)
    valid_guesses = Set{Integer}([])
    for i = 1:length(guesses)
        try
            iterations, uncertainty = Sudoku.solve_puzzle!(guesses[i],n)
            if uncertainty != 0 && r > 0
                backtrack = backtrack_solve(guesses[i],n,r-1)
                if length(backtrack) > 1
                    throw(ErrorException("Backtracking recursion found multiple solutions"))
                elseif length(backtrack) == 1
                    guesses[i].grid .= backtrack[1].grid
                end
                # If backtrack returned a zero-length array, guesses[i] is invalid
            end
            if Sudoku.valid_puzzle(Sudoku.as_values(guesses[i]))
                valid_guesses = union(valid_guesses,[i])
            end
        catch e
            # DomainErrors may occur with bad guesses
            if !isa(e,DomainError)
                throw(e)
            end
        end # try blcok
    end # loop over all guesses
    result = Array{Sudoku.SolvablePuzzle}(undef,length(valid_guesses))
    # If any guesses are valid solutions, they should all be equal.
    if length(valid_guesses) > 0
        valid_guesses_begin, iter_state = iterate(valid_guesses)
        iterator = iterate(valid_guesses,iter_state)
        all_match = true # using Boolean AND in loop
        while iterator !== nothing
            value, iter_state = iterator
            if Sudoku.as_values(guesses[valid_guesses_begin]) != Sudoku.as_values(guesses[value])
                all_match = false
            end
            iterator = iterate(valid_guesses,iter_state)
        end
        # If we confirm a perfect match, return the result
        if all_match
            result = Array{Sudoku.SolvablePuzzle}(undef,(1,))
            result[1] = Sudoku.SolvablePuzzle(Sudoku.get_rank(puzzle))
            result[1].grid .= guesses[valid_guesses_begin].grid
        else
            throw(ErrorException("Backtracking identified multiple disparate solutions"))
        end
    end
    return result
end