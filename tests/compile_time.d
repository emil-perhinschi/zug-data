module tests.compile_time;

import zug.matrix.dbg;

struct Matrix(T, size_t init_height, size_t init_width)
{

    immutable T[ init_height * init_width] data;
    immutable size_t height = init_height;
    immutable size_t width  = init_width;

    this(T default_value) {
        this.data = default_value;
    }
}

void main() {
    import std.stdio: writeln;
    import std.traits: isStaticArray;

    auto orig = Matrix!(int, 4, 4)(1);
    writeln(orig.data, " immutables");
    static assert(__traits(isStaticArray, orig.data), "array is static");
}
