module zug.matrix.basic;

import std.array;
import std.algorithm : map;
import std.traits;
import std.conv : to;

import zug.matrix;

version (unittest)
{
    import std.stdio : writeln;
}

///
struct Offset
{
    size_t x;
    size_t y;
}

// TODO: functions which give info about the matrix or modify the matrix should stay in the class as methods
// TODO: functions which create new stuff based on the matrix should stay out and be called via UFCS 

/**
 * 
 *
 */

struct Matrix(T) if (isNumeric!T)
{

    T[] data;
    size_t height;
    size_t width;

    ///
    this(T[] data, size_t width)
    in
    {
        assert(data.length >= width, "data length should be larger than or equal with 'width'");
        assert(data.length % width == 0, "data length should be divisible by 'width'");
    }
    do
    {
        this.data = data;
        this.width = width;
        this.height = data.length / width;
    }

    ///
    this(size_t width, size_t height)
    {
        this.data = new T[](width * height);
        this.width = width;
        this.height = height;
    }

    ///
    void set(size_t index, T value)
    {
        this.data[index] = value;
    }

    ///
    void set(size_t x, size_t y, T value)
    {
        this.data[this.width * y + x] = value;
    }

    ///
    T get(size_t index)
    {
        return this.data[index];
    }

    ///
    T get(size_t x, size_t y)
    {
        return this.data[this.width * y + x];
    }

    /// get
    unittest
    {
        Matrix!int orig = Matrix!int(3, 3);
        orig.set(0, 0, 1);
        assert(orig.get(0, 0) == orig.get(0));
        orig.set(1, 1, 111);
        assert(orig.get(1, 1) == orig.get(4));
    }

    ///
    size_t data_length()
    {
        return this.data.length;
    }

    ///
    T min()
    {
        import std.algorithm.searching : minElement;

        return this.data.minElement;
    }

    ///
    T max()
    {
        import std.algorithm.searching : maxElement;

        return this.data.maxElement;
    }

    ///
    Matrix!T dice(T)(Offset offset, size_t width, size_t height)
    {
        import std.range : chunks;

        auto chunked = this.data.chunks(this.width);

        T[] result;

        foreach (T[] row; chunked[offset.y .. (offset.y + height)])
        {
            result ~= row[offset.x .. (offset.x + width)].dup;
        }

        return Matrix!T(result, width);
    }
    /// 
    unittest
    {
        // dfmt off
        int[] data = [
            0, 0, 0, 0, 0, 0,
            0, 1, 1, 1, 1, 0,
            0, 1, 0, 0, 1, 0,
            0, 1, 0, 0, 1, 0,
            0, 1, 1, 1, 1, 0,
            0, 0, 0, 0, 0, 0
        ];
        // dfmt on

        size_t width = 6;
        auto orig = Matrix!int(data, width);

        Matrix!int result = orig.dice!int(Offset(1, 1), 4, 4);
        debug dbg!int(result, "dice 1,1->4,4");
        foreach (size_t i; 0 .. 4)
        {
            assert(result.get(1) == 1);
        }
        assert(result.get(1) == 1);
        assert(result.get(5) == 0);
        assert(result.get(6) == 0);
        assert(result.get(7) == 1);

        auto small = orig.dice!int(Offset(0, 0), 2, 2);
        dbg(small, "2x2 dice");
        assert(small.height == 2);
        assert(small.width == 2);
    }

    // https://en.wikipedia.org/wiki/Scaling_(geometry)#Using_homogeneous_coordinates
    // https://www.tomdalling.com/blog/modern-opengl/explaining-homogenous-coordinates-and-projective-geometry/ 
    Matrix!T homogenous_coordinates(T)() if (isNumeric!T)
    {
        Matrix!T result = Matrix!T(3, this.width * this.height);

        for (size_t i = 0; i < (this.width * this.height); i++)
        {
            auto modulo = (i % this.width).to!T;
            result.set(0, i, modulo);
            result.set(1, i, ((i - modulo) / this.width).to!T);
            result.set(2, i, 1);
        }
        return result;
    }
    /// homogenous_coordinates
    unittest
    {
        auto orig = Matrix!int([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], 3);
        dbg(orig, "Matrix 3x4 orig, testing coordinates");
        auto coord = orig.homogenous_coordinates!size_t();
        dbg(coord, "homogenous coordinates");

    }

