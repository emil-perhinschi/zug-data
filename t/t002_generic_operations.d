#! /usr/bin/env dub
/+dub.json: { "dependencies": { "zug-tap": "*", "zug-data": { "path": "../" }  } } +/

void main() {
    import std.range : take;
    import std.random : Random, uniform;

    import zug.tap;
    import zug.matrix;

    auto tap = Tap("t002_generic_operations.d");
    tap.verbose(true);
    tap.plan(62);
    {
        auto first = Matrix!int ([1, 2, 3, 4], 2);
        auto second = Matrix!int ([1, 2, 3, 4, 5, 6], 2);
        auto result = first.concatenate_vertically(second);
        dbg(result, "concatenate_vertically");
        // dfmt off
        auto expected = Matrix!int (
            [
                1, 2,
                3, 4,
                1, 2,
                3, 4,
                5, 6,
            ],
            2
        );
// dfmt on
        tap.ok(result.equal(expected), "concatenate_vertically");
    }

    /// non-numeric test
    {
        auto first = Matrix!Offset([Offset(0, 0), Offset(1, 0), Offset(0, 1), Offset(1, 1)], 2);

        auto second = Matrix!Offset([Offset(0, 0), Offset(1, 0), Offset(2, 0),
                                     Offset(0, 1), Offset(1, 1), Offset(2, 1)], 2);

        auto result = first.concatenate_vertically(second);
        dbg(result, "concatenate_vertically with non-numeric elements");
        // dfmt off
        auto expected = Matrix!Offset(
                [
                    Offset(0, 0), Offset(1, 0),
                    Offset(0, 1), Offset(1, 1),
                    Offset(0, 0), Offset(1, 0),
                    Offset(2, 0), Offset(0, 1),
                    Offset(1, 1), Offset(2, 1),
                ],
                2);
        // dfmt on
        tap.ok(result.equal(expected), "concatenate_vertically with non-numeric elements");

        // let's check equal(), just to make sure
        auto not_expected = result.copy();
        not_expected.set(1, 1, Offset(100, 100));
        tap.ok(!result.equal(not_expected));
    }

    {
        auto first = Matrix!int ([1, 2, 3, 4], 2);
        auto second = Matrix!int ([1, 2, 3, 4, 5, 6], 3);
        auto result = first.concatenate_horizontally(second);
        dbg(result, "concatenate_horizontally");
        auto expected = Matrix!int ([1, 2, 1, 2, 3, 3, 4, 4, 5, 6], 5);
        tap.ok(result.equal(expected), "concatenate_horizontally");
    }

    /// non-numeric test
    {
        // dfmt off
        auto first = Matrix!Offset(
                [
                    Offset(0, 0), Offset(1, 0),
                    Offset(0, 1), Offset(1, 1)
                ],
                2);

        auto second = Matrix!Offset(
                [
                    Offset(0, 0), Offset(1, 0), Offset(2, 0),
                    Offset(0, 1), Offset(1, 1), Offset(2, 1)
                ],
                3);

        auto result = first.concatenate_horizontally(second);
        dbg(result, "concatenate_horizontally with non-numeric elements");
        auto expected = Matrix!Offset(
                [
                    Offset(0, 0), Offset(1, 0), Offset(0, 0), Offset(1, 0), Offset(2, 0),
                    Offset(0, 1), Offset(1, 1), Offset(0, 1), Offset(1, 1), Offset(2, 1)
                ],
                5);
        // dfmt on
        tap.ok(result.equal(expected), "concatenate_horizontally with non-numeric elements");

        // let's check equal(), just to make sure
        auto not_expected = result.copy();
        not_expected.set(1, 1, Offset(100, 100));
        tap.ok(!result.equal(not_expected));
    }

    // to_2d_array
    {
        import std.algorithm : equal;

        // dfmt off
        auto orig = Matrix!int (
            [
                1, 2, 3,
                4, 5, 6,
                7, 8, 9,
                10, 11, 12
            ],
            3
        );
// dfmt on
        auto result = orig.to_2d_array();
        int[][] expected = [[1, 2, 3], [4, 5, 6], [7, 8, 9], [10, 11, 12]];
        tap.ok(result.equal(expected));
    }

    /// transpose square matrix
    {
        // dfmt off
        auto orig = Matrix!int (
            [
                1, 2, 3,
                4, 5, 6,
                7, 8, 9
            ],
            3
        );

        auto expected = Matrix!int (
            [
                1, 4, 7,
                2, 5, 8,
                3, 6, 9
            ],
            3);
        // dfmt on
        auto result = orig.transpose();
        for (size_t i = 0; i < result.data_length; i++) {
            tap.ok(result.get(i) == expected.get(i));
        }
    }

    /// transpose non-square matrix
    {
        // dfmt off
        auto orig = Matrix!int (
            [
                1, 2,
                3, 4,
                5, 6,
                7, 8
            ],
            2
        );

        auto expected = Matrix!int (
            [
                1, 3, 5, 7,
                2, 4, 6, 8
            ],
            4);
        // dfmt on
        auto result = orig.transpose();
        for (size_t i = 0; i < result.data_length; i++) {
            tap.ok(result.get(i) == expected.get(i));
        }
    }

    /// get_minors
    {
        // dfmt off
        auto orig = Matrix!int (
            [
                1, 2, 3,
                4, 5, 6,
                7, 8, 9
            ],
            3,
        );
        // dfmt on

        auto minors = orig.get_minors();

        auto expected_0_0 = Matrix!int ([5, 6, 8, 9], 2);
        tap.ok(minors.get(0, 0).equal(expected_0_0));

        auto expected_1_0 = Matrix!int ([4, 6, 7, 9], 2);
        tap.ok(minors.get(1, 0).equal(expected_1_0));

        auto expected_2_0 = Matrix!int ([4, 5, 7, 8], 2);
        tap.ok(minors.get(2, 0).equal(expected_2_0));

        auto expected_0_1 = Matrix!int ([2, 3, 8, 9], 2);
        tap.ok(minors.get(0, 1).equal(expected_0_1));
    }

    /// get_minor
    {
        import std.stdio : writeln;

        auto orig = Matrix!int ([1, 2, 3, 4, 5, 6, 7, 8, 9], 3);

        auto minor_0_0 = orig.get_minor(0, 0);
        auto expected_0_0 = Matrix!int ([5, 6, 8, 9], 2);
        tap.ok(minor_0_0.equal(expected_0_0));

        auto minor_1_0 = orig.get_minor(1, 0);
        auto expected_1_0 = Matrix!int ([4, 6, 7, 9], 2);
        tap.ok(minor_1_0.equal(expected_1_0));

        auto minor_2_0 = orig.get_minor(2, 0);
        auto expected_2_0 = Matrix!int ([4, 5, 7, 8], 2);
        tap.ok(minor_2_0.equal(expected_2_0));

        auto minor_0_1 = orig.get_minor(0, 1);
        auto expected_0_1 = Matrix!int ([2, 3, 8, 9], 2);
        tap.ok(minor_0_1.equal(expected_0_1));
    }

    /// dice
    {
        // dfmt off
        int[] orig_data = [
            0, 0, 0, 0, 0, 0,
            0, 1, 1, 1, 1, 0,
            0, 1, 0, 0, 1, 0,
            0, 1, 0, 0, 1, 0,
            0, 1, 1, 1, 1, 0,
            0, 0, 0, 0, 0, 0
        ];
        // dfmt on

        size_t width = 6;
        auto orig = Matrix!int (orig_data, width);

        Matrix!int result = orig.dice!int (Offset(1, 1), 4, 4);
        debug dbg!int (result, "dice 1,1->4,4");
        foreach (size_t i; 0 .. 4) {
            tap.ok(result.get(1) == 1);
        }
        tap.ok(result.get(1) == 1);
        tap.ok(result.get(5) == 0);
        tap.ok(result.get(6) == 0);
        tap.ok(result.get(7) == 1);

        auto small = orig.dice!int (Offset(0, 0), 2, 2);
        dbg(small, "2x2 dice");
        tap.ok(small.height == 2);
        tap.ok(small.width == 2);
    }

    /// enlarge
    {
        import zug.matrix.array_utils : random_array;

        // orig
        // [ 6,  3, 12, 14]
        // [10,  7, 12,  4]
        // [ 6,  9,  2,  6]
        // [10, 10,  7,  4]
        uint seed = 42;
        auto orig = Matrix!int (random_array(16, 0, 16, seed), 4);
        dbg(orig, "orig enlarge");
        auto larger = orig.enlarge(2, 2);
        dbg(larger, "larger enlarge");

        // dfmt off
        int[] expected_data = [
            6, 6, 3, 3, 12, 12, 14, 14,
            6, 6, 3, 3, 12, 12, 14, 14,
            10, 10, 7, 7, 12, 12, 4, 4,
            10, 10, 7, 7, 12, 12, 4, 4,
            6, 6, 9, 9, 2, 2, 6, 6,
            6, 6, 9, 9, 2, 2, 6, 6,
            10, 10, 10, 10, 7, 7, 4, 4,
            10, 10, 10, 10, 7, 7, 4, 4
        ];
        // dfmt on

        import std.algorithm.comparison : equal;

        tap.ok(equal(larger.data, expected_data));

        auto larger_still = orig.enlarge(3, 3);
        dbg(larger_still, "larger_still enlarge");

    }

    /// shaper_square
    {
        Matrix!int orig = Matrix!int (8, 8);
        // change one element, enable testing if it is in the right position
        orig.set(3, 3, 1);
        auto window = orig.shaper_square(4, 4, 1);

        dbg(window, 1, "shaper_square(4,4,1)");
        tap.ok(window.length == 8, "got 8 elements in the window");
        tap.ok(window[0] == 1, "changed element in orig is in the expected spot");
        tap.ok(window[1] == 0, "unchanged element in orig is in the expected spot");

        auto larger_window = orig.shaper_square(4, 4, 2);
        tap.ok(larger_window.length == 24, "got 24 elements in the larger window");
        tap.ok(larger_window[6] == 1, "changed element in orig is in the expected spot");
        tap.ok(larger_window[7] == 0, "unchanged element in orig is in the expected spot");
        dbg(larger_window, 1, "shaper_square(4,4,2)");

        auto left_top_corner_window = orig.shaper_square(0, 0, 2);
        tap.ok(left_top_corner_window.length == 8);

        auto bottom_right_corner_window = orig.shaper_square(7, 7, 2);
        tap.ok(bottom_right_corner_window.length == 8);
    }

    /// shaper_circle
    {
        import zug.matrix.array_utils;
        import zug.matrix.numeric.operations;

        auto data = random_array!int (16, 0, 15, 12_341_234);
        auto random_mask = Matrix!int (random_array!int (1600, 0, 4, 12_345_678), 40);
        size_t window_size = 3;
        auto orig = Matrix!int (data, 4);
        dbg(orig, "build_random_map_shaper_circle orig");
        auto stretched = orig.stretch_bilinear(10, 10);
        dbg(stretched, "build_random_map_shaper_circle stretched");
        auto randomized = stretched.add(random_mask);
        dbg(randomized, "build_random_map_shaper_circle randomized");
        auto smooth = randomized.moving_average!(int, int)(window_size,
                &shaper_circle!int, &moving_average_simple_calculator!(int, int));
        dbg(smooth, "build_random_map_shaper_circle smooth");
    }

    {
        Matrix!int orig = Matrix!int (8, 8);
        // change one element, enable testing if it is in the right position
        orig.set(3, 3, 1);
        auto window = orig.shaper_circle(4, 4, 2);

        dbg(window, 1, "shaper_circle(4,4,2)");
        tap.ok(window.length == 20, "got 8 elements in the window");
        tap.ok(window[4] == 1, "changed element in orig is in the expected spot");
        tap.ok(window[1] == 0, "unchanged element in orig is in the expected spot");
    }

    /// equal
    {
        Matrix!int first = Matrix!int ([1, 2, 3, 4], 2);
        Matrix!int second = Matrix!int ([1, 2, 3, 4], 2);
        tap.ok(first.equal(second));
        tap.ok(second.equal(first));
        second.set(0, 0, 100);
        tap.ok(!first.equal(second));
        tap.ok(!second.equal(first));
    }

    {

        Matrix!Offset first = Matrix!Offset(2, 2);
        Matrix!Offset second = Matrix!Offset(2, 2);
        tap.ok(first.equal(second));
        tap.ok(second.equal(first));

        auto wrong = Offset(1, 1);
        second.set(0, 0, wrong);
        tap.ok(!first.equal(second));
        tap.ok(!second.equal(first));
    }

    tap.done_testing();
}
