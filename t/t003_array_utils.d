#! /usr/bin/env dub
/+dub.json: { "dependencies": { "zug-tap": "*", "zug-data": { "path": "../" }  } } +/

void main() {
    import std.range : take;
    import std.random : Random, uniform;

    import zug.tap;
    import zug.matrix;

    auto tap = Tap("array_utils.d");
    tap.verbose(true);
    tap.plan(18);

    {
        uint seed = 42;
        auto result = random_array!int (10, 0, 15, seed);

        tap.ok(result[0] == 12);
        tap.ok(result[1] == 2);

        auto result_float = random_array!float (10, 0, 15, seed);
        // TODO figure out how to check floats, this does not work
        // writeln(result_float);
        // assert(result_float[0] == 5.6181 );

        size_t how_big = 64;
        auto orig = Matrix!int (random_array!int (how_big, 0, 255, seed), 8);

        // should look like this
        //      0    1    2    3    4    5    6    7
        // 0 # [132, 167, 181, 199, 126, 125,  70, 164]
        // 1 # [85,   38,  43, 124, 200,  39, 171,  37]
        // 2 # [140,  10, 207, 106, 229, 176,  73, 206]
        // 3 # [209, 208, 146, 189, 142,  79, 207, 150]
        // 4 # [205, 184,  98, 229, 224, 176,   7,  90]
        // 5 # [221,  12,  97,  69, 237,   8, 218, 199]
        // 6 # [243,   2, 195,  54,  85, 189,  61, 169]
        // 7 # [250, 179, 158, 243, 101,   0,  95, 250]
        tap.ok(orig.get(0, 0) == 132);
        tap.ok(orig.get(1, 1) == 38);
        tap.ok(orig.get(1, 3) == 208);
        tap.ok(orig.get(3, 1) == 124);
        tap.ok(orig.get(3, 3) == 189);
        tap.ok(orig.get(3, 5) == 69);
        tap.ok(orig.get(3, 7) == 243);
        tap.ok(orig.get(5, 5) == 8);
    }

    {
        import std.algorithm.comparison : equal;

        float[] orig = new float[10];
        orig[0] = 1;
        orig[9] = 10;
        float[] result = orig.segment_linear_interpolation();
        float[] expected = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        dbg(result, 1, "linear_interpolation result");
        tap.ok(expected.equal(result), "segment_linear_interpolation");
    }

    {
        import std.algorithm.comparison : equal;

        float[] orig = [0, 1, 2, 3, 4];
        auto result = stretch_row(orig, 15);
        // expected [0, 0.285714, 0.571429, 1, 1.14286, 1.42857, 1.71429, 2, 2.28571, 2.57143, 3, 3.14286, 3.42857, 3.71429, 4]
        // assert(result.equal(expected)); ... floats will be floats :-/
        // writeln("result", result);
        tap.ok(result.length == 15, "stretch_row floats");
        tap.ok(result[0] == orig[0], "stretch_row floats");
        tap.ok(result[3] == orig[1], "stretch_row floats");
        tap.ok(result[7] == orig[2], "stretch_row floats");
        tap.ok(result[10] == orig[3], "stretch_row floats");
        tap.ok(result[14] == orig[4], "stretch_row floats");
    }

    {
        import std.algorithm.comparison : equal;

        int[] orig = [0, 25, 75, 0, 255];
        int[] result = stretch_row(orig, 15);
        int[] expected = [0, 7, 14, 25, 32, 46, 60, 75, 53, 32, 0, 36, 109, 182, 255];
        tap.ok(result.equal(expected), "stretch_row integers");
    }

    tap.done_testing();
}