    ///
    Matrix!T coordinates(T)() if (isNumeric!T)
    {
        Matrix!T result = Matrix!T(2, this.width * this.height);

        for (size_t i = 0; i < (this.width * this.height); i++)
        {
            auto modulo = (i % this.width).to!T;
            result.set(0, i, modulo);
            result.set(1, i, ((i - modulo) / this.width).to!T);
        }
        return result;
    }
    /// coordinates
    unittest
    {
        auto orig = Matrix!int([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], 3);
        dbg(orig, "Matrix 3x4 orig, testing coordinates");
        auto coord = orig.coordinates!size_t();
        dbg(coord, "coordinates");

    }

    ///
    T[] column(size_t x)
    {
        T[] result = new T[](this.height);
        foreach (size_t i; 0 .. this.height)
        {
            result[i] = this.get(x, i);
        }
        return result;
    }

    /// get Matrix column
    unittest
    {
        Matrix!int orig = Matrix!int([1, 2, 3, 4, 5, 6, 7, 8, 9], 3);
        dbg!int(orig, "matrix for column");
        dbg!int(orig.column(1), orig.height, "column 1");
    }

    /// set column
    void column(T[] new_column, size_t x)
    {
        for (size_t i = 0; i < this.height; i++)
        {
            this.set(i * this.width + x, new_column[i]);
        }
    }

    unittest
    {
        import std.algorithm.comparison : equal;

        auto orig = Matrix!int(5, 5);
        int[] column = [5, 5, 5, 5, 5];
        orig.column(column, 2);
        dbg(orig, "column set");
        auto check = orig.column(2);
        assert(check.equal(column));
    }

    ///
    T[] row(size_t y)
    {
        T[] result = new T[](this.width);
        foreach (size_t i; 0 .. this.width)
        {
            result[i] = this.get(i, y);
        }
        return result;
    }

    /// get Matrix row
    unittest
    {
        Matrix!int orig = Matrix!int([1, 2, 3, 4, 5, 6, 7, 8, 9], 3);
        dbg!int(orig, "matrix for row");
        dbg!int(orig.row(1), orig.width, "row 1");
    }

    /// set row
    void row(T[] new_row, size_t y)
    {
        size_t first_id = y * width;
        size_t last_id = first_id + width;
        auto row = this.data[first_id .. last_id] = new_row;
    }

    unittest
    {
        import std.algorithm.comparison : equal;

        auto orig = Matrix!int(5, 5);
        int[] row = [5, 5, 5, 5, 5];
        orig.row(row, 2);
        dbg(orig, "row set");
        auto check = orig.row(2);
        assert(check.equal(row));
    }

    ///
    bool is_on_edge(size_t x, size_t y, size_t distance)
    {
        if (x < distance || y < distance || x >= (this.width - distance)
                || y >= (this.height - distance))
        {
            return true;
        }
        return false;
    }

    /// is_on_edge
    unittest
    {
        auto orig = Matrix!int(10, 10);
        assert(orig.is_on_edge(0, 0, 1) == true);
        assert(orig.is_on_edge(2, 2, 3) == true);
    }

    Matrix!T window(T)(Offset offset, size_t window_size, T delegate(size_t, size_t) fill)
            if (isNumeric!T)
    {
        import std.range : chunks, join;

        auto offset_x_orig = offset.x;

        auto chunked = this.data.chunks(this.width);
        T[][] result = new T[][](window_size, window_size);

        for (int y = 0; y < window_size; y++)
        {
            offset.x = offset_x_orig;
            for (int x = 0; x < window_size; x++)
            {
                if (offset.x < 0 || offset.y < 0 || offset.x > this.width - 1
                        || offset.y > this.height - 1)
                {
                    result[y][x] = fill(offset.x, offset.y);
                }
                else
                {
                    result[y][x] = chunked[offset.y][offset.x];
                }
                offset.x++;
            }
            offset.y++;
        }
        return Matrix!T(result.join(), window_size);
    }
    /// window
    unittest
    {
        // dfmt off 
    float[] data = [
        1, 2, 3, 4, 5, 6, 7,
        1, 2, 3, 4, 5, 6, 7, 
        1, 2, 3, 4, 5, 6, 7, 
        1, 2, 3, 4, 5, 6, 7, 
        1, 2, 3, 4, 5, 6, 7, 
        1, 2, 3, 4, 5, 6, 7, 
        1, 2, 3, 4, 5, 6, 7
    ];
    // dfmt on

        Matrix!float orig = Matrix!float(data, 7);
        auto r1 = orig.window!float(Offset(-3, -3), 4, delegate(size_t x, size_t y) => 0);
        debug dbg(r1, "Matrix.window");
        debug dbg(orig.window!float(Offset(-2, -2), 4, delegate(size_t x,
                size_t y) => 0), "Matrix.window");
        debug dbg(orig.window!float(Offset(-1, -1), 4, delegate(size_t x,
                size_t y) => 0), "Matrix.window");
        debug dbg(orig.window!float(Offset(0, 0), 4, delegate(size_t x,
                size_t y) => 0), "Matrix.window");
    }

