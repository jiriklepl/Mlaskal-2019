# Mlaskal Framework + Skeleton

The framework contains the following folders:

- build.gcc - makefile for GNU C++
- build.vc141 - projects for Microsoft Visual Studio 2017
- build.vc142 - projects for Microsoft Visual Studio 2019
- private-src - sandbox containing skeletons of your solution
- public-cpp - C++ files of the mlaskal support library - DO NOT MODIFY
- public-tests - test files and expected results

### Assignments 1 and 2

For the first two assignments, you will submit the following files:

- du12l.lex - Flex source file for the lexical analyzer
- du12sem.hpp - C++ header file
- du12sem.cpp - C++ source file

In the private-src folder, you will find compilable and runnable skeletons of these files. You shall edit them in place - the makefile and the projects refer to this location.

For Assignment 1, you will probably leave the C++ files empty. For Assignment 2, you may use them for C++ routines called from du12l.lex - in this case, add #include "du12sem.hpp" to du12l.lex.

### Assignments 3 to 6

For the last four assignments, you will submit the following files:

- du3456l.lex - Flex source file for the lexical analyzer
- du3456g.y - Bison source file for the parser and semantic actions
- du3456sem.hpp - C++ header file
- du3456sem.cpp - C++ source file

When moving from Assignment 2 to 3, replace the skeletons du3456l.lex, du3456sem.hpp, and du3456sem.cpp by copies of your du12l.lex, du12sem.hpp, and du12sem.cpp files. After copying, change the following:

- #include "dummyg.hpp" directive in du3456l.lex to #include "du3456g.hpp".
- #include "du12sem.hpp" directive in du12sem.cpp (and in du3456l.lex, if any) to #include "du3456sem.hpp".

### The makefile

For assignment 1, run make du1 to build and make test1 to run the respective tests. Use similarly for assignment 2 to 6.

Note that the du1 and du2 targets produce the same executable file tmp/du12, similarly, the du5 and du6 targets produce tmp/du56. The test targets are however different.

### The Visual Studio projects

Start the Visual Studio with the mlaskal.sln file.

Edit only the files in folders marked as "STUDENTS". These folders are only in the projects du12, du12grm, du3456, and du3456grm. Don't touch the files in "READONLY" or "GENERATED" folders.

For Assignments 1 and 2, set the du12 project as "Start up". The du12 project depends on du12grm (which runs flex) and on mlaskallib.

For Assignment 3 use the du3 project as "Start up". It depends on du3456, du3456grm (runs flex and bison) and on mlaskallib.

For Assignment 4 use the du4 project as "Start up". Dependences are the same as for du3.

For Assignments 5 and 6 use the du56 project as "Start up". Dependences are the same.

### Test files

The mlaskal source files have the suffix .mls, the corresponding expected outputs are in the .out files.

The test files whose names end with "r" contain records - ignore them this year.

The test files whose names end with "a" contain arrays, the files ending with "c" contain constant definitions - together they form the bonus 50 points (in Assignments 4 to 6).

The test files whose names end with "n" contain intentional semantic errors and are expected to fail during compilation.