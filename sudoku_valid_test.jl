# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.
#
# Thsi file depends upon sudoku_valid.jl to be included first.
using Test

function test_valid_subarray()
    @test Sudoku.valid_subarray(3,[1,2,3,4,5,6,7,8,9])
    @test Sudoku.valid_subarray(3,[1,2,3,7,8,9,4,5,6])
    @test !Sudoku.valid_subarray(3,[2,2,3,4,5,6,7,8,9])
end

function test_valid_puzzle_2()
    p = Sudoku.puzzle_n(2)
    @test Sudoku.valid_puzzle(p)
    p[1,1] = p[1,2] # invalidate puzzle
    @test !Sudoku.valid_puzzle(p)
end

@testset "Puzzle validity checks" begin
    test_valid_subarray()
    test_valid_puzzle_2()
end