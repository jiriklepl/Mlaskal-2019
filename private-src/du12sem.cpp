/*

    DU12SEM.CPP

    JY

    Mlaskal's semantic interface for DU1-2

*/

// CHANGE THIS LINE TO #include "du3456sem.hpp"
// WHEN THIS FILE IS COPIED TO du3456sem.cpp
#include "du12sem.hpp"
#include "duerr.hpp"

namespace mlc {

    std::string& upper_case(std::string& from) {
        for (auto&& c : from) {
            c |= 32;
        }

        return from;
    }

}

/*****************************************/
