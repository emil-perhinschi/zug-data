#! /usr/bin/env dub
/+dub.json: { "dependencies": { "zug-tap": "*", "zug-data": { "path": "../" }  } } +/

void main() {
    import std.range : array, iota;
    import std.stdio : writeln;

    import zug.tap;
    import zug.matrix;

    auto tap = Tap("cartesian.d");
    tap.verbose(true);
    tap.plan(2);

    int[] data = array(iota(1600));
    auto cartesian_matrix = CartesianMatrix!int (data, 40, 20, 20);

    auto got_data = cartesian_matrix.data();
    tap.ok(cartesian_matrix.get(0, 0) == cartesian_matrix.data.get(20, 20));

    auto viewport = cartesian_matrix.window(CartesianCoordinates(5, 5), 5, 5);
    dbg(viewport, "cartesian viewport");
    auto viewport_corner = cartesian_matrix.get(5, 5);
    tap.ok(viewport.get(0, 0) == cartesian_matrix.get(5, 5));

    tap.done_testing();
}

