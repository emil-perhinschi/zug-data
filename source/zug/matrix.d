module zug.matrix;

import std.array;
import std.algorithm : map;
import std.traits;
import std.range : chunks;
import std.stdio : writeln;
import std.conv : to;

///
bool do_debug()
{
    import std.process;

    if (environment.get("DEBUG") is null)
    {
        return false;
    }

    int can_debug = environment.get("DEBUG").to!int;

    if (can_debug == 0)
    {
        return false;
    }
    return true;
}

///
void dbg(T)(T[][] data, string label = "")
{
    if (do_debug)
    {
        if (label != "")
        {
            label = "\n# " ~ label;
        }
        writeln(label);
        foreach (T[] row; data)
        {
            writeln("# ", row);
        }
        writeln();
    }
}


///
void dbg(T)(T[] data, size_t width, string label = "")
{
    if (do_debug())
    {
        if (label != "")
        {
            label = "\n# " ~ label;
        }
        writeln(label);
        auto chunked = data.chunks(width);
        foreach (T[] row; chunked)
        {
            writeln("# ", row);
        }
        writeln();
    }
}

///
void dbg(T)(Matrix!T orig, string label = "")
{
    if (do_debug())
    {
        if (label != "")
        {
            label = "\n# " ~ label;
        }
        writeln(label);
        auto chunked = orig.data.chunks(orig.width);
        foreach (T[] row; chunked)
        {
            writeln("# ", row);
        }
        writeln();
    }
}

///
struct Offset
{
    size_t x;
    size_t y;
}

///
alias CoordinatesMatrix = size_t[];

