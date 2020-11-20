module zug.matrix.generic;

import std.array;
import std.algorithm : map;
import std.traits;
import std.conv : to;

import zug.matrix;

version (unittest) {
    import std.stdio : writeln;
}

///
struct Offset {
    size_t x;
    size_t y;
}

// TODO: functions which give info about the matrix or modify the matrix should stay in the class as methods
// TODO: functions which create new stuff based on the matrix should stay out and be called via UFCS

/**
 *
 *
 */

struct Matrix(T) // TODO testing generic matrices (should I call them symbolic matrices ? )
// if (isNumeric!T)
//
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
    this(size_t width, size_t height) {
        this.data = new T[] (width * height);
        this.width = width;
        this.height = height;
    }

    ///
    void set(size_t index, T value) {
        this.data[index] = value;
    }

    ///
    void set(size_t x, size_t y, T value) {
        this.data[this.width * y + x] = value;
    }

    ///
    T get(size_t index) {
        return this.data[index];
    }

    ///
    T get(size_t x, size_t y) {
        return this.data[this.width * y + x];
    }

    ///
    size_t data_length() {
        return this.data.length;
    }

    // https://en.wikipedia.org/wiki/Scaling_(geometry)#Using_homogeneous_coordinates
    // https://www.tomdalling.com/blog/modern-opengl/explaining-homogenous-coordinates-and-projective-geometry/
    Matrix!T homogenous_coordinates(T)() if (isNumeric!T) {
        Matrix!T result = Matrix!T(3, this.width * this.height);

        for (size_t i = 0; i < (this.width * this.height); i++) {
            auto modulo = (i % this.width).to!T;
            result.set(0, i, modulo);
            result.set(1, i, ((i - modulo) / this.width).to!T);
            result.set(2, i, 1);
        }
        return result;
    }

    ///
    Matrix!T coordinates(T)() if (isNumeric!T) {
        Matrix!T result = Matrix!T(2, this.width * this.height);

        for (size_t i = 0; i < (this.width * this.height); i++) {
            auto modulo = (i % this.width).to!T;
            result.set(0, i, modulo);
            result.set(1, i, ((i - modulo) / this.width).to!T);
        }
        return result;
    }

    ///
    T[] column(size_t x) {
        T[] result = new T[] (this.height);
        foreach (size_t i; 0 .. this.height) {
            result[i] = this.get(x, i);
        }
        return result;
    }

    /// set column
    void column(T[] new_column, size_t x) {
        for (size_t i = 0; i < this.height; i++) {
            this.set(i * this.width + x, new_column[i]);
        }
    }

    ///
    T[] row(size_t y) {
        T[] result = new T[] (this.width);
        foreach (size_t i; 0 .. this.width) {
            result[i] = this.get(i, y);
        }
        return result;
    }

    /// set row
    void row(T[] new_row, size_t y) {
        size_t first_id = y * width;
        size_t last_id = first_id + width;
        this.data[first_id .. last_id] = new_row;
    }

    ///
    bool is_on_edge(size_t x, size_t y, size_t distance) {
        if (x < distance || y < distance || x >= (this.width - distance)
            || y >= (this.height - distance)) {
            return true;
        }
        return false;
    }

    /// fill: fill is for adding in missing data if the window is outside the matrix
    /// window_size: makes a square window
    /// TODO: make rectangular windows, maybe switch to window_size_x, window_size_y ?
    Matrix!T window(T)(Offset offset, size_t width, size_t height, T delegate(size_t, size_t) fill)
    if (isNumeric!T) {
        import std.range : chunks, join;

        immutable auto offset_x_orig = offset.x;

        auto chunked = this.data.chunks(this.width);
        T[][] result = new T[][] (width, height);

        for (int y = 0; y < height; y++) {
            offset.x = offset_x_orig;
            for (int x = 0; x < width; x++) {
                if (offset.x < 0 || offset.y < 0 || offset.x > this.width - 1
                    || offset.y > this.height - 1) {
                    result[y][x] = fill(offset.x, offset.y);
                } else {
                    result[y][x] = chunked[offset.y][offset.x];
                }
                offset.x++;
            }
            offset.y++;
        }
        return Matrix!T(result.join(), width);
    }

    Matrix!T copy() {
        return Matrix!T(this.data.dup, this.width);
    }
}

