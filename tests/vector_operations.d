module tests.vector_operations;

void main() 
{
    test_loop();
    test_vector();
}


void test_vector() {

    int[10000000] test;
    int[] result;
    result[] = test[] + 1;
}

void test_loop() {
    int[10000000] test;
    int[10000000] result;
    for (size_t i = 0; i < 100000; i++) {
        result[i] = test[i] + 1;
    }
}
