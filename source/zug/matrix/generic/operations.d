module zug.matrix.generic.operations;

import std.traits : isNumeric;
import zug.matrix.generic;

version (unittest)
{
    public import zug.matrix.dbg;
}

Matrix!T concatenate_vertically(T)(Matrix!T first, Matrix!T second) pure
in
{
    assert(first.width == second.width);
}
do
{
    Matrix!T result = Matrix!T(first.width, first.height + second.height);

    for (size_t i = 0; i < first.width; i++)
    {
        auto first_col = first.column(i);
        first_col ~= second.column(i);
        result.column(first_col, i);
    }
    return result;
}

unittest
{
    auto first = Matrix!int([1,2,3,4], 2);
    auto second = Matrix!int([ 1,2,3,4,5,6], 2);
    auto result = first.concatenate_vertically(second);
    dbg(result, "concatenate_vertically");
    auto expected = Matrix!int(
        [
            1, 2,
            3, 4,
            1, 2,
            3, 4,
            5, 6,
        ],
        2
    );
    assert(result.equal(expected), "concatenate_vertically");
}


/// non-numeric test
unittest
{
    auto first = Matrix!Offset(
        [
            Offset(0,0), Offset(1,0),
            Offset(0,1), Offset(1,1)
        ],
        2
    );

    auto second = Matrix!Offset(
        [
            Offset(0,0), Offset(1,0), Offset(2,0),
            Offset(0,1), Offset(1,1), Offset(2,1)
        ],
        2
    );

    auto result = first.concatenate_vertically(second);
    dbg(result, "concatenate_vertically with non-numeric elements");
    auto expected = Matrix!Offset(
        [
            Offset(0, 0), Offset(1, 0),
            Offset(0, 1), Offset(1, 1),
            Offset(0, 0), Offset(1, 0),
            Offset(2, 0), Offset(0, 1),
            Offset(1, 1), Offset(2, 1),
        ],
        2
    );

    assert(result.equal(expected), "concatenate_vertically with non-numeric elements");

    // let's check equal(), just to make sure
    auto not_expected = result.copy();
    not_expected.set(1,1, Offset(100, 100));
    assert(!result.equal(not_expected));
}


Matrix!T concatenate_horizontally(T)(Matrix!T first, Matrix!T second) pure
in
{
    assert(first.height == second.height);
}
do
{
    Matrix!T result = Matrix!T(first.width + second.width, first.height);

    for (size_t i = 0; i < first.height; i++)
    {
        auto first_row = first.row(i);
        first_row ~= second.row(i);
        result.row(first_row, i);
    }
    return result;
}

unittest
{
    auto first = Matrix!int([1,2,3,4], 2);
    auto second = Matrix!int([ 1,2,3,4,5,6], 3);
    auto result = first.concatenate_horizontally(second);
    dbg(result, "concatenate_horizontally");
    auto expected = Matrix!int(
        [
            1, 2, 1, 2, 3,
            3, 4, 4, 5, 6
        ],
        5
    );
    assert(result.equal(expected), "concatenate_horizontally");
}


/// non-numeric test
unittest
{
    auto first = Matrix!Offset(
        [
            Offset(0,0), Offset(1,0),
            Offset(0,1), Offset(1,1)
        ],
        2
    );

    auto second = Matrix!Offset(
        [
            Offset(0,0), Offset(1,0), Offset(2,0),
            Offset(0,1), Offset(1,1), Offset(2,1)
        ],
        3
    );

    auto result = first.concatenate_horizontally(second);
    dbg(result, "concatenate_horizontally with non-numeric elements");
    auto expected = Matrix!Offset(
        [
            Offset(0, 0), Offset(1, 0), Offset(0, 0), Offset(1, 0), Offset(2, 0),
            Offset(0, 1), Offset(1, 1), Offset(0, 1), Offset(1, 1), Offset(2, 1)
        ],
        5
    );

    assert(result.equal(expected), "concatenate_horizontally with non-numeric elements");

    // let's check equal(), just to make sure
    auto not_expected = result.copy();
    not_expected.set(1,1, Offset(100, 100));
    assert(!result.equal(not_expected));
}

T[][] to_2d_array(T)(Matrix!T orig) pure
{
    T[][] result;
    for(size_t i = 0; i < orig.height; i++) 
    {
        result ~= orig.row(i);
    }
    return result;
}


