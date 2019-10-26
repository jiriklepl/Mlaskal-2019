#!/bin/bash

if command -v colordiff > /dev/null; then
    diff="colordiff"
else
    diff="diff"
fi

ls public-cpp/*.out | {
    while read name; do
        output="public-cpp/"`basename "$name"`
        expected="public-tests/"`basename "$name"`
        echo  "comparing $output (left) against $expected (right)"
        $diff -y --suppress-common-lines "$output" "$expected"
    done
} | less -R
