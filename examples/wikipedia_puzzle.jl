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
iterations, uncertainty = Sudoku.solve_puzzle!(puzzle)
print("\n\nSolution after $iterations steps\n")
print(Sudoku.as_text_grid(puzzle))

# Solution image is CC BY-SA 3.0 (Attribution-ShareAlike) per
# https://en.wikipedia.org/wiki/Sudoku#/media/File:Sudoku_Puzzle_by_L2G-20050714_solution_standardized_layout.svg
#
# It is an exercise for reader to compare the calculated solution to the reference
if uncertainty != 0
    print("Failure: puzzle solution is incomplete\n")
else
    if Sudoku.valid_puzzle(Sudoku.as_values(puzzle))
        print("Verified that solution satisfies Suduko rules\n")
    else
        print("Solution is not a valid Sudoku\n")
    end
end