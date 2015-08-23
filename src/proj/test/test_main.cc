#include "test/test_main.h"

int main(int argc, char** argv) {
  ::testing::InitGoogleTest(&argc, argv);
  // what ever initialization you need here
  // invode the test
  return RUN_ALL_TESTS();
}
