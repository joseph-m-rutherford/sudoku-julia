# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.
#
# This file depends upon sudoku_common.jl

function row_block_permute(puzzle,row_block_a,row_block_b)
    rank=Int16(sqrt(sqrt(length(puzzle))))
    if length(puzzle) != rank*rank*rank*rank
        throw(DimensionMismatch("Array length is not a square-of-a-square"))
    elseif row_block_a < 1 || row_block_a > rank
        throw(DomainError("Invalid row block A"))
    elseif row_block_b < 1 || row_block_b > rank
        throw(DomainError("Invalid row block B"))
    end
    start_row_a = rank*(row_block_a-1)+1
    stop_row_a = rank*(row_block_a-1)+rank
    start_row_b = rank*(row_block_b-1)+1
    stop_row_b = rank*(row_block_b-1)+rank
    rank_squared = rank*rank
    # copy block A from source
    block = puzzle[start_row_a:stop_row_a,:]
    # write block B into A
    puzzle[start_row_a:stop_row_a,:] = puzzle[start_row_b:stop_row_b,:]
    # write block A into B
    puzzle[start_row_b:stop_row_b,:] = block[:,:]
end

function col_block_permute(puzzle,col_block_a,col_block_b)
    rank=Int16(sqrt(sqrt(length(puzzle))))
    if length(puzzle) != rank*rank*rank*rank
        throw(DimensionMismatch("Array length is not a square-of-a-square"))
    elseif col_block_a < 1 || col_block_a > rank
        throw(DomainError("Invalid col block A"))
    elseif col_block_b < 1 || col_block_b > rank
        throw(DomainError("Invalid col block B"))
    end
    start_col_a = rank*(col_block_a-1)+1
    stop_col_a = rank*(col_block_a-1)+rank
    start_col_b = rank*(col_block_b-1)+1
    stop_col_b = rank*(col_block_b-1)+rank
    rank_squared = rank*rank
    # copy block A from source
    block = puzzle[:,start_col_a:stop_col_a]
    # write block B into A
    puzzle[:,start_col_a:stop_col_a] = puzzle[:,start_col_b:stop_col_b]
    # write block A into B
    puzzle[:,start_col_b:stop_col_b] = block[:,:]
end

function row_permute(puzzle,row_block,subrow_a,subrow_b)
    rank=Int16(sqrt(sqrt(length(puzzle))))
    if length(puzzle) != rank*rank*rank*rank
        throw(DimensionMismatch("Array length is not a square-of-a-square"))
    elseif row_block < 1 || row_block > rank
        throw(DomainError("Invalid row block"))
    elseif subrow_a < 1 || subrow_a > rank
        throw(DomainError("Invalid subrow A"))
    elseif subrow_b < 1 || subrow_b > rank
        throw(DomainError("Invalid subrow B"))
    end
    start_row = rank*(row_block-1)+1
    stop_row = rank*(row_block-1)+rank
    permutation = [i for i in 1:rank]
    permutation[subrow_a] = subrow_b
    permutation[subrow_b] = subrow_a
    # copy permuted rows from source
    block = puzzle[(start_row-1).+permutation,:]
    # update source with permuted rows
    puzzle[start_row:stop_row,:] = block[:,:]
end

function col_permute(puzzle,col_block,subcol_a,subcol_b)
    rank=Int16(sqrt(sqrt(length(puzzle))))
    if length(puzzle) != rank*rank*rank*rank
        throw(DimensionMismatch("Array length is not a square-of-a-square"))
    elseif col_block < 1 || col_block > rank
        throw(DomainError("Invalid col block"))
    elseif subcol_a < 1 || subcol_a > rank
        throw(DomainError("Invalid subcol A"))
    elseif subcol_b < 1 || subcol_b > rank
        throw(DomainError("Invalid subcol B"))
    end
    start_col = rank*(col_block-1)+1
    stop_col = rank*(col_block-1)+rank
    permutation = [i for i in 1:rank]
    permutation[subcol_a] = subcol_b
    permutation[subcol_b] = subcol_a
    # copy permuted rows from source
    block = puzzle[:,(start_col-1).+permutation]
    # update source with permuted rows
    puzzle[:,start_col:stop_col] = block[:,:]
end

function mirror_horizontal(puzzle)
    rank=Int16(sqrt(sqrt(length(puzzle))))
    if length(puzzle) != rank*rank*rank*rank
        throw(DimensionMismatch("Array length is not a square-of-a-square"))
    end
    if rank > 1 # blockwise swapping
        half_rank = Int16(floor(rank/2))
        for i = 1:half_rank # swap blocks
            col_block_permute(puzzle,i,rank-i+1) 
            for j = 1:half_rank # swap rows in blocks
                col_permute(puzzle,i,j,rank-j+1) 
                col_permute(puzzle,rank-i+1,j,rank-j+1)
            end # end subrow loop
        end # end block loop
    end # end rank switch
end

function mirror_vertical(puzzle)
    rank=Int16(sqrt(sqrt(length(puzzle))))
    if length(puzzle) != rank*rank*rank*rank
        throw(DimensionMismatch("Array length is not a square-of-a-square"))
    end
    # no mirroring for rank 1
    if rank > 1 # blockwise swapping
        half_rank = Int16(floor(rank/2))
        for i = 1:half_rank # swap blocks
            row_block_permute(puzzle,i,rank-i+1) 
            for j = 1:half_rank # swap rows in blocks
                row_permute(puzzle,i,j,rank-j+1) 
                row_permute(puzzle,rank-i+1,j,rank-j+1)
            end # end subrow loop
        end # end block loop
    end # end rank switch
end
