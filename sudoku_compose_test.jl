# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.
using Test
using Random

function multiple_random_permutations!(seed,results)
    rng = MersenneTwister(seed)
    num_tests = size(results)[1]
    puzzle = SolvablePuzzle(3)
    for i = 1:num_tests
        permutation = random_permutation!(puzzle,rng)
        results[i,1:length(permutation)] = permutation[:]
    end
end

function test_random_permutations()
    num_tests = 4000000 # number of calls to test
    all_results = zeros(Int,(num_tests,4))
    
    # Plan to split the work across all worker
    num_tasks = Threads.nthreads() # number of workers
    # Make a separate RNG seed for each worker
    seed_rng = MersenneTwister(12345)
    rng_seeds = zeros(Int,(num_tasks,1))
    for i = 1:num_tasks
        rng_seeds[i] = rand(seed_rng,1000:100000)
    end
    workload = Int(num_tests/num_tasks)
    Threads.@threads for i = 1:num_tasks
        if i == num_tasks
            multiple_random_permutations!(
                rng_seeds[i],
                @view all_results[((i-1)*workload+1):num_tests,:])
        else
            multiple_random_permutations!(
                rng_seeds[i],
                @view all_results[((i-1)*workload+1):(i*workload),:])
        end
    end
    MAX_RESIDUAL_ERROR = 2.0/sqrt(num_tests)
    # Verify that the number of each permutation type is consistent
    column_1_counts = [count(i->i==j,@view all_results[:,1]) for j in 1:7]
    @test abs(column_1_counts[1] - (num_tests/7))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_1_counts[2] - (num_tests/7))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_1_counts[3] - (num_tests/7))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_1_counts[4] - (num_tests/7))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_1_counts[5] - (num_tests/7))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_1_counts[6] - (num_tests/7))/num_tests < MAX_RESIDUAL_ERROR
    
    # Verify that the number of each block selected for permutation 1:4 is consistent
    column_2_counts = zeros(Int,(3,))
    for i in 1:size(all_results)[1]
        if all_results[i,1] in 1:4
            column_2_counts[all_results[i,2]] += 1
        end
    end
    # 4/7 of the time we selected a block, and 1/3 of the those were 1, 2, and 3
    @test abs(column_2_counts[1] - (4*num_tests/21))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_2_counts[2] - (4*num_tests/21))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_2_counts[3] - (4*num_tests/21))/num_tests < MAX_RESIDUAL_ERROR
    
    # Verify that the subrow selected for permutations 1, 3 is consistent
    column_3_subrow_counts = zeros(Int,(3,))
    for i in 1:size(all_results)[1]
        if all_results[i,1] == 1 || all_results[i,1] == 3 
            column_3_subrow_counts[all_results[i,3]] += 1
        end
    end
    # 2/7 of the time we selected a subrow, and 1/3 of the those were 1, 2, and 3
    @test abs(column_3_subrow_counts[1] - (2*num_tests/21))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_3_subrow_counts[2] - (2*num_tests/21))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_3_subrow_counts[3] - (2*num_tests/21))/num_tests < MAX_RESIDUAL_ERROR
    
    # Verify that the second subrow selected for permutations 1, 3 is consistent
    column_4_subrow_counts = zeros(Int,(3,))
    for i in 1:size(all_results)[1]
        if all_results[i,1] == 1 || all_results[i,1] == 3 
            @test all_results[i,4] != all_results[i,3]
            column_4_subrow_counts[all_results[i,4]] += 1
        end
    end
    # 2/7 of the time we selected a subrow, and 1/3 of the those were 1, 2, and 3
    @test abs(column_4_subrow_counts[1] - (2*num_tests/21))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_4_subrow_counts[2] - (2*num_tests/21))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_4_subrow_counts[3] - (2*num_tests/21))/num_tests < MAX_RESIDUAL_ERROR
    
    # Verify that the second block selected for permutations 2, 4 is consistent
    column_3_block_counts = zeros(Int,(3,))
    for i in 1:size(all_results)[1]
        if all_results[i,1] == 2 || all_results[i,1] == 4
            @test all_results[i,3] != all_results[i,2]
            column_3_block_counts[all_results[i,3]] += 1
        end
    end
    # 2/7 of the time we selected a second block, and 1/3 of the those were 1, 2, and 3
    @test abs(column_3_block_counts[1] - (2*num_tests/21))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_3_block_counts[2] - (2*num_tests/21))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_3_block_counts[3] - (2*num_tests/21))/num_tests < MAX_RESIDUAL_ERROR
    
    # Verify that the first, second symbol selected for permutation 7 is consistent
    column_2_symbol_counts = zeros(Int,(9,))
    column_3_symbol_counts = zeros(Int,(9,))
    for i in 1:size(all_results)[1]
        if all_results[i,1] == 7
            @test all_results[i,3] != all_results[i,2]
            column_2_symbol_counts[all_results[i,2]] += 1
            column_3_symbol_counts[all_results[i,3]] += 1
        end
    end
    # 1/7 of the time we selected a symbol, and 1/9 of the those were 1:9
    @test abs(column_2_symbol_counts[1] - (1*num_tests/63))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_2_symbol_counts[2] - (1*num_tests/63))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_2_symbol_counts[3] - (1*num_tests/63))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_2_symbol_counts[4] - (1*num_tests/63))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_2_symbol_counts[5] - (1*num_tests/63))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_2_symbol_counts[6] - (1*num_tests/63))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_2_symbol_counts[7] - (1*num_tests/63))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_2_symbol_counts[8] - (1*num_tests/63))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_2_symbol_counts[9] - (1*num_tests/63))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_3_symbol_counts[1] - (1*num_tests/63))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_3_symbol_counts[2] - (1*num_tests/63))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_3_symbol_counts[3] - (1*num_tests/63))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_3_symbol_counts[4] - (1*num_tests/63))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_3_symbol_counts[5] - (1*num_tests/63))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_3_symbol_counts[6] - (1*num_tests/63))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_3_symbol_counts[7] - (1*num_tests/63))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_3_symbol_counts[8] - (1*num_tests/63))/num_tests < MAX_RESIDUAL_ERROR
    @test abs(column_3_symbol_counts[9] - (1*num_tests/63))/num_tests < MAX_RESIDUAL_ERROR
end

@testset "Composition helpers statistics" begin
    @time test_random_permutations()
end