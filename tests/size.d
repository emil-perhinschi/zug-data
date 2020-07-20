void main() {
    import std.stdio;
    import zug.matrix;
    size_t x = 35000;
    size_t y = 35000;

    auto large = Matrix!int (x, y);
    writeln("matrix done, pausing, size is ", x * y);
    readln();

}
