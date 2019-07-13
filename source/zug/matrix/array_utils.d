module zug.matrix.array_utils;

import std.traits;
import std.conv : to;

import zug.matrix.generic;

version (unittest)
{
    public import zug.matrix.dbg;
}

/**
* Params: 
*   size = how long the resulting array should be
*   min  = minimum value in the resulting array
*   max  = maximum value in the resulting array
*   seed = integer - the seed
*
* Returns:
*   result = array of length "size" with values between "min" and "max"
* 
* uses std.random.uniform to generate the values
*/
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

// TODO later, after I make a function to plot functions 
T[] cubic_interpolation(T)(T[] input, double[] coordinates_populated_elements)
        if (isNumeric!T)
{
    T[] result;
    return result;
}
