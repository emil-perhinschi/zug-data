module _tests;
import zug.matrix;
import std.stdio: writeln;

unittest {
    writeln("++++++++++++++++++++++");
}

/// Stretch row
unittest
{
    import std.algorithm.comparison : equal;

    float[] orig = [0, 1, 2, 3, 4];
    auto result = stretch_row(orig, 15);
    // expected [0, 0.285714, 0.571429, 1, 1.14286, 1.42857, 1.71429, 2, 2.28571, 2.57143, 3, 3.14286, 3.42857, 3.71429, 4]
    // assert(result.equal(expected)); ... floats will be floats :-/
    // writeln("result", result);
    assert(result.length == 15);
    assert(result[0] == orig[0]);
    assert(result[3] == orig[1]);
    assert(result[7] == orig[2]);
    assert(result[10] == orig[3]);
    assert(result[14] == orig[4]);
}

/// Stretch row
unittest
{
    import std.algorithm.comparison : equal;

    int[] orig = [0, 25, 75, 0, 255];
    int[] result = stretch_row(orig, 15);
    int[] expected = [0, 7, 14, 25, 32, 46, 60, 75, 53, 32, 0, 36, 109, 182, 255];
    assert(result.equal(expected));
}
