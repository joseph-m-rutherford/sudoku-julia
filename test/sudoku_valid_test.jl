# Copyright (c) 2021-2022, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.
#
# This file depends upon the Sudoku module being defined first.
using Test

function valid_subarray()
    @test Sudoku.valid_subarray(3,[1,2,3,4,5,6,7,8,9])
    @test Sudoku.valid_subarray(3,[1,2,3,7,8,9,4,5,6])
    @test !Sudoku.valid_subarray(3,[2,2,3,4,5,6,7,8,9])
end

function valid_puzzle_2()
    p = Sudoku.puzzle_n(2)
    @test Sudoku.valid_puzzle(p)
    p[1,1] = p[1,2] # invalidate puzzle
    @test !Sudoku.valid_puzzle(p)
end

function satisfies_puzzle_2()
    p = Sudoku.puzzle_n(2)
    s = similar(p)
    s .= p
    p[1,1] = 0
    @test Sudoku.satisfies(p,s)
    Sudoku.row_permute!(p,2,1,2)
    @test !Sudoku.satisfies(p,s)
end