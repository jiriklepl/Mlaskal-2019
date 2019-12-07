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
#include <memory>

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

    class constant_value {
     public:
        typedef std::unique_ptr<constant_value> pointer;
        enum class constant_value_type {
            SIGNED_UINT_CONSTANT,
            SIGNED_REAL_CONSTANT,
            UINT_CONSTANT,
            STR_CONSTANT,
            REAL_CONSTANT,
            ID_CONSTANT
        };

        constant_value() = default;
        virtual ~constant_value() noexcept = default;
        virtual constant_value_type get_type() const = 0;
    };

    class id_constant : public constant_value {
     public:
        id_constant(
            mlc::ls_id_index val
        ) : _val{val} {
        }

        ~id_constant() noexcept override = default;
        constant_value_type get_type() const override {
            return constant_value_type::ID_CONSTANT;
        }

        mlc::ls_id_index _val;
    };

    class str_constant : public constant_value {
     public:
        str_constant(
            mlc::ls_str_index val
        ) : _val{val} {
        }

        ~str_constant() noexcept override = default;
        constant_value_type get_type() const override {
            return constant_value_type::STR_CONSTANT;
        }

        mlc::ls_str_index _val;
    };

    class real_constant : public constant_value {
     public:
        real_constant(
            mlc::ls_real_index val
        ) : _val{val} {
        }

        ~real_constant() noexcept override = default;
        constant_value_type get_type() const override {
            return constant_value_type::REAL_CONSTANT;
        }

        mlc::ls_real_index _val;
    };

    class uint_constant : public constant_value {
     public:
        uint_constant(
            mlc::ls_int_index val
        ) : _val{val} {
        }

        ~uint_constant() noexcept override = default;
        constant_value_type get_type() const override {
            return constant_value_type::UINT_CONSTANT;
        }

        mlc::ls_int_index _val;
    };

    class signed_uint_constant : public constant_value {
     public:
        signed_uint_constant(
            mlc::DUTOKGE_OPER_SIGNADD oper,
            mlc::ls_int_index val
        ) : _oper{oper}, _val{val} {
        }

        ~signed_uint_constant() noexcept override = default;
        constant_value_type get_type() const override {
            return constant_value_type::SIGNED_UINT_CONSTANT;
        }

        mlc::DUTOKGE_OPER_SIGNADD _oper;
        mlc::ls_int_index _val;
    };

    class signed_real_constant : public constant_value {
     public:
        signed_real_constant(
            mlc::DUTOKGE_OPER_SIGNADD oper,
            mlc::ls_real_index val
        ) : _oper{oper}, _val{val} {
        }

        ~signed_real_constant() noexcept override = default;
        constant_value_type get_type() const override {
            return constant_value_type::SIGNED_REAL_CONSTANT;
        }

        mlc::DUTOKGE_OPER_SIGNADD _oper;
        mlc::ls_real_index _val;
    };
}

#endif  // DU3456SEM_HPP_