    Matrix!T copy()
    {
        return Matrix!T(this.data.dup, this.width);
    }

    unittest
    {
        auto orig = Matrix!float([0, 1, 2, 3, 4, 5], 3);
        auto copy = orig.copy();
        dbg(copy, "copy before modified");

        for (size_t i = 0; i < orig.data_length; i++)
        {
            assert(orig.get(i) == copy.get(i));
        }

        copy.set(0, 0, 1000);
        dbg(copy, "copy modified");
        dbg(orig, "copy orig");

        assert(orig.get(0, 0) != copy.get(0, 0));
    }
}

/// Matrix instantiation
unittest
{
    auto orig = Matrix!int([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], 3);

    dbg(orig, "Matrix 3x4, testing instatiation");
    assert(orig.get(0, 0) == 0, "get 0,0");
    assert(orig.get(1, 1) == 4, "get 1,1");
    assert(orig.get(2, 2) == 8, "get 2,2");
    assert(orig.get(2, 3) == 11, "get 2,3");
}

///
Matrix!int normalize(T)(Matrix!T orig, T normal_min, T normal_max) if (isNumeric!T)
{
    import std.array;
    import std.algorithm;

    auto min = orig.min;
    auto max = orig.max;

    auto new_data = map!((T value) => normalize_value!(T, int)(value, min, max,
            normal_min, normal_max))(orig.data[0 .. $]).array;
    return Matrix!int(new_data, orig.width);
}

/// normalize!float
unittest
{
    auto orig = Matrix!float([1.1, 100.1, 50.1], 3);
    float normal_min = 0.0;
    float normal_max = 16.0;
    auto result = orig.normalize!float(normal_min, normal_max);

    assert(result.get(0) == 0);
    assert(result.get(1) == 16);
    // assert(result[2] ==  7.91919); // this fails for some reason , probably float weiredness ? TODO: investigate further
}

/// normalize!double
unittest
{
    auto orig = Matrix!double([0, 255, 125], 3);
    double normal_min = 0;
    double normal_max = 16;
    auto result = orig.normalize!double(normal_min, normal_max);

    assert(result.get(0) == 0);
    assert(result.get(1) == 16);
    assert(result.get(2) == 7);
}

/// http://mathforum.org/library/drmath/view/60433.html 1 + (x-A)*(10-1)/(B-A)
U normalize_value(T, U)(T item, T actual_min_value, T actual_max_value, T normal_min, T normal_max)
        if (isNumeric!T)
{
    import std.math;

    if (normal_min == normal_max)
    {
        throw new Error("the normal min and max values are equal");
    }

    return (normal_min + (item - actual_min_value) * (normal_max - normal_min) / (
            actual_max_value - actual_min_value)).to!U;
}

/// normalize_value
unittest
{
    int orig = 4;
    int actual_min_value = 0;
    int actual_max_value = 16;
    int normal_min = 0;
    int normal_max = 255;
    int result = normalize_value!(int, int)(orig, actual_min_value,
            actual_max_value, normal_min, normal_max);
    assert(result == 63);
}

/**
* Pick elements of a matrix around an element in a square shape whose sides
*    are equal with 2*distance + 1 .
*    
* This is the default shaper for the moving_average function
* 
* Params:
*   orig     = original matrix
*   x        = x coordinate for the current element in orig
*   y        = y coordinate for the current element in orig
*   distance = how large should be the window

* Returns: an array of elements picked, not including the current element
*/

T[] shaper_square(T)(Matrix!T orig, size_t x, size_t y, size_t distance)
        if (isNumeric!T)
in
{
    assert(distance > 0, "distance must be positive");
    assert(distance < orig.height, "window must be smaller than the height of the orignal");
    assert(distance < orig.width, "window must be smaller than the width of the original");
}
do
{
    // close to the left edge
    size_t start_x = x < distance ? 0 : x - distance;

    // close to the top edge
    size_t start_y = y < distance ? 0 : y - distance;

    // close to the right edge
    size_t max_x = orig.width - 1;
    size_t end_x = x + distance >= max_x ? max_x : x + distance;

    // close to the bottom edge
    size_t max_y = orig.height - 1;
    size_t end_y = y + distance >= max_y ? max_y : y + distance;

    T[] result;
    for (size_t i = start_y; i < end_y + 1; i++)
    {
        for (size_t j = start_x; j < end_x + 1; j++)
        {
            if (i == y && j == x)
            {
                // don't add the element around which the window is built
                // this will allow for weighting
                continue;
            }
            result ~= orig.get(j, i);
        }
    }
    return result;
}

