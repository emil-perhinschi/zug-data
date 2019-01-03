module zug.matrix.numeric.operations;
import std.traits;
import zug.matrix.generic;

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

    auto result = orig.moving_average_simple_calculator!(float, int)(x, y, window);
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
    size_t how_big = 64;
    auto orig = Matrix!int(random_array!int(64, 0, 255, 12341234), 8);
    dbg(orig, "moving_average orig ");

    size_t window_size = 2;
    auto smooth = orig.moving_average!(int, int)(window_size,
            &shaper_square!int, &moving_average_simple_calculator!(int, int));
    assert(smooth.height == orig.height);
    assert(smooth.width == orig.width);
    dbg(smooth, "smoothed with moving average over square window");
}
