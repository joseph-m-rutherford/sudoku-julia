# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.
#
# This code depends upon sudoku_common.jl and sudoku_permute.jl

# Given a puzzle and a RNG, apply some permutation to the puzzle.
# Report the permutation as a variable-length sequence of integers.

function symbol_swap!(puzzle,value_1,value_2)
    rank = get_rank(puzzle)
    rank_squared = rank*rank
    p = BitVector(undef,rank_squared)

    for row = 1:rank_squared
        for col = 1:rank_squared
            p .= false
            if puzzle.grid[row,col].value == 0
                #Swap possible values
                p.chunks[1] = puzzle.grid[row,col].possibilities
                possible_value_1 = p[value_1]
                possible_value_2 = p[value_2]
                p[value_2] = possible_value_1
                p[value_1] = possible_value_2
                puzzle.grid[row,col].possibilities = p.chunks[1]
                
            elseif puzzle.grid[row,col].value == value_1
                # Swap value
                p[value_2] = true
                puzzle.grid[row,col] = PuzzleEntry(Int8(value_2),p)
            elseif puzzle.grid[row,col].value == value_2
                # Swap value
                p[value_1] = true
                puzzle.grid[row,col] = PuzzleEntry(Int8(value_1),p)
            end # end switch on symbol match
        end # end column loop
    end # end row loop
end

function random_permutation!(puzzle,rng)
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
            col_permute(puzzle.grid,block,sub_row_col_a,sub_row_col_b)
        else
            row_permute(puzzle.grid,block,sub_row_col_a,sub_row_col_b)
        end
        return [permutation_type,block,sub_row_col_a,sub_row_col_b]
    elseif permutation_type == 2 || permutation_type == 4
        source_block = rand(rng,1:rank)
        destination_block = 1 + ((source_block - 1 + rand(rng,1:(rank-1))) % rank)
        if permutation_type == 2
            col_block_permute(puzzle.grid,source_block,destination_block)
        else
            row_block_permute(puzzle.grid,source_block,destination_block)
        end
        return [permutation_type,source_block,destination_block]
    elseif permutation_type == 5
        mirror_horizontal(puzzle.grid)
        return [permutation_type]
    elseif permutation_type == 6
        mirror_vertical(puzzle.grid)
        return [permutation_type]
    elseif permutation_type == 7
        rank_squared = rank*rank
        symbol_1 = rand(rng,1:rank_squared)
        symbol_2 = 1 + ((symbol_1 - 1 + rand(rng,1:(rank_squared-1))) % rank_squared)
        symbol_swap!(puzzle,symbol_1,symbol_2)
        return [permutation_type,symbol_1,symbol_2]
    end
end

# Given a starting solution, an RNG, and a number of permutations, make new solution.
function random_solution(rank,rng,permutation_count)
    result = SolvablePuzzle(rank)
    for p = 1:permutation_count
       random_permutation!(result,rng)
    end
    if valid_puzzle(as_values(result))
        return result
    else
        throw(DomainError("Generated invalid puzzle"))
    end
end

function random_puzzle!(solution,rng,removals)
    rank = get_rank(solution)
    rank_squared = rank*rank
    for i = 1:removals
        row = rand(rng,1:rank_squared)
        col = rand(rng,1:rank_squared)
        while solution.grid[row,col].value == 0
            row = rand(rng,1:rank_squared)
            col = rand(rng,1:rank_squared)
        end
        set_unknown(solution,row,col)
    end
end
