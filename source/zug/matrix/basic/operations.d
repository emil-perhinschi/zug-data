module zug.matrix.basic.operations;
import std.traits;
import zug.matrix;

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

///
Matrix!R replace_elements(T, R)(bool delegate(T) filter, R delegate(T) transform)
        if (isNumeric!T && isNumeric!R)
{
    import std.algorithm : map;

    auto transformer = delegate R(T i) {
        if (filter(i))
        {
            return transform(i);
        }
        return i.to!R;
    };

    R[] result = map!(transformer)(this.data[0 .. $]).array;

    return Matrix!R(result, this.width);
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
