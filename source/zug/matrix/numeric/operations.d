module zug.matrix.numeric.operations;

import std.traits : isNumeric, isIntegral;
import std.conv : to;
import zug.matrix.generic;
import zug.matrix.array_utils;

version (unittest) {
    public import zug.matrix.dbg;
}

///
T min(T)(Matrix!T orig) pure
if (isNumeric!T) {
    import std.algorithm.searching : minElement;

    return orig.data.minElement;
}

///
T max(T)(Matrix!T orig) pure
if (isNumeric!T) {
    import std.algorithm.searching : maxElement;

    return orig.data.maxElement;
}


Matrix!T multiply(T)(Matrix!T orig, T scalar) pure
if (isNumeric!T) {
    import std.stdio : writeln;

    auto result = orig.data.dup;
    // https://dlang.org/spec/arrays.html#array-operations
    // the [] after the variable name means it's a vector operation
    result[] *= scalar;
    return Matrix!T(result, orig.width);
}


///
Matrix!T multiply(T)(Matrix!T first, Matrix!T second) pure
if (isNumeric!T)
    in {
        assert(first.width == second.height,
                "width of the first matrix must be equal with the height of the second matrix");
    }
do
{
    size_t height = first.height;
    size_t width = second.width;
    Matrix!T result = Matrix!T(width, height);

    for (size_t y = 0; y < height; y++) {
        for (size_t x = 0; x < width; x++) {
            // first.row X second.column
            T[] first_row = first.row(y);
            T[] second_column = second.column(x);
            T current = 0;
            foreach (size_t i; 0 .. first.width) {
                current += first_row[i] * second_column[i];
            }
            result.set(x, y, current);
        }
    }

    return result;
}


/// scalar addition
// TODO: apparently this is not a thing, geometrically does not make sense
// more details https://math.stackexchange.com/a/1379252
Matrix!T add(T)(Matrix!T orig, T scalar)
if (isNumeric!T) {
    import std.stdio : writeln;

    auto result = orig.data.dup;
    // https://dlang.org/spec/arrays.html#array-operations
    // the [] after the variable name means it's a vector operation
    result[] += scalar;
    return Matrix!T(result, orig.width);
}

/// add two matrices
Matrix!T add(T)(Matrix!T first, Matrix!T second) pure {

    if (first.width != second.width || first.height != second.height) {
        throw new Error("the matrices don't have the same size");
    }

    auto result = Matrix!T(first.width, first.height);

    foreach (size_t i; 0 .. first.data_length) {
        result.set(i, first.get(i) + second.get(i));
    }
    return result;
}

