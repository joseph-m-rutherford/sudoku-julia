# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.
#
# This file include the SudokuTester module's source code, runs the tests, and writes a report.

include("sudoku_tester.jl")

using Test

@testset verbose=true "Sudoku puzzle" begin

@testset "Composition helpers" begin
    SudokuTester.random_puzzle()
end

#@testset "Solution helpers" begin
#    SudokuTester.solve_random_puzzle()
#    SudokuTester.backtrack_solve_puzzle()
#end
    
end # end top-level testset
