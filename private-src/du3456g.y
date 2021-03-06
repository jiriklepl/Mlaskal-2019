%language "c++"
%require "3.0.4"
%defines
%define parser_class_name { mlaskal_parser }
%define api.token.constructor
%define api.token.prefix{DUTOK_}
%define api.value.type variant
%define parse.assert
%define parse.error verbose

%locations
%define api.location.type{ unsigned }

%code requires
{
    // this code is emitted to du3456g.hpp

    // allow references to semantic types in %type
#include "dutables.hpp"

#include "du3456sem.hpp"

    // avoid no-case warnings when compiling du3g.hpp
#pragma warning (disable:4065)

// adjust YYLLOC_DEFAULT macro for our api.location.type
#define YYLLOC_DEFAULT(res,rhs,N)    (res = (N)?YYRHSLOC(rhs, 1):YYRHSLOC(rhs, 0))
// supply missing YY_NULL in bfexpg.hpp
#define YY_NULL    0
#define YY_NULLPTR 0
}

%param{ mlc::yyscan_t2 yyscanner }    // formal name "yyscanner" is enforced by flex
%param{ mlc::MlaskalCtx* ctx }

%code
{
    // this code is emitted to du3456g.cpp

    // declare yylex here
    #include "bisonflex.hpp"
    YY_DECL;

    // allow access to context
    #include "dutables.hpp"

    // other user-required contents
    #include <assert.h>
    #include <stdlib.h>

    /* local stuff */
    using namespace mlc;

}

%token EOF    0    "end of file"

%token PROGRAM                                   /* program */
%token LABEL                                     /* label */
%token CONST                                     /* const */
%token TYPE                                      /* type */
%token VAR                                       /* var */
%token BEGIN                                     /* begin */
%token END                                       /* end */
%token PROCEDURE                                 /* procedure */
%token FUNCTION                                  /* function */
%token ARRAY                                     /* array */
%token OF                                        /* of */
%token GOTO                                      /* goto */
%token IF                                        /* if */
%token THEN                                      /* then */
%token ELSE                                      /* else */
%token WHILE                                     /* while */
%token DO                                        /* do */
%token REPEAT                                    /* repeat */
%token UNTIL                                     /* until */
%token FOR                                       /* for */
%token OR                                        /* or */
%token NOT                                       /* not */
%token RECORD                                    /* record */

/* literals */
%token<mlc::ls_id_index> IDENTIFIER              /* identifier */
%token<mlc::ls_int_index> UINT                   /* unsigned integer */
%token<mlc::ls_real_index> REAL                  /* real number */
%token<mlc::ls_str_index> STRING                 /* string */

/* delimiters */
%token SEMICOLON                                 /* ; */
%token DOT                                       /* . */
%token COMMA                                     /* , */
%token EQ                                        /* = */
%token COLON                                     /* : */
%token LPAR                                      /* ( */
%token RPAR                                      /* ) */
%token DOTDOT                                    /* .. */
%token LSBRA                                     /* [ */
%token RSBRA                                     /* ] */
%token ASSIGN                                    /* := */

/* grouped operators and keywords */
%token<mlc::DUTOKGE_OPER_REL> OPER_REL           /* <, <=, <>, >=, > */
%token<mlc::DUTOKGE_OPER_SIGNADD> OPER_SIGNADD   /* +, - */
%token<mlc::DUTOKGE_OPER_MUL> OPER_MUL           /* *, /, div, mod, and */
%token<mlc::DUTOKGE_FOR_DIRECTION> FOR_DIRECTION /* to, downto */

/* statements */
%type<mlc::icblock_pointer> simple_statement
%type<mlc::icblock_pointer> if_statement
%type<mlc::icblock_pointer> safe_statement
%type<mlc::icblock_pointer> headered_safe_statement
%type<mlc::icblock_pointer> headered_if_statement
%type<mlc::icblock_pointer> block
%type<mlc::icblock_pointer> block_body
%type<mlc::icblock_pointer> program_block
%type<mlc::icblock_pointer> statement
%type<mlc::icblock_pointer> statement_list

/* expressions */
%type<mlc::expression::pointer> factor
%type<mlc::expression::pointer> mul_expression
%type<mlc::expression::pointer> add_expression
%type<mlc::expression::pointer> simple_expression
%type<mlc::expression::pointer> expression

%type<mlc::real_par_list::pointer> real_par_list

