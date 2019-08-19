#!/usr/bin/env dub
/+dub.json: { "dependencies": { "zug-tap": "*", "zug-data": { "path": "../" }  } } +/

module t.dumper;

void main()
{
    import zug.tap;
    import zug.dumper: dumper;

    auto tap = Tap("dumper.d");
    tap.verbose(true);
    tap.plan(1);

    string expected = `{
  "b" => "1",
  "a" => "1"
},
{
  "b" => "2",
  "a" => "2"
}`;

    string dumped = dumper([["a" : "1", "b" : "1"], ["a" : "2", "b" : "2"]]);
    tap.ok(expected == dumped, "dumped data looks like expected");
    tap.done_testing();

    test1();
}


void test1() 
{
    import std.json;
    import std.stdio: writeln;
    import zug.dumper: dumper;

    struct Test {
        int i = 777;
        float j = 3.555;
    }

    struct Test1 {
        int i = 888;
        Test bla = Test();
        JSONValue qewert;
    }

    auto test = Test1();

    writeln("**** ", dumper(test));
}
