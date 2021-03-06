# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.

include("../src/sudoku.jl") # Defines Sudoku module

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
puzzle = Sudoku.SolvablePuzzle(3)
Sudoku.assign_values!(puzzle,puzzle_values)
print("\nUnsolved puzzle\n")
print(Sudoku.as_text_grid(puzzle))
iterations, uncertainty = Sudoku.iterative_solve!(puzzle,1)
print("\n\nSolution after $iterations steps\n")
print(Sudoku.as_text_grid(puzzle))

# Solution image is CC BY-SA 3.0 (Attribution-ShareAlike) per
# https://en.wikipedia.org/wiki/Sudoku#/media/File:Sudoku_Puzzle_by_L2G-20050714_solution_standardized_layout.svg
#
# It is an exercise for reader to compare the calculated solution to the reference
if uncertainty != 0
    println("Failure: puzzle solution is incomplete")
else
    result_values = Sudoku.as_values(puzzle)
    if Sudoku.satisfies(puzzle_values,result_values)
        println("Verified that solution satisfies initial puzzle")
    else
        println("Solution does not match original puzzle inputs")
    end
    if Sudoku.valid_puzzle(result_values)
        println("Verified that solution satisfies Suduko rules")
    else
        println("Solution is not a valid Sudoku")
    end
end