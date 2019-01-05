module zug.matrix.numeric.operations;
import std.traits: isNumeric, isIntegral;
import std.conv: to;
import zug.matrix.generic;
import zug.matrix.array_utils;

version(unittest)
{
    public import zug.matrix.dbg;
}

///
Matrix!T multiply(T)(Matrix!T first, Matrix!T second) if (isNumeric!T)
in
{
    assert(first.width == second.height,
            "width of the first matrix must be equal with the height of the second matrix");
}
do
{
    size_t height = first.height;
    size_t width = second.width;
    Matrix!T result = Matrix!T(width, height);

    for (size_t y = 0; y < height; y++)
    {
        for (size_t x = 0; x < width; x++)
        {
            // first.row X second.column
            T[] first_row = first.row(y);
            T[] second_column = second.column(x);
            T current = 0;
            foreach (size_t i; 0 .. first.width)
            {
                current += first_row[i] * second_column[i];
            }
            result.set(x, y, current);
        }
    }

    return result;
}

/// multiply: plain
unittest
{
    auto first = Matrix!int([1, 2, 3, 4, 5, 6], 3);
    auto second = Matrix!int([7, 8, 9, 10, 11, 12], 2);
    dbg(first, "multiplied first");
    dbg(second, "multiplied second");
    auto result = multiply!int(first, second);
    dbg(result, "multiplied result");

    assert(result.get(0, 0) == 58);
    assert(result.get(1, 0) == 64);
    assert(result.get(0, 1) == 139);
    assert(result.get(1, 1) == 154);
}

/// multiply: float
unittest
{
    auto first = Matrix!float([1, 2, 3, 4, 5, 6], 3);
    auto second = Matrix!float([7, 8, 9, 10, 11, 12], 2);
    dbg(first, "multiplied first float");
    dbg(second, "multiplied second float");
    auto result = multiply!float(first, second);
    dbg(result, "multiplied result float");

    assert(result.get(0, 0) == 58);
    assert(result.get(1, 0) == 64);
    assert(result.get(0, 1) == 139);
    assert(result.get(1, 1) == 154);
}

/// add two matrices
Matrix!T add(T)(Matrix!T first, Matrix!T second)
{

    if (first.width != second.width || first.height != second.height)
    {
        throw new Error("the matrices don't have the same size");
    }

    auto result = Matrix!T(first.width, first.height);

    foreach (size_t i; 0 .. first.data_length)
    {
        result.set(i, first.get(i) + second.get(i));
    }
    return result;
}

/// add
unittest
{

    auto first = Matrix!long([1, 2, 3, 4], 4);
    auto second = Matrix!long([0, 2, 4, 6], 4);

    auto result = add!long(first, second);
    assert(result.get(0) == 1);
    assert(result.get(1) == 4);
    assert(result.get(2) == 7);
    assert(result.get(3) == 10);
}


/// this will work only for numeric 2d matrices 
//    because of the  "return i.to!R;" inside, TODO have to think about alternatives for the generic code
Matrix!R replace_elements(T, R)(Matrix!T orig, bool delegate(T) filter, R delegate(T) transform)
        if (isNumeric!T && isNumeric!R)
{
    import std.algorithm : map;
    import std.array: array;

    auto transformer = delegate R(T i) {
        if (filter(i))
        {
            return transform(i);
        }
        return i.to!R;
    };

    R[] result = map!(transformer)(orig.data[0 .. $]).array;

    return Matrix!R(result, orig.width);
}

/// replace_elements
unittest
{
    auto orig = Matrix!int([1, 0, -1, 5, 7], 5);
    dbg(orig, "replace_elements orig");
    auto filter = delegate bool(int i) => i < 0;
    auto transformer = delegate int(int i) => 0;

    auto result = orig.replace_elements!(int, int)(filter, transformer);
    dbg(result, "replace_elements result");
    assert(result.get(0) == 1);
    assert(result.get(1) == 0);
    assert(result.get(2) == 0);
    assert(result.get(3) == 5);
    assert(result.get(4) == 7);
}


/**
*  Simple moving average calculator callback, the default callback passed to the moving_average function
*
*  Params:
*    orig = Matrix!T, original matrix 
*    x = size_t, current element x coordinate
*    y = size_t, current element y coordinate
*    window = T[], the moving window as retrieved by the shaper callback sent to moving_average
*
*  Returns: a number of the type U specified when calling the function
*/
U moving_average_simple_calculator(U, T)(Matrix!T orig, size_t x, size_t y, T[] window)
    if (isNumeric!T)
{
    import std.algorithm.iteration : sum;

    auto total = orig.get(x, y) + window.sum;
    auto count = window.length.to!T + 1;

    static if (is(U == T))
    {
        return total / count;
    }
    else
    {
        return total.to!U / count.to!U;
    }
}

unittest
{
    auto orig = Matrix!int(3, 3);
    size_t x = 1;
    size_t y = 1;
    orig.set(x, y, 1);
    int[] window = [2, 2, 2];

    immutable auto result = orig.moving_average_simple_calculator!(float, int)(x, y, window);
    assert(result == 1.75, "simple average of 2,2,2 and 1 is 1.75 as expected");
}

/**
* Smooth the matrix/height map by averaging values in a window around each element
*  
*  
* Params:
*   orig       = original Matrix!T matrix
*   distance   = how far should be the elements to be picked for averaging
*   shaper     = function which will pick the elements and shape the window
*                for example a square window will pick elements in a square with the side 2*distance + 1  
*   calculator = delegate which will calculate the average (plain, weighted, exponential etc.), deal
*              edges etc.
*   
* Returns: a new matrix the same type and size as the original
*/
Matrix!U moving_average(T, U)(Matrix!T orig, size_t distance,
        T[]function(Matrix!T, size_t, size_t, size_t) shaper,
        U function(Matrix!T, size_t, size_t, T[]) calculator) if (isNumeric!T)
in
{
    assert(distance >= 0);
}
do
{
    auto result = Matrix!U(orig.width, orig.height);

    for (size_t y = 0; y < orig.height; y++)
    {
        for (size_t x = 0; x < orig.width; x++)
        {
            auto window = shaper(orig, x, y, distance);
            U new_element = calculator(orig, x, y, window);
            result.set(x, y, new_element);
        }
    }

    return result;
}

unittest
{
    import zug.matrix: random_array;

    auto orig = Matrix!int(random_array!int(64, 0, 255, 12_341_234), 8);
    dbg(orig, "moving_average orig ");

    size_t window_size = 2;
    auto smooth = orig.moving_average!(int, int)(window_size,
            &shaper_square!int, &moving_average_simple_calculator!(int, int));
    assert(smooth.height == orig.height);
    assert(smooth.width == orig.width);
    dbg(smooth, "smoothed with moving average over square window");
}

Matrix!R round_elements(T, R)(Matrix!T orig) if (isNumeric!T && isIntegral!R)
{
    import std.math : round;

    static if (isIntegral!T)
    {
        return orig.copy();
    }
    else
    {
        auto filter = delegate bool(T i) => true;
        auto transform = delegate R(T i) => round(i).to!R;
        return orig.replace_elements!(T, R)(filter, transform);
    }
}

unittest 
{
    auto orig = Matrix!double(
        [
            1.1, 1.6, 1.5,
            1.0, 1.3, 1.7,
            1.0, 1.9, 1.8
        ],
        3
    );
    dbg(orig);

    auto result = orig.round_elements!(double, size_t)();
    dbg(result);
    // expected
    // # [1, 2, 2]
    // # [1, 1, 2]
    // # [1, 2, 2]
    assert(result.get(0,0) == 1);
    assert(result.get(1,0) == 2);
    assert(result.get(2,0) == 2);
    assert(result.get(1,1) == 1);
}


/**
 * stretch_bilinear can only create an enlarged version of the original, 
 *    else use squeeze (TODO squeeze) 
 * 
 * Params:
 *   orig = Matrix!T,  orignal matrix
 *   scale_x = float, how much to scale horizontally
 *   scale_y = float, how much to scale vertically
 *
 * Returns:
 *   stretched_matrix = Matrix!T, a new matrix with the requested size
 */
