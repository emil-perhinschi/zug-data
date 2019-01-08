module zug.matrix.dbg;

import std.conv : to;
import std.stdio: writeln;
import std.range : chunks;
import std.traits;

import zug.matrix.generic;

/** 
    Debuging helpers, probably should move to another module 
*/


private bool do_debug()
{
    import std.process: environment;

    if (environment.get("DEBUG") is null)
    {
        return false;
    }

    immutable int can_debug = environment.get("DEBUG").to!int;

    if (can_debug == 0)
    {
        return false;
    }
    return true;
}

///
void dbg(T)(T[][] data, string label = "")
{
    if (do_debug)
    {
        if (label != "")
        {
            label = "\n# " ~ label;
        }
        writeln(label);
        foreach (T[] row; data)
        {
            writeln("# ", row);
        }
        writeln();
    }
}

///
void dbg(T)(T[] data, size_t width, string label = "")
{
    if (do_debug())
    {
        if (label != "")
        {
            label = "\n# " ~ label;
        }
        writeln(label);
        auto chunked = data.chunks(width);
        foreach (T[] row; chunked)
        {
            writeln("# ", row);
        }
        writeln();
    }
}

///
void dbg(T)(Matrix!T orig, string label = "")
{
    if (do_debug())
    {
        if (label != "")
        {
            label = "\n# " ~ label;
        }
        writeln(label);
        auto chunked = orig.data.chunks(orig.width);
        foreach (T[] row; chunked)
        {
            writeln("# ", row);
        }
        writeln();
    }
}


T[] sample_2d_array(T)() if (isNumeric!T)
{
    // dfmt off
    T[] data = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0,
        0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0,
        0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0,
        0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0,
        0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0,
        0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0,
        0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
        0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0,
        0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0,
        0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0,
        0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    ];
    // dfmt on
    return data;
}

