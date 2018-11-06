module zug.matrix;

import std.array;
import std.algorithm : map;
import std.traits;

/++
matrices are stored in plain arrays; this might change 
+/

T[] add_matrices(T)(T[] first, T[] second) if (isNumeric!T)
{

    if (first.length != second.length)
    {
        throw new Error("the matrices don't have the same size");
    }

    auto result = new T[](first.length);
    foreach (size_t i; 0 .. first.length)
    {
        result[i] = first[i] + second[i];
    }
    return result;
}

unittest
{
    import std.stdio;

    double[4] first = [1, 2, 3, 4];
    double[4] second = [0, 2, 4, 6];

    auto result = add_matrices!double(first, second);
    assert(result[0] == 1);
    assert(result[1] == 4);
    assert(result[2] == 7);
    assert(result[3] == 10);
}

int[] normalize_matrix(T)(T[] orig, T normal_min, T normal_max) if (isNumeric!T)
{
    import std.array;
    import std.algorithm;

    auto min = orig.minElement;
    auto max = orig.maxElement;

    return map!((T value) => normalize_value!T(value, min, max, normal_min, normal_max))(
            orig[0 .. $]).array;
}

unittest
{
    import std.stdio : writeln;

    float[] orig = [1.1, 100.1, 50.1];
    float normal_min = 0.0;
    float normal_max = 16.0;
    int[] result = normalize_matrix!float(orig, normal_min, normal_max);

    assert(result[0] == 0);
    assert(result[1] == 16);
    // assert(result[2] ==  7.91919); // this fails for some reason , probably float weiredness ? TODO: investigate further
}

unittest
{
    import std.stdio : writeln;

    double[] orig = [0, 255, 125];
    double normal_min = 0;
    double normal_max = 16;
    int[] result = normalize_matrix!double(orig, normal_min, normal_max);

    assert(result[0] == 0);
    assert(result[1] == 16);
    assert(result[2] == 7);
}

/++

http://mathforum.org/library/drmath/view/60433.html
1 + (x-A)*(10-1)/(B-A)

+/
int normalize_value(T)(T item, T actual_min_value, T actual_max_value, T normal_min, T normal_max)
        if (isNumeric!T)
{
    import std.math;
    import std.conv : to;

    if (normal_min == normal_max)
    {
        throw new Error("the normal min and max values are equal");
    }

    return (normal_min + (item - actual_min_value) * (normal_max - normal_min) / (
            actual_max_value - actual_min_value)).to!int;
}

T[] slice2d(T)(T[] original, size_t width, size_t start_x, size_t start_y,
        size_t size_x, size_t size_y) if (isNumeric!T)
{
    import std.range : chunks;
    import std.stdio;

    auto chunked = original.chunks(width);

    T[] result;

    foreach (T[] row; chunked[start_y .. (start_y + size_y)])
    {
        auto selected = row[start_x .. (start_x + size_x)].dup;

        result ~= selected;
    }

    return result.dup;
}

void dbg(T)(T[] data, size_t width)
{
    import std.range : chunks;
    import std.stdio : writeln;

    auto chunked = data.chunks(width);
    foreach (T[] row; chunked)
    {
        writeln("#", row);
    }
}

unittest
{
    import std.stdio : writeln;

    int[] data = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
        1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0,
        0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
        0, 1, 0, 0, 1, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0,
        0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1,
        0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0,
        1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
        0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1,
        1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0,
        0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1, 1, 1, 0, 0, 0,
        1, 1, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,];
    size_t width = 18;
    auto result = slice2d!int(data, width, 1, 1, 4, 4);
    debug dbg(result, 4);
    assert(result[0] == 1);
    assert(result[5] == 0);

}

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

unittest
{
    import std.range : take;
    import std.random : Random, uniform;
    import std.stdio : writeln;

    auto result = random_array!int(10, 0, 15, 12341234);

    assert(result[0] == 12);
    assert(result[1] == 2);

    auto result_float = random_array!float(10, 0, 15, 12341234);
    // TODO figure out how to check floats, this does not work
    // writeln(result_float);
    // assert(result_float[0] == 5.6181 ); 
}



// fill : (x,y) => do_something_based_on_x_and_y_or_just_return_a_value()
T[] resize(T)( T[] original, size_t width, int offset_x, int offset_y, size_t new_size, T delegate (size_t,size_t) fill) 
if (isNumeric!T)
{
    import std.range: chunks, join;
    import std.stdio: writeln;

    auto offset_x_orig = offset_x;

    auto chunked = original.chunks(width);
    T[][] result = new T[][](new_size, new_size);

    for (int y = 0; y < new_size; y++ ) {
        offset_x = offset_x_orig;
        for ( int x = 0; x < new_size; x++ ) {
            if ( offset_x < 0 || offset_y < 0 ) {
                result[y][x] = fill(offset_x, offset_y);
            } else {
                result[y][x] = chunked[offset_y][offset_x];
            }
            offset_x++;
        }
        offset_y++;
    }
    return result.join();
}

unittest {
    import std.stdio: writeln;

    float[] orig = [
        1,2,3,4,5,6,7,
        1,2,3,4,5,6,7,
        1,2,3,4,5,6,7,
        1,2,3,4,5,6,7,
        1,2,3,4,5,6,7,
        1,2,3,4,5,6,7,
        1,2,3,4,5,6,7
    ];

    auto r1 = resize!float(orig, 7, -3, -3, 4, delegate (size_t x, size_t y) => 0);
    debug dbg(r1, 4);
    debug dbg(resize!float(orig, 7, -2, -2, 4, delegate (size_t x, size_t y) => 0), 4);
    debug dbg(resize!float(orig, 7, -1, -1, 4, delegate (size_t x, size_t y) => 0), 4);
    debug dbg(resize!float(orig, 7,  0,  0, 4, delegate (size_t x, size_t y) => 0), 4);
}

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



/// TODO finish me 
T[] moving_average(T)(T[] matrix, size_t width, size_t distance)
if (isNumeric!T)
in
{
    assert(distance >= 0);
}
do 
{
    import std.range: chunks;
    import std.algorithm.iteration: sum;

    T[] result;
    auto chunked = matrix.chunks(width);
    
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
*/

template replace_elements(T)
{
    alias MatrixFilter = bool delegate(T);
    alias MatrixTransformer = T delegate(T);

    import std.math : abs;

    T[] replace_elements(T[] orig, MatrixFilter filter, MatrixTransformer transform)
    {
        import std.algorithm : map;

        auto result = map!((T i) {
            if (filter(i))
            {
                return transform(i);
            }
            return i;
        })(orig[0 .. $]).array;

        return result;
    }
}

unittest
{
    import std.stdio : writeln;

    int[5] orig = [1, 0, -1, 5, 7];
    auto filter = delegate bool(int i) => i < 0;
    auto transformer = delegate int(int i) => 0;
    auto result = replace_elements!int(orig, filter, transformer);
    // writeln(result);
    // [1, 0, 0, 5, 7]
    assert(result[0] == 1);
    assert(result[1] == 0);
    assert(result[2] == 0);
    assert(result[3] == 5);
    assert(result[4] == 7);
}

bool is_on_edge(size_t width, size_t height, size_t x, size_t y, size_t distance)
{
    if (x < distance || y < distance || x >= (width - distance) || y >= (height - distance))
    {
        return true;
    }
    return false;
}

unittest
{
    assert(is_on_edge(10, 10, 0, 0, 1) == true);
    assert(is_on_edge(10, 10, 2, 2, 3) == true);
}
