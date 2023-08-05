# Copyright (c) 2022, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.

include("../src/sudoku.jl") # Defines Sudoku module

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
println("Unsolved puzzle")
print(Sudoku.as_text_grid(puzzle))
# Backtrack solve using
#   * up to 8-fold compound rules to simplify backtracking
#   * up to 57 recursive steps (24 knowns)
#   * solution cap of 2 to detect a unique solution
results = Sudoku.backtrack_solve(puzzle,2,81-24,2)
if length(results) == 0
    println("Failure: puzzle solution is incomplete")
elseif length(results) == 1
    print("\nSolved puzzle\n")
    print(Sudoku.as_text_grid(results[1]))
    if Sudoku.valid_puzzle(Sudoku.as_values(results[1]))
        println("Verified that solution satisfies Suduko rules")
    else
        println("Solution is not a valid Sudoku")
    end
    if Sudoku.satisfies(Sudoku.as_values(puzzle),Sudoku.as_values(results[1]))
        println("Verified that solution matches original puzzle")
    else
        println("Failure: solution does not match the original puzzle")
    end
else
    println("Failure: puzzle solution has multiple solutions")
end