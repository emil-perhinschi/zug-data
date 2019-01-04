module tests.generic;

import zug.matrix.generic;
import zug.matrix.dbg;
/// Testing how well the Matrix struct works with generic elements other than 
//     numbers, for example classes or structs

unittest {

    class TestElement {
        bool is_initialized = false;
        string data = "uninitialized";
        this() {}
        this(string _data) {
            this.data = _data;
        }
    }

    auto orig = Matrix!TestElement(3,3);
    orig.set(0,0, new TestElement());
    dbg(orig, "matrix initialized with TestElement class");
}