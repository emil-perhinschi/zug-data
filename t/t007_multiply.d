#!/usr/bin/env dub
/+dub.json: { "dependencies": { "zug-tap": "*", "zug-data": { "path": "../" }  } } +/

void main() {
    import zug.matrix;
    import zug.tap;

    auto tap = Tap("array_utils.d");
    tap.verbose(true);

    auto first = Matrix!int([1, 2, 3, 4, 5, 6], 3);
    auto second = Matrix!int([7, 8, 9, 10, 11, 12], 2);
    dbg(first, "xxxxx multiplied first");
    dbg(second, "multiplied second");
    auto result = multiply!int(first, second);
    dbg(result, "multiplied result");

    tap.ok(result.get(0, 0) == 58);
    tap.ok(result.get(1, 0) == 64);
    tap.ok(result.get(0, 1) == 139);
    tap.ok(result.get(1, 1) == 154);

    tap.done_testing();
}