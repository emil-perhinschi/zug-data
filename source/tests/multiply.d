module tests.multiply;

import zug.matrix;


unittest
{
    auto first = Matrix!int([1, 2, 3, 4, 5, 6], 3);
    auto second = Matrix!int([7, 8, 9, 10, 11, 12], 2);
    dbg(first, "xxxxx multiplied first");
    dbg(second, "multiplied second");
    auto result = multiply!int(first, second);
    dbg(result, "multiplied result");

    assert(result.get(0, 0) == 58);
    assert(result.get(1, 0) == 64);
    assert(result.get(0, 1) == 139);
    assert(result.get(1, 1) == 154);
}

unittest
{

    auto coordinates = Matrix!float(
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

    auto transf_matrix = Matrix!float([1.5, 0, 0, 1.5], 2);

    dbg(coordinates, "coordinates, testing multiply");
    dbg(transf_matrix, "transf_matrix, testing multiply");
    auto result = multiply!float(coordinates, transf_matrix);
    dbg(result, "multiplied result");

    auto stretched = stretch_row_coordinates(4,6);
    dbg(stretched, 1);
}


