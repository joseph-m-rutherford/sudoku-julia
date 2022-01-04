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

"""
    puzzle_n(rank)

Given 2 <= rank <= 15, return a Sudoku integer array sized rank*rank.
"""
function puzzle_n(rank::Integer)
    if (rank < 2) || (rank > 15)
        throw(DomainError("Invalid puzzle rank outside [2,15]"))
    end
    rank_squared = rank*rank
    result = Array{UInt8}(undef,(rank_squared,rank_squared))
    for col = 1:rank_squared
        col_shift = UInt8(floor((col-1)/rank))
        for row = 1:rank_squared
            result[row,col] = ( (rank*(col-1) + (row-1)) + col_shift) % rank_squared + 1
        end
    end
    return result
end

"""
A maybe-unknown Sudoku value with possible values tracked.

If value > 0, the entry is known and 1<= value <= rank-squared.
If value == 0, the the entry is unknown, and possible values indices into a bit vector for which true is assigned.
"""
struct PuzzleEntry
    value::UInt8 # 0 indicates unknown, literal value otherwise
    possibilities::UInt16 # Bitmask index = 1 iff index is allowed
    
    """
    Define entry with a value and a BitVector of possibilities.
    """
    function PuzzleEntry(value::Integer,possibilities::BitVector)
        rank = 0
        rank_squared = length(possibilities)
        if rank_squared == 4
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

"""
A square grid of PuzzleEntry instances.

See also [`random_puzzle`](@ref), [`solve_puzzle!`](@ref).
"""
struct SolvablePuzzle
    grid::Array{PuzzleEntry}
    """
    
    """
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

"""
Assign a grid of integers into a SolvablePuzzle.

    assign_values!(puzzle,new_values)

# Arguments
- puzzle::SolvablePuzzle: grid of Sudoku values to set.
- new_values::Array: input integers of same shape as SolvablePuzzle.grid

Zero values are set as unknowns.
"""
function assign_values!(puzzle::SolvablePuzzle,new_values::Array)
    if size(puzzle.grid) != size(new_values)
        throw(DomainError("Mismatched shape of new values for puzzle"))
    end
    rank_squared = size(new_values)[1]
    for row = 1:rank_squared
        for col = 1:rank_squared
            value = new_values[row,col]
            if value < 0 || value > rank_squared
                throw(DomainError("Invalid new value; must be in [0 (unknown), rank-squared]"))
            elseif new_values[row,col] == 0
                # Unknown value
                set_unknown(puzzle,row,col)
            else
                v = UInt8(value)
                p = BitVector(undef,rank_squared)
                p .= false
                p[v] = true
                puzzle.grid[row,col] = PuzzleEntry(v,p)
            end
        end
    end
end
            
"""
Return a Sudoku rank from the shape of a 2D aray.

    get_rank(puzzle)
"""
function get_rank(puzzle::Array)
    grid_shape = size(puzzle)
    if grid_shape == (4,4) || grid_shape == (16,)
        return 2
    elseif grid_shape == (9,9) || grid_shape == (81,)
        return 3
    elseif grid_shape == (16,16) || grid_shape == (256,)
        return 4
    else
        throw(DimensionMismatch("Puzzles must of shape (rank*rank,rank*rank), 1 < rank < 5"))
    end
end

"""
Return a Sudoku rank from a SolvablePuzzle..

    get_rank(puzzle)
"""
function get_rank(puzzle::SolvablePuzzle)
    return get_rank(puzzle.grid)
end

"""
Assign a position in the grid of a SolvablePuzzle to known.

    set_unknown(puzzle,row,col)
"""
function set_unknown(puzzle::SolvablePuzzle,row::Integer,col::Integer)
    rank = get_rank(puzzle)
    rank_squared = rank*rank
    p = BitVector(undef,rank_squared)
    p .= true
    puzzle.grid[row,col] = PuzzleEntry(0,p)
    return nothing
end

"""
Return the contents of the puzzle as a grid of strings.

    as_text(puzzle)

Known values are integers greater than 0.
Unknown values are 0.
"""
function as_text(puzzle::SolvablePuzzle)
    result = fill(" ",size(puzzle.grid)) # unknowns!
    for i = 1:length(puzzle.grid)
        if puzzle.grid[i].value != 0 # fill in the knowns
            result[i] = string(puzzle.grid[i].value)
        end
    end
    return result
end

"""
Return the contents of the puzzle as a grid of integers.

    as_values(puzzle)

Known values are integers greater than 0.
Unknown values are 0.
"""
function as_values(puzzle::SolvablePuzzle)
    result = Array{UInt8}(undef, size(puzzle.grid)) # invalid data
    for i = 1:length(puzzle.grid)
        result[i] = puzzle.grid[i].value
    end
    return result
end

"""
Return the contents of the puzzle as a grid of integers representing possible values.

    as_possibilities(puzzle)

Known values are have one value set to true at that values index.
Unknown values are have more than one bit set to true.
"""
function as_possibilities(puzzle::SolvablePuzzle)
    result = Array{UInt16}(undef, size(puzzle.grid)) # invalid data
    for i = 1:length(puzzle.grid)
        result[i] = puzzle.grid[i].possibilities
    end
    return result        
end

"""
Assess the degree of uncertainty in a SolvablePuzzle.

    uncertainty(puzzle)

Zero uncertainty is associated with solved puzzles.
Unsolved puzzles have uncertainty greater than zero.
"""
function uncertainty(puzzle::SolvablePuzzle)
    result::UInt64 = 0
    rank = get_rank(puzzle.grid)
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
