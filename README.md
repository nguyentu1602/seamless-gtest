# seamless-gtest
Example of how to seamlessly incorporate Google C++ Gtest framework to your day-to-day TDD

        I recently checked out Google Gtest framework at https://code.google.com/p/googletest/wiki/AdvancedGuide and like its flexibility a lot.
By giving users the option to fuse the Gtest source files into just one header and one source, the authors ultimately make Gtest very portable.
However, to incoporate Gtest effectively into a C++ project under test-driven-development (TDD) was not exactly straightforward to me at first.
My objective is to use GNU make to enable smooth TDD with Gtest; hence I come up with a couple of requirements that must be fulfilled when I setup the workflow:

   1. All tests get compiled with a single command (e.g. 'make test')
   2. All tests or any individual test could be run with a single command (e.g. 'make runtest')
   3. New test cases get pickup automatically in the build process and require no change of the Makefile

As you can see, it's all about preserving your precious keystrokes to make TDD manageable with Gtest.
I will show you an example of a Makefile that help you achieve it.

I re-used the examples that Gtest provided for illustration here, with some minor changes to make them compiled. Therefore, all credits regarding these source files belong to the Gtest team and all errors are mine. The Makefile follows a similar strategy used in BVLC/caffe project.

I tried my best to document all steps and made the Makefile as generic as possible, but your mileage may vary. The Makefile works on Ubuntu 14.04.1 - please feel free to suggest patches to make it more generic.