# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.

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

struct PuzzleEntry
    value::UInt8 # 0 indicates unknown, literal value otherwise
    possibilities::UInt16 # Bitmask index = 1 iff index is allowed
    
    # Define entry with rank and value
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

using Test

function test_puzzle_2()
    puzzle_2_reference = Array{Int16}(undef,(4,4))
    puzzle_2_reference[:] = [1,2,3,4, 3,4,1,2, 2,3,4,1, 4,1,2,3][:]
    @test puzzle_n(2) == puzzle_2_reference
end

function test_solvable_puzzle_2_construction()
    puzzle_2_reference = Array{Int16}(undef,(4,4))
    puzzle_2_reference[:] = [1,2,3,4, 3,4,1,2, 2,3,4,1, 4,1,2,3][:]
    p2 = SolvablePuzzle(2)
    @test length(p2.grid) == 16
    for i = 1:16
        @test p2.grid[i].value == puzzle_2_reference[i]
        @test p2.grid[i].possibilities == (0x1 << (puzzle_2_reference[i]-1))
    end

    # Verify text conversion
    puzzle_2_reference_text = Array{String}(undef,(4,4))
    puzzle_2_reference_text[:] = ["1","2","3","4", "3","4","1","2", "2","3","4","1", "4","1","2","3"][:]
    @test as_text(p2) == puzzle_2_reference_text

    # Verify zero uncertainty
    @test uncertainty(p2) == 0
end

function test_solvable_puzzle_2_modification()
    puzzle_2_reference = Array{Int8}(undef,(4,4))
    puzzle_2_reference[:] = [0,2,3,4, 3,0,1,2, 2,3,0,1, 4,1,2,0][:]
    p2 = SolvablePuzzle(Int8(2))
    # Make the diagonal unknowns
    for i = 1:4
        set_unknown(p2,i,i)
    end
    
    for i = 1:4
        for j = 1:4
            @test p2.grid[i,j].value == puzzle_2_reference[i,j]
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
    @test as_values(p2) == puzzle_2_reference_values
    
    # Verify possibility extraction
    puzzle_2_reference_possibilities = Array{UInt16}(undef,(4,4))
    puzzle_2_reference_possibilities[:] = [0xf,0x2,0x4,0x8, 0x4,0xf,0x1,0x2, 0x2,0x4,0xf,0x1, 0x8,0x1,0x2,0xf][:]
    @test as_possibilities(p2) == puzzle_2_reference_possibilities
    
    # Verify text conversion
    puzzle_2_reference_text = Array{String}(undef,(4,4))
    puzzle_2_reference_text[:] = [" ","2","3","4", "3"," ","1","2", "2","3"," ","1", "4","1","2"," "][:]
    @test as_text(p2) == puzzle_2_reference_text
    
    # Verify 4 totally unknown entries
    @test uncertainty(p2) == 16
end

@testset "Sudoku Puzzle rank == 2 definitions" begin
    test_puzzle_2()
    test_solvable_puzzle_2_construction()
    test_solvable_puzzle_2_modification()
end