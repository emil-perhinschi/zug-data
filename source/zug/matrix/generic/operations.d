module zug.matrix.generic.operations;

import std.traits : isNumeric;
import zug.matrix.generic;

version (unittest)
{
    public import zug.matrix.dbg;
}

Matrix!T transpose(T)(Matrix!T orig) if (isNumeric!T)
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
Matrix!(Matrix!T) get_minors(T)(Matrix!T orig)
{
    auto result = Matrix!(Matrix!T)(orig.width, orig.height);

    for (size_t y = 0; y < orig.height; y++)
    {
        for (size_t x = 0; x < orig.width; x++)
        {
            result.set(x,y, orig.get_minor(x,y));
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
    assert(minors.get(0,0).equal(expected_0_0));

    auto expected_1_0 = Matrix!int([4, 6, 7, 9], 2);
    assert(minors.get(1,0).equal(expected_1_0));

    auto expected_2_0 = Matrix!int([4, 5, 7, 8], 2);
    assert(minors.get(2,0).equal(expected_2_0));

    auto expected_0_1 = Matrix!int([2, 3, 8, 9], 2);
    assert(minors.get(0,1).equal(expected_0_1));
}

Matrix!T get_minor(T)(Matrix!T orig, size_t exclude_x, size_t exclude_y)
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

    auto minor_0_0    = orig.get_minor(0, 0);
    auto expected_0_0 = Matrix!int([5, 6, 8, 9], 2);
    assert( minor_0_0.equal(expected_0_0) );

    auto minor_1_0    = orig.get_minor(1, 0);
    auto expected_1_0 = Matrix!int([4, 6, 7, 9], 2);
    assert( minor_1_0.equal(expected_1_0) );

    auto minor_2_0    = orig.get_minor(2, 0);
    auto expected_2_0 = Matrix!int([4, 5, 7, 8], 2);
    assert( minor_2_0.equal(expected_2_0) );

    auto minor_0_1    = orig.get_minor(0, 1);
    auto expected_0_1 = Matrix!int([2, 3, 8, 9], 2);
    assert( minor_0_1.equal(expected_0_1) );
}

// TODO list minors of matrix

///
Matrix!T dice(T)(Matrix!T orig, Offset offset, size_t width, size_t height)
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
