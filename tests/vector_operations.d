module tests.vector_operations;

void main() 
{
    test_loop();
    test_vector();
}


void test_vector() {

    int[1000000] test;
    int[] result;
    result[] = test[] + 1;
}

void test_loop() {
    int[1000000] test;
    int[1000000] result;
    for (size_t i = 0; i < test.length; i++) {
        result[i] = test[i] + 1;
    }
}
