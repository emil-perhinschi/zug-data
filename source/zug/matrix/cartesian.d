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
    }

    ///
    this(size_t width, size_t height, size_t center_x, size_t center_y)
    {
        this.matrix = Matrix!T(width, height);
    }

    //TODO adjust for cartesian coordinates
    // Matrix!T window(T)(Offset offset, size_t window_size,  T delegate(size_t, size_t) fill)
    //         if (isNumeric!T)
    Matrix!T window(size_t start_x, size_t start_y, size_t width, size_t height) 
    {
        return 
    }
    
    ///TODO adjust for cartesian coordinates
    T get(size_t x, size_t y)
    {
        return this.data[this.width * y + x];
    }
}


unittest {
    auto cartesian_matrix = CartesianMatrix!int(40, 40, 20,20);

}