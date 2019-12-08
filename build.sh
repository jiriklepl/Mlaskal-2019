#!/bin/bash

cd public-cpp
[ -d tmp ] || mkdir tmp
make -f ../build.gcc/makefile $@ 2>&1 | grep -E "(du3456|du12)"
