#! /usr/bin/env dub
/+dub.json: { "dependencies": { "zug-tap": "0.1.1", "zug-data": { "path": "../" }  } } +/

void main() {
    import std.range : take;
    import std.random : Random, uniform;

    import zug.tap;
    import zug.matrix;

    auto tap = Tap("t001_generic.d");
    tap.verbose(true);
    tap.plan(17);

    /// get
    {
        Matrix!int orig = Matrix!int (3, 3);
        orig.set(0, 0, 1);
        tap.ok(orig.get(0, 0) == orig.get(0));
        orig.set(1, 1, 111);
        tap.ok(orig.get(1, 1) == orig.get(4));
    }
    /// homogenous_coordinates
    {
        auto orig = Matrix!int ([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], 3);
        dbg(orig, "Matrix 3x4 orig, testing coordinates");
        auto coord = orig.homogenous_coordinates!size_t ();
        dbg(coord, "homogenous coordinates");

    }

    /// coordinates
    {
        auto orig = Matrix!int ([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], 3);
        dbg(orig, "Matrix 3x4 orig, testing coordinates");
        auto coord = orig.coordinates!size_t ();
        dbg(coord, "coordinates");

    }

    /// get column
    {
        Matrix!int orig = Matrix!int ([1, 2, 3, 4, 5, 6, 7, 8, 9], 3);
        dbg!int (orig, "matrix for column");
        dbg!int (orig.column(1), orig.height, "column 1");
    }

    // set column
    {
        import std.algorithm.comparison : equal;

        auto orig = Matrix!int (5, 5);
        int[] column = [5, 5, 5, 5, 5];
        orig.column(column, 2);
        dbg(orig, "column set");
        auto check = orig.column(2);
        tap.ok(check.equal(column));
    }

    /// get Matrix row
    {
        Matrix!int orig = Matrix!int ([1, 2, 3, 4, 5, 6, 7, 8, 9], 3);
        dbg!int (orig, "matrix for row");
        dbg!int (orig.row(1), orig.width, "row 1");
    }

    {
        import std.algorithm.comparison : equal;

        auto orig = Matrix!int (5, 5);
        int[] row = [5, 5, 5, 5, 5];
        orig.row(row, 2);
        dbg(orig, "row set");
        auto check = orig.row(2);
        tap.ok(check.equal(row));
    }

    /// is_on_edge
    {
        auto orig = Matrix!int (10, 10);
        tap.ok(orig.is_on_edge(0, 0, 1) == true);
        tap.ok(orig.is_on_edge(2, 2, 3) == true);
    }

    /// window
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

        Matrix!float orig = Matrix!float (data, 7);
        auto r1 = orig.window!float(Offset(0, 0), 4, 4, delegate(size_t x, size_t y) => 0);
        debug dbg(r1, "Matrix.window");
        debug dbg(orig.window!float (Offset(0, 0), 4, 4, delegate(size_t x,
            size_t y) => 0), "Matrix.window");
        debug dbg(orig.window!float (Offset(0, 0), 4, 4, delegate(size_t x,
            size_t y) => 0), "Matrix.window");
        debug dbg(orig.window!float (Offset(0, 0), 4, 4, delegate(size_t x,
            size_t y) => 0), "Matrix.window");
    }

    /// copy
    {
        auto orig = Matrix!float ([0, 1, 2, 3, 4, 5], 3);
        auto copy = orig.copy();
        dbg(copy, "copy before modified");

        for (size_t i = 0; i < orig.data_length; i++) {
            tap.ok(orig.get(i) == copy.get(i));
        }

        copy.set(0, 0, 1000);
        dbg(copy, "copy modified");
        dbg(orig, "copy orig");

        tap.ok(orig.get(0, 0) != copy.get(0, 0));
    }

    /// Matrix instantiation
    {
        auto orig = Matrix!int ([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], 3);

        dbg(orig, "Matrix 3x4, testing instatiation");
        tap.ok(orig.get(0, 0) == 0, "get 0,0");
        tap.ok(orig.get(1, 1) == 4, "get 1,1");
        tap.ok(orig.get(2, 2) == 8, "get 2,2");
        tap.ok(orig.get(2, 3) == 11, "get 2,3");
    }

    tap.done_testing();
}
