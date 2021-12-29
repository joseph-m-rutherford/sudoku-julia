# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.
#
# This code depends upon sudoku_common.jl and sudoku_permute.jl

function random_permutation!(puzzle,rng)
    rank = Sudoku.get_rank(puzzle)
    # Symbols to select permutation type
    #undefined = 0 # less than a valid choice
    #column = 1
    #block_column = 2
    #row = 3
    #block_row = 4
    #mirror_horizontal = 5
    #mirror_vertical = 6
    #error = 7 # greater than a valid choice
    permutation_type = rand(rng,1:6)
    if permutation_type == 1 || permutation_type == 3
        block = rand(rng,1:rank)
        sub_row_col_a = rand(rng,1:rank)
        sub_row_col_b = 1 + ((sub_row_col_a - 1 + rand(rng,1:(rank-1))) % rank)
        
        if permutation_type == 1
            Sudoku.col_permute(puzzle.grid,block,sub_row_col_a,sub_row_col_b)
        else
            Sudoku.row_permute(puzzle.grid,block,sub_row_col_a,sub_row_col_b)
        end
        return [permutation_type,block,sub_row_col_a,sub_row_col_b]
    elseif permutation_type == 2 || permutation_type == 4
        source_block = rand(rng,1:rank)
        destination_block = 1 + ((source_block - 1 + rand(rng,1:(rank-1))) % rank)
        if permutation_type == 2
            Sudoku.col_block_permute(puzzle.grid,source_block,destination_block)
        else
            Sudoku.row_block_permute(puzzle.grid,source_block,destination_block)
        end
        return [permutation_type,source_block,destination_block]
    elseif permutation_type == 5
        Sudoku.mirror_horizontal(puzzle.grid)
        return [permutation_type]
    elseif permutation_type == 6
        Sudoku.mirror_vertical(puzzle.grid)
        return [permutation_type]
    end
end

function random_solution(rank,rng,permutation_count)
    result = SolvablePuzzle(rank)
    for p = 1:permutation_count
       permutation = random_permutation!(result,rng)
    end
    return result
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
