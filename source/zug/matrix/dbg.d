module zug.matrix.dbg;

import std.conv : to;
import zug.matrix.basic;
import std.stdio: writeln;
import std.range : chunks;

/** 
    Debuging helpers, probably should move to another module 
*/


private bool do_debug()
{
    import std.process;

    if (environment.get("DEBUG") is null)
    {
        return false;
    }

    int can_debug = environment.get("DEBUG").to!int;

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
