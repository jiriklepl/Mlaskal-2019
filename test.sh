#!/bin/bash

ls public-cpp/*.out 2> /dev/null | grep -vE ".*a.out" | {
    while read name; do
        output="public-cpp/"`basename "$name"`
        expected="public-tests/"`basename "$name"`
        echo  "comparing $output (left) against $expected (right)"
        sdiff -l --strip-trailing-cr $output $expected | cat -n | grep -v -e ' ($'
    done
} | less
