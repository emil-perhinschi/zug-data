module zug.matrix.cartesian;
import zug.matrix;

struct CartesianMatrix(T) {
    private Matrix!T matrix;
    private Offset center;


    this(T[] data, size_t width, Offset center_offset) {
        this.matrix = Matrix!T(data, width);
        this.center = center_offset;
    }

    this(size_t width, size_t height, Offset center_offset) {
        this.matrix = Matrix!T(width, height);
        this.center = center_offset;
    }


    ///
    this(T[] data, size_t width, size_t center_x, size_t center_y) {
        this.matrix = Matrix!T(data, width);
        this.center = Offset(center_x, center_y);
    }

    ///
    this(size_t width, size_t height, size_t center_x, size_t center_y) {
        this.matrix = Matrix!T(width, height);
        this.center = Offset(center_x, center_y);
    }

    // TODO adjust for cartesian coordinates
    // Matrix!T window(T)(Offset offset, size_t window_size,  T delegate(size_t, size_t) fill)
    //         if (isNumeric!T)
    /// TODO: allow for rectangular windows, will need to change the matrix.window function too
    Matrix!T window(Offset offset, size_t width, size_t height) {
        assert(
                (offset.x <= this.matrix.width - this.center.x)
                && (offset.y < this.matrix.height - this.center.y));

        Offset matrix_offset = Offset(this.center.x + offset.x, this.center.y + offset.y);

        return this.data.window(matrix_offset, width, height, delegate(size_t x, size_t y) => 0);
    }

    ///TODO adjust for cartesian coordinates
    T get(size_t x, size_t y) {
        assert(
                (x <= this.matrix.width - this.center.x)
                && (y < this.matrix.height - this.center.y));

        size_t matrix_x = this.center.x + x;
        size_t matrix_y = this.center.y + y;
        return this.matrix.get(matrix_x, matrix_y);
    }

    Matrix!T data() {
        return this.matrix;
    }
}