unittest
{
    import std.algorithm: equal;

    auto orig = Matrix!int(
        [
            1,2,3,
            4,5,6,
            7,8,9,
            10,11,12
        ],
        3
    );
    auto result = orig.to_2d_array();
    int[][] expected = [[1, 2, 3], [4, 5, 6], [7, 8, 9], [10, 11, 12]];
    assert(result.equal(expected));
}

Matrix!T transpose(T)(Matrix!T orig) pure if (isNumeric!T)
{
    auto result = Matrix!T(orig.height, orig.width);
    for (size_t y = 0; y < orig.height; y++)
    {
        for (size_t x = 0; x < orig.width; x++)
        {
            result.set(y, x, orig.get(x, y));
        }
    }
    return result;
}

/// transpose square matrix
unittest
{
    // dfmt off
    auto orig = Matrix!int(
        [
            1,2,3,
            4,5,6,
            7,8,9
        ],
        3
    );

    auto expected = Matrix!int(
        [
            1,4,7,
            2,5,8,
            3,6,9
        ],
    3);
    // dfmt on
    auto result = orig.transpose();
    for (size_t i = 0; i < result.data_length; i++)
    {
        assert(result.get(i) == expected.get(i));
    }
}

/// transpose non-square matrix
unittest
{
    // dfmt off
    auto orig = Matrix!int(
        [
            1,2,
            3,4,
            5,6,
            7,8
        ],
        2
    );

    auto expected = Matrix!int(
        [
            1,3,5,7,
            2,4,6,8
        ],
    4);
    // dfmt on
    auto result = orig.transpose();
    for (size_t i = 0; i < result.data_length; i++)
    {
        assert(result.get(i) == expected.get(i));
    }
}

/// returns a matrix of matrices
Matrix!(Matrix!T) get_minors(T)(Matrix!T orig) pure
{
    auto result = Matrix!(Matrix!T)(orig.width, orig.height);

    for (size_t y = 0; y < orig.height; y++)
    {
        for (size_t x = 0; x < orig.width; x++)
        {
            result.set(x, y, orig.get_minor(x, y));
        }
    }
    return result;
}

unittest
{
    // dfmt off
    auto orig = Matrix!int(
        [
            1, 2, 3,
            4, 5, 6,
            7, 8, 9
        ],
        3,
    );
    // dfmt on

    auto minors = orig.get_minors();

    auto expected_0_0 = Matrix!int([5, 6, 8, 9], 2);
    assert(minors.get(0, 0).equal(expected_0_0));

    auto expected_1_0 = Matrix!int([4, 6, 7, 9], 2);
    assert(minors.get(1, 0).equal(expected_1_0));

    auto expected_2_0 = Matrix!int([4, 5, 7, 8], 2);
    assert(minors.get(2, 0).equal(expected_2_0));

    auto expected_0_1 = Matrix!int([2, 3, 8, 9], 2);
    assert(minors.get(0, 1).equal(expected_0_1));
}

Matrix!T get_minor(T)(Matrix!T orig, size_t exclude_x, size_t exclude_y) pure
{
    Matrix!T result = Matrix!T(orig.width - 1, orig.height - 1);
    size_t new_x = 0;
    size_t new_y = 0;
    for (size_t y = 0; y < orig.height; y++)
    {
        new_x = 0;
        if (y == exclude_y)
        {
            continue;
        }
        for (size_t x = 0; x < orig.width; x++)
        {
            if (x == exclude_x)
            {
                continue;
            }
            result.set(new_x, new_y, orig.get(x, y));
            new_x++;
        }
        new_y++;
    }
    return result;
}

unittest
{
    import std.stdio : writeln;

    auto orig = Matrix!int([1, 2, 3, 4, 5, 6, 7, 8, 9], 3);

    auto minor_0_0 = orig.get_minor(0, 0);
    auto expected_0_0 = Matrix!int([5, 6, 8, 9], 2);
    assert(minor_0_0.equal(expected_0_0));

    auto minor_1_0 = orig.get_minor(1, 0);
    auto expected_1_0 = Matrix!int([4, 6, 7, 9], 2);
    assert(minor_1_0.equal(expected_1_0));

    auto minor_2_0 = orig.get_minor(2, 0);
    auto expected_2_0 = Matrix!int([4, 5, 7, 8], 2);
    assert(minor_2_0.equal(expected_2_0));

    auto minor_0_1 = orig.get_minor(0, 1);
    auto expected_0_1 = Matrix!int([2, 3, 8, 9], 2);
    assert(minor_0_1.equal(expected_0_1));
}

// TODO list minors of matrix

