module zug.matrix.generic.operations;

import zug.matrix.generic;

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

