# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.
# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.
#
# This file does not have any dependencies upon other scripts

# Construct a puzzle as integers
function puzzle_n(rank)
    rank_squared = rank*rank
    result = Array{Int16}(undef,(rank_squared,rank_squared))
    for col = 1:rank_squared
        col_shift = Int16(floor((col-1)/rank))
        for row = 1:rank_squared
            result[row,col] = ( (rank*(col-1) + (row-1)) + col_shift) % rank_squared + 1
        end
    end
    return result
end

# PuzzleEntry has two states: known (value > 0) or unknown (value == 0)
# If it is known, the value is <= rank-squared.
# If it is unknown, the possibilities are a bitmask of possible values by index.
struct PuzzleEntry
    value::UInt8 # 0 indicates unknown, literal value otherwise
    possibilities::UInt16 # Bitmask index = 1 iff index is allowed
    
    # Define entry with a value and a BitVector of possibilities
    function PuzzleEntry(value,possibilities)
        rank = 0
        rank_squared = length(possibilities)
        if rank_squared == 1
            rank = 1
        elseif rank_squared == 4
            rank = 2
        elseif rank_squared == 9
            rank = 3
        elseif rank_squared == 16
            rank = 4
        else
            throw(DomainError("Possibilities vector length invalid"))
        end
        
        # Cross check value and possibilites
        if value > rank_squared
            throw(DomainError("Value > rank squared"))
        elseif value == 0
            if sum(possibilities) == 1
                throw(DomainError("Undetermined value cannot have single possibility"))
            end
        else
            if sum(possibilities) != 1
                throw(DomainError("Valid value must have single possibility"))
            end
        end
        new(value,possibilities.chunks[1]) # Use local new method
    end
end

struct SolvablePuzzle
    grid::Array{PuzzleEntry}
    
    function SolvablePuzzle(rank)
        solved_puzzle = puzzle_n(rank)
        puzzle = Array{PuzzleEntry}(undef,size(solved_puzzle))
        rank_squared = rank*rank
        for i = 1:length(solved_puzzle)
            v = UInt8(solved_puzzle[i])
            p = BitVector(undef,rank_squared)
            p .= false
            p[v] = true
            puzzle[i] = PuzzleEntry(v,p)
        end
        return new(puzzle)
    end
end

function get_rank(puzzle::SolvablePuzzle)
    rank=Int16(sqrt(sqrt(length(puzzle.grid))))
    if length(puzzle.grid) != rank*rank*rank*rank
        throw(DimensionMismatch("Array length is not a square-of-a-square")) 
    end
    return rank
end

function set_unknown(puzzle::SolvablePuzzle,row,col)
    rank = get_rank(puzzle)
    rank_squared = rank*rank
    p = BitVector(undef,rank_squared)
    p .= true
    puzzle.grid[row,col] = PuzzleEntry(0,p)
end

function as_text(puzzle::SolvablePuzzle)
    result = fill(" ",size(puzzle.grid)) # unknowns!
    for i = 1:length(puzzle.grid)
        if puzzle.grid[i].value != 0 # fill in the knowns
            result[i] = string(puzzle.grid[i].value)
        end
    end
    return result        
end

function as_values(puzzle::SolvablePuzzle)
    result = Array{UInt8}(undef, size(puzzle.grid)) # invalid data
    for i = 1:length(puzzle.grid)
        result[i] = puzzle.grid[i].value
    end
    return result
end

function as_possibilities(puzzle::SolvablePuzzle)
    result = Array{UInt16}(undef, size(puzzle.grid)) # invalid data
    for i = 1:length(puzzle.grid)
        result[i] = puzzle.grid[i].possibilities
    end
    return result        
end

function uncertainty(puzzle::SolvablePuzzle)
    result::UInt = 0
    rank = get_rank(puzzle)
    rank_squared = rank*rank
    for i = 1:length(puzzle.grid)
        if puzzle.grid[i].value == 0
            temp = BitVector(undef,rank_squared)
            temp.chunks[1] = puzzle.grid[i].possibilities # Convert int to BitVector
            result += sum(temp)
        end
    end
    return result
end