/*

    DU12SEM.H

    DB

    Mlaskal's semantic interface for DU1-2

*/

#ifndef DU12SEM_HPP_
#define DU12SEM_HPP_

#include <cstddef>

#include <string>
#include <sstream>

#include "literal_storage.hpp"
#include "flat_icblock.hpp"
#include "dutables.hpp"
#include "abstract_instr.hpp"
#include "gen_ainstr.hpp"

namespace mlc {

    std::string& upper_case(std::string&);
    std::string& un_apostrophe(std::string&);
    ls_real_type::value_type convert_real(const std::string&);
    ls_int_type::value_type convert_int(
        const char* from,
        decltype(mlc::MlaskalCtx::curline) line);
}

#endif  // DU12SEM_HPP_
