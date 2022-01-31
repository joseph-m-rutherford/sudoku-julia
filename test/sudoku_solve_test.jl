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
        solution, puzzle = Sudoku.random_puzzle(3,rng,1000,25)
        @test Sudoku.valid_puzzle(Sudoku.as_values(solution))
        # Exclusively rules-based solution
        puzzle1 = deepcopy(puzzle)
        iteration, uncertainty = Sudoku.solve_puzzle!(puzzle1,1)
        @test iteration > 0
        @test uncertainty == 0
        @test Sudoku.valid_puzzle(Sudoku.as_values(puzzle1))
        for j = 1:length(puzzle1.grid)
            @test Sudoku.get_value(puzzle1.grid[j]) == Sudoku.get_value(solution.grid[j])
        end
        # Repeat using exclusively rules-evaluation in backtrack
        puzzle2 = deepcopy(puzzle)
        result_puzzle2 = Sudoku.backtrack_solve(puzzle2,1,1,2)
        @test length(result_puzzle2) == 1
        @test Sudoku.valid_puzzle(Sudoku.as_values(result_puzzle2[1]))
        for j = 1:length(result_puzzle2[1].grid)
            @test Sudoku.get_value(result_puzzle2[1].grid[j]) == Sudoku.get_value(solution.grid[j])
        end
        # Repeat using logic and not actually backtracking
        result_puzzle3 = Sudoku.backtrack_solve(puzzle2,1,2,2)
        @test length(result_puzzle3) == 1
        @test Sudoku.valid_puzzle(Sudoku.as_values(result_puzzle3[1]))
        for j = 1:length(result_puzzle3[1].grid)
            @test Sudoku.get_value(result_puzzle3[1].grid[j]) == Sudoku.get_value(solution.grid[j])
        end
    end
end


function solve_puzzle()
    # Puzzle example from
    # https://en.wikipedia.org/wiki/Sudoku accessed 1/1/2022
    # Puzzle image license is CC0 (Public Domain Dedication) per
    # https://en.wikipedia.org/wiki/Sudoku#/media/File:Sudoku_Puzzle_by_L2G-20050714_standardized_layout.svg
    puzzle_values = [
        5 3 0 0 7 0 0 0 0;
        6 0 0 1 9 5 0 0 0;
        0 9 8 0 0 0 0 6 0;
        8 0 0 0 6 0 0 0 3;
        4 0 0 8 0 3 0 0 1;
        7 0 0 0 2 0 0 0 6;
        0 6 0 0 0 0 2 8 0;
        0 0 0 4 1 9 0 0 5;
        0 0 0 0 8 0 0 7 9]
    puzzle1 = Sudoku.SolvablePuzzle(3)
    Sudoku.assign_values!(puzzle1,puzzle_values)
    iterations, uncertainty = Sudoku.solve_puzzle!(puzzle1,2)
    @test uncertainty == 0
    @test Sudoku.satisfies(puzzle_values,Sudoku.as_values(puzzle1))
    @test Sudoku.valid_puzzle(Sudoku.as_values(puzzle1))
    
    # Repeat w/ simple backtracking
    puzzle2 = Sudoku.SolvablePuzzle(3)
    Sudoku.assign_values!(puzzle2,puzzle_values)
    results = Sudoku.backtrack_solve(puzzle2,8,81,2)
    @test length(results) == 1
    @test Sudoku.satisfies(puzzle_values,Sudoku.as_values(results[1]))
    @test Sudoku.valid_puzzle(Sudoku.as_values(results[1]))
    @test Sudoku.as_values(results[1]) == Sudoku.as_values(puzzle1)
    

    # Puzzle example from
    # https://sourceforge.net/projects/winsudoku/ accessed Jan 30, 2022
    # Example taken from BSD-licensed project
    puzzle_values = [
        0 2 1 0 6 0 0 0 8;
        8 0 0 0 0 0 7 5 0;
        0 0 0 0 0 1 0 0 0;
        0 0 4 9 0 3 0 0 0;
        9 0 0 1 0 0 0 3 0;
        1 0 0 0 0 8 0 0 0;
        0 0 0 0 0 0 5 0 0;
        0 7 0 0 0 9 0 0 6;
        0 8 3 7 0 0 1 0 4]
    puzzle = Sudoku.SolvablePuzzle(3)
    Sudoku.assign_values!(puzzle,puzzle_values)
    # Backtrack solve using
    #   * up to 8-fold compound rules to simplify backtracking
    #   * up to 57 recursive steps (24 knowns)
    #   * solution cap of 2 to detect a unique solution
    results = Sudoku.backtrack_solve(puzzle,8,81-24,2)
    @test length(results) == 1
    if length(results) == 1
        @test Sudoku.valid_puzzle(Sudoku.as_values(results[1]))
        @test Sudoku.satisfies(Sudoku.as_values(puzzle),Sudoku.as_values(results[1]))    
    end
end


