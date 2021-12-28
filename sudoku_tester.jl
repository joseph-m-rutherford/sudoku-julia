# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.
# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.
#
# This file depends upon sudoku.jl and its Sudoku module
# This file imports all sudoku_*_test.jl scripts

module SudokuTester

include("sudoku_common.jl")
include("sudoku_common_test.jl")
include("sudoku_permute.jl")
include("sudoku_permute_test.jl")
include("sudoku_valid.jl")
include("sudoku_valid_test.jl")

end