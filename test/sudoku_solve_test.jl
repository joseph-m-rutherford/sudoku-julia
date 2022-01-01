# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.
#
# This file depends upon the Sudoku module being defined first.
using Test
using Random


function solve_random_puzzle()
    rng = MersenneTwister(123456)
    for i = 1:50
        solution, puzzle = Sudoku.random_puzzle(3,rng,1000,20)
        @test Sudoku.valid_puzzle(Sudoku.as_values(solution))
        iteration, uncertainty = Sudoku.solve_puzzle!(puzzle)
        @test iteration > 0
        @test uncertainty == 0
        @test Sudoku.valid_puzzle(Sudoku.as_values(puzzle))
        for j = 1:length(puzzle.grid)
            @test puzzle.grid[j].value == solution.grid[j].value
        end
    end
end
