module zug.pixmap_util;

import zug.matrix;
import zug.dumper;


ulong difference(T)(Matrix!(DataPoint!T)left, Matrix!(DataPoint!T)right) {
    import std.conv : to;
    import std.math : abs;

    assert(
            (
                left.width == right.width
                && left.height == right.height
            ),
            "matrices must have the same size");

    long result = 0;
    for (size_t i = 0; i < left.data_length; i++) {
        // using greyscale values
        long grey_left = left.get(i).to_grayscale.red.to!long;
        long grey_right = right.get(i).to_grayscale.red.to!long;
        result += (grey_left - grey_right).abs();
    }

    return result;
}


struct DataPoint(T) {
    private:
    T red;
    T green;
    T blue;
    T alpha;

    public:
    T[4] to_array() {
        return [this.red, this.green, this.blue, this.alpha];
    }
}

DataPoint!T to_average(T)(DataPoint!T point) {
    import std.algorithm.iteration : mean;

    T average = (point.red + point.green + point.blue) / 3;
    return DataPoint!T(average, average, average, point.alpha);
}


// https://www.mathworks.com/matlabcentral/answers/99136-how-do-i-convert-my-rgb-image-to-grayscale-without-using-the-image-processing-toolbox
DataPoint!ubyte to_grayscale(DataPoint!ubyte orig) {
    import std.conv : to;

    float greyscaled = 0.2989 * orig.red.to!float + 0.5870 * orig.green.to!float + 0.1140 * orig.blue.to!float;
    ubyte computed = greyscaled.to!ubyte;
    return DataPoint!ubyte (computed, computed, computed, orig.alpha);
}

/// TODO finish me: add checks that the data type makes sense in this context
char[] data_matrix_to_pixmap(P)(Matrix!P matrix) {
    import std.conv : to;
    import std.stdio: writeln;

    char[] result;
    foreach (P point; matrix.data) {
        writeln(point);
        result ~= cast(char[]) point.to_array();
    }
    return result;
}


Matrix!T to_grayscale_values(T)(Matrix!T matrix) {

    size_t width = matrix.width;
    T[] result = new T[matrix.data_length];
    for (size_t i = 0; i < matrix.data_length; i++) {
        auto old = matrix.get(i);
        result[i] = old.to_grayscale();
    }
    return Matrix!T(result, matrix.width);
}

Matrix!T to_average_values(T)(Matrix!T matrix) {

    size_t width = matrix.width;
    auto result = new T[matrix.data_length];
    for (size_t i = 0; i < matrix.data_length; i++) {
        auto old = matrix.get(i);
        result[i] = old.to_average!(ubyte)();
    }
    return Matrix!T(result, matrix.width);
}

