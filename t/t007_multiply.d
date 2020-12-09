#! /usr/bin/env dub
/+dub.json: { "dependencies": { "zug-tap": "*", "zug-data": { "path": "../" }  } } +/

void main() {

    {
        import zug.matrix;
        import zug.tap;

        auto tap = Tap("t007_multiply.d");
        tap.verbose(true);

        auto first = Matrix!int ([1, 2, 3, 4, 5, 6], 3);
        auto second = Matrix!int ([7, 8, 9, 10, 11, 12], 2);
        dbg(first, "multiplied first");
        dbg(second, "multiplied second");
        auto result = multiply!int (first, second);
        dbg(result, "multiplied result");

        tap.ok(result.get(0, 0) == 58);
        tap.ok(result.get(1, 0) == 64);
        tap.ok(result.get(0, 1) == 139);
        tap.ok(result.get(1, 1) == 154);

        // dfmt off
        auto coordinates = Matrix!float (
            [
                0, 0,
                1, 0,
                2, 0,
                3, 0,
                0, 1,
                1, 1,
                2, 1,
                3, 1,
                0, 2,
                1, 2,
                2, 2,
                3, 2,
                0, 3,
                1, 3,
                2, 3,
                3, 3
            ],
            2
        );

        auto transf_matrix = Matrix!float (
            [
                1.5, 0,
                0, 1.5
            ],
            2
        );
        // dfmt on
        // dbg(coordinates, "coordinates, testing multiply");
        // dbg(transf_matrix, "transf_matrix, testing multiply");
        auto multiplied = multiply!float (coordinates, transf_matrix);
        dbg(multiplied, "multiplied result");

        double[] stretched = stretch_row_coordinates(4, 6);
        dbg(stretched, 1, "stretched");
        tap.ok(stretched[0] == 0);
        tap.ok(stretched[$ - 1] == 5);

        tap.done_testing();
    }
}
