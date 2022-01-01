# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.
# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.
#
# This file depends upon sudoku.jl and its Sudoku module
# This file imports all sudoku_*_test.jl scripts

module SudokuTester

include("sudoku.jl")

include("sudoku_common_test.jl")
include("sudoku_permute_test.jl")
include("sudoku_compose_test.jl")
include("sudoku_valid_test.jl")
include("sudoku_solve_test.jl")

using Test

@testset verbose=true "Sudoku puzzle" begin

@testset "Common definitions" begin
    test_puzzle_2()
    test_puzzle_rank_array()
    test_solvable_puzzle_2_construction()
    test_solvable_puzzle_2_modification()
    test_solvable_puzzle_2_assignment()
end

@testset "Permutations helpers" begin
    test_block_permutations()
    test_intrablock_permutations()
    test_mirroring()
end

@testset "Composition helpers" begin
    test_symbol_swap()
    test_random_puzzle()
end

@testset "Compostition statistics" begin
    test_random_permutations(100000)
    test_random_permutations(400000)
    test_random_permutations(1600000)
end

@testset "Validity checks" begin
    test_valid_subarray()
    test_valid_puzzle_2()
end

@testset "Solution helpers" begin
    test_solve_random_puzzle()
end
    
end # end top-level testset

end # end module