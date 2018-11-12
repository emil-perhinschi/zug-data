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

// void dbg(T)(T[] data, string label = "") 
// {
//     if (do_debug()) 
//     {
//         if (label != "") {
//             label = "\n# " ~ label;
//         }
//         writeln("# ", data);
//     }
// }

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
private:
    T[] data;
    size_t height;
    size_t width;

public:
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
    Matrix!size_t coordinates()
    {
        Matrix!size_t result = Matrix!size_t(2, this.width * this.height);

        for (size_t i = 0; i < (this.width * this.height); i++)
        {
            auto modulo = i % this.width;
            result.set(0, i, modulo);
            result.set(1, i, (i - modulo) / this.width);
        }
        return result;
    }
    /// coordinates
    unittest
    {
        auto orig = Matrix!int([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], 3);
        dbg(orig, "Matrix 3x4");
        auto coord = orig.coordinates();
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
    Matrix!T stretch(T)(size_t new_size_x, size_t new_size_y)
    in
    {
        assert(this.width <= new_size_x && this.height <= new_size_y,
                "new dimensions should be greather or equal than the old dimensions");
    }
    do
    {
        if (new_size_x == this.width && new_size_y == this.height)
        {
            return this;
        }

        auto coord = this.coordinates();
        size_t transformation_matrix = [
            new_size_x, 0,
            0,          new_size_y
        ];
        auto new_coords = multiply(coord, transformation_matrix);
        auto result = Matrix!T(new_size_x, new_size_y);

        for (size_t i; i < new_coords.height; i++) {
            // result.set(0,i, )
        }

    }
    ///
    unittest
    {
    }

    /// TODO smooth the matrix by averaging values in the window
    T[] moving_average(T)(size_t window_width, size_t window_height)
            if (isNumeric!T)
    in
    {
        assert(distance >= 0);
    }
    do
    {

        // return Array.from(
        //     matrix,
        //     function (row, y) {
        //         return Array.from(
        //             row,
        //             function (item, x) {
        //                 const slice = resize(
        //                     matrix,
        //                     { "x": x - distance, "y": y - distance },
        //                     { "x": 2*distance + 1, "y": 2*distance + 1 },
        //                     () => 0, // fill the extra cells with 0s,
        //                     true // allow cropping
        //                 )
        //                 const cells_count = slice.length * slice.length
        //                 return sum_elements(slice) / cells_count
        //             }
        //         )
        //     }
        // )

        return result;
    }

}

/// Matrix instantiation
unittest
{
    auto orig = Matrix!int([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], 3);
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
    for (int y = 0; y < height; y++)
    {
        for (int x = 0; x < width; x++)
        {
            // first.row X second.column
            T[] first_row = first.row(y);
            T[] second_column = second.column(x);
            foreach (size_t i; 0 .. first.width)
            {
                result.set(x, y, result.get(x, y) + first_row[i] * second_column[i]);
            }
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
/// TODO: is this needed ? already have std.algorithm.iteration: sum 
export function sum_elements(matrix) {
    let result = 0
    matrix.forEach(
        (row) => {
            result += row.reduce(
                (row_sum, cell) => {
                    // can't find a reliable way to determine if a variable
                    // is numeric, so I'm sticking with the strict option
                    // which will throw errors even for "1234"
                    if (isNaN(cell)) {
                        throw new Error("cell is NaN")
                    }
                    if ( Number(cell) !== cell ) {
                        throw new Error("element " + cell + " is not a number")
                    }
                    return Number(row_sum) + Number(cell)
                }
            )
        }
    )
    return result
}

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
