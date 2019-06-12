module zug.matrix.cartesian;
import zug.matrix;

struct CartesianMatrix(T) 
{
    Matrix!T matrix;
    size_t center_x;
    size_t center_y;

    ///
    this(T[] data, size_t width, size_t center_x, size_t center_y)
    {
        this.matrix = Matrix!T(data, width);
        this.center_x = center_x;
        this.center_y = center_y;
    }

    ///
    this(size_t width, size_t height, size_t center_x, size_t center_y)
    {
        this.matrix = Matrix!T(width, height);
        this.center_x = center_x;
        this.center_y = center_y;
    }

    //TODO adjust for cartesian coordinates
    // Matrix!T window(T)(Offset offset, size_t window_size,  T delegate(size_t, size_t) fill)
    //         if (isNumeric!T)
    Matrix!T window(size_t start_x, size_t start_y, size_t width, size_t height) 
    {
        return Matrix!T(3,3); //TODO
    }
    
    ///TODO adjust for cartesian coordinates
    T get(size_t x, size_t y)
    {
        assert(
            (x <= this.matrix.width - this.center_x)
            && (y < this.matrix.height - this.center_y)
        );

        size_t matrix_x = this.center_x + x;
        size_t matrix_y = this.center_y + y;
        return this.matrix.get(matrix_x, matrix_y);
    }

    Matrix!T data() {
        return this.matrix;
    }
}


unittest {
    import std.range;
    import std.algorithm;
    int[] data = array(iota(1600));
    auto cartesian_matrix = CartesianMatrix!int(data, 40, 20,20);
    writeln(cartesian_matrix);
    auto got_data = cartesian_matrix.data();
    assert(cartesian_matrix.get(0,0) == cartesian_matrix.data.get(20,20));
}