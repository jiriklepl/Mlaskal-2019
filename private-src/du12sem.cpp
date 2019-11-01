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
            if (c >= 'a' && c <= 'z') {
                c ^= (1UL << 5);
            }
        }

        return from;
    }

    std::string& un_apostrophe(std::string& from) {
        std::string to;
        to.reserve(from.size());

        for (std::size_t i = 0; i < from.size(); ++i) {
            if (from[i] == '\'') {
                ++i;
            }

            to.push_back(from[i]);
        }

        return from = std::move(to);
    }

    ls_int_type::value_type convert_int(
        const char* from,
        decltype(mlc::MlaskalCtx::curline) line
    ) {
        ls_int_type::value_type number = 0;
        const char* where = from;
        constexpr std::uint_least32_t limit = 1U << 31;

        for (; *where != '\0'; ++where) {
            if (static_cast<std::uint_least32_t>(number) >= limit / 10) {
                message(DUERR_INTOUTRANGE, line, from);
                break;
            }

            number *= 10;

            char digit = (*where - '0');

            if (static_cast<std::uint_least32_t>(number) >= limit - digit) {
                message(DUERR_INTOUTRANGE, line, from);
                goto for_rest_digit;
            }

            number += digit;
        }

        for (; *where != '\0'; ++where) {
            number *= 10;
        for_rest_digit:
            number += (*where - '0');
        }

        return number & ((1UL << 31) - 1UL);
    }

    ls_real_type::value_type convert_real(const std::string& from) {
        std::istringstream from_stream{from};
        ls_real_type::value_type number;

        from_stream >> number;
        return number;
    }

}

/*****************************************/