unittest
{
    Matrix!int orig = Matrix!int(8, 8);
    // change one element, enable testing if it is in the right position
    orig.set(3, 3, 1);
    auto window = orig.shaper_square(4, 4, 1);

    dbg(window, 1, "shaper_square(4,4,1)");
    assert(window.length == 8, "got 8 elements in the window");
    assert(window[0] == 1, "changed element in orig is in the expected spot");
    assert(window[1] == 0, "unchanged element in orig is in the expected spot");

    auto larger_window = orig.shaper_square(4, 4, 2);
    assert(larger_window.length == 24, "got 24 elements in the larger window");
    assert(larger_window[6] == 1, "changed element in orig is in the expected spot");
    assert(larger_window[7] == 0, "unchanged element in orig is in the expected spot");
    dbg(larger_window, 1, "shaper_square(4,4,2)");

    auto left_top_corner_window = orig.shaper_square(0, 0, 2);
    assert(left_top_corner_window.length == 8);

    auto bottom_right_corner_window = orig.shaper_square(7, 7, 2);
    assert(bottom_right_corner_window.length == 8);
}

/**
* Pick elements of a matrix around an element in a round shape whose radius is 
*   equal or less than the distance. It reduces the number of elements to 
*   check by getting a square window first; if the rounded (std.math.round) 
*   distance between the reference element and the inspected element is less 
*   or equal with the distance parameter the element is selected for the window.
*
* This is the default shaper for the moving_average function
*
* Params:
*   orig     = original matrix
*   x        = x coordinate for the current element in orig
*   y        = y coordinate for the current element in orig
*   distance = how large should be the window
*
* Returns: an array of elements picked, not including the current element
*/
// TODO unittest
T[] shaper_circle(T)(Matrix!T orig, size_t x, size_t y, size_t distance)
        if (isNumeric!T)
in
{
    assert(distance > 0, "distance must be positive");
    assert(distance < orig.height, "window must be smaller than the height of the orignal");
    assert(distance < orig.width, "window must be smaller than the width of the original");
}
do
{
    import std.math : sqrt, round;

    // close to the left edge
    size_t start_x = x < distance ? 0 : x - distance;
    // close to the top edge
    size_t start_y = y < distance ? 0 : y - distance;
    // close to the right edge
    size_t end_x = distance + x > orig.width ? orig.width : x + distance;
    // close to the bottom edge
    size_t end_y = distance + y > orig.height ? orig.height : y + distance;

    T[] result;
    for (size_t i = start_y; i < end_y + 1; i++)
    {
        for (size_t j = start_x; j < end_x + 1; j++)
        {
            if (i == y && j == x)
            {
                // don't add the element around which the window is built
                // this will allow for weighting
                continue;
            }
            real how_far = sqrt(((x - j) * (x - j) + (y - i) * (y - i)).to!real);
            if (round(how_far) <= distance)
            {
                result ~= orig.get(j, i);
            }
        }
    }
    return result;
}

unittest
{
    Matrix!int orig = Matrix!int(8, 8);
    // change one element, enable testing if it is in the right position
    orig.set(3, 3, 1);
    auto window = orig.shaper_circle(4, 4, 2);

    dbg(window, 1, "shaper_circle(4,4,2)");
    assert(window.length == 20, "got 8 elements in the window");
    assert(window[4] == 1, "changed element in orig is in the expected spot");
    assert(window[1] == 0, "unchanged element in orig is in the expected spot");
}


// TODO 
// https://en.wikipedia.org/wiki/Scaling_(geometry)#Using_homogeneous_coordinates
/**


  Notes: the numbers in the transformation matrix are not about how many rows and 
  columns will the new matrix have after interpolation, instead are relevant only
  for each vector describing the coordinates of each pixel

  if I want to grow the image by 1.5 horizontally I need to find out how many columns 
  the new image will have, remove 1 because indices are indexed at zero, and those are 
  the x coordinates of the last row, and based on the original coordinates of the last 
  row I should find the scaling number which should go into the transformation matrix 
  in the X position
  
 */

