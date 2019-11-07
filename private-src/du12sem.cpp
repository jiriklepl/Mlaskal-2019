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

        for (const char* c = from.c_str(); *c != '\0'; ++c) {
            if (*c == '\'') {
                ++c;
            }

            to.push_back(*c);
        }

        return from = std::move(to);
    }

    ls_int_type::value_type convert_int(
        const char* from,
        std::add_const<decltype(mlc::MlaskalCtx::curline)>::type line
    ) {
        constexpr std::uint_least32_t limit = 1U << 31;
        constexpr std::uint_least32_t mask = (1UL << 31) - 1UL;

        static_assert(mask + 1 == limit);

        std::uint_least32_t number = 0;
        const char* where = from;

        for (; *where >= '0' && *where <= '9'; ++where) {
            if (number > (limit / 10) - ((limit % 10) ? 0 : 1)) {
                message(DUERR_INTOUTRANGE, line, from);
                break;
            }

            number *= 10;

            assert(number < limit);

            const char digit = (*where - '0');

            if (number >= limit - digit) {
                message(DUERR_INTOUTRANGE, line, from);

                number += digit;
                ++where;
                break;
            }

            number += digit;

            assert(number < limit);
        }

        for (; *where >= '0' && *where <= '9'; ++where) {
            number *= 10;
            number += (*where - '0');
        }

        return static_cast<ls_int_type::value_type>(number & mask);
    }

    ls_real_type::value_type convert_real(const std::string& from) try {
        return std::stod(from);
    } catch (std::out_of_range&) {
        std::istringstream from_stream{from};
        ls_real_type::value_type number;

        from_stream >> number;
        return number;
    }

}

/*****************************************/
