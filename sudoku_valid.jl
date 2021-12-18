# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.

function valid_subarray(rank,test)
    if rank < 1 || Unsigned(rank) != rank
        throw(DomainError("Invalid rank"))
    end
    rank_squared = Unsigned(rank)*Unsigned(rank)
    if length(test) != rank_squared
        throw(DomainError("Array length mismatch to rank-squared"))
    end
    add_entries = sum(test) == sum(1:rank_squared)
    multiply_entries = prod(test) == factorial(rank_squared)
    return add_entries && multiply_entries
end

function valid_puzzle(puzzle)
    rank=Int16(sqrt(sqrt(length(puzzle))))
    if length(puzzle) != rank*rank*rank*rank
        throw(DimensionMismatch("Array length is not a square-of-a-square"))
    end
    rank_squared = rank*rank
    result = true
    # use logical AND throughout loops
    for rowcol = 1:rank_squared
        # check full row and col
        if result
            result = 
            valid_subarray(rank, puzzle[rowcol,:]) && 
            valid_subarray(rank, puzzle[:,rowcol])
        else
            break # don't bother checking more
        end
    end
    # Check rank x rank blocks
    for row_block = 1:rank
        if result
            start_row = rank*(row_block-1)+1
            stop_row = rank*(row_block-1)+rank
            for col_block = 1:rank
                if result
                    start_col = rank*(col_block-1)+1
                    stop_col = rank*(col_block-1)+rank
                    result = valid_subarray(rank, puzzle[start_row:stop_row,start_col:stop_col])
                else
                    break # don't bother checking more col blocks
                end
            end
        else
            break # don't bother checking more row or col blocks
        end
    end
    return result
end

using Test

function test_valid_subarray()
    @test valid_subarray(3,[1,2,3,4,5,6,7,8,9])
    @test valid_subarray(3,[1,2,3,7,8,9,4,5,6])
    @test !valid_subarray(3,[2,2,3,4,5,6,7,8,9])
end

function test_valid_puzzle_2()
    p = puzzle_n(2)
    @test valid_puzzle(p)
    p[1,1] = p[1,2] # invalidate puzzle
    @test !valid_puzzle(p)
end

@testset "Puzzle validity checks" begin
    test_valid_subarray()
    test_valid_puzzle_2()
end