Matrix!T stretch_bilinear(T)(Matrix!T orig, float scale_x, float scale_y)
in
{
    assert(scale_x >= 1 && scale_y >= 1);
}
do
{
    if (scale_x == 1 && scale_y == 1)
    {
        return orig.copy();
    }

    size_t new_width = (orig.width * scale_x).to!size_t;
    size_t new_height = (orig.height * scale_y).to!size_t;

    Matrix!T result = Matrix!T(new_width, new_height);

    // double because they're not integers any more after stretching
    double[] new_vertical_coordinates = stretch_row_coordinates(orig.height, new_height);

    // first get the rows from orig and stretch them and add to result in proper place
    // then get each column from the result and interpolate missing values
    size_t original_y = 0;
    double next_y = 0;
    size_t[] populated_rows_coordinates;
    for (size_t i = 0; i < new_height; i++)
    {
        if (next_y - i <= next_y % 1)
        {
            auto stretched = stretch_row(orig.row(original_y), new_width);
            result.row(stretched, i);
            original_y++;
            populated_rows_coordinates ~= i;

            if (original_y >= orig.height)
            {
                break;
            }

            next_y = new_vertical_coordinates[original_y];
        }
    }

    // interpolate between the rows set above rows
    // need all the known rows to be already set, 
    //    that's why the interpolation is delayed

    // start from the top set row and interpolate the missing values 
    //     until the bottom set row
    size_t top_row_id;
    size_t bottom_row_id;

    for (size_t i = 0; i < populated_rows_coordinates.length; i++)
    {
        if (bottom_row_id == 0)
        { // first loop
            top_row_id = populated_rows_coordinates[i];
            bottom_row_id = populated_rows_coordinates[i + 1];
            i++;
        }
        else
        {
            top_row_id = bottom_row_id;
            bottom_row_id = populated_rows_coordinates[i];
        }

        // for each column between those two rows calculate the slope
        // then interpolate all missing elements
        // TODO: move to a different function
        for (size_t x = 0; x < new_width; x++)
        {
            immutable double top_value = result.get(x, top_row_id).to!double;
            immutable double bottom_value = result.get(x, bottom_row_id).to!double;

            // calculate the slope once per vertical segment
            immutable double slope = (bottom_value - top_value).to!double / (bottom_row_id - top_row_id).to!double;
            double last_computed_value = top_value;
            // SEEME: can I do this in parallel ?
            //    maybe if the distance between the populated rows is big enough ?
            // A: not really, need the last computed value before going on, probably, I think
            // TODO look into this later
            for (size_t y = top_row_id + 1; y < bottom_row_id; y++)
            {
                // stepping over 1, so just add the slope to save on computations
                // SEEME: maybe if using only the start, the end and the position in betwee
                //    I don't need the last_computed_value, so I can make this parallel ?
                immutable double value = last_computed_value + slope;
                result.set(x, y, value.to!T);
                last_computed_value = value;
            }
        }
    }
    return result;
}

// TODO visual inspection works fine but add some asserts too
unittest
{

    auto orig = Matrix!int([0, 5, 10, 15, 20, 25, 30, 35, 40], 3);
    dbg(orig.coordinates!float, "old_coords");
    auto result = orig.stretch_bilinear!int(2, 2);
    dbg(result, "sssssssssssssssstretch ");
}
// TODO visual inspection works fine but add some asserts too
unittest
{
    auto orig = Matrix!float([0.1, 5.3, 11.2, 14.0, 19.8, 15.1, 30.3, 35.1, 41.7], 3);
    dbg(orig.coordinates!float, "old_coords");
    auto result = orig.stretch_bilinear!float(2, 2);
    dbg(result, "sssssssssssssssstretch floats");

    auto large = Matrix!double(sample_2d_array!double(), 18);
    auto large_result = large.stretch_bilinear!double(3, 3);
    dbg(large_result, "sssssssssssssssstretch doubles large array");
}

