module zug.dumper;

import std.stdio;
import std.conv;
import std.array;
import std.process;

string dumper(string[string][] all_rows) {
    string[] result;
   
    foreach (string[string] row_data; all_rows) {
	 result ~= dumper(row_data);
    }
    return result.join(",\n");
}

string dumper(string[string] data) {
    string[] result;
    foreach (string key; data.keys) {
        result ~= "  \"" ~ key ~ "\" => " ~ "\"" ~ data[key] ~ "\"";
    }    
    
    return "{\n" ~ result.join(",\n") ~ "\n}";
}


// TODO: this dumps the names but not the types, instead puts "string" 
void dumper(T)(T[] array_of_structs) {
    foreach (T item; array_of_structs) {
        auto members = __traits(allMembers, typeof(item));
        foreach (member; members) {
            stderr.writefln("%s %s", typeof(member).stringof, member );
        }
    }
}


// http://forum.dlang.org/post/gqqpl2$1ujg$1@digitalmars.com
string dumper(T)(T obj, uint depth = 0) 
if ( is(T == struct) || is(T == class) ) 
{
    import std.format: format;

    string result = "";
    result ~= T.stringof ~ ": {\n";

    foreach(i,_;obj.tupleof) {
        auto element = obj.tupleof[i];
        auto element_type = typeid(element);
        writeln("+++++", element_type);
        if (is(element_type == struct)) {
            writeln("is struct");
        }

        if (is(element_type == class)) {
            writeln("is class");
        }
        result ~= format!"  (%s) %s : %s,\n"(
                element_type, 
                obj.tupleof[i].stringof[4..$], 
                obj.tupleof[i]
            );

        // writeln("# ", element_type);
        // writefln("  (%s) %s : %s,", 
        //     element_type, 
        //     obj.tupleof[i].stringof[4..$], 
        //     obj.tupleof[i]
        // );
    }
    result ~= "}";

    return result;
}

// TODO: is it possible to make this a template ? 
void warn(string message)
{
    stderr.writeln(message);    
}

// I need a better name, D2 took "debug", but their debug is not what I need my
//    "debug" for 
void write_debug(string message)
{
    if (env_debug_enabled()) {
        stderr.writeln("DEBUG: " ~ message);
    }
}

bool env_debug_enabled() {
    string do_debug = std.process.environment.get("DEBUG");
    if (do_debug != "0" && do_debug > "") {
        return true;
    }
    return false;
}
