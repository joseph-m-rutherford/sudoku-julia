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
    result = Array{Integer}(undef,(rank_squared,rank_squared))
    for col = 1:rank_squared
        col_shift = Integer(floor((col-1)/rank))
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
    possibilities::UInt16 # Bitmask index = 1 iff index is allowed
    
    """
    Define entry with a value and a BitVector of possibilities.
    """
    function PuzzleEntry(possibilities::BitVector)
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
        new(UInt16(possibilities.chunks[1])) # Use local new method
    end
end

"""
    make_entry(rank_squared,value)

Given a squared-rank > 3 and < 17, create a new PuzzleEntry.
A value of 0 is completely unknown.
A value in 1:rank_squared is completely known.
"""
function make_entry(rank_squared::Integer, value::Integer)
    if !(rank_squared in [4,9,16])
        throw(DomainError("Cannot instantiate an entry for rank < 2 or > 4"))
    end
    if value < 0 || value > rank_squared
        throw(DomainError("Cannot instantiate an entry from an value < 0 or > rank*rank"))
    end
    possibilities = BitVector(undef,rank_squared)
    if value == 0
        possibilities .= true
    else
        possibilities .= false
        possibilities[value] = true
    end
    return PuzzleEntry(possibilities)
end

function get_value(entry::PuzzleEntry)
    temp = BitVector(undef,16) # Driven by storage as Int16
    temp.chunks[1] = entry.possibilities # Convert int to BitVector
    possible_count = 0 # Number of possibilities found
    result = 0 # Default to unknown
    for i in 1:length(temp)
        if temp[i]
            possible_count += 1
            result = i
        end
    end
    if possible_count != 1
        result = 0
    end
    return result
end

"""
A square grid of PuzzleEntry instances.

See also [`random_puzzle`](@ref), [`solve_puzzle!`](@ref).
"""
struct SolvablePuzzle
    grid::Array{PuzzleEntry}
    """
    
    """
    function SolvablePuzzle(rank::Integer)
        solved_puzzle = puzzle_n(rank)
        puzzle = Array{PuzzleEntry}(undef,size(solved_puzzle))
        rank_squared = rank*rank
        for i = 1:length(solved_puzzle)
            v = Integer(solved_puzzle[i])
            puzzle[i] = make_entry(rank_squared,v)
        end
        return new(puzzle)
    end
end

"""
    assign_values!(puzzle,new_values)

Assign a grid of integers into a SolvablePuzzle.
Zero values are set as unknowns.

# Arguments
- puzzle::SolvablePuzzle: grid of Sudoku values to set.
- new_values::Array: input integers of same shape as SolvablePuzzle.grid
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
                v = Integer(value)
                puzzle.grid[row,col] = make_entry(rank_squared,v)
            end
        end
    end
end
            
"""
    get_rank(puzzle)

Return a Sudoku rank from the shape of a 2D aray.
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
    get_rank(puzzle)

Return a Sudoku rank from a SolvablePuzzle.
"""
function get_rank(puzzle::SolvablePuzzle)
    return get_rank(puzzle.grid)
end

"""
    set_unknown(puzzle,row,col)

Assign a position in the grid of a SolvablePuzzle to known.
"""
function set_unknown(puzzle::SolvablePuzzle,row::Integer,col::Integer)
    p = BitVector(undef,size(puzzle.grid)[1])
    p .= true
    puzzle.grid[row,col] = PuzzleEntry(p)
    return nothing
end

"""
    as_text(puzzle)

Return the contents of the puzzle as a grid of strings.

Known values are integers greater than 0.
Unknown values are 0.
"""
function as_text(puzzle::SolvablePuzzle)
    result = fill(" ",size(puzzle.grid)) # unknowns!
    for i = 1:length(puzzle.grid)
        value = get_value(puzzle.grid[i])
        if value != 0 # fill in the knowns
            result[i] = string(value)
        end
    end
    return result
end

"""
    as_values(puzzle)

Return the contents of the puzzle as a grid of integers.

Known values are integers greater than 0.
Unknown values are 0.
"""
function as_values(puzzle::SolvablePuzzle)
    result = Array{Integer}(undef, size(puzzle.grid)) # invalid data
    for i = 1:length(puzzle.grid)
        result[i] = get_value(puzzle.grid[i])
    end
    return result
end

"""
    as_possibilities(puzzle)

Return the contents of the puzzle as a grid of integers representing possible values.

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
    uncertainty(puzzle)

Assess the degree of uncertainty in a SolvablePuzzle.

Zero uncertainty is associated with solved puzzles.
Unsolved puzzles have uncertainty greater than zero.
"""
function uncertainty(puzzle::SolvablePuzzle)
    result::Integer = 0
    rank = get_rank(puzzle.grid)
    rank_squared = rank*rank
    error_detected = false
    for i = 1:length(puzzle.grid)
        temp = BitVector(undef,rank_squared)
        temp.chunks[1] = puzzle.grid[i].possibilities # Convert int to BitVector
        possibility_count = sum(temp)
        error_detected = error_detected || (possibility_count == 0)
        if possibility_count > 1
            result += sum(temp)
        end
    end
    if error_detected
        throw(DomainError("Puzzle entry with zero valid possibilities detected."))
    end
    return result
end
