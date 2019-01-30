module tests.convert;

// TODO finish this
bool to_png() {
    
    import arsd.png;

    // void writePng(string filename, const ubyte[] data, int width, int height, PngType type, ubyte depth = 8)

    const ubyte[] data = [
        255, 50, 100, 150,
        255, 50, 100, 150,
        255, 50, 100, 150,
        255, 50, 100, 150,
    ];

    writePng("/tmp/bla.png", data, 4, 4, PngType.greyscale);

    const ubyte[] data_truecolor = [
        100, 0, 0,  0, 100, 100,  0, 0, 200,  0, 255, 0,
        100, 0, 0,  0, 100, 100,  0, 0, 200,  0, 255, 0,
        100, 0, 0,  0, 100, 100,  0, 0, 200,  0, 255, 0,
        100, 0, 0,  0, 100, 100,  0, 0, 200,  0, 255, 0,
    ];

    writePng("/tmp/truecolor_bla.png", data_truecolor, 4, 4, PngType.truecolor);

    return true;
}

unittest 
{
    assert(to_png(), "random png");
}