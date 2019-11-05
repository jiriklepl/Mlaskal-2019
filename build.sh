#!/bin/bash

cd public-cpp
[ -d tmp ] || mkdir tmp
make -f ../build.gcc/makefile $@