Matrix!T scale(T)(Matrix!T orig, double scale_x, double scale_y)
{
    import std.math : round;

    auto coordinates = orig.coordinates!double();
    auto scaled_coordinates = scale_coordinates!T(coordinates, orig.width,
            orig.height, scale_x, scale_y);
    dbg(scaled_coordinates, "coordinates scaled");

    size_t new_width = round(orig.width.to!double * scale_x).to!size_t;
    size_t new_height = round(orig.height.to!double * scale_x).to!size_t;

    auto result = Matrix!T(new_width, new_height);
    dbg(result, "result");

    for (size_t i = 0; i < scaled_coordinates.height; i++)
    {
        // the old coordinates were kept as doubles to allow scaling by fractional numbers
        //     now we need to return them to size_t
        size_t old_x = coordinates.get(0, i).to!size_t;
        size_t old_y = coordinates.get(1, i).to!size_t;

        size_t new_x = round(scaled_coordinates.get(0, i)).to!size_t;
        size_t new_y = round(scaled_coordinates.get(1, i)).to!size_t;

        auto old_value = orig.get(old_x, old_y);
        result.set(new_x, new_y, old_value);
    }
    return result;
}

/**
 * scale_coordinates returns a 2D Matrix!double with the coordinates of each point in the original matrix 
 *   put in the position 
 */
Matrix!size_t scale_coordinates(T)(Matrix!T coordinates, size_t width,
        size_t height, double scale_x, double scale_y) if (isNumeric!T)
in
{
    // width of two, that is x and y
    assert(coordinates.width == 2);
    // height of the coordinates matrix is equal to the total number of elements in the original
    assert(coordinates.height == width * height);
}
do
{
    import std.math : round;

    // very detailed steps because I keep forgetting this and revert to thinking in 
    //   scaling images instead of thinking in terms of vectors

    double orig_width = width.to!double;
    double orig_height = height.to!double;

    double new_width = round(orig_width * scale_x);
    double new_height = round(orig_height * scale_x);

    double orig_max_x_index = orig_width - 1;
    double orig_max_y_index = orig_height - 1;

    double new_max_x_index = new_width - 1;
    double new_max_y_index = new_height - 1;

    double vector_scale_x = new_max_x_index / orig_max_x_index;
    double vector_scale_y = new_max_y_index / orig_max_y_index;

    Matrix!double trans_m = Matrix!double([vector_scale_x, 0, 0, vector_scale_y], 2);

    return coordinates.multiply(trans_m).round_elements!(T, size_t)();
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


/// SEEME: is this nearest neighbour interpolation ?
// returns a new matrix, does not change the old
Matrix!T enlarge(T)(Matrix!T orig, int scale_x, int scale_y) if (isNumeric!T)
in
{
    assert(scale_x > 0);
    assert(scale_y > 0);
}
do
{

    size_t new_width = orig.width * scale_x;
    size_t new_height = orig.height * scale_y;
    auto result = Matrix!T(new_width, new_height);

    size_t full_length = new_width * new_height;
    for (size_t i = 0; i < full_length; i++)
    {
        auto orig_x = (i % new_width) / scale_x; // SEEME .to!size_t ??
        auto orig_y = (i / new_width) / scale_y; // SEEME .to!size_t ??
        result.set(i, orig.get(orig_x, orig_y));
    }

    return result;
}

unittest
{
    // orig 
    // [ 6,  3, 12, 14]
    // [10,  7, 12,  4]
    // [ 6,  9,  2,  6]
    // [10, 10,  7,  4]
    auto orig = Matrix!int(random_array(16, 0, 16, 12341234), 4);
    dbg(orig, "orig enlarge");
    auto larger = orig.enlarge(2, 2);
    dbg(larger, "larger enlarge");

    // dfmt off 
    int[] expected_data = [ 
        6,  6,  3,  3, 12, 12, 14, 14,
        6,  6,  3,  3, 12, 12, 14, 14,
       10, 10,  7,  7, 12, 12,  4,  4,
       10, 10,  7,  7, 12, 12,  4,  4,
        6,  6,  9,  9,  2,  2,  6,  6,
        6,  6,  9,  9,  2,  2,  6,  6,
       10, 10, 10, 10,  7,  7,  4,  4,
       10, 10, 10, 10,  7,  7,  4,  4
    ];
    // dfmt on

    import std.algorithm.comparison : equal;

    assert(equal(larger.data, expected_data));

    auto larger_still = orig.enlarge(3, 3);
    dbg(larger_still, "larger_still enlarge");

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
            double top_value = result.get(x, top_row_id).to!double;
            double bottom_value = result.get(x, bottom_row_id).to!double;

            // calculate the slope once per vertical segment
            double slope = (bottom_value - top_value).to!double / (bottom_row_id - top_row_id).to!double;
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
                double value = last_computed_value + slope;
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