/// this will work only for numeric 2d matrices
//    because of the  "return i.to!R;" inside,
// TODO have to think about alternatives for the generic code
Matrix!R replace_elements(T, R)(Matrix!T orig, bool delegate(T) filter, R delegate(T) transform)
if (isNumeric!T && isNumeric!R) {
    import std.algorithm : map;
    import std.array : array;

    auto transformer = delegate R(T i) {
        if (filter(i)) {
            return transform(i);
        }
        return i.to!R;
    };

    // TODO: can't mark the function as pure because this is not pure
    // replace it
    R[] result = map!(transformer)(orig.data[0 .. $]).array;

    return Matrix!R(result, orig.width);
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
U moving_average_simple_calculator(U, T)(Matrix!T orig, size_t x, size_t y, T[] window) pure
if (isNumeric!T) {
    import std.algorithm.iteration : sum;

    auto total = orig.get(x, y) + window.sum;
    auto count = window.length.to!T + 1;

    static if (is(U == T)) {
        return total / count;
    } else {
        return total.to!U / count.to!U;
    }
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
        T[] function(Matrix!T, size_t, size_t, size_t) shaper,
        U function(Matrix!T, size_t, size_t, T[]) calculator)
if (isNumeric!T)
    in {
        assert(distance >= 0);
    }
do
{
    auto result = Matrix!U(orig.width, orig.height);

    for (size_t y = 0; y < orig.height; y++) {
        for (size_t x = 0; x < orig.width; x++) {
            auto window = shaper(orig, x, y, distance);
            U new_element = calculator(orig, x, y, window);
            result.set(x, y, new_element);
        }
    }

    return result;
}


Matrix!R round_elements(T, R)(Matrix!T orig) if (isNumeric!T && isIntegral!R) {
    import std.math : round;

    static if (isIntegral!T) {
        return orig.copy();
    } else {
        auto filter = delegate bool(T i) => true;
        auto transform = delegate R(T i) => round(i).to!R;
        return orig.replace_elements!(T, R)(filter, transform);
    }
}

// TODO finish this
Matrix!T squeeze(T)(Matrix!T orig, float scale_x, float scale_y)
if (isNumeric!T) {
    import std.math : round;

    size_t new_width = round(orig.width * scale_x).to!size_t;
    size_t new_height = round(orig.height * scale_y).to!size_t;

    Matrix!T result = Matrix!T(new_width, new_height);

    return result;
}


/**
 * stretch_bilinear can only create an enlarged version of the original,
 *    else use squeeze
 *
 * Params:
 *   orig = Matrix!T,  orignal matrix
 *   scale_x = float, how much to scale horizontally
 *   scale_y = float, how much to scale vertically
 *
 * Returns:
 *   stretched_matrix = Matrix!T, a new matrix with the requested size
 */
Matrix!T stretch_bilinear(T)(Matrix!T orig, float scale_x, float scale_y) pure
in {
    assert(scale_x >= 1 && scale_y >= 1);
}
do
{
    if (scale_x == 1 && scale_y == 1) {
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
    for (size_t i = 0; i < new_height; i++) {
        if (next_y - i <= next_y % 1) {
            auto stretched = stretch_row(orig.row(original_y), new_width);
            result.row(stretched, i);
            original_y++;
            populated_rows_coordinates ~= i;

            if (original_y >= orig.height) {
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

    for (size_t i = 0; i < populated_rows_coordinates.length; i++) {
        if (bottom_row_id == 0) { // first loop
            top_row_id = populated_rows_coordinates[i];
            bottom_row_id = populated_rows_coordinates[i + 1];
            i++;
        } else {
            top_row_id = bottom_row_id;
            bottom_row_id = populated_rows_coordinates[i];
        }

        // for each column between those two rows calculate the slope
        // then interpolate all missing elements
        // TODO: move to a different function
        for (size_t x = 0; x < new_width; x++) {
            immutable double top_value = result.get(x, top_row_id).to!double;
            immutable double bottom_value = result.get(x, bottom_row_id).to!double;

            // calculate the slope once per vertical segment
            immutable double slope = (bottom_value - top_value).to!double / (
                bottom_row_id - top_row_id).to!double;
            double last_computed_value = top_value;
            // SEEME: can I do this in parallel ?
            //    maybe if the distance between the populated rows is big enough ?
            // A: not really, need the last computed value before going on, probably, I think
            // TODO look into this later
            for (size_t y = top_row_id + 1; y < bottom_row_id; y++) {
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

T determinant2x2(T)(Matrix!T orig) pure
if (isNumeric!T)
    in {
        assert(orig.width == orig.height, "matrix must be square");
        assert(orig.width == 2, "matrix must be 2x2");
    }
do
{
    return (orig.get(0, 0) * orig.get(1, 1)) - (orig.get(0, 1) * orig.get(1, 0));
}

// TODO determinant of matrix 3x3

// TODO determinant of matrix 4x4


// TODO determinant of matrix larger than 2x2

///
Matrix!int normalize(T)(Matrix!T orig, T normal_min, T normal_max) pure
if (isNumeric!T) {
    import std.array : array;
    import std.algorithm : map;

    auto min = orig.min;
    auto max = orig.max;

    auto new_data = map!((T value) => normalize_value!(T, int)(value, min, max,
            normal_min, normal_max))(orig.data[0 .. $]).array;
    return Matrix!int (new_data, orig.width);
}

// TODO: need to benchmark this, and if it works better drop the other one
Matrix!T normalize_vector_operation(T)(Matrix!T orig, T normal_min, T normal_max) pure
if (isNumeric!T) {
    import std.array : array;
    import std.algorithm : map;

    immutable auto actual_min_value = orig.min;
    immutable auto actual_max_value = orig.max;

    T[] new_data = new T[orig.data_length];
    auto old_data = orig.data;
    new_data[] = (normal_min + (old_data[] - actual_min_value) * (normal_max - normal_min) / (actual_max_value - actual_min_value));

    return Matrix!T(new_data, orig.width);
}


/// http://mathforum.org/library/drmath/view/60433.html 1 + (x-A)*(10-1)/(B-A)
U normalize_value(T, U)(T item, T actual_min_value, T actual_max_value, T normal_min, T normal_max) pure
if (isNumeric!T) {
    if (normal_min == normal_max) {
        throw new Error("the normal min and max values are equal");
    }

    return (normal_min + (item - actual_min_value) * (normal_max - normal_min) / (
        actual_max_value - actual_min_value)).to!U;
}
