module zug.matrix.generic.operations;

import std.traits : isNumeric;
import zug.matrix.generic;

version (unittest) {
    public import zug.matrix.dbg;
}

Matrix!T concatenate_vertically(T)(Matrix!T first, Matrix!T second) pure
in {
    assert(first.width == second.width);
}
do
{
    Matrix!T result = Matrix!T(first.width, first.height + second.height);

    for (size_t i = 0; i < first.width; i++) {
        auto first_col = first.column(i);
        first_col ~= second.column(i);
        result.column(first_col, i);
    }
    return result;
}


Matrix!T concatenate_horizontally(T)(Matrix!T first, Matrix!T second) pure
in {
    assert(first.height == second.height);
}
do
{
    Matrix!T result = Matrix!T(first.width + second.width, first.height);

    for (size_t i = 0; i < first.height; i++) {
        auto first_row = first.row(i);
        first_row ~= second.row(i);
        result.row(first_row, i);
    }
    return result;
}

T[][] to_2d_array(T)(Matrix!T orig) pure {
    T[][] result;
    for (size_t i = 0; i < orig.height; i++) {
        result ~= orig.row(i);
    }
    return result;
}


Matrix!T transpose(T)(Matrix!T orig) pure if (isNumeric!T) {
    auto result = Matrix!T(orig.height, orig.width);
    for (size_t y = 0; y < orig.height; y++) {
        for (size_t x = 0; x < orig.width; x++) {
            result.set(y, x, orig.get(x, y));
        }
    }
    return result;
}


/// returns a matrix of matrices
Matrix!(Matrix!T)get_minors(T)(Matrix!T orig) pure
{
    auto result = Matrix!(Matrix!T)(orig.width, orig.height);

    for (size_t y = 0; y < orig.height; y++) {
        for (size_t x = 0; x < orig.width; x++) {
            result.set(x, y, orig.get_minor(x, y));
        }
    }
    return result;
}

Matrix!T get_minor(T)(Matrix!T orig, size_t exclude_x, size_t exclude_y) pure {
    Matrix!T result = Matrix!T(orig.width - 1, orig.height - 1);
    size_t new_x = 0;
    size_t new_y = 0;
    for (size_t y = 0; y < orig.height; y++) {
        new_x = 0;
        if (y == exclude_y) {
            continue;
        }
        for (size_t x = 0; x < orig.width; x++) {
            if (x == exclude_x) {
                continue;
            }
            result.set(new_x, new_y, orig.get(x, y));
            new_x++;
        }
        new_y++;
    }
    return result;
}

Matrix!T dice(T)(Matrix!T orig, Offset offset, size_t width, size_t height) pure {
    import std.range : chunks;

    auto chunked = orig.data.chunks(orig.width);

    T[] result;

    foreach (T[] row; chunked[offset.y .. (offset.y + height)]) {
        result ~= row[offset.x .. (offset.x + width)].dup;
    }

    return Matrix!T(result, width);
}


// TODO testme
Matrix!T enlarge(T)(Matrix!T orig, int scale_x, int scale_y) pure
in {
    assert(scale_x > 1);
    assert(scale_y > 1);
}
do
{
    import std.conv : to;

    size_t new_width = orig.width * scale_x;
    size_t new_height = orig.height * scale_y;

    auto result = Matrix!T(new_width, new_height);

    immutable size_t full_length = new_width * new_height;
    for (size_t i = 0; i < full_length; i++) {
        size_t orig_x = (i % new_width).to!size_t / scale_x; // SEEME .to!size_t ??
        size_t orig_y = (i / new_width).to!size_t / scale_y; // SEEME .to!size_t ??
        result.set(i, orig.get(orig_x, orig_y));
    }

    return result;
}

// draw a rectangular frame
Matrix!T add_frame(T)(
        Matrix!T orig,
        Offset offset,
        size_t frame_width, size_t frame_height,
        T frame_data)
in {
    assert(orig.width >= offset.x + frame_width);
    assert(orig.height >= offset.y + frame_height);
}
do
{
    import std.stdio;

    auto copy = orig.copy;

    auto top_left = offset;
    auto top_right = Offset(offset.x + frame_width, offset.y);
    auto bottom_left = Offset(offset.x, offset.y + frame_height);
    auto bottom_right = Offset(offset.x + frame_width, offset.y + frame_height);
    // i < top_right.x because (top_right.x, top_right.y) will be filled when drawing the vertical line
    //   same in various places below

    for (size_t i = top_left.x; i < top_right.x; i++) {
        copy.set(i, top_left.y, frame_data);
    }

    for (size_t i = bottom_left.x; i < bottom_right.x; i++) {
        copy.set(i, bottom_left.y, frame_data);
    }

    for (size_t i = (top_left.y + 1); i < bottom_left.y; i++) {
        copy.set(top_left.x, i, frame_data);
    }

    for (size_t i = (top_right.y + 1); i < bottom_right.y; i++) {
        copy.set(top_right.x, i, frame_data);
    }

    return copy;
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
in {
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
    for (size_t i = start_y; i < end_y + 1; i++) {
        for (size_t j = start_x; j < end_x + 1; j++) {
            if (i == y && j == x) {
                // don't add the element around which the window is built
                // this will allow for weighting
                continue;
            }
            result ~= orig.get(j, i);
        }
    }
    return result;
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
T[] shaper_circle(T)(Matrix!T orig, size_t x, size_t y, size_t distance) 
in {
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
    for (size_t i = start_y; i < end_y + 1; i++) {
        for (size_t j = start_x; j < end_x + 1; j++) {
            if (i == y && j == x) {
                // don't add the element around which the window is built
                // this will allow for weighting
                continue;
            }
            immutable real how_far = sqrt(((x - j) * (x - j) + (y - i) * (y - i)).to!real);
            if (round(how_far) <= distance) {
                result ~= orig.get(j, i);
            }
        }
    }
    return result;
}

bool equal(T)(Matrix!T first, Matrix!T second) {
    static import std.algorithm;

    // dfmt off
    if (
        std.algorithm.equal(first.data, second.data)
        && second.width == second.width
        && first.height == second.height) {
        return true;
    }
// dfmt on
    return false;
}


// TODO test
Matrix!T apply_filter(T)(T delegate(T) filter) {
    size_t width = matrix.width;
    auto result = new T[matrix.data_length];
    for (size_t i = 0; i < matrix.data_length; i++) {
        auto old = matrix.get(i);
        result[i] = old.filter!(T, ubyte)();
    }
    return Matrix!T(result, matrix.width);
}
