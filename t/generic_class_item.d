#!/usr/bin/env dub
/+dub.json: { "dependencies": { "zug-tap": "*", "zug-data": { "path": "../" }  } } +/

void main() {
    import std.stdio : writeln;
    import zug.tap;
    import zug.matrix;

    auto tap = Tap("generic_class_item.d");
    tap.verbose(true);

    auto orig = Matrix!TestElement(3, 3);
    orig.set(0, 0, new TestElement());
    auto orig_0_0 = orig.get(0, 0);
    tap.ok(orig_0_0.data == "uninitialized");
    tap.ok(orig.get(1, 1) is null);
    dbg(orig, "matrix initialized with TestElement class");

    tap.done_testing();
}

class TestElement {
    bool is_initialized = false;
    string data = "uninitialized";
    this() {
    }

    this(string _data) {
        this.data = _data;
    }
}
