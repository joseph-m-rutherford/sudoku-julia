# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.
#
# This file depends upon sudoku_common.jl to be included first.

"""
    valid_subarray(rank,test)

Traverse an length rank*rank array of integers to report valid symbols 1:rank*rank.
Rank is required here because we could be getting Vector or Matrix arguments.
"""
function valid_subarray(rank::Integer,test::Array)
    if rank < 1 || Unsigned(rank) != rank
        throw(DomainError("Invalid rank"))
    end
    rank_squared = Unsigned(rank)*Unsigned(rank)
    if length(test) != rank_squared
        throw(DomainError("Array length mismatch to rank-squared"))
    end
    add_entries = Unsigned(sum(test)) == sum(1:rank_squared)
    multiply_entries = prod(test) == factorial(rank_squared)
    return add_entries && multiply_entries
end


"""
    valid_puzzle(puzzle)

Confirm that every row, column, and block of entries in 1:rank*rank.
"""
function valid_puzzle(puzzle::Matrix)
    rank=get_rank(puzzle)
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

"""
   satisfies(puzzle,solution)

Verify that a valid solution is a candidate for the puzzle.
"""
function satisfies(puzzle::Matrix,solution::Matrix)
    if size(solution) != size(puzzle)
        throw(DomainError("Solution cannot be checked against a different size puzzle"))
    end
    if !(valid_puzzle(solution))
        throw(DomainError("Invalid solution cannot be checked against a puzzle"))
    end
    satisfies = true
    for i = 1:length(puzzle)
        if puzzle[i] == 0
            continue
        elseif puzzle[i] != solution[i]
            satisfies = false
            break
        end
    end
    return satisfies
end