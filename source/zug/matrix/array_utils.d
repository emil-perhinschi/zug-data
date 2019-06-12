module zug.matrix.array_utils;

import std.traits;
import std.conv : to;

import zug.matrix.generic;

version (unittest)
{
    public import zug.matrix.dbg;
}

///
T[] random_array(T)(size_t size, T min, T max, uint seed) if (isNumeric!T)
{
    import std.random : Random, uniform;

    auto rnd = Random(seed);
    T[] result = new T[](size);
    foreach (size_t i; 0 .. size)
    {
        result[i] = uniform(min, max, rnd);
    }
    return result;
}

/// random_array
unittest
{
    import std.range : take;
    import std.random : Random, uniform;

    uint seed = 42;
    auto result = random_array!int(10, 0, 15, seed);

    assert(result[0] == 12);
    assert(result[1] == 2);

    auto result_float = random_array!float(10, 0, 15, seed);
    // TODO figure out how to check floats, this does not work
    // writeln(result_float);
    // assert(result_float[0] == 5.6181 ); 

    size_t how_big = 64;
    auto orig = Matrix!int(random_array!int(how_big, 0, 255, seed), 8);

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
    assert(orig.get(0, 0) == 132);
    assert(orig.get(1, 1) == 38);
    assert(orig.get(1, 3) == 208);
    assert(orig.get(3, 1) == 124);
    assert(orig.get(3, 3) == 189);
    assert(orig.get(3, 5) == 69);
    assert(orig.get(3, 7) == 243);
    assert(orig.get(5, 5) == 8);
}

/**
 * Params: 
 *   input = an array with the first and last elements set, we need to interpolate
 *                 those in the middle we don't look at the values in the middle, various 
 *                 numeric types have various defaults (0 for int, nan for float etc.)
 *
 * Returns:
 *   result = a new array with the values from 1 to the penultimate interpolated 
 */
T[] segment_linear_interpolation(T)(T[] input) pure
in
{
    assert(input.length >= 3);
}
do
{
    T[] result = input.dup;

    immutable double top_value = input[0].to!double;
    immutable double bottom_value = input[$ - 1].to!double;

    // calculate the slope once per vertical segment
    immutable double slope = (bottom_value - top_value).to!double / (input.length - 1).to!double;
    double last_computed_value = top_value;
    // SEEME: can I do this in parallel ?
    //    maybe if the distance between the populated rows is big enough ?
    // A: not really, need the last computed value before going on, probably, I think
    // TODO look into this later
    for (size_t i = 1; i < input.length - 1; i++)
    {
        // stepping over 1, so just add the slope to save on computations
        // SEEME: maybe if using only the start, the end and the position in betwee
        //    I don't need the last_computed_value, so I can make this parallel ?
        immutable double value = last_computed_value + slope;
        result[i] = value;
        last_computed_value = value;
    }

    return result;
}

unittest
{
    import std.algorithm.comparison : equal;

    float[] orig = new float[10];
    orig[0] = 1;
    orig[9] = 10;
    float[] result = orig.segment_linear_interpolation();
    float[] expected = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    dbg(result, 1, "linear_interpolation result");
    assert(expected.equal(result));
}

/// works for squeezing too
double[] stretch_row_coordinates(size_t orig_length, size_t new_length) pure
{

    // keep forgetting so here it is: 
    // I'm computing the largest index for the original array and for the stretched array
    //  - 1 because the first index is 0
    double new_max_index = (new_length - 1).to!double;
    double orig_max_index = (orig_length - 1).to!double;

    immutable double spacing = new_max_index / orig_max_index;
    double[] stretched_coordinates = new double[orig_length];
    for (size_t i = 0; i < orig_length; i++)
    {
        stretched_coordinates[i] = i.to!double * spacing;
    }

    // deal with floating point weirdnesses, make sure the last value is what it should be
    stretched_coordinates[stretched_coordinates.length - 1] = new_length - 1;

    return stretched_coordinates;
}

T[] stretch_row(T)(T[] orig, size_t new_length) pure
{

    double[] stretched_coordinates = stretch_row_coordinates(orig.length, new_length);

    size_t orig_coordinates = 0;
    double next_coordinates = stretched_coordinates[orig_coordinates];
    double prev_coordinates = 0;
    T[] stretched = new T[new_length];

    for (size_t i = 0; i < new_length; i++)
    {
        if (next_coordinates - i <= (next_coordinates % 1))
        {
            stretched[i] = orig[orig_coordinates];
            prev_coordinates = next_coordinates;
            orig_coordinates += 1;
            if (orig_coordinates < stretched_coordinates.length)
            {
                next_coordinates = stretched_coordinates[orig_coordinates];
            }
            else
            {
                break;
            }
        }
        else
        {
            immutable double slope = (orig[orig_coordinates] - orig[orig_coordinates - 1]).to!double / (
                    next_coordinates - prev_coordinates);

            immutable double value = orig[orig_coordinates - 1].to!double + (
                    slope * (i - prev_coordinates)).to!double;

            stretched[i] = value.to!T;
        }
    }

    return stretched;
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

// TODO later, after I make a function to plot functions 
T[] cubic_interpolation(T)(T[] input, double[] coordinates_populated_elements)
        if (isNumeric!T)
{
    T[] result;
    return result;
}

