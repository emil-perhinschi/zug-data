#! /usr/bin/env dub
/+dub.json: { "dependencies": { "zug-tap": "*", "zug-data": { "path": "../" }  } } +/

void main() {
    import std.range : take;
    import std.random : Random, uniform;

    import zug.tap;
    import zug.matrix;

    auto tap = Tap("t005_numeric_operations.d");
    tap.verbose(true);
    tap.plan(39);

    {
        import zug.matrix.generic.operations : equal;

        auto orig = Matrix!int ([1, 2, 3, 4, 5, 6, 7, 8, 9], 3);
        auto expected = Matrix!int ([3, 6, 9, 12, 15, 18, 21, 24, 27], 3);
        int scalar = 3;
        auto result = orig.multiply(scalar);
        tap.ok(result.equal(expected));
        tap.ok(!orig.equal(expected));
    }

    /// multiply: plain
    {
        auto first = Matrix!int ([1, 2, 3, 4, 5, 6], 3);
        auto second = Matrix!int ([7, 8, 9, 10, 11, 12], 2);
        dbg(first, "multiplied first");
        dbg(second, "multiplied second");
        auto result = multiply!int (first, second);
        dbg(result, "multiplied result");

        tap.ok(result.get(0, 0) == 58);
        tap.ok(result.get(1, 0) == 64);
        tap.ok(result.get(0, 1) == 139);
        tap.ok(result.get(1, 1) == 154);
    }

    /// multiply: float
    {
        auto first = Matrix!float ([1, 2, 3, 4, 5, 6], 3);
        auto second = Matrix!float ([7, 8, 9, 10, 11, 12], 2);
        dbg(first, "multiplied first float");
        dbg(second, "multiplied second float");
        auto result = multiply!float (first, second);
        dbg(result, "multiplied result float");

        tap.ok(result.get(0, 0) == 58);
        tap.ok(result.get(1, 0) == 64);
        tap.ok(result.get(0, 1) == 139);
        tap.ok(result.get(1, 1) == 154);
    }

    // add scalar to matrix
    {
        import zug.matrix.generic.operations : equal;

        auto orig = Matrix!int ([1, 2, 3, 4, 5, 6, 7, 8, 9], 3);
        auto expected = Matrix!int ([2, 3, 4, 5, 6, 7, 8, 9, 10], 3);
        int scalar = 1;
        auto result = orig.add(scalar);
        tap.ok(result.equal(expected));
        tap.ok(!orig.equal(expected));
    }

    /// add
    {

        auto first = Matrix!long ([1, 2, 3, 4], 4);
        auto second = Matrix!long ([0, 2, 4, 6], 4);

        auto result = add!long (first, second);
        tap.ok(result.get(0) == 1);
        tap.ok(result.get(1) == 4);
        tap.ok(result.get(2) == 7);
        tap.ok(result.get(3) == 10);
    }

    /// replace_elements
    {
        auto orig = Matrix!int ([1, 0, -1, 5, 7], 5);
        dbg(orig, "replace_elements orig");
        auto filter = delegate bool(int i) => i < 0;
        auto transformer = delegate int(int i) => 0;

        auto result = orig.replace_elements!(int, int)(filter, transformer);
        dbg(result, "replace_elements result");
        tap.ok(result.get(0) == 1);
        tap.ok(result.get(1) == 0);
        tap.ok(result.get(2) == 0);
        tap.ok(result.get(3) == 5);
        tap.ok(result.get(4) == 7);
    }

    {
        auto orig = Matrix!int (3, 3);
        size_t x = 1;
        size_t y = 1;
        orig.set(x, y, 1);
        int[] window = [2, 2, 2];

        immutable auto result = orig.moving_average_simple_calculator!(float, int)(x, y, window);
        tap.ok(result == 1.75, "simple average of 2,2,2 and 1 is 1.75 as expected");
    }

    {
        import zug.matrix : random_array, shaper_square;

        auto orig = Matrix!int (random_array!int (64, 0, 255, 12_341_234), 8);
        dbg(orig, "moving_average orig ");

        size_t window_size = 2;
        auto smooth = orig.moving_average!(int, int)(window_size,
                &shaper_square!int, &moving_average_simple_calculator!(int, int));
        tap.ok(smooth.height == orig.height);
        tap.ok(smooth.width == orig.width);
        dbg(smooth, "smoothed with moving average over square window");
    }

    {
        auto orig = Matrix!double ([1.1, 1.6, 1.5, 1.0, 1.3, 1.7, 1.0, 1.9, 1.8], 3);
        dbg(orig);

        auto result = orig.round_elements!(double, size_t)();
        dbg(result);
        // expected
        // # [1, 2, 2]
        // # [1, 1, 2]
        // # [1, 2, 2]
        tap.ok(result.get(0, 0) == 1);
        tap.ok(result.get(1, 0) == 2);
        tap.ok(result.get(2, 0) == 2);
        tap.ok(result.get(1, 1) == 1);
    }

    {
        auto orig = Matrix!double ([1.1, 1.6, 1.5, 1.1, 1.0, 1.3, 1.7, 1.0, 1.9, 1.8, 1.0, 0.9], 4);

        auto result = squeeze!double (orig, 0.5, 0.5);
        dbg(result, "squeeze");
    }

    // TODO visual inspection works fine but add some tap.oks too
    {

        auto orig = Matrix!int ([0, 5, 10, 15, 20, 25, 30, 35, 40], 3);
        dbg(orig.coordinates!float, "old_coords");
        auto result = orig.stretch_bilinear!int (2, 2);
        dbg(result, "sssssssssssssssstretch ");
    }

    // TODO visual inspection works fine but add some tap.oks too
    {
        auto orig = Matrix!float ([0.1, 5.3, 11.2, 14.0, 19.8, 15.1, 30.3, 35.1, 41.7], 3);
        dbg(orig.coordinates!float, "old_coords");
        auto result = orig.stretch_bilinear!float (2, 2);
        dbg(result, "sssssssssssssssstretch floats");

        auto large = Matrix!double (sample_2d_array!double (), 18);
        auto large_result = large.stretch_bilinear!double (3, 3);
        dbg(large_result, "sssssssssssssssstretch doubles large array");
    }

    {
        import std.stdio : writeln;

        auto orig = Matrix!int ([3, 8, 4, 6], 2);
        auto determinant = orig.determinant2x2();
        tap.ok(determinant == -14);
    }

    /// normalize!float
    {
        auto orig = Matrix!float ([1.1, 100.1, 50.1], 3);
        immutable float normal_min = 0.0;
        immutable float normal_max = 16.0;
        auto result = orig.normalize(normal_min, normal_max);

        tap.ok(result.get(0) ==  0);
        tap.ok(result.get(1) == 16);
        tap.ok(result.get(2) ==  7); // this fails for some reason , probably float weiredness ? TODO: investigate further
    }

    /// normalize!double
    {
        auto orig = Matrix!double ([0, 255, 125], 3);
        immutable double normal_min = 0;
        immutable double normal_max = 16;
        auto result = orig.normalize(normal_min, normal_max);
        tap.ok(result.get(0) ==  0, "normalize!double");
        tap.ok(result.get(1) == 16, "normalize!double");
        tap.ok(result.get(2) ==  7, "normalize!double");
    }

    /// normalize!float
    {
        auto orig = Matrix!float ([1.1, 100.1, 50.1], 3);
        immutable float normal_min = 0.0;
        immutable float normal_max = 16.0;
        auto result = orig.normalize(normal_min, normal_max);
        dbg(result, "normalized using vector operations");
        tap.ok(result.get(0) ==  0, "normalize_float");
        tap.ok(result.get(1) == 16, "normalize_float");
        tap.ok(result.get(2) ==  7, "normalize_float");
    }

    /// normalize_value
    {
        immutable int orig = 4;
        immutable int actual_min_value = 0;
        immutable int actual_max_value = 16;
        immutable int normal_min = 0;
        immutable int normal_max = 255;
        immutable int result = normalize_value!(int, int)(orig,
                actual_min_value, actual_max_value, normal_min, normal_max);
        tap.ok(result == 63, "normalize_value");
    }

    tap.done_testing();
}