///
Matrix!T dice(T)(Matrix!T orig, Offset offset, size_t width, size_t height) pure
{
    import std.range : chunks;

    auto chunked = orig.data.chunks(orig.width);

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
    auto orig = Matrix!int(orig_data, width);

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

Matrix!T enlarge(T)(Matrix!T orig, int scale_x, int scale_y) pure
in
{
    assert(scale_x > 1);
    assert(scale_y > 1);
}
do
{

    size_t new_width = orig.width * scale_x;
    size_t new_height = orig.height * scale_y;
    auto result = Matrix!T(new_width, new_height);

    immutable size_t full_length = new_width * new_height;
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
    import zug.matrix.array_utils : random_array;

    // orig 
    // [ 6,  3, 12, 14]
    // [10,  7, 12,  4]
    // [ 6,  9,  2,  6]
    // [10, 10,  7,  4]
    uint seed = 42;
    auto orig = Matrix!int(random_array(16, 0, 16, seed), 4);
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

T[] shaper_square(T)(Matrix!T orig, size_t x, size_t y, size_t distance) pure
in
{
    assert(distance > 0, "distance must be positive");
    assert(distance < orig.height, "window must be smaller than the height of the orignal");
    assert(distance < orig.width, "window must be smaller than the width of the original");
}
do
{
    // close to the left edge
    immutable size_t start_x = x < distance ? 0 : x - distance;

    // close to the top edge
    immutable size_t start_y = y < distance ? 0 : y - distance;

    // close to the right edge
    immutable size_t max_x = orig.width - 1;
    immutable size_t end_x = x + distance >= max_x ? max_x : x + distance;

    // close to the bottom edge
    immutable size_t max_y = orig.height - 1;
    immutable size_t end_y = y + distance >= max_y ? max_y : y + distance;

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
T[] shaper_circle(T)(Matrix!T orig, size_t x, size_t y, size_t distance) pure
in
{
    assert(distance > 0, "distance must be positive");
    assert(distance < orig.height, "window must be smaller than the height of the orignal");
    assert(distance < orig.width, "window must be smaller than the width of the original");
}
do
{
    import std.math : sqrt, round;
    import std.conv : to;

    // close to the left edge
    immutable size_t start_x = x < distance ? 0 : x - distance;
    // close to the top edge
    immutable size_t start_y = y < distance ? 0 : y - distance;
    // close to the right edge
    immutable size_t max_x = orig.width - 1;
    immutable size_t end_x = distance + x > max_x ? max_x : x + distance;
    // close to the bottom edge
    immutable size_t max_y = orig.height - 1;
    immutable size_t end_y = distance + y > max_y ? max_y : y + distance;

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
            immutable real how_far = sqrt(((x - j) * (x - j) + (y - i) * (y - i)).to!real);
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
    import zug.matrix.array_utils;
    import zug.matrix.numeric.operations;

    auto data = random_array!int(16, 0, 15,12_341_234);
    auto random_mask = Matrix!int(random_array!int(1600, 0, 4, 12_345_678), 40);
    size_t window_size = 3;
    auto orig = Matrix!int(data, 4);
    dbg(orig, "build_random_map_shaper_circle orig");
    auto stretched = orig.stretch_bilinear(10,10);
    dbg(stretched, "build_random_map_shaper_circle stretched");
    auto randomized = stretched.add(random_mask);
    dbg(randomized, "build_random_map_shaper_circle randomized");
    auto smooth = randomized.moving_average!(int, int)(window_size, &shaper_circle!int, &moving_average_simple_calculator!(int, int));
    dbg(smooth, "build_random_map_shaper_circle smooth");
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


bool equal(T)(Matrix!T first, Matrix!T second)
{
    static import std.algorithm;
// dfmt off
    if (
        std.algorithm.equal(first.data, second.data)
        && second.width == second.width 
        && first.height == second.height
    )
    {
        return true;
    }
// dfmt on
    return false;
}

unittest 
{
    Matrix!int first = Matrix!int( [1,2,3,4],2 );
    Matrix!int second = Matrix!int( [1,2,3,4],2 );
    assert(first.equal(second));
    assert(second.equal(first));
    second.set(0,0,100);
    assert(!first.equal(second));
    assert(!second.equal(first));
}

unittest 
{
    
    Matrix!Offset first = Matrix!Offset( 2, 2 );
    Matrix!Offset second = Matrix!Offset(2, 2 );
    assert(first.equal(second));
    assert(second.equal(first));

    auto wrong = Offset(1,1);
    second.set(0,0, wrong);
    assert(!first.equal(second));
    assert(!second.equal(first));
}
