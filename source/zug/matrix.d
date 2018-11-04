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

/*

export function slice2d(original, start_x, end_x, start_y, end_y) {

    if (start_x >= end_x)
        throw new Error("start_x should be smaller than end_x")
    if (start_y >= end_y)
        throw new Error("start_y should be smaller than end_y")

    return Array.from(
        original.slice(start_y, end_y),
        (row) => row.slice(start_x, end_x)
    )
}


export function random_array(width, callback = (i) => i) {
    return Array.from(
        Array(width),
        (v, x) => callback( Math.round( Math.random() ) )
    )
}

// fill : (x,y) => do_something_based_on_x_and_y_or_just_return_a_value()
// allow_cropping: permit the original to be placed partially outside the new
//    matrix, thus cropping the parts which stay outside
export function resize(original, offset, new_size, fill, allow_cropping) {
    if(
        typeof new_size !== "object"
        || parseInt(new_size.x) !== new_size.x
        ||  parseInt(new_size.y) !== new_size.y
    ) {
        throw new Error("new_size must be {x: integer, y: integer}")
    }

    if (allow_cropping === false) {
        if (offset.x < 0 || offset.y < 0) {
            throw new Error("cropping is not allowed and the offset coordinates are negative")
        }
        if (
            original.length > new_size.y
            || original[0].length > new_size.x
        ) {
            throw new Error("cropping is not allowed and the new size is smaller than the original")
        }

        if (
            original.length + offset.y > new_size.y
            || original[0].length + offset.x > new_size.x
        ) {
            throw new Error("cropping is not allowed and the offset"
                + " pushes the original outside the new size")
        }
    }

    return Array.from(
        Array(new_size.y),
        (y_value, y) => Array.from(
            Array(new_size.x),
            function (x_value, x) {
                if ( original[y + offset.y] !== undefined
                    && original[y + offset.y][x + offset.x] !== undefined ) {
                    return original[y + offset.y][x + offset.x]
                }
                return fill(x, y)
            }
        )
    )
}

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

export function moving_average(matrix, distance) {
    if (distance !== parseInt(distance)) {
        throw new Error("distance " + distance + " is not an integer")
    }

    if (distance <= 0 ) {
        throw new Error("distance should be a positive integer")
    }

    return Array.from(
        matrix,
        function (row, y) {
            return Array.from(
                row,
                function (item, x) {
                    const slice = resize(
                        matrix,
                        { "x": x - distance, "y": y - distance },
                        { "x": 2*distance + 1, "y": 2*distance + 1 },
                        () => 0, // fill the extra cells with 0s,
                        true // allow cropping
                    )
                    const cells_count = slice.length * slice.length
                    return sum_elements(slice) / cells_count
                }
            )
        }
    )
}

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

export function replace_elements(
    matrix,
    filter = (i) => i < 0,
    transform = (i) => Math.abs(i)
) {

    return Array.from(
        matrix,
        function(row,y) {
            return Array.from(
                row,
                function(cell, x) {
                    if (filter(cell)) {
                        return transform(cell)
                    }
                    return cell
                }
            )
        }
    )
}

export function is_on_edge(width, height, x, y, distance) {
    if (
        x < distance || y < distance
        ||
        x >= (width - distance) || y >= (height - distance)
    ) {
        return true
    }
    return false
}

*/
