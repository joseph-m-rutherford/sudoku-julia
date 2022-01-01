# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.
#
# This file depends upon sudoku_permute.jl to be included first.

using Test

function test_block_permutations()
    p_reference = Array{Int16}(undef,(4,4))
    #p_reference[:] = [1,2,3,4, 3,4,1,2, 2,3,4,1, 4,1,2,3][:]
    
    p = Sudoku.puzzle_n(2)
    #@test p == p_reference 
    
    Sudoku.row_block_permute!(p,1,2)
    p_reference[:] = [3,4,1,2, 1,2,3,4, 4,1,2,3, 2,3,4,1][:]
    @test p == p_reference

    Sudoku.col_block_permute!(p,1,2)
    p_reference[:] = [4,1,2,3, 2,3,4,1, 3,4,1,2, 1,2,3,4][:]
    @test p == p_reference
end

function test_intrablock_permutations()
    p_reference = Array{Int16}(undef,(4,4))
    #p_reference[:] = [1,2,3,4, 3,4,1,2, 2,3,4,1, 4,1,2,3][:]
    
    p = Sudoku.puzzle_n(2)
    #@test p == p_reference 
    
    Sudoku.row_permute!(p,1,2,1)
    p_reference[:] = [2,1,3,4, 4,3,1,2, 3,2,4,1, 1,4,2,3][:]
    @test p == p_reference

    Sudoku.col_permute!(p,2,1,2)
    p_reference[:] = [2,1,3,4, 4,3,1,2, 1,4,2,3, 3,2,4,1][:]
    @test p == p_reference
end

function test_mirroring()
    p_reference = Array{Int16}(undef,(4,4))
    #p_reference[:] = [1,2,3,4, 3,4,1,2, 2,3,4,1, 4,1,2,3][:]
    
    p = Sudoku.puzzle_n(2)
    #@test p == p_reference 
    
    Sudoku.mirror_horizontal!(p)
    p_reference[:] = [4,1,2,3, 2,3,4,1, 3,4,1,2, 1,2,3,4][:]
    @test p == p_reference

    Sudoku.mirror_vertical!(p)
    p_reference[:] = [3,2,1,4, 1,4,3,2, 2,1,4,3, 4,3,2,1][:]
    @test p == p_reference
end