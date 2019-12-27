/*

DU3456SEM.CPP

JY

Mlaskal's semantic interface for DU3-6

*/

#include "du3456sem.hpp"
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

    icblock_pointer create_destr( type_category t_cat) {
        icblock_pointer icblock = icblock_create();

        switch (t_cat) {
            case TCAT_BOOL:
                icblock->append<ai::DTORB>();
            break;

            case TCAT_INT:
                icblock->append<ai::DTORI>();
            break;

            case TCAT_REAL:
                icblock->append<ai::DTORR>();
            break;

            case TCAT_STR:
                icblock->append<ai::DTORS>();
            break;

            case TCAT_RECORD:
                icblock->append<ai::DTORP>();
            break;
        }

        return icblock;
    }

    auto expression::rexpressionize(MlaskalCtx* ctx, pointer expr) -> r_pointer {
        if (expr->get_type() == type::REXPRESSION) {
            return std::dynamic_pointer_cast<r_expression>(expr);
        } else {
            l_expression* l_expr = (l_expression*)&*expr;
            type_pointer type;
            icblock_pointer constr;
            icblock_pointer destr;

            constr = icblock_create();

            if(l_expr->_ids->_ids.size() == 1) {
                ls_id_index id = l_expr->_ids->_ids[0];
                auto symbol = ctx->tab->find_symbol(id);
                auto kind = symbol->kind();

                switch (kind) {
                    case SKIND_GLOBAL_VARIABLE:
                        type = symbol->access_global_variable()->type();
                        switch (type->cat()) {
                            case TCAT_BOOL:
                                constr->append<ai::GLDB>(symbol->access_global_variable()->address());
                            break;

                            case TCAT_INT:
                                constr->append<ai::GLDI>(symbol->access_global_variable()->address());
                            break;

                            case TCAT_REAL:
                                constr->append<ai::GLDR>(symbol->access_global_variable()->address());
                            break;

                            case TCAT_STR:
                                constr->append<ai::GLDS>(symbol->access_global_variable()->address());
                            break;

                            case TCAT_RECORD:
                                // TODO
                            break;
                        }
                    break;

                    case SKIND_LOCAL_VARIABLE:
                        type = symbol->access_local_variable()->type();
                        switch (type->cat()) {
                            case TCAT_BOOL:
                                constr->append<ai::LLDB>(symbol->access_local_variable()->address());
                            break;

                            case TCAT_INT:
                                constr->append<ai::LLDI>(symbol->access_local_variable()->address());
                            break;

                            case TCAT_REAL:
                                constr->append<ai::LLDR>(symbol->access_local_variable()->address());
                            break;

                            case TCAT_STR:
                                constr->append<ai::LLDS>(symbol->access_local_variable()->address());
                            break;

                            case TCAT_RECORD:
                                // TODO
                            break;
                        }
                    break;
                }

                destr = create_destr(type->cat());

                return std::make_shared<r_expression>(type, constr, destr);
            } else {
                return nullptr;
            }
        }
    }

}

/*****************************************/
