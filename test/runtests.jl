# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.
#
# This file include the SudokuTester module's source code, runs the tests, and writes a report.

include("sudoku_tester.jl")

using Test

@testset verbose=true "Sudoku puzzle" begin

@testset "Common definitions" begin
    SudokuTester.puzzle_2()
    SudokuTester.puzzle_rank_array()
    SudokuTester.puzzle_3_entry()
    SudokuTester.solvable_puzzle_2_construction()
    SudokuTester.solvable_puzzle_2_modification()
    SudokuTester.solvable_puzzle_2_assignment()
end

@testset "Permutations helpers" begin
    SudokuTester.block_permutations()
    SudokuTester.intrablock_permutations()
    SudokuTester.mirroring()
end

@testset "Composition helpers" begin
    SudokuTester.symbol_swap()
    SudokuTester.random_puzzle()
end

@testset "Compostition statistics" begin
    SudokuTester.random_permutations(100000)
    SudokuTester.random_permutations(200000)
    SudokuTester.random_permutations(400000)
end

@testset "Validity checks" begin
    SudokuTester.valid_subarray()
    SudokuTester.valid_puzzle_2()
    SudokuTester.satisfies_puzzle_2()
end

@testset "Solution helpers" begin
    SudokuTester.solve_example_puzzles()
    SudokuTester.solve_random_puzzles()
end
    
end # end top-level testset
