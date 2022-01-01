# Copyright (c) 2021, Joseph M. Rutherford
# All rights reserved.
#
# Code provided under the license contained in the LICENSE file.
#
# This file includes the Sudoku module source code.
# This file imports all sudoku_*_test.jl scripts into a separate namespace.
# Tests are executed using runtests.jl.

module SudokuTester

include("../src/sudoku.jl")

include("sudoku_common_test.jl")
include("sudoku_permute_test.jl")
include("sudoku_compose_test.jl")
include("sudoku_valid_test.jl")
include("sudoku_solve_test.jl")

end # end module