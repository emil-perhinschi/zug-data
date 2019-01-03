module zug.matrix.numeric;

import zug.matrix;

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