/* variables */
%type<mlc::id_list::pointer> variable_noidentifier
%type<mlc::id_list::pointer> variable

/* profun-definition */
%type<std::tuple<mlc::ls_id_index, mlc::parameter_list_ptr>> profun_header
%type<std::tuple<mlc::ls_id_index, mlc::parameter_list_ptr>> procedure_header
%type<std::tuple<mlc::ls_id_index, mlc::parameter_list_ptr>> function_header
%type<mlc::parameter_list_ptr> formal_par_list
%type<mlc::parameter_list_ptr> formal_par

/* types */
%type<mlc::type_specifier::pointer> type
%type<mlc::type_pointer> structured_type
%type<mlc::field_list_ptr> record_body
%type<mlc::field_list_ptr> field_list
%type<mlc::var_def::pointer> var_def
%type<mlc::id_list::pointer> identifier_list

/* constants */
%type<mlc::constant_value::pointer> constant
%type<mlc::constant_value::pointer> unsigned_constant
%type<mlc::constant_value::pointer> unsigned_constant_noidentifier

%start program

%%

program:
    PROGRAM IDENTIFIER SEMICOLON program_block DOT {
        ctx->tab->set_main_code($IDENTIFIER, $program_block);
    }
    ;

program_block:
    block_header
    profun_def_list
    block_body { $$ = std::move($block_body); }
    ;

block_header:
    block_header_label
    block_header_const
    block_header_type
    block_header_var
    ;

block_header_label:
    /* empty */
    | LABEL label_list SEMICOLON
    ;

block_header_const:
    /* empty */
    | CONST const_def_list
    ;

block_header_type:
    /* empty */
    | TYPE type_def_list
    ;

block_header_var:
    /* empty */
    | VAR var_def_list
    ;

block:
    block_header block_body { $$ = std::move($block_body); }
    ;

block_body:
    BEGIN statement_list END { $$ = std::move($statement_list); }
    ;

statement_list:
    statement { $$ = std::move($statement); }
    | statement_list[lft_list] SEMICOLON statement { $$ = icblock_merge_and_kill($lft_list, $statement); }
    ;

label_list:
    UINT {
        ctx->tab->add_label_entry(
            @UINT,
            $UINT,
            ctx->tab->new_label());
    }
    | label_list[list] COMMA UINT {
        ctx->tab->add_label_entry(
            @UINT,
            $UINT,
            ctx->tab->new_label());
    }
    ;

const_def_list:
    const_def SEMICOLON
    | const_def_list const_def SEMICOLON
    ;

const_def:
    IDENTIFIER EQ constant {
        switch ($constant->get_type()) {
            case constant_value::type::ID_CONSTANT: {
                auto value = ((id_constant*)&*$constant)->_val;
                mlc::symbol_pointer sp = ctx->tab->find_symbol(value);
                if (sp->kind() != SKIND_CONST) {
                    message(DUERR_NOTCONST, @constant, *value);
                }

                switch (sp->access_const()->type()->cat()) {
                    case TCAT_REAL:
                        ctx->tab->add_const_real(
                            @IDENTIFIER,
                            $IDENTIFIER,
                            sp->access_const()->access_real_const()->real_value());

                    break;

                    case TCAT_INT:
                        ctx->tab->add_const_int(
                            @IDENTIFIER,
                            $IDENTIFIER,
                            sp->access_const()->access_int_const()->int_value());
                    break;

                    case TCAT_STR:
                        ctx->tab->add_const_str(
                            @IDENTIFIER,
                            $IDENTIFIER,
                            sp->access_const()->access_str_const()->str_value());
                    break;

                    case TCAT_BOOL:
                        ctx->tab->add_const_bool(
                            @IDENTIFIER,
                            $IDENTIFIER,
                            sp->access_const()->access_bool_const()->bool_value());
                    break;

                    case TCAT_UNDEF:
                    case TCAT_RECORD:
                    case TCAT_RANGE:
                    case TCAT_ARRAY:
                    // NOTHING YET...
                    break;
                }
            } break;

            case constant_value::type::UINT_CONSTANT:
                ctx->tab->add_const_int(@IDENTIFIER, $IDENTIFIER, ((uint_constant*)&*$constant)->_val);
            break;

            case constant_value::type::STR_CONSTANT:
                ctx->tab->add_const_str(@IDENTIFIER, $IDENTIFIER, ((str_constant*)&*$constant)->_val);
            break;

            case constant_value::type::REAL_CONSTANT:
                ctx->tab->add_const_real(@IDENTIFIER, $IDENTIFIER, ((real_constant*)&*$constant)->_val);
            break;

            case constant_value::type::SIGNED_UINT_CONSTANT:
                if (
                    ((signed_uint_constant*)&*$constant)->_oper ==
                        DUTOKGE_OPER_SIGNADD::DUTOKGE_PLUS
                ) {
                    ctx->tab->add_const_int(
                        @IDENTIFIER,
                        $IDENTIFIER,
                        ((signed_uint_constant*)&*$constant)->_val);
                } else {
                    ctx->tab->add_const_int(
                        @IDENTIFIER,
                        $IDENTIFIER,
                        ctx->tab->ls_int().add(
                            -*((signed_uint_constant*)&*$constant)->_val));
                }
            break;

            case constant_value::type::SIGNED_REAL_CONSTANT:
                if (
                    ((signed_real_constant*)&*$constant)->_oper ==
                        DUTOKGE_OPER_SIGNADD::DUTOKGE_PLUS
                ) {
                    ctx->tab->add_const_real(
                        @IDENTIFIER,
                        $IDENTIFIER,
                        ((signed_real_constant*)&*$constant)->_val);
                } else {
                    ctx->tab->add_const_real(
                        @IDENTIFIER,
                        $IDENTIFIER,
                        ctx->tab->ls_real().add(
                            -*((signed_real_constant*)&*$constant)->_val));
                }
            break;
        }
    }
    ;

