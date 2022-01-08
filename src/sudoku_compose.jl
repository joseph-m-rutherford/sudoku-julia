# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.
#
# This code depends upon sudoku_common.jl and sudoku_permute.jl

using Random

"""
    symbol_swap!(puzzle,value_1,value_2)

Within a SolvablePuzzle interchange the roles of two integers.
"""
function symbol_swap!(puzzle::SolvablePuzzle,value_1::Integer,value_2::Integer)
    rank = get_rank(puzzle)
    rank_squared = rank*rank
    p = BitVector(undef,rank_squared) # reused in loop

    for row = 1:rank_squared
        for col = 1:rank_squared
            p .= false
            # Swap possible value roles
            p.chunks[1] = puzzle.grid[row,col].possibilities
            possible_value_1 = p[value_1]
            possible_value_2 = p[value_2]
            # Change the contents if the bits are different
            if possible_value_1 != possible_value_2
                p[value_2] = possible_value_1
                p[value_1] = possible_value_2
                reported_value = get_value(puzzle.grid[row,col])
                puzzle.grid[row,col] = PuzzleEntry(reported_value,p)
            end # end switch on required change
        end # end column loop
    end # end row loop
end

"""
    random_permutation!(puzzle,rng)

Apply a random permutation to a SolvablePuzzle and return the permutation.

Permutation is reported as a variable-length sequence of integers.
"""
function random_permutation!(puzzle::SolvablePuzzle,rng::AbstractRNG)
    rank = get_rank(puzzle)
    # Symbols to select permutation type
    #undefined = 0 # less than a valid choice
    #column = 1
    #block_column = 2
    #row = 3
    #block_row = 4
    #mirror_horizontal = 5
    #mirror_vertical = 6
    #symbol_swap = 7
    #error = 8 # greater than a valid choice
    permutation_type = rand(rng,1:7)
    if permutation_type == 1 || permutation_type == 3
        block = rand(rng,1:rank)
        sub_row_col_a = rand(rng,1:rank)
        sub_row_col_b = 1 + ((sub_row_col_a - 1 + rand(rng,1:(rank-1))) % rank)
        if permutation_type == 1
            col_permute!(puzzle.grid,block,sub_row_col_a,sub_row_col_b)
        else
            row_permute!(puzzle.grid,block,sub_row_col_a,sub_row_col_b)
        end
        return [permutation_type,block,sub_row_col_a,sub_row_col_b]
    elseif permutation_type == 2 || permutation_type == 4
        source_block = rand(rng,1:rank)
        destination_block = 1 + ((source_block - 1 + rand(rng,1:(rank-1))) % rank)
        if permutation_type == 2
            col_block_permute!(puzzle.grid,source_block,destination_block)
        else
            row_block_permute!(puzzle.grid,source_block,destination_block)
        end
        return [permutation_type,source_block,destination_block]
    elseif permutation_type == 5
        mirror_horizontal!(puzzle.grid)
        return [permutation_type]
    elseif permutation_type == 6
        mirror_vertical!(puzzle.grid)
        return [permutation_type]
    elseif permutation_type == 7
        rank_squared = rank*rank
        symbol_1 = rand(rng,1:rank_squared)
        symbol_2 = 1 + ((symbol_1 - 1 + rand(rng,1:(rank_squared-1))) % rank_squared)
        symbol_swap!(puzzle,symbol_1,symbol_2)
        return [permutation_type,symbol_1,symbol_2]
    end
end

"""
    random_solution(rank,rng,permutation_count)

Given a rank, an RNG, and a number of permutations, make new solution.
"""
function random_solution(rank::Integer,rng::AbstractRNG,permutation_count::Integer)
    result = SolvablePuzzle(rank)
    for p = 1:permutation_count
       random_permutation!(result,rng)
    end
    return result
end

"""
    random_puzzle(rank,rng,permutation_count,removals)

Construct a randomized solution, puzzle pair.
"""
function random_puzzle(rank::Integer,rng::AbstractRNG,permutation_count::Integer,removals::Integer)
    rank_squared = rank*rank
    if removals > rank_squared*rank_squared
        throw(DomainError("Cannot remove more entries than rank dictates"))
    elseif rank_squared*rank_squared - removals <= 3*rank_squared
        print("WARNING: high number of removals requested for rank")
    end
    solution = random_solution(rank,rng,permutation_count)
    puzzle = deepcopy(solution)
    for i = 1:removals
        # Randomly grab rows and columns to remove    
        row = rand(rng,1:rank_squared)
        col = rand(rng,1:rank_squared)
        # If we hit a duplicate removal, jump around until we find an intact entry
        while get_value(puzzle.grid[row,col]) == 0
            row = rand(rng,1:rank_squared)
            col = rand(rng,1:rank_squared)
        end
        set_unknown(puzzle,row,col)
    end
    return [solution,puzzle]
end
