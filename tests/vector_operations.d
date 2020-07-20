module tests.vector_operations;

void main() {
    test_loop();
    test_vector();
    test_dynamic_array();
}


void test_vector() {

    int[1_000_000] test;
    int[] result;
    result[] = test[] + 1;
}

void test_loop() {
    int[1_000_000] test;
    int[1_000_000] result;
    for (size_t i = 0; i < test.length; i++) {
        result[i] = test[i] + 1;
    }
}

void test_dynamic_array() {

    int[] test = new int[1_000_000];

    int[] result;
    result[] = test[] + 1;
}