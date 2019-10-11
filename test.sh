#!/bin/bash

ls public-cpp/*.out | {
    while read name; do
        diff "public-cpp/"`basename "$name"` "public-tests/"`basename "$name"`
    done
}