///
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

    /// Matrix dice
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
    }

    ///
    Matrix!int normalize(T)(T normal_min, T normal_max) if (isNumeric!T)
    {
        import std.array;
        import std.algorithm;

        auto min = this.min;
        auto max = this.max;

        auto new_data = map!((T value) => normalize_value!(T, int)(value, min,
                max, normal_min, normal_max))(this.data[0 .. $]).array;
        return Matrix!int(new_data, this.width);
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

    ///
    Matrix!T coordinates(T)()
    if (isNumeric!T)
    {
        Matrix!T result = Matrix!T(2, this.width * this.height);

        for (size_t i = 0; i < (this.width * this.height); i++)
        {
            auto modulo = (i % this.width).to!T;
            result.set(0, i, modulo);
            result.set(1, i, ( (i - modulo) / this.width).to!T );
        }
        return result;
    }
    /// coordinates
    unittest
    {
        auto orig = Matrix!int([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], 3);
        dbg(orig, "Matrix 3x4");
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

    /// Matrix column
    unittest
    {
        Matrix!int orig = Matrix!int([1, 2, 3, 4, 5, 6, 7, 8, 9], 3);
        dbg!int(orig, "matrix for column");
        dbg!int(orig.column(1), orig.height, "column 1");
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

    /// Matrix row
    unittest
    {
        Matrix!int orig = Matrix!int([1, 2, 3, 4, 5, 6, 7, 8, 9], 3);
        dbg!int(orig, "matrix for row");
        dbg!int(orig.row(1), orig.width, "row 1");
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

    ///
    Matrix!T replace_elements(T)(bool delegate(T) filter, T delegate(T) transform)
    {
        import std.algorithm : map;

        auto result = map!((T i) {
            if (filter(i))
            {
                return transform(i);
            }
            return i;
        })(this.data[0 .. $]).array.dup;

        return Matrix(result, this.width);
    }

    /// replace_elements
    unittest
    {
        auto orig = Matrix!int([1, 0, -1, 5, 7], 5);
        auto filter = delegate bool(int i) => i < 0;
        auto transformer = delegate int(int i) => 0;
        auto result = orig.replace_elements!int(filter, transformer);
        // writeln(result);
        // [1, 0, 0, 5, 7]
        assert(result.get(0) == 1);
        assert(result.get(1) == 0);
        assert(result.get(2) == 0);
        assert(result.get(3) == 5);
        assert(result.get(4) == 7);
    }

    // TODO 
    /// stretch can only create an enlarged version of the original, else use squeeze (TODO squeeze)
    Matrix!T stretch(T)(float scale_x, float scale_y)
    in
    {
        assert(scale_x >= 1 && scale_y >= 1);
    }
    do
    {
        if (scale_x == 1 && scale_y == 1)
        {
            return this;
        }

        auto coord = this.coordinates!float();
        Matrix!float transformation_matrix = Matrix!float([scale_x, 0, 0, scale_y], 2);
        dbg(transformation_matrix, "transformation_matrix");
        auto new_coords = coord.multiply!float(transformation_matrix);
        dbg(new_coords, "new_coords");

        for (size_t i; i < new_coords.height; i++)
        {
            // result.set(0,i, )
        }

        Matrix!int placeholder = Matrix!int(6,6);
        return placeholder;
    }
    /// TODO
    unittest
    {
        
        auto orig = Matrix!int(3, 3);
        dbg(orig.coordinates!float, "old_coords");
        orig.stretch!int(2,2);

    }
}

/// Matrix instantiation
unittest
{
    auto orig = Matrix!int(
        [
            0,  1,  2, 
            3,  4,  5, 
            6,  7,  8, 
            9, 10, 11
        ], 
        3
    );

    dbg(orig, "Matrix 3x4");
    assert(orig.get(0, 0) == 0, "get 0,0");
    assert(orig.get(1, 1) == 4, "get 1,1");
    assert(orig.get(2, 2) == 8, "get 2,2");
    assert(orig.get(2, 3) == 11, "get 2,3");
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
// TODO unittest
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
    size_t max_x = orig.width  - 1;
    size_t end_x = x + distance >= max_x ? max_x : x + distance;
    
    // close to the bottom edge
    size_t max_y = orig.height - 1;
    size_t end_y = y + distance >= max_y ? max_y : y + distance;

    T[] result;
    for (size_t i = start_y; i < end_y + 1; i++) {
        for (size_t j = start_x; j < end_x + 1; j++) {
            if (i == y && j == x) {
                // don't add the element around which the window is built
                // this will allow for weighting
                continue;
            }
            // debug writeln(["orig.width": orig.width, "orig.height": orig.height, "start_x": start_x, "end_x": end_x, "start_y": start_y, "end_y": end_y, "j":j, "i":i]);
            result ~= orig.get(j,i);
        }
    }
    return result;
}

unittest
{
    Matrix!int orig = Matrix!int(8,8);
    // change one element, enable testing if it is in the right position
    orig.set(3, 3, 1);
    auto window = orig.shaper_square(4,4,1);

    dbg(window,1, "shaper_square(4,4,1)");
    assert(window.length == 8, "got 8 elements in the window");
    assert(window[0] == 1, "changed element in orig is in the expected spot");
    assert(window[1] == 0, "unchanged element in orig is in the expected spot");

    auto larger_window = orig.shaper_square(4,4,2);
    assert(larger_window.length == 24, "got 24 elements in the larger window");
    assert(larger_window[6] == 1, "changed element in orig is in the expected spot");
    assert(larger_window[7] == 0, "unchanged element in orig is in the expected spot");
    dbg(larger_window, 1, "shaper_square(4,4,2)");

    auto left_top_corner_window = orig.shaper_square(0,0,2);
    // writeln(left_top_corner_window, " length: ", left_top_corner_window.length, " left_top_corner_window");
    assert(left_top_corner_window.length == 8);

    auto bottom_right_corner_window = orig.shaper_square(7,7,2);
    // writeln(bottom_right_corner_window, " length: ", bottom_right_corner_window.length, " bottom_right_corner_window");
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
    import std.math: sqrt, round;

    // close to the left edge
    size_t start_x = x < distance ? 0 : x - distance;
    // close to the top edge
    size_t start_y = y < distance ? 0 : y - distance;
    // close to the right edge
    size_t end_x = distance + x > orig.width  ? orig.width : x + distance;
    // close to the bottom edge
    size_t end_y = distance + y > orig.height ? orig.height : y + distance;

    T[] result;
    for (size_t i = start_y; i < end_y + 1; i++) {
        for (size_t j = start_x; j < end_x + 1; j++) {
            if (i == y && j == x) {
                // don't add the element around which the window is built
                // this will allow for weighting
                continue;
            }
            real how_far = sqrt( ((x - j)*(x - j) + (y - i)*(y - i) ).to!real );
            if (round(how_far) <= distance) {
                result ~= orig.get(j,i);
            }
        }
    }
    return result;
}

unittest
{
    Matrix!int orig = Matrix!int(8,8);
    // change one element, enable testing if it is in the right position
    orig.set(3, 3, 1);
    auto window = orig.shaper_circle(4,4,2);

    dbg(window,1, "shaper_circle(4,4,2)");
    assert(window.length == 20, "got 8 elements in the window");
    assert(window[4] == 1, "changed element in orig is in the expected spot");
    assert(window[1] == 0, "unchanged element in orig is in the expected spot");
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
    import std.algorithm.iteration: sum;
    auto total = orig.get(x,y) + window.sum;
    auto count = window.length.to!T + 1;
    
    static if ( is(U == T) ) {
        return total/count;
    }
    else {
        return total.to!U/count.to!U;
    }
}
unittest 
{
    auto orig = Matrix!int(3,3);
    size_t x = 1;
    size_t y = 1;
    orig.set(x, y, 1);
    int[] window = [2, 2, 2];

    auto result = orig.moving_average_simple_calculator!(float,int)(x, y, window);
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
Matrix!U moving_average(T,U)(
    Matrix!T orig,
    size_t distance, 
    T[] function (Matrix!T, size_t, size_t, size_t) shaper,
    U function (Matrix!T, size_t, size_t, T[]) calculator
) if (isNumeric!T)
in
{
    assert(distance >= 0);
}
do
{
    auto result = Matrix!U(orig.width, orig.height);

    for (size_t y = 0; y < orig.height; y++) {
        for (size_t x = 0; x < orig.width; x++) {
            // debug writeln("x: ", x, " y:", y);
            auto window = shaper(orig, x, y, distance);
            U new_element = calculator(orig, x, y, window);
            result.set(x,y, new_element);
        }
    }

    return result;
}

unittest 
{
    size_t how_big = 64;
    auto orig = Matrix!int(random_array!int(64, 0, 255, 12341234), 8);
    dbg(orig,"====================================================");

    size_t window_size = 2;
    auto smooth = orig.moving_average!(int,int)(
        window_size, 
        &shaper_square!int, 
        &moving_average_simple_calculator!(int,int)
    );
    assert(smooth.height == orig.height);
    assert(smooth.width  == orig.width);
    dbg(smooth, "smoothed with moving average over square window");
}

///
T[] random_array(T)(size_t size, T min, T max, ulong seed) if (isNumeric!T)
{
    import std.random : Random, uniform;

    auto rnd = Random(42);
    T[] result = new T[](size);
    foreach (size_t i; 0 .. size)
    {
        result[i] = uniform(min, max, rnd);
    }
    return result;
}

/// random_array
unittest
{
    import std.range : take;
    import std.random : Random, uniform;

    auto result = random_array!int(10, 0, 15, 12341234);

    assert(result[0] == 12);
    assert(result[1] == 2);

    auto result_float = random_array!float(10, 0, 15, 12341234);
    // TODO figure out how to check floats, this does not work
    // writeln(result_float);
    // assert(result_float[0] == 5.6181 ); 

    size_t how_big = 64;
    auto orig = Matrix!int(random_array!int(64, 0, 255, 12341234), 8);
    
// should look like this
//      0    1    2    3    4    5    6    7
// 0 # [132, 167, 181, 199, 126, 125,  70, 164]
// 1 # [85,   38,  43, 124, 200,  39, 171,  37]
// 2 # [140,  10, 207, 106, 229, 176,  73, 206]
// 3 # [209, 208, 146, 189, 142,  79, 207, 150]
// 4 # [205, 184,  98, 229, 224, 176,   7,  90]
// 5 # [221,  12,  97,  69, 237,   8, 218, 199]
// 6 # [243,   2, 195,  54,  85, 189,  61, 169]
// 7 # [250, 179, 158, 243, 101,   0,  95, 250]
    assert(orig.get(0,0) == 132);
    assert(orig.get(1,1) ==  38);
    assert(orig.get(1,3) == 208);
    assert(orig.get(3,1) == 124);
    assert(orig.get(3,3) == 189);
    assert(orig.get(3,5) ==  69);
    assert(orig.get(3,7) == 243);
    assert(orig.get(5,5) ==   8);
}

///
Matrix!T multiply(T)(Matrix!T first, Matrix!T second)
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

/*

// dfmt off
int[] data = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0,
    0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0,
    0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0,
    0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0,
    0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0,
    0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0,
    0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
    0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0,
    0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0,
    0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0,
    0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
];
// dfmt on

*/

/*

export function stretch(orig, new_width, new_height) {
    const height = orig.length
    const spacing = (new_height - 1)/( height - 1 )
    const stretched_coordinates = Array.from(
        Array(height),
        (value, i) => (i * spacing)
    )
    // deal with floating point weirdnesses, make sure the last value is what
    //   it should be; problems happen when the initial matrix has one size 40
    stretched_coordinates[stretched_coordinates.length - 1] = new_height - 1

    let orig_coordinates = 0
    let next_coordinates = stretched_coordinates[orig_coordinates]
    // let prev_coordinates = 0
    const sparse = Array.from(
        Array(new_height),
        function(undef, i) {
            if (
                next_coordinates - i <= (next_coordinates % 1) // less than the fractional part
            ) {
                const stretched_row = stretch_row(orig[orig_coordinates], new_width)
                // prev_coordinates = next_coordinates
                orig_coordinates += 1
                next_coordinates = stretched_coordinates[orig_coordinates]
                return stretched_row
            } else {
                return Array.from(
                    Array(new_width),
                    () => null
                )
            }
        }
    )

    const stretched = Array.from(
        sparse,
        (row, y) => Array.from(
            row,
            function(cell, x) {
                if (cell === null ) {
                    return evaluate_neighbours(sparse, x, y)
                } else {
                    return cell
                }
            }
        )
    )

    return stretched
}

function evaluate_neighbours(matrix, x, y) {

    if (x !== parseInt(x)) { throw new Error("x is not an integer") }
    if (y !== parseInt(y)) { throw new Error("y is not an integer") }

    let top_value = 0
    let bottom_value = 0
    // we're in the top or bottom row:
    //   that is wrong, the algorithm keeps the original
    //   data for the borders on the new borders so it should not happen
    if (typeof(matrix[y - 1]) === "undefined") {
        console.error({ "length":matrix.length, "x": x, "y":y })
        // console.error(matrix)
        throw new Error("we're in the top row - , there should be no undefined value here")
    }

    if ( typeof(matrix[y + 1]) === "undefined") {
        console.error({ "length":matrix.length, "x": x, "y":y })
        // console.error(matrix)
        throw new Error("we're in the top row +, there should be no undefined value here")
    }

    let top = 1 // distance to the first not null row
    while (top < matrix.length) {
        if (matrix[y - top ][x] !== null) {
            top_value = Number(matrix[y - top ][x])
            break
        }
        top += 1
    }

    let bottom = 1
    while (bottom < matrix.length) {
        if (matrix[y + bottom][x] !== null) {
            bottom_value = Number(matrix[y + bottom][x])
            if (isNaN(bottom_value)) {
                console.error({
                    y: y,
                    bottom: bottom,
                    x: x,
                    wrong: matrix[y + bottom][x],
                    length: matrix[0].length,
                    height: matrix.length
                })
                throw new Error("bottom value isNaN, something is very wrong")
            }
            break
        }
        bottom += 1
    }

    const slope = (bottom_value - top_value)/(top + bottom)
    const value = top_value + slope * (top)
    if ( isNaN(value) ) {
        console.error({
            top_value: top_value,
            top: top,
            bottom: bottom,
            bottom_value: bottom_value,
            slope: slope,
            value: value
        })
        throw new Error("got a NaN result, something is very wrong")
    }
    return value
}


export function stretch_row(orig, new_size) {

    const spacing = (new_size - 1)/( orig.length - 1 )
    const stretched_coordinates = Array.from(
        Array(orig.length),
        (value,i) => (i * spacing)
    )

    // deal with floating point weirdnesses, make sure the last value is what
    //   it should be; problems happen when the initial matrix has one size 40
    stretched_coordinates[stretched_coordinates.length -1] = new_size - 1

    let orig_coordinates = 0
    let next_coordinates = stretched_coordinates[orig_coordinates]
    let prev_coordinates = 0
    const stretched = Array.from(
        Array(new_size),
        function(undef, i) {

            if (
                // less than the fractional part
                next_coordinates - i <= (next_coordinates % 1)
            ) {
                const value = orig[orig_coordinates]
                prev_coordinates = next_coordinates
                orig_coordinates += 1
                next_coordinates = stretched_coordinates[orig_coordinates]
                return value
            } else {
                const slope =
                    Number(orig[orig_coordinates] - orig[orig_coordinates - 1])
                    /
                    Number(next_coordinates - prev_coordinates)

                if(isNaN(slope)) {
                    console.error("xxx slope is NaN", i, orig_coordinates, orig)
                    throw new Error("something very wrong: slope is NaN")

                }

                const value =  Number(orig[orig_coordinates - 1])
                    + Number( slope * (i - prev_coordinates) )

                if(isNaN(value)) {
                    console.error("yyy isNaN", i, slope, orig[orig_coordinates - 1], prev_coordinates, orig)
                    throw new Error("something very wrong: value is NaN")
                }
                return value
            }
        }
    )
    return stretched
}


export function enlarge(orig, new_width, new_height) {
    const height = orig.length
    const spacing = (new_height - 1)/( height - 1 )
    const stretched_coordinates = Array.from(
        Array(height),
        (value, i) => (i * spacing)
    )

    let orig_coordinates = 0
    let next_coordinates = stretched_coordinates[orig_coordinates]
    // let prev_coordinates = 0
    const sparse = Array.from(
        Array(new_height),
        function(undef, i) {
            if (
                next_coordinates - i <= (next_coordinates % 1) // less than the fractional part
            ) {
                const stretched_row = stretch_row(orig[orig_coordinates], new_width)
                // prev_coordinates = next_coordinates
                orig_coordinates += 1
                next_coordinates = stretched_coordinates[orig_coordinates]
                return stretched_row
            } else {
                return Array.from(
                    Array(new_width),
                    () => null
                )
            }
        }
    )

    const stretched = Array.from(
        sparse,
        (row, y) => Array.from(
            sparse[y],
            function(cell, x) {
                if (cell === null ) {
                    return evaluate_neighbours(sparse, x, y)
                } else {
                    return cell
                }
            }
        )
    )

    return stretched
}

*/


private T[] sample_2d_array(T)() if (isNumeric!T) 
{
    // dfmt off
    T[] data = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0,
        0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0,
        0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0,
        0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0,
        0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0,
        0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0,
        0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
        0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0,
        0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0,
        0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0,
        0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    ];
    // dfmt on
    return data;
}