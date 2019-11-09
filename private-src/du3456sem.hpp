/*

	DU3456SEM.H

	DB

	Mlaskal's semantic interface for DU3-6

*/

#ifndef DU3456SEM_HPP_
#define DU3456SEM_HPP_

#include <string>
#include <sstream>
#include <utility>

#include "literal_storage.hpp"
#include "flat_icblock.hpp"
#include "dutables.hpp"
#include "abstract_instr.hpp"
#include "gen_ainstr.hpp"

namespace mlc {
    std::string& upper_case(std::string&);
    std::string& un_apostrophe(std::string&);

    enum class SPECIAL_CASE {
        SC_NORMAL,
        SC_UINT_DOTDOT
    };

    ls_real_type::value_type convert_real(const std::string&);
    ls_int_type::value_type convert_int(
        const char* from,
        decltype(mlc::MlaskalCtx::curline) line);
}

#endif  // DU3456SEM_HPP_
