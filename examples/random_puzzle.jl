# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.

include("../src/sudoku.jl") # Defines Sudoku module

# Form a random solution and puzzle pair
using Random
solution, puzzle = Sudoku.random_puzzle(3,MersenneTwister(12345),10000,45)

# Solve puzzle and report findings
print("\nUnsolved puzzle\n")
print(Sudoku.as_text_grid(puzzle))
iterations, uncertainty = Sudoku.solve_puzzle!(puzzle,2)
print("\n\nSolution after $iterations step(s)\n")
print(Sudoku.as_text_grid(puzzle))

if uncertainty != 0
    print("Failure: puzzle solution is incomplete\n")
else
    if Sudoku.as_values(puzzle) == Sudoku.as_values(solution)
        print("Success: solved puzzle matches expected solution\n")
    else
        print("Failure: solved puzzle does not match expected solution\n")
        print("Expected\n")
        print(Sudoku.as_text_grid(solution))
    end
end