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

    icblock_pointer create_destr(type_category t_cat) {
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

    icblock_pointer do_assign(
        MlaskalCtx* ctx,
        ls_id_index id,
        expression::pointer expr
    ) {
        auto symbol = ctx->tab->find_symbol(id);
        auto r_expr = expression::rexpressionize(ctx, expr);
        auto kind = symbol->kind();
        type_pointer type;

        switch (kind) {
            case SKIND_GLOBAL_VARIABLE:
                type = symbol->access_global_variable()->type();
                switch (type->cat()) {
                    case TCAT_BOOL:
                        r_expr->_constr->append<ai::GSTB>(symbol->access_global_variable()->address());
                    break;

                    case TCAT_INT:
                        r_expr->_constr->append<ai::GSTI>(symbol->access_global_variable()->address());
                    break;

                    case TCAT_REAL:
                        if (r_expr->_type->cat() == TCAT_INT) {
                            r_expr->_constr->append<ai::CVRTIR>();
                        } else if (r_expr->_type->cat() != TCAT_REAL) {
                            // TODO: cannot be converted to real
                        }

                        r_expr->_constr->append<ai::GSTR>(symbol->access_global_variable()->address());
                    break;

                    case TCAT_STR:
                        r_expr->_constr->append<ai::GSTS>(symbol->access_global_variable()->address());
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
                        r_expr->_constr->append<ai::LSTB>(symbol->access_local_variable()->address());
                    break;

                    case TCAT_INT:
                        r_expr->_constr->append<ai::LSTI>(symbol->access_local_variable()->address());
                    break;

                    case TCAT_REAL:
                        if (r_expr->_type->cat() == TCAT_INT) {
                            r_expr->_constr->append<ai::CVRTIR>();
                        } else if (r_expr->_type->cat() != TCAT_REAL) {
                            // TODO: cannot be converted to real
                        }

                        r_expr->_constr->append<ai::LSTR>(symbol->access_local_variable()->address());
                    break;

                    case TCAT_STR:
                        r_expr->_constr->append<ai::LSTS>(symbol->access_local_variable()->address());
                    break;

                    case TCAT_RECORD:
                        // TODO
                    break;
                }
            break;

            case SKIND_FUNCTION:
                if (ctx->tab->nested() && ctx->tab->my_function_name() == id) {
                    type = symbol->access_function()->type();

                    switch (type->cat()) {
                        case TCAT_BOOL:
                            r_expr->_constr->append<ai::LSTB>(ctx->tab->my_return_address());
                        break;

                        case TCAT_INT:
                            r_expr->_constr->append<ai::LSTI>(ctx->tab->my_return_address());
                        break;

                        case TCAT_REAL:
                            if (r_expr->_type->cat() == TCAT_INT) {
                                r_expr->_constr->append<ai::CVRTIR>();
                            } else if (r_expr->_type->cat() != TCAT_REAL) {
                                // TODO: cannot be converted to real
                            }

                            r_expr->_constr->append<ai::LSTR>(ctx->tab->my_return_address());
                        break;

                        case TCAT_STR:
                            r_expr->_constr->append<ai::LSTS>(ctx->tab->my_return_address());
                        break;

                        case TCAT_RECORD:
                            // TODO
                        break;
                    }
                } else {
                    // TODO: wrong return
                }
            break;

            case SKIND_PARAMETER_BY_REFERENCE:
                type = symbol->access_parameter_by_reference()->type();

                switch (type->cat()) {
                    case TCAT_BOOL:
                        r_expr->_constr->append<ai::LLDP>(symbol->access_parameter_by_reference()->address());
                        r_expr->_constr->append<ai::XSTB>();
                    break;

                    case TCAT_INT:
                        r_expr->_constr->append<ai::LLDP>(symbol->access_parameter_by_reference()->address());
                        r_expr->_constr->append<ai::XSTI>();
                    break;

                    case TCAT_REAL:
                        r_expr->_constr->append<ai::LLDP>(symbol->access_parameter_by_reference()->address());
                        r_expr->_constr->append<ai::XSTR>();
                    break;

                    case TCAT_STR:
                        r_expr->_constr->append<ai::LLDP>(symbol->access_parameter_by_reference()->address());
                        r_expr->_constr->append<ai::XSTS>();
                    break;

                    case TCAT_RECORD:
                        // TODO
                    break;
                }
            break;
        }

        return r_expr->_constr;
    }

    expression::pointer do_compare(
        MlaskalCtx* ctx,
        expression::pointer left,
        expression::pointer right,
        DUTOKGE_OPER_REL oper
    ) {
        r_expression::pointer r_expr1 = expression::rexpressionize(ctx, left);
        r_expression::pointer r_expr2 = expression::rexpressionize(ctx, right);

        type_category tcat1 = r_expr1->_type->cat();
        type_category tcat2 = r_expr2->_type->cat();
        if (tcat1 == TCAT_REAL) {
            if (tcat2 == TCAT_REAL) {
                r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
            } else if (tcat2 == TCAT_INT) {
                r_expr2->_constr->append<ai::CVRTIR>();
                r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
            } else {
                // TODO
            }

            switch (oper) {
                case DUTOKGE_OPER_REL::DUTOKGE_LT:
                    r_expr1->_constr->append<ai::LTR>();
                break;

                case DUTOKGE_OPER_REL::DUTOKGE_LE:
                    r_expr1->_constr->append<ai::LER>();
                break;

                case DUTOKGE_OPER_REL::DUTOKGE_NE:
                    r_expr1->_constr->append<ai::NER>();
                break;

                case DUTOKGE_OPER_REL::DUTOKGE_GE:
                    r_expr1->_constr->append<ai::GER>();
                break;

                case DUTOKGE_OPER_REL::DUTOKGE_GT:
                    r_expr1->_constr->append<ai::GTR>();
                break;
            }
        } else if (tcat1 == TCAT_INT) {
            if (tcat2 == TCAT_REAL) {
                r_expr1->_constr->append<ai::CVRTIR>();
                r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);

                switch (oper) {
                    case DUTOKGE_OPER_REL::DUTOKGE_LT:
                        r_expr1->_constr->append<ai::LTR>();
                    break;

                    case DUTOKGE_OPER_REL::DUTOKGE_LE:
                        r_expr1->_constr->append<ai::LER>();
                    break;

                    case DUTOKGE_OPER_REL::DUTOKGE_NE:
                        r_expr1->_constr->append<ai::NER>();
                    break;

                    case DUTOKGE_OPER_REL::DUTOKGE_GE:
                        r_expr1->_constr->append<ai::GER>();
                    break;

                    case DUTOKGE_OPER_REL::DUTOKGE_GT:
                        r_expr1->_constr->append<ai::GTR>();
                    break;
                }
            } else if (tcat2 == TCAT_INT) {
                r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);

                switch (oper) {
                    case DUTOKGE_OPER_REL::DUTOKGE_LT:
                        r_expr1->_constr->append<ai::LTI>();
                    break;

                    case DUTOKGE_OPER_REL::DUTOKGE_LE:
                        r_expr1->_constr->append<ai::LEI>();
                    break;

                    case DUTOKGE_OPER_REL::DUTOKGE_NE:
                        r_expr1->_constr->append<ai::NEI>();
                    break;

                    case DUTOKGE_OPER_REL::DUTOKGE_GE:
                        r_expr1->_constr->append<ai::GEI>();
                    break;

                    case DUTOKGE_OPER_REL::DUTOKGE_GT:
                        r_expr1->_constr->append<ai::GTI>();
                    break;
                }
            } else {
                // TODO
            }
        } else if (tcat1 == TCAT_BOOL && tcat2 == TCAT_BOOL) {
            r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);

            switch (oper) {
                case DUTOKGE_OPER_REL::DUTOKGE_LT:
                    r_expr1->_constr->append<ai::LTB>();
                break;

                case DUTOKGE_OPER_REL::DUTOKGE_LE:
                    r_expr1->_constr->append<ai::LEB>();
                break;

                case DUTOKGE_OPER_REL::DUTOKGE_NE:
                    r_expr1->_constr->append<ai::NEB>();
                break;

                case DUTOKGE_OPER_REL::DUTOKGE_GE:
                    r_expr1->_constr->append<ai::GEB>();
                break;

                case DUTOKGE_OPER_REL::DUTOKGE_GT:
                    r_expr1->_constr->append<ai::GTB>();
                break;
            }
        } else if (tcat1 == TCAT_STR && tcat2 == TCAT_STR) {
            r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);

            switch (oper) {
                case DUTOKGE_OPER_REL::DUTOKGE_LT:
                    r_expr1->_constr->append<ai::LTS>();
                break;

                case DUTOKGE_OPER_REL::DUTOKGE_LE:
                    r_expr1->_constr->append<ai::LES>();
                break;

                case DUTOKGE_OPER_REL::DUTOKGE_NE:
                    r_expr1->_constr->append<ai::NES>();
                break;

                case DUTOKGE_OPER_REL::DUTOKGE_GE:
                    r_expr1->_constr->append<ai::GES>();
                break;

                case DUTOKGE_OPER_REL::DUTOKGE_GT:
                    r_expr1->_constr->append<ai::GTS>();
                break;
            }
        } else {
            // TODO
        }

        r_expr1->_type = ctx->tab->logical_bool();
        return r_expr1;
    }

    expression::pointer do_signadd(
        MlaskalCtx* ctx,
        expression::pointer left,
        expression::pointer right,
        DUTOKGE_OPER_SIGNADD oper
    ) {
        r_expression::pointer r_expr1 = expression::rexpressionize(ctx, left);
        r_expression::pointer r_expr2 = expression::rexpressionize(ctx, right);

        type_category tcat1 = r_expr1->_type->cat();
        type_category tcat2 = r_expr2->_type->cat();

        if (tcat1 == TCAT_REAL) {
            if (tcat2 == TCAT_REAL) {
                r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
            } else if (tcat2 == TCAT_INT) {
                r_expr2->_constr->append<ai::CVRTIR>();
                r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
            } else {
                // TODO
            }

            if (oper == DUTOKGE_OPER_SIGNADD::DUTOKGE_PLUS) {
                r_expr1->_constr->append<ai::ADDR>();
            } else {
                r_expr1->_constr->append<ai::SUBR>();
            }
        } else if (tcat1 == TCAT_INT) {
            if (tcat2 == TCAT_REAL) {
                r_expr1->_constr->append<ai::CVRTIR>();
                r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
                r_expr1->_type = r_expr2->_type;

                if (oper == DUTOKGE_OPER_SIGNADD::DUTOKGE_PLUS) {
                    r_expr1->_constr->append<ai::ADDR>();
                } else {
                    r_expr1->_constr->append<ai::SUBR>();
                }
            } else if (tcat2 == TCAT_INT) {
                r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);

                if (oper == DUTOKGE_OPER_SIGNADD::DUTOKGE_PLUS) {
                    r_expr1->_constr->append<ai::ADDI>();
                } else {
                    r_expr1->_constr->append<ai::SUBI>();
                }
            } else {
                // TODO
            }
        } else if (tcat1 == TCAT_STR && tcat2 == TCAT_STR) {
                r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);

                if (oper == DUTOKGE_OPER_SIGNADD::DUTOKGE_PLUS) {
                    r_expr1->_constr->append<ai::ADDS>();
                } else {
                    // TODO
                }
        } else {
            // TODO
        }

        return r_expr1;
    }

    icblock_pointer address_load(
        MlaskalCtx* ctx,
        expression::pointer par
    ) {
        icblock_pointer icblock = icblock_create();

        if (par->get_type() == expression::type::REXPRESSION) {
            return nullptr;
        }

        l_expression* l_expr = (l_expression*)&*par;
        ls_id_index id = l_expr->_ids->_ids[0];
        auto symbol = ctx->tab->find_symbol(id);
        auto kind = symbol->kind();

        switch (kind) {
            case SKIND_GLOBAL_VARIABLE:
                icblock->append<ai::GREF>(symbol->access_global_variable()->address());
            break;

            case SKIND_LOCAL_VARIABLE:
                icblock->append<ai::LREF>(symbol->access_local_variable()->address());
            break;

            case SKIND_PARAMETER_BY_REFERENCE:
                icblock->append<ai::LLDP>(symbol->access_parameter_by_reference()->address());
            break;

            default:
            break;
        }

        return icblock;
    }

    icblock_pointer make_if(
        MlaskalCtx * ctx,
        expression::pointer condition,
        icblock_pointer then_stmt,
        icblock_pointer else_stmt
    ) {
        auto r_expr = expression::rexpressionize(
            ctx,
            condition);

        ic_label l1 = ctx->tab->new_label();
        ic_label l2 = ctx->tab->new_label();
        icblock_pointer icblock = r_expr->_constr;

        icblock->append_with_target<ai::JF>(l1);

        icblock = icblock_merge_and_kill(
            icblock,
            then_stmt);

        if (else_stmt != nullptr) {
            icblock->append_with_target<ai::JMP>(l2);
        }

        icblock->add_label(l1);

        if (else_stmt != nullptr) {
            icblock = icblock_merge_and_kill(
                icblock,
                else_stmt);

            icblock->add_label(l2);
        }

        return icblock;
    }

    icblock_pointer make_repeat(
        MlaskalCtx * ctx,
        expression::pointer condition,
        icblock_pointer stmt
    ) {
        auto r_expr = expression::rexpressionize(
            ctx,
            condition);

        ic_label l1 = ctx->tab->new_label();
        icblock_pointer icblock = icblock_create();

        icblock->add_label(l1);

        icblock = icblock_merge_and_kill(
            icblock,
            stmt);

        icblock = icblock_merge_and_kill(
            icblock,
            r_expr->_constr);

        icblock->append_with_target<ai::JF>(l1);

        return icblock;
    }

    icblock_pointer make_while(
        MlaskalCtx * ctx,
        expression::pointer condition,
        icblock_pointer stmt
    ) {
        auto r_expr = expression::rexpressionize(
            ctx,
            condition);

        ic_label l1 = ctx->tab->new_label();
        ic_label l2 = ctx->tab->new_label();
        icblock_pointer icblock = icblock_create();

        icblock->append_with_target<ai::JMP>(l2);
        icblock->add_label(l1);

        icblock = icblock_merge_and_kill(
            icblock,
            stmt);

        icblock->add_label(l2);

        icblock = icblock_merge_and_kill(
            icblock,
            r_expr->_constr);

        icblock->append_with_target<ai::JT>(l1);

        return icblock;
    }

    icblock_pointer make_for(
        MlaskalCtx * ctx,
        ls_id_index id,
        expression::pointer left,
        expression::pointer right,
        DUTOKGE_FOR_DIRECTION direction,
        icblock_pointer stmt
    ) {
        ic_label l1 = ctx->tab->new_label();
        ic_label l2 = ctx->tab->new_label();
        ic_label l3 = ctx->tab->new_label();

        icblock_pointer icblock = do_assign(
            ctx,
            id,
            left);

        icblock->append_with_target<ai::JMP>(l2);
        icblock->add_label(l1);

        auto lit_one = icblock_create();

        auto unit = ctx->tab->ls_int().add(1);

        lit_one->append<ai::LDLITI>(unit);

        icblock_pointer assignment = do_assign(
            ctx,
            id,
            do_signadd(
                ctx,
                std::make_shared<l_expression>(
                    ctx->tab->find_symbol(id)->access_typed()->type(),
                    std::make_shared<id_list>(id)),
                std::make_shared<r_expression>(
                    ctx->tab->logical_integer(),
                    lit_one),
                (direction == DUTOKGE_FOR_DIRECTION::DUTOKGE_TO)
                    ? DUTOKGE_OPER_SIGNADD::DUTOKGE_PLUS
                    : DUTOKGE_OPER_SIGNADD::DUTOKGE_MINUS));


        icblock = icblock_merge_and_kill(
            icblock,
            assignment);

        icblock->add_label(l2);

        icblock = icblock_merge_and_kill(
            icblock,
            stmt);

        icblock->add_label(l3);

        icblock = icblock_merge_and_kill(
            icblock,
            expression::rexpressionize(
                ctx,
                    do_compare(
                    ctx,
                    std::make_shared<l_expression>(
                        ctx->tab->find_symbol(id)->access_typed()->type(),
                        std::make_shared<id_list>(id)),
                    right,
                    DUTOKGE_OPER_REL::DUTOKGE_NE))->_constr);

        icblock->append_with_target<ai::JT>(l1);

        return icblock;
    }

    icblock_pointer make_call(
        MlaskalCtx * ctx,
        parameter_list_const_ptr pars,
        real_par_list::pointer real_pars,
        ic_function_pointer code
    ) {
        // TODO: test for lengths of parameter lists

        icblock_pointer constr = icblock_create();
        icblock_pointer destr = icblock_create();

        for (
            auto [par, real_par] = std::tuple{
                pars->begin(),
                real_pars->_pars.begin()
            };

            (par != pars->end()) &&
            (real_par != real_pars->_pars.end());

            ++par,
            ++real_par
        ) {
            if (par->partype == PMODE_BY_VALUE) {
                auto expr = expression::rexpressionize(ctx, *real_par);

                auto tcat1 = par->ltype->cat();
                auto tcat2 = expr->_type->cat();

                if (tcat1 != tcat2) {
                    if (tcat1 == TCAT_REAL) {
                        if (tcat2 == TCAT_INT) {
                            expr->_constr->append<ai::CVRTIR>();
                        } else {
                            // TODO
                        }
                    } else if (tcat1 == TCAT_INT) {
                        if (tcat2 == TCAT_REAL) {
                            // TODO: warning
                            expr->_constr->append<ai::CVRTRI>();
                        } else {
                            // TODO
                        }
                    } else {
                        // TODO
                    }
                }

                constr = icblock_merge_and_kill(constr, expr->_constr);
                destr = icblock_merge_and_kill(create_destr(par->ltype->cat()), destr);
            } else {
                auto pass_par = address_load(ctx, *real_par);

                if (pass_par == nullptr) {
                    message(DUERR_NOTPARAMVAR, ctx->curline);
                    continue;
                }

                constr = icblock_merge_and_kill(
                    constr,
                    pass_par);


                icblock_pointer icblock = icblock_create();
                icblock->append<ai::DTORP>();

                destr = icblock_merge_and_kill(
                    icblock,
                    destr);
            }
        }

        constr->append<ai::CALL>(code);

        return icblock_merge_and_kill(constr, destr);
    }

    bool count_field_recur(
        symbol_pointer symbol,
        const std::vector<ls_id_index>& ids,
        type_pointer& type,
        stack_address& address
    ) {
        for (
            auto i = ids.cbegin() + 1;
            i != ids.cend();
            ++i
        ) {
            auto field = type->access_record()->find(*i);
            if (!field) {
                return false;
            }

            type = field->type();
            address += field->offset();
        }

        return true;
    }

    auto expression::rexpressionize(MlaskalCtx* ctx, pointer expr) -> r_pointer {
        if (expr->get_type() == type::REXPRESSION) {
            return std::static_pointer_cast<r_expression>(expr);
        } else {
            l_expression* l_expr = (l_expression*)&*expr;
            type_pointer type;
            icblock_pointer constr;
            icblock_pointer destr;

            constr = icblock_create();

            if (l_expr->_ids->_ids.size() >= 1) {
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

                            case TCAT_RECORD: {
                                auto address = symbol->access_global_variable()->address();
                                type = symbol->access_global_variable()->type();

                                if (count_field_recur(symbol, l_expr->_ids->_ids, type, address)) {
                                    switch (type->cat()) {
                                        case TCAT_BOOL:
                                            constr->append<ai::GLDB>(address);
                                        break;

                                        case TCAT_INT:
                                            constr->append<ai::GLDI>(address);
                                        break;

                                        case TCAT_REAL:
                                            constr->append<ai::GLDR>(address);
                                        break;

                                        case TCAT_STR:
                                            constr->append<ai::GLDS>(address);
                                        break;

                                        default:
                                            // TODO: ERROR
                                        break;
                                    }
                                } else {
                                    // TODO: ERROR
                                }
                            } break;
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

                            case TCAT_RECORD: {
                                auto address = symbol->access_local_variable()->address();
                                type = symbol->access_local_variable()->type();

                                if (count_field_recur(symbol, l_expr->_ids->_ids, type, address)) {
                                    switch (type->cat()) {
                                        case TCAT_BOOL:
                                            constr->append<ai::LLDB>(address);
                                        break;

                                        case TCAT_INT:
                                            constr->append<ai::LLDI>(address);
                                        break;

                                        case TCAT_REAL:
                                            constr->append<ai::LLDR>(address);
                                        break;

                                        case TCAT_STR:
                                            constr->append<ai::LLDS>(address);
                                        break;

                                        default:
                                            // TODO: ERROR
                                        break;
                                    }
                                } else {
                                    // TODO: ERROR
                                }
                            } break;
                        }
                    break;

                    case SKIND_FUNCTION:
                        type = symbol->access_function()->type();

                        switch (type->cat()) {
                            case TCAT_BOOL:
                                constr->append<ai::INITB>();
                            break;

                            case TCAT_INT:
                                constr->append<ai::INITI>();
                            break;

                            case TCAT_REAL:
                                constr->append<ai::INITR>();
                            break;

                            case TCAT_STR:
                                constr->append<ai::INITS>();
                            break;

                            case TCAT_RECORD:
                                // TODO
                            break;
                        }

                        constr->append<ai::CALL>(symbol->access_function()->code());
                    break;

                    case SKIND_CONST:
                        type = symbol->access_const()->type();

                        switch (type->cat()) {
                            case TCAT_BOOL:
                                constr->append<ai::LDLITB>(symbol->access_const()->access_bool_const()->bool_value());
                            break;

                            case TCAT_INT:
                                constr->append<ai::LDLITI>(symbol->access_const()->access_int_const()->int_value());
                            break;

                            case TCAT_REAL:
                                constr->append<ai::LDLITR>(symbol->access_const()->access_real_const()->real_value());
                            break;

                            case TCAT_STR:
                                constr->append<ai::LDLITS>(symbol->access_const()->access_str_const()->str_value());
                            break;

                            case TCAT_RECORD:
                                // TODO
                            break;
                        }
                    break;
                }

                return std::make_shared<r_expression>(type, constr);
            } else {
                return nullptr;
            }
        }
    }

}

/*****************************************/
