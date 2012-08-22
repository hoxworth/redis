start_server {tags {"iset"}} {
    test "ISET basic IADD" {
        r del itmp
        r iadd itmp 10 20 x
        r iadd itmp 12 22 y
        r iadd itmp 15 25 z
        assert_equal_elements {x y z} [r istab itmp 18]
        assert_equal_elements {y z} [r istab itmp 21]
    }
    
    test "ISET complex IADD" {
        r del itmp
        # Create a right-left tree for balancing
        r iadd itmp 100 200 100_200
        r iadd itmp 200 300 200_300
        r iadd itmp 150 250 150_250
      
        # Create a right-right tree for balancing
        r iadd itmp 300 400 300_400
        r iadd itmp 400 500 400_500
        
        # Create a left-right tree for balancing
        r iadd itmp 50 100 50_100
        r iadd itmp 75 125 75_125
        
        # Create a left-left tree for balancing
        r iadd itmp 25 50 25_50
        r iadd itmp 0 25 0_25
        
        assert_equal_elements {0_25} [r istab itmp 23]
        assert_equal_elements {25_50} [r istab itmp 40]
        assert_equal_elements {50_100 75_125} [r istab itmp 77]
        assert_equal_elements {100_200 150_250} [r istab itmp 175]
        assert_equal_elements {300_400} [r istab itmp 350]
    }

    test "ISET Boundaries" {
        r del itmp
        r iadd itmp 10 20 x
        assert_equal {x} [r istab itmp 10]
        assert_equal {x} [r istab itmp 20]
    }

    test "ISET floating point stab" {
        r del itmp
        r iadd itmp 1 1.5 x
        r iadd itmp 1.25 2 y
        assert_equal {} [r istab itmp 0.99999]
        assert_equal {x} [r istab itmp 1.2]
        assert_equal_elements {x y} [r istab itmp 1.25]
        assert_equal {} [r istab itmp 2.1111]
    }

    test "ISET score update" {
        r del itmp
        r iadd itmp 10 20 x
        r iadd itmp 15 25 x
        assert_equal {x} [r istab itmp 24]
        assert_equal {} [r istab itmp 14]
    }

    test "ISET wrong number of arguments" {
        assert_error "*wrong*number*arguments*" {r iadd itmp 2}
        assert_error "*wrong*number*arguments*" {r iadd itmp 2 3}
        assert_error "*wrong*number*arguments*" {r iadd itmp 2 3 too 2}
        assert_error "*wrong*number*arguments*" {r iadd itmp 2 3 too 2 3}
        assert_error "*wrong*number*arguments*" {r iadd itmp 2 3 too 2 3 many more}
    }

    test "ISET Can't update a key without floats" {
        assert_error "*not*float*" {r iadd itmp banana cream pie}
        assert_error "*not*float*" {r iadd itmp 2 cream pies}
    }

    test "ISET variadic IADD" {
        r del itmp
        r iadd itmp 10 20 x 12 22 y 15 25 z
        assert_equal_elements {x y z} [r istab itmp 18]
        assert_equal_elements {y z} [r istab itmp 21]
    }

    test "ISET IADD returns correct value" {
        r del itmp
        assert_equal {1} [r iadd itmp 10 20 x]
    }

    test "ISET IADD returns correct zero" {
        r del itmp
        r iadd itmp 10 20 x
        assert_equal {0} [r iadd itmp 10 20 x]
    }

    test "ISET variadic IADD returns correct value" {
        r del itmp
        assert_equal {3} [r iadd itmp 10 20 x 12 22 y 15 25 z]
    }

    test "ISET IADD returns correct value after insert" {
        r del itmp
        r iadd itmp 10 20 x
        r iadd itmp 12 22 y
        assert_equal {1} [r iadd itmp 10 20 x 12 22 y 15 25 z]
    }

    test "ISET ISTAB basics" {
        r del itmp
        r iadd itmp 1 10 a
        r iadd itmp 3 10 b
        r iadd itmp 5 10 c
        r iadd itmp 7 12 d

        assert_equal_elements {a b c d} [r istab itmp 8]
        assert_equal_elements {a b c} [r istab itmp 6]
        assert_equal_elements {a b} [r istab itmp 4]
        assert_equal_elements {a} [r istab itmp 2]
        assert_equal_elements {d} [r istab itmp 11]
        assert_equal_elements {} [r istab itmp 0]
        assert_equal_elements {} [r istab itmp 13]

        #this doesn't really work, because assert_equal_elements
        #will verify {1 2 a 3 4 b} and {3 4 a 1 2 b} as the same set.
        #TODO: figure out a better assert
        #assert_equal_elements {}
    }

    test "ISET ISTAB weird scenario I hit that caused a bug" {
        r del itmp
        r iadd itmp 1 10 x
        assert_error "*not*valid*float*" {r istab x withintervals}
        assert_equal {x} [r istab itmp 5]
    }

    test "ISET adding multiple keys to a node" {
        r del itmp
        r iadd itmp 1 3 x
        r iadd itmp 1 3 y
        assert_equal {x y} [r istab itmp 2]
    }

    test "ISET IREM basics" {
        r del itmp
        r iadd itmp 1 3 x
        assert_equal {1} [r irem itmp x]
        assert_error "*no*such*key" {r istab itmp 2}
    }

    test "ISET IREM simple rem" {
        r del itmp
        #  2
        # 1 3
        r iadd itmp 1 10 1
        r iadd itmp 2 10 2
        r iadd itmp 3 10 3

        assert_equal {1} [r irem itmp 2]

        assert_equal_elements {1 3} [r istab itmp 9]
    }

    test "ISET IREM parent error" {
        r del itmp
        #     2
        #   1   4
        #      3
        r iadd itmp 2 2 2
        r iadd itmp 1 1 1
        r iadd itmp 4 4 4
        r iadd itmp 3 3 3
        assert_equal {1} [r irem itmp 4]
        assert_equal {1} [r irem itmp 2]
        assert_equal {1} [r irem itmp 3]

        assert_equal {1} [r istab itmp 1]
    }
    
    test "ISET IREM complex" {
        r del itmp
        # Create a right-left tree for balancing
        r iadd itmp 100 200 100_200
        r iadd itmp 200 300 200_300
        r iadd itmp 150 250 150_250

        # Create a right-right tree for balancing
        r iadd itmp 300 400 300_400
        r iadd itmp 400 500 400_500

        # Create a left-right tree for balancing
        r iadd itmp 50 100 50_100
        r iadd itmp 75 125 75_125

        # Create a left-left tree for balancing
        r iadd itmp 25 50 25_50
        r iadd itmp 0 25 0_25

        # Causes the code to fail.
        r iadd itmp 51 101 51_101

        assert_equal {1} [r irem itmp 100_200]
        assert_equal {1} [r irem itmp 50_100]
        
        assert_equal_elements {0_25} [r istab itmp 23]
        assert_equal_elements {25_50} [r istab itmp 40]
        assert_equal_elements {75_125 51_101} [r istab itmp 77]
        assert_equal_elements {150_250} [r istab itmp 175]
        assert_equal_elements {300_400} [r istab itmp 350]
    }

    test "ISET a sequence that failed" {
        r del itmp
        r iadd itmp 10 17 10_17
        r irem itmp 10_17
        r iadd itmp 46 49 46_49
        r iadd itmp 3 45 3_45
        r irem itmp 3_45
        r irem itmp 46_49
        r iadd itmp 9 14 9_14
        r iadd itmp 17 31 17_31
        r iadd itmp 16 42 16_42
        r irem itmp 17_31
        r iadd itmp 3 30 3_30
        r iadd itmp 1 48 1_48
        r irem itmp 1_48
        r iadd itmp 9 37 9_37
        r irem itmp 9_14
        r irem itmp 16_42

        #   9_37
        #3_30
        assert_equal_elements {3_30 9_37} [r istab itmp 21]
    }

    test "ISET Removing right child with children" {
        r del itmp
        #      5
        #   4      7
        #         6 8
        r iadd itmp 5 10 5
        r iadd itmp 4 10 4
        r iadd itmp 7 10 7
        r iadd itmp 6 10 6
        r iadd itmp 8 10 8

        assert_equal {1} [r irem itmp 7]

        assert_equal_elements {4 5 6 8} [r istab itmp 9]
        assert_equal_elements {} [r istab itmp 3]
        assert_equal_elements {4} [r istab itmp 4.5]
    }

    test "ISET Removing left child with children" {
        r del itmp
        #      7
        #   5      8
        #  4 6
        r iadd itmp 7 10 7
        r iadd itmp 8 10 8
        r iadd itmp 5 10 5
        r iadd itmp 4 10 4
        r iadd itmp 6 10 6

        assert_equal {1} [r irem itmp 5]

        assert_equal_elements {4 6 7 8} [r istab itmp 9]
        assert_equal_elements {} [r istab itmp 3]
        assert_equal_elements {4} [r istab itmp 4.5]
    }

    test "ISET Removing left child with >1 layer children" {
        r del itmp
        #       7
        #    4     8
        #  3   6     9
        #     5
        r iadd itmp 7 10 7
        r iadd itmp 8 10 8
        r iadd itmp 4 10 4
        r iadd itmp 3 10 3
        r iadd itmp 6 10 6
        r iadd itmp 9 10 9
        r iadd itmp 5 10 5

        assert_equal {1} [r irem itmp 4]

        assert_equal_elements {3 5 6 7 8 9} [r istab itmp 9]
        assert_equal_elements {} [r istab itmp 2]
        assert_equal_elements {3} [r istab itmp 3.5]
    }

    test "ISET Removing right child with >1 layer children" {
        r del itmp
        #       5
        #    4      7
        #  3      6   9
        #            8
        r iadd itmp 5 10 5
        r iadd itmp 4 10 4
        r iadd itmp 7 10 7
        r iadd itmp 3 10 3
        r iadd itmp 6 10 6
        r iadd itmp 9 10 9
        r iadd itmp 8 10 8

        assert_equal {1} [r irem itmp 7]

        assert_equal_elements {3 4 5 6 8 9} [r istab itmp 9]
        assert_equal_elements {} [r istab itmp 2]
        assert_equal_elements {3} [r istab itmp 3.5]
    }

    test "ISET adding multiple keys to a node then deleting one" {
        r del itmp
        r iadd itmp 1 3 x
        r iadd itmp 1 3 y
        r irem itmp x
        assert_equal {y} [r istab itmp 2]
    }

#    test "IREMBYSTAB empty" {
#        r del itmp
#        r iadd itmp 0 1 x
#        assert_equal {0} [r irembystab itmp 2]
#    }

#    test "IREMBYSTAB basics" {
#        r del itmp
#        r iadd itmp 1 4 x
#        r iadd itmp 2 5 y
#        r iadd itmp 20 50 z
#        r irembystab itmp 2
#        assert_equal {} [r istab itmp 2]
#        assert_equal {z} [r istab itmp 25]
#    }
}