type_def_list:
    type_def SEMICOLON
    | type_def_list type_def SEMICOLON
    ;

type_def:
    IDENTIFIER EQ type {
        switch ($type->get_type()) {
            case type_specifier::type::ID_TYPE: {
                auto value = ((id_specifier*)&*$type)->_val;
                mlc::symbol_pointer sp =
                    ctx->tab->find_symbol(value);

                if (!sp || (sp->kind() != SKIND_TYPE)) {
                    message(DUERR_NOTTYPE, @type, *value);
                } else {
                    ctx->tab->add_type(
                        @IDENTIFIER,
                        $IDENTIFIER,
                        sp->access_type()->type());
                }
            } break;

            case type_specifier::type::RECORD_TYPE:
                ctx->tab->add_type(
                    @IDENTIFIER,
                    $IDENTIFIER,
                    ((record_specifier*)&*$type)->_val);
            break;

            case type_specifier::type::ARRAY_TYPE:
                // SHOULD NOT HAPPEN
            break;
        }
    }
    ;

var_def_list:
    var_def_do SEMICOLON
    | var_def_list var_def_do SEMICOLON
    ;

var_def_do:
    var_def {
        for (auto&& id : $var_def->_list->_ids) {
            ctx->tab->add_var(@var_def, id, $var_def->_type);
        }
    }
    ;

var_def:
    identifier_list COLON type {
        type_pointer type;

        switch ($type->get_type()) {
            case type_specifier::type::ID_TYPE: {
                auto value = ((id_specifier*)&*$type)->_val;
                mlc::symbol_pointer sp =
                    ctx->tab->find_symbol(value);

                if (!sp || (sp->kind() != SKIND_TYPE)) {
                    message(DUERR_NOTTYPE, @type, *value);
                } else {
                    type = sp->access_type()->type();
                }
            } break;

            case type_specifier::type::RECORD_TYPE:
                type = ((record_specifier*)&*$type)->_val;
            break;

            case type_specifier::type::ARRAY_TYPE:
                // SHOULD NOT HAPPEN
            break;
        }

        $$ = std::make_shared<var_def>(
            std::move($identifier_list),
            type
        );
    }
    ;

identifier_list:
    IDENTIFIER { $$ = std::make_shared<id_list>($IDENTIFIER); }
    | identifier_list[list] COMMA IDENTIFIER {
        $list->append($IDENTIFIER);
        $$ = std::move($list);
    }
    ;

profun_def_list:
    /* empty */
    | profun_def_list procedure_header SEMICOLON block SEMICOLON[end] {
        ctx->tab->leave(@end);

        ctx->tab->set_subprogram_code(
            std::get<
                0
                >($procedure_header),
            $block);
    }
    | profun_def_list function_header SEMICOLON block SEMICOLON[end] {
        ctx->tab->leave(@end);

        ctx->tab->set_subprogram_code(
            std::get<
                0
                >($function_header),
            $block);
    }
    ;

procedure_header: PROCEDURE profun_header {
        ctx->tab->add_proc(
            @profun_header,
            std::get<
                0
                >($profun_header),
            std::get<
                1
                >($profun_header));

        ctx->tab->enter(
            @profun_header,
            std::get<
                0
                >($profun_header));

        $$ = std::move($profun_header);
    }
    ;

function_header: FUNCTION profun_header COLON IDENTIFIER {
        mlc::symbol_pointer sp = ctx->tab->find_symbol($IDENTIFIER);

        if (!sp || (sp->kind() != SKIND_TYPE)) {
            message(DUERR_NOTTYPE, @IDENTIFIER, *$IDENTIFIER);
        }

        ctx->tab->add_fnc(
            @profun_header,
            std::get<0
            >($profun_header),
            sp->access_type()->type(),
            std::get<
                1
                >($profun_header));

        ctx->tab->enter(
            @profun_header,
            std::get<
                0
                >($profun_header));

        $$ = std::move($profun_header);
    }
    ;

profun_header:
    IDENTIFIER {
        $$ = std::make_tuple($IDENTIFIER, std::make_shared<parameter_list_body>());
    }
    | IDENTIFIER LPAR formal_par_list RPAR {
        ctx->tab->enter(@IDENTIFIER, $IDENTIFIER);
        $$ = std::make_tuple($IDENTIFIER, $formal_par_list);
    }
    ;

formal_par_list:
    formal_par { $$ = $formal_par; }
    | formal_par_list[list] SEMICOLON formal_par {
        $list->append_and_kill($formal_par);
        $$ = $list;
    }
    ;

formal_par:
    identifier_list COLON IDENTIFIER {
        $$ = std::make_shared<parameter_list_body>();

        mlc::symbol_pointer sp = ctx->tab->find_symbol($IDENTIFIER);

        if (!sp || (sp->kind() != SKIND_TYPE)) {
            message(DUERR_NOTTYPE, @IDENTIFIER, *$IDENTIFIER);
        }

        for (auto&& id : $identifier_list->_ids) {
            $$->append_parameter_by_value(id, sp->access_type()->type());
        }
    }
    | VAR identifier_list COLON IDENTIFIER  {
        $$ = std::make_shared<parameter_list_body>();

        mlc::symbol_pointer sp = ctx->tab->find_symbol($IDENTIFIER);

        if (!sp || (sp->kind() != SKIND_TYPE)) {
            message(DUERR_NOTTYPE, @IDENTIFIER, *$IDENTIFIER);
        }

        for (auto&& id : $identifier_list->_ids) {
            $$->append_parameter_by_reference(id, sp->access_type()->type());
        }
    }
    ;

type:
    IDENTIFIER  { $$ = std::make_shared<id_specifier>($IDENTIFIER); }
    | structured_type { $$ = std::make_shared<record_specifier>($structured_type); }
    ;

structured_type:
    RECORD END {
        $$ = ctx->tab->create_record_type(
            std::make_shared<field_list_body>(),
            @RECORD);
    }
    | RECORD record_body END {
        $$ = ctx->tab->create_record_type(
            $record_body,
            @RECORD);
    }
    ;

record_body:
    field_list { $$ = $field_list; }
    | field_list SEMICOLON { $$ = $field_list; }
    ;

field_list:
    var_def {
        auto fields = std::make_shared<field_list_body>();

        for (auto&& id : $var_def->_list->_ids) {
            fields->append_field(id, $var_def->_type);
        }

        $$ = fields;
    }
    | field_list[fields] SEMICOLON var_def {
        for (auto&& id : $var_def->_list->_ids) {
            $fields->append_field(id, $var_def->_type);
        }

        $$ = $fields;
    }
    ;

statement:
    headered_safe_statement { $$ = std::move($headered_safe_statement); }
    | headered_if_statement { $$ = std::move($headered_if_statement); }
    ;

headered_safe_statement:
    safe_statement { $$ = std::move($safe_statement); }
    | UINT COLON safe_statement {
        auto symbol = ctx->tab->find_label($UINT);

        if (symbol->label_found(@UINT)) {
            $$ = icblock_create();
            $$->add_label(symbol->label());
            $$ = icblock_merge_and_kill(
                $$,
                $safe_statement);
        } else {
            $$ = std::move($safe_statement);
        }

    }
    ;

safe_statement:
    /* empty */  { $$ = icblock_create(); }
    | IF expression THEN headered_safe_statement[then] ELSE headered_safe_statement[else] {
        $$ = make_if(
            ctx,
            $expression,
            $then,
            $else);
    }
    | REPEAT statement_list UNTIL expression {
        $$ = make_repeat(
            ctx,
            $expression,
            $statement_list);
    }
    | WHILE expression DO headered_safe_statement {
        $$ = make_while(
            ctx,
            $expression,
            $headered_safe_statement);
    }
    | FOR IDENTIFIER ASSIGN  // IDENTIFIER: ordinal type variable
    expression[left] FOR_DIRECTION expression[right]  // expression: ordinal
    DO headered_safe_statement {
        $$ = make_for(
            ctx,
            $IDENTIFIER,
            $left,
            $right,
            $FOR_DIRECTION,
            $headered_safe_statement);
    }
    | simple_statement { $$ = std::move($simple_statement); }
    ;

headered_if_statement:
    if_statement { $$ = std::move($if_statement); }
    | UINT COLON if_statement {
        auto symbol = ctx->tab->find_label($UINT);

        if (symbol->label_found(@UINT)) {
            $$ = icblock_create();
            $$->add_label(symbol->label());
            $$ = icblock_merge_and_kill(
                $$,
                $if_statement);
        } else {
            $$ = std::move($if_statement);
        }

    }
    ;

if_statement:
    IF expression THEN statement {
        $$ = make_if(
            ctx,
            $expression,
            $statement,
            nullptr);
    }
    | IF expression THEN headered_safe_statement[then] ELSE headered_if_statement[else] {
        $$ = make_if(
            ctx,
            $expression,
            $then,
            $else);
    }
    | WHILE expression DO headered_if_statement {
        $$ = make_while(
            ctx,
            $expression,
            $headered_if_statement);
    }
    | FOR IDENTIFIER ASSIGN  // IDENTIFIER: ordinal type variable
    expression[left] FOR_DIRECTION expression[right]  // expression: ordinal
    DO headered_if_statement {
        $$ = make_for(
            ctx,
            $IDENTIFIER,
            $left,
            $right,
            $FOR_DIRECTION,
            $headered_if_statement);
    }
    ;

simple_statement:
    IDENTIFIER ASSIGN expression {
        // IDENTIFIER: variable || function identifier (return value)
        $$ = do_assign(
            ctx,
            $IDENTIFIER,
            $expression);
    }
    | variable_noidentifier ASSIGN expression {
        // IDENTIFIER: variable || function identifier (return value)
        $$ = do_assign_long(
            ctx,
            $variable_noidentifier,
            $expression);
    }
    | IDENTIFIER {
        // IDENTIFIER: procedure

        auto symbol = ctx->tab->find_symbol($IDENTIFIER);
        auto kind = symbol->kind();
        icblock_pointer constr = icblock_create();

        if (kind == SKIND_PROCEDURE) {
            constr->append<ai::CALL>(symbol->access_procedure()->code());

            $$ = std::move(constr);
        } else {
            message(DUERR_NOTPROC, @IDENTIFIER, *$IDENTIFIER);
        }
    }
    | IDENTIFIER LPAR real_par_list RPAR {
        // IDENTIFIER: procedure

        auto symbol = ctx->tab->find_symbol($IDENTIFIER);
        auto kind = symbol->kind();

        if (kind == SKIND_PROCEDURE) {
            $$ = make_call(
                ctx,
                symbol->access_procedure()->parameters(),
                $real_par_list,
                symbol->access_procedure()->code());
        } else {
            message(DUERR_NOTPROC, @IDENTIFIER, *$IDENTIFIER);
        }
    }
    | GOTO UINT {
        auto symbol = ctx->tab->find_label($UINT);
        if(symbol->label()) {
            symbol->goto_found(@UINT);
            $$ = icblock_create();
            $$->append_with_target<ai::JMP>(symbol->label());
        } else {
            message(DUERR_NOTLABEL, ctx->curline, *$UINT);
        }
    }
    | block_body { $$ = std::move($block_body); }
    ;

variable:
    IDENTIFIER {
        // IDENTIFIER: variable
        $$ = std::make_shared<id_list>($IDENTIFIER);
    }
    | variable_noidentifier { $$ = std::move($variable_noidentifier); }
    ;

variable_noidentifier:
    variable DOT IDENTIFIER {
        // IDENTIFIER: field_identifier
        $variable->append($IDENTIFIER);
        $$ = std::move($variable);
    }
    ;

real_par_list:
    expression { $$ = std::make_shared<real_par_list>($expression); }
    | real_par_list[lft_list] COMMA expression {
        $lft_list->append($expression);
        $$ = std::move($lft_list);
    }
    ;

expression:
    simple_expression { $$ = std::move($simple_expression); }
    | simple_expression[lft_expression] OPER_REL simple_expression[rgt_expression] {
        $$ = do_compare(
            ctx,
            $lft_expression,
            $rgt_expression,
            $OPER_REL);
    }
    | simple_expression[lft_expression] EQ simple_expression[rgt_expression] {
        r_expression::pointer r_expr1 = expression::rexpressionize(ctx, $lft_expression);
        r_expression::pointer r_expr2 = expression::rexpressionize(ctx, $rgt_expression);

        type_category tcat1 = r_expr1->_type->cat();
        type_category tcat2 = r_expr2->_type->cat();

        if (tcat1 == TCAT_REAL) {
            if (tcat2 == TCAT_REAL) {
                r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
            } else if (tcat2 == TCAT_INT) {
                r_expr2->_constr->append<ai::CVRTIR>();
                r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
            } else {
                message(DUERR_TYPEMISMATCH, @EQ);
            }

            r_expr1->_constr->append<ai::EQR>();
        } else if (tcat1 == TCAT_INT) {
            if (tcat2 == TCAT_REAL) {
                r_expr1->_constr->append<ai::CVRTIR>();
                r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
                r_expr1->_constr->append<ai::EQR>();
            } else if (tcat2 == TCAT_INT) {
                r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
                r_expr1->_constr->append<ai::EQI>();
            } else {
                message(DUERR_TYPEMISMATCH, @EQ);
            }
        } else if (tcat1 == TCAT_BOOL && tcat2 == TCAT_BOOL) {
            r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
            r_expr1->_constr->append<ai::EQB>();
        } else if (tcat1 == TCAT_STR && tcat2 == TCAT_STR) {
            r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
            r_expr1->_constr->append<ai::EQS>();
        } else {
            message(DUERR_TYPEMISMATCH, @EQ);
        }

        r_expr1->_type = ctx->tab->logical_bool();
        $$ = std::move(r_expr1);
    }
    ;

simple_expression:
    add_expression { $$ = std::move($add_expression); }
    | OPER_SIGNADD add_expression {
        r_expression::pointer r_expr = expression::rexpressionize(ctx, $add_expression);

        if ($OPER_SIGNADD == DUTOKGE_OPER_SIGNADD::DUTOKGE_MINUS) {
            switch (r_expr->_type->cat()) {
                case TCAT_INT:
                    r_expr->_constr->append<ai::MINUSI>();
                break;

                case TCAT_REAL:
                    r_expr->_constr->append<ai::MINUSR>();
                break;

                default:
                    message(DUERR_TYPEMISMATCH, @add_expression);
                break;
            }
        }

        $$ = std::move(r_expr);
    }
    ;

add_expression:
    mul_expression { $$ = std::move($mul_expression); }
    | add_expression[lft_expression] OPER_SIGNADD mul_expression {
        $$ = do_signadd(
            ctx,
            $lft_expression,
            $mul_expression,
            $OPER_SIGNADD);
    }
    | add_expression[lft_expression] OR mul_expression {
        r_expression::pointer r_expr1 = expression::rexpressionize(ctx, $lft_expression);
        r_expression::pointer r_expr2 = expression::rexpressionize(ctx, $mul_expression);

        type_category tcat1 = r_expr1->_type->cat();
        type_category tcat2 = r_expr2->_type->cat();

        if (tcat1 == TCAT_BOOL) {
            if (tcat2 == TCAT_BOOL) {
                r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
                r_expr1->_constr->append<ai::OR>();
            } else {
                message(DUERR_TYPEMISMATCH, @OR);
            }
        } else {
            message(DUERR_TYPEMISMATCH, @OR);
        }

        $$ = std::move(r_expr1);
    }
    ;

mul_expression:
    factor { $$ = std::move($factor); }
    | mul_expression[lft_expr] OPER_MUL factor {
        r_expression::pointer r_expr1 = expression::rexpressionize(ctx, $lft_expr);
        r_expression::pointer r_expr2 = expression::rexpressionize(ctx, $factor);

        type_category tcat1 = r_expr1->_type->cat();
        type_category tcat2 = r_expr2->_type->cat();

        switch ($OPER_MUL) {
            case DUTOKGE_OPER_MUL::DUTOKGE_AND:
                if (tcat1 == TCAT_BOOL) {
                    if (tcat2 == TCAT_BOOL) {
                        r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
                        r_expr1->_constr->append<ai::AND>();
                    } else {
                        message(DUERR_TYPEMISMATCH, @OPER_MUL);
                    }
                } else {
                    message(DUERR_TYPEMISMATCH, @OPER_MUL);
                }
            break;

            case DUTOKGE_OPER_MUL::DUTOKGE_ASTERISK:
                if (tcat1 == TCAT_REAL) {
                    if (tcat2 == TCAT_REAL) {
                        r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
                    } else if (tcat2 == TCAT_INT) {
                        r_expr2->_constr->append<ai::CVRTIR>();
                        r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
                    } else {
                        message(DUERR_TYPEMISMATCH, @OPER_MUL);
                    }

                    r_expr1->_constr->append<ai::MULR>();
                } else if (tcat1 == TCAT_INT) {
                    if (tcat2 == TCAT_REAL) {
                        r_expr1->_constr->append<ai::CVRTIR>();
                        r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
                        r_expr1->_constr->append<ai::MULR>();
                        r_expr1->_type = r_expr2->_type;
                    } else if (tcat2 == TCAT_INT) {
                        r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
                        r_expr1->_constr->append<ai::MULI>();
                    } else {
                        message(DUERR_TYPEMISMATCH, @OPER_MUL);
                    }
                } else {
                    message(DUERR_TYPEMISMATCH, @OPER_MUL);
                }
            break;

            case DUTOKGE_OPER_MUL::DUTOKGE_SOLIDUS:
                if (tcat1 == TCAT_REAL) {
                    if (tcat2 == TCAT_REAL) {
                        r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
                    } else if (tcat2 == TCAT_INT) {
                        r_expr2->_constr->append<ai::CVRTIR>();
                        r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
                    } else {
                        message(DUERR_TYPEMISMATCH, @OPER_MUL);
                    }

                } else if (tcat1 == TCAT_INT) {
                    r_expr1->_constr->append<ai::CVRTIR>();

                    if (tcat2 == TCAT_REAL) {
                        r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
                    } else if (tcat2 == TCAT_INT) {
                        r_expr2->_constr->append<ai::CVRTIR>();
                        r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
                    } else {
                        message(DUERR_TYPEMISMATCH, @OPER_MUL);
                    }
                } else {
                    message(DUERR_TYPEMISMATCH, @OPER_MUL);
                }

                r_expr1->_type = ctx->tab->logical_real();
                r_expr1->_constr->append<ai::DIVR>();
            break;

            case DUTOKGE_OPER_MUL::DUTOKGE_DIV:
                if (tcat1 == TCAT_REAL) {
                    r_expr1->_constr->append<ai::CVRTRI>();
                    if (tcat2 == TCAT_REAL) {
                        r_expr2->_constr->append<ai::CVRTRI>();
                        r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
                    } else if (tcat2 == TCAT_INT) {
                        r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
                    } else {
                        message(DUERR_TYPEMISMATCH, @OPER_MUL);
                    }
                } else if (tcat1 == TCAT_INT) {
                    if (tcat2 == TCAT_REAL) {
                        r_expr2->_constr->append<ai::CVRTRI>();
                        r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
                    } else if (tcat2 == TCAT_INT) {
                        r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
                    } else {
                        message(DUERR_TYPEMISMATCH, @OPER_MUL);
                    }
                } else {
                    message(DUERR_TYPEMISMATCH, @OPER_MUL);
                }

                r_expr1->_type = ctx->tab->logical_integer();
                r_expr1->_constr->append<ai::DIVI>();
            break;

            case DUTOKGE_OPER_MUL::DUTOKGE_MOD:
                if (tcat1 == TCAT_REAL) {
                    r_expr1->_constr->append<ai::CVRTRI>();
                    if (tcat2 == TCAT_REAL) {
                        r_expr2->_constr->append<ai::CVRTRI>();
                        r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
                    } else if (tcat2 == TCAT_INT) {
                        r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
                    } else {
                        message(DUERR_TYPEMISMATCH, @OPER_MUL);
                    }
                } else if (tcat1 == TCAT_INT) {
                    if (tcat2 == TCAT_REAL) {
                        r_expr2->_constr->append<ai::CVRTRI>();
                        r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
                    } else if (tcat2 == TCAT_INT) {
                        r_expr1->_constr = icblock_merge_and_kill(r_expr1->_constr, r_expr2->_constr);
                    } else {
                        message(DUERR_TYPEMISMATCH, @OPER_MUL);
                    }
                } else {
                    message(DUERR_TYPEMISMATCH, @OPER_MUL);
                }

                r_expr1->_type = ctx->tab->logical_integer();
                r_expr1->_constr->append<ai::MODI>();
            break;
        }

        $$ = std::move(r_expr1);
    }
    ;

factor:
    unsigned_constant_noidentifier[constant] {
        type_pointer type;
        icblock_pointer constr = icblock_create();

        switch($constant->get_type()) {
            case constant_value::type::UINT_CONSTANT:
                type = ctx->tab->logical_integer();
                constr->append<ai::LDLITI>(((uint_constant*)&*$constant)->_val);
            break;

            case constant_value::type::STR_CONSTANT:
                type = ctx->tab->logical_string();
                constr->append<ai::LDLITS>(((str_constant*)&*$constant)->_val);
            break;

            case constant_value::type::REAL_CONSTANT:
                type = ctx->tab->logical_real();
                constr->append<ai::LDLITR>(((real_constant*)&*$constant)->_val);
            break;

            default:
                /* shouldn't be able to get here */
            break;
        }

        $$ = std::make_shared<r_expression>(
            type,
            constr);
    }
    | variable_noidentifier {
        $$ = std::make_shared<l_expression>(
            ctx->tab->find_symbol($variable_noidentifier->_ids[
                0
                ])->access_typed()->type(),
            $variable_noidentifier);
    }
    | IDENTIFIER {
        // IDENTIFIER: function || variable || unsigned_constant

        $$ = std::make_shared<l_expression>(
            ctx->tab->find_symbol($IDENTIFIER)->access_typed()->type(),
            std::make_shared<id_list>($IDENTIFIER));
    }
    | IDENTIFIER LPAR real_par_list RPAR {
        // IDENTIFIER: function

        auto symbol = ctx->tab->find_symbol($IDENTIFIER);
        auto kind = symbol->kind();
        icblock_pointer constr = icblock_create();

        if (kind == SKIND_FUNCTION) {
            type_pointer type = symbol->access_function()->type();

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
                    // TODO (maybe): function returning a record
                break;
            }

            $$ = std::make_shared<r_expression>(
                type,
                icblock_merge_and_kill(
                    constr,
                    make_call(
                        ctx,
                        symbol->access_function()->parameters(),
                        $real_par_list,
                        symbol->access_function()->code())));
        } else {
            message(DUERR_NOTFNC, @IDENTIFIER, *$IDENTIFIER);
        }
    }
    | LPAR expression RPAR { $$ = std::move($expression); }
    | NOT factor[inner_factor] {
        r_expression::pointer r_expr = expression::rexpressionize(ctx, $inner_factor);

        switch (r_expr->_type->cat()) {
            case TCAT_BOOL:
                r_expr->_constr->append<ai::NOT>();
            break;

            default:
                message(DUERR_TYPEMISMATCH, @inner_factor);
            break;
        }

        $$ = std::move(r_expr);
    }
    ;

constant:
    unsigned_constant { $$ = std::move($unsigned_constant); }
    | OPER_SIGNADD UINT { $$ = std::make_shared<signed_uint_constant>($OPER_SIGNADD, $UINT); }
    | OPER_SIGNADD REAL { $$ = std::make_shared<signed_real_constant>($OPER_SIGNADD, $REAL); }
    ;

unsigned_constant:
    IDENTIFIER  { $$ = std::make_shared<id_constant>($IDENTIFIER); }
    | unsigned_constant_noidentifier { $$ = std::move($unsigned_constant_noidentifier); }
    ;

unsigned_constant_noidentifier:
    UINT { $$ = std::make_shared<uint_constant>($UINT); }
    | REAL { $$ = std::make_shared<real_constant>($REAL); }
    | STRING { $$ = std::make_shared<str_constant>($STRING); }
    ;

%%


namespace yy {

    void mlaskal_parser::error(const location_type& l, const std::string& m)
    {
        message(DUERR_SYNTAX, l, m);
    }

}