/*
  Notes: the numbers in the transformation matrix are not about how many rows and
  columns will the new matrix have after interpolation, instead are relevant only
  for each vector describing the coordinates of each pixel

  if I want to grow the image by 1.5 horizontally I need to find out how many columns
  the new image will have, remove 1 because indices are indexed at zero, and those are
  the x coordinates of the last row, and based on the original coordinates of the last
  row I should find the scaling number which should go into the transformation matrix
  in the X position
 */
// TODO generic interpolation function
Matrix!T scale_bilinear(T)(
        Matrix!T orig, double scale_x, double scale_y,
        T delegate(T, T, size_t) interpolate) {
    import std.math : round;

    auto coordinates = orig.coordinates!double ();
    auto scaled_coordinates = scale_coordinates!T(coordinates, orig.width,
            orig.height, scale_x, scale_y);

    size_t new_width = round(orig.width.to!double * scale_x).to!size_t;
    size_t new_height = round(orig.height.to!double * scale_x).to!size_t;

    auto result = Matrix!T(new_width, new_height);

    for (size_t i = 0; i < scaled_coordinates.height; i++) {
        // the old coordinates were kept as doubles to allow scaling by fractional numbers
        //     now we need to return them to size_t
        size_t old_x = coordinates.get(0, i).to!size_t;
        size_t old_y = coordinates.get(1, i).to!size_t;

        size_t new_x = round(scaled_coordinates.get(0, i)).to!size_t;
        size_t new_y = round(scaled_coordinates.get(1, i)).to!size_t;

        auto old_value = orig.get(old_x, old_y);
        result.set(new_x, new_y, old_value);
    }

    return result;
}

// unittest
// {
//     import std.math : isNaN;

//     auto orig = Matrix!double([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], 4);
//     auto result = orig.scale(1.5, 1.5);
//     dbg(result, "orig scaled the linear algebra way");
//     assert(result.get(0, 0) == 1);
//     assert(isNaN(result.get(1, 1)));
//     assert(result.get(2, 2) == 1);
//     assert(isNaN(result.get(4, 4)));
// }

/**
 * scale_coordinates returns a 2D Matrix!double with the coordinates of each point in the original matrix
 *   put in the position
 */
Matrix!size_t scale_coordinates(T)(Matrix!T coordinates, size_t width,
        size_t height, double scale_x, double scale_y) if (isNumeric!T)
    in {
        // width of two, that is x and y
        assert(coordinates.width == 2);
        // height of the coordinates matrix is equal to the total number of elements in the original
        assert(coordinates.height == width * height);
    }
do
{
    import std.math : round;

    // very detailed steps because I keep forgetting this and revert to thinking in
    //   scaling images instead of thinking in terms of vectors

    immutable double orig_width = width.to!double;
    immutable double orig_height = height.to!double;

    immutable double new_width = round(orig_width * scale_x);
    immutable double new_height = round(orig_height * scale_y);

    immutable double orig_max_x_index = orig_width - 1;
    immutable double orig_max_y_index = orig_height - 1;

    immutable double new_max_x_index = new_width - 1;
    immutable double new_max_y_index = new_height - 1;

    immutable double vector_scale_x = new_max_x_index / orig_max_x_index;
    immutable double vector_scale_y = new_max_y_index / orig_max_y_index;

    Matrix!double trans_m = Matrix!double ([vector_scale_x, 0, 0, vector_scale_y], 2);

    return coordinates.multiply(trans_m).round_elements!(T, size_t)();
}
// TODO unittest for scale_coordinates


char[] to_greyscale_bitmap(T)(Matrix!T orig) {
    import std.conv : to;
    import std.stdio : writeln;
    char[] result;
    char alpha = 0;
    foreach (T value; orig.data) {
        // writeln([ value, value, value, alpha ]);
        result ~= [value.to!char, value.to!char, value.to!char];
    }

    return result;
}