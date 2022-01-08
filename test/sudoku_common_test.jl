# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.
#
# This file depends upon the Sudoku module being defined first.

using Test

function puzzle_2()
    puzzle_2_reference = Array{Int16}(undef,(4,4))
    puzzle_2_reference[:] = [1,2,3,4, 3,4,1,2, 2,3,4,1, 4,1,2,3][:]
    @test Sudoku.puzzle_n(2) == puzzle_2_reference
end

function puzzle_rank_array()
    @test Sudoku.get_rank(Sudoku.puzzle_n(2)) == 2
    @test Sudoku.get_rank(Sudoku.puzzle_n(3)) == 3
    @test Sudoku.get_rank(Sudoku.puzzle_n(4)) == 4
end

function puzzle_3_entry()
    rank = 3
    rank_squared = rank*rank
    test_possibilities = BitVector(undef,rank_squared)
    test_possibilities .= true
    test_entry = Sudoku.PuzzleEntry(0,test_possibilities)
    @test Sudoku.get_value(test_entry) == 0
    for i = 1:rank_squared
        test_possibilities .= false
        test_possibilities[i] = true
        test_entry = Sudoku.PuzzleEntry(i,test_possibilities)
        @test Sudoku.get_value(test_entry) == i
    end
end

function solvable_puzzle_2_construction()
    puzzle_2_reference = Array{Int16}(undef,(4,4))
    puzzle_2_reference[:] = [1,2,3,4, 3,4,1,2, 2,3,4,1, 4,1,2,3][:]
    p2 = Sudoku.SolvablePuzzle(2)
    @test length(p2.grid) == 16
    for i = 1:16
        @test Sudoku.get_value(p2.grid[i]) == puzzle_2_reference[i]
        @test p2.grid[i].possibilities == (0x1 << (puzzle_2_reference[i]-1))
    end

    # Verify text conversion
    puzzle_2_reference_text = Array{String}(undef,(4,4))
    puzzle_2_reference_text[:] = ["1","2","3","4", "3","4","1","2", "2","3","4","1", "4","1","2","3"][:]
    @test Sudoku.as_text(p2) == puzzle_2_reference_text

    # Verify zero uncertainty
    @test Sudoku.uncertainty(p2) == 0
end

function solvable_puzzle_2_modification()
    puzzle_2_reference = Array{Int8}(undef,(4,4))
    puzzle_2_reference[:] = [0,2,3,4, 3,0,1,2, 2,3,0,1, 4,1,2,0][:]
    p2 = Sudoku.SolvablePuzzle(Int8(2))
    # Make the diagonal unknowns
    for i = 1:4
        Sudoku.set_unknown(p2,i,i)
    end
    
    for i = 1:4
        for j = 1:4
            @test Sudoku.get_value(p2.grid[i,j]) == puzzle_2_reference[i,j]
            if i == j
                @test p2.grid[i,j].possibilities == 0xf
            else
                @test p2.grid[i,j].possibilities == 0x1 << (puzzle_2_reference[i,j]-1)
            end
        end
    end

    # Verify value extraction
    puzzle_2_reference_values = Array{UInt8}(undef,(4,4))
    puzzle_2_reference_values[:] = [0,2,3,4, 3,0,1,2, 2,3,0,1, 4,1,2,0][:]
    @test Sudoku.as_values(p2) == puzzle_2_reference_values
    
    # Verify possibility extraction
    puzzle_2_reference_possibilities = Array{UInt16}(undef,(4,4))
    puzzle_2_reference_possibilities[:] = [0xf,0x2,0x4,0x8, 0x4,0xf,0x1,0x2, 0x2,0x4,0xf,0x1, 0x8,0x1,0x2,0xf][:]
    @test Sudoku.as_possibilities(p2) == puzzle_2_reference_possibilities
    
    # Verify text conversion
    puzzle_2_reference_text = Array{String}(undef,(4,4))
    puzzle_2_reference_text[:] = [" ","2","3","4", "3"," ","1","2", "2","3"," ","1", "4","1","2"," "][:]
    @test Sudoku.as_text(p2) == puzzle_2_reference_text
    
    # Verify 4 totally unknown entries
    @test Sudoku.uncertainty(p2) == 16
end

function solvable_puzzle_2_assignment()
    puzzle_2_reference = Array{Int16}(undef,(4,4))
    puzzle_2_reference[:] = [1,2,0,3, 0,3,1,2, 2,0,3,1, 3,1,2,0][:]
    p2 = Sudoku.SolvablePuzzle(2)
    Sudoku.assign_values!(p2,puzzle_2_reference)
    @test length(p2.grid) == 16
    for i = 1:16
        @test Sudoku.get_value(p2.grid[i]) == puzzle_2_reference[i]
        if puzzle_2_reference[i] == 0
            @test p2.grid[i].possibilities == 0xf
        else
            @test p2.grid[i].possibilities == (0x1 << (puzzle_2_reference[i]-1))
        end
    end
end
