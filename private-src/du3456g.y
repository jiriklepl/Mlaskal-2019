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
%type<mlc::icblock_pointer> headered_statement
%type<mlc::icblock_pointer> headered_safe_statement
%type<mlc::icblock_pointer> headered_if_statement
%type<mlc::icblock_pointer> whilefor_header
%type<mlc::icblock_pointer> statement

/* expressions */
%type<mlc::expression::pointer> factor
%type<mlc::expression::pointer> mul_expression
%type<mlc::expression::pointer> add_expression
%type<mlc::expression::pointer> simple_expression
%type<mlc::expression::pointer> expression
%type<mlc::expression::pointer> real_par_list

/* variables */
%type<mlc::id_list::pointer> variable_noidentifier
%type<mlc::id_list::pointer> variable

/* profuns-definition */
%type<mlc::parameter_list_ptr> formal_par_list
%type<mlc::parameter_list_ptr> formal_par
%type<std::tuple<mlc::ls_id_index, mlc::parameter_list_ptr>> profun_header

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
    PROGRAM IDENTIFIER SEMICOLON program_block DOT
    ;

program_block:
    block_header
    profun_def_list
    block_body
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
    block_header block_body
    ;

block_body:
    BEGIN statement_list END
    ;

statement_list:
    statement
    | statement_list SEMICOLON statement
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
    | profun_def_list procedure_header SEMICOLON block SEMICOLON[END] {
        ctx->tab->leave(@END);
    }
    | profun_def_list function_header SEMICOLON block SEMICOLON[END] {
        ctx->tab->leave(@END);
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
    headered_safe_statement
    | headered_if_statement
    ;

whilefor_header:
    WHILE expression DO  // expression: bool
    | FOR IDENTIFIER ASSIGN  // IDENTIFIER: ordinal type variable
    expression FOR_DIRECTION expression  // expression: ordinal
    DO
    ;

headered_safe_statement:
    label_header safe_statement
    ;

safe_statement:
    /* empty */
    | IF expression THEN headered_safe_statement ELSE headered_safe_statement
    | REPEAT statement_list UNTIL expression
    | whilefor_header headered_safe_statement
    | simple_statement
    ;

headered_if_statement:
    label_header if_statement
    ;

if_statement:
    IF expression THEN statement
    | IF expression THEN headered_safe_statement ELSE headered_if_statement
    | whilefor_header headered_if_statement
    ;

label_header:
    /* empty */
    | UINT COLON
    ;

simple_statement:
    IDENTIFIER ASSIGN expression  // IDENTIFIER: variable || function identifier (return value)
    | variable_noidentifier ASSIGN expression  // IDENTIFIER: variable || function identifier (return value)
    | IDENTIFIER  // IDENTIFIER: procedure || function
    | IDENTIFIER LPAR real_par_list RPAR  // IDENTIFIER: function || procedure
    | GOTO UINT
    | block_body
    ;

variable:
    IDENTIFIER  // IDENTIFIER: variable
    | variable_noidentifier { $$ = std::move($variable_noidentifier); }
    ;

variable_noidentifier:
    variable DOT IDENTIFIER  // IDENTIFIER: field_identifier
    ;

real_par_list:
    expression { $$ = std::move($expression); }
    | real_par_list COMMA expression
    ;

expression:
    simple_expression { $$ = std::move($simple_expression); }
    | simple_expression OPER_REL simple_expression
    ;

simple_expression:
    add_expression { $$ = std::move($add_expression); }
    | OPER_SIGNADD add_expression {
        r_expression::pointer r_expr = expression::rexpressionize($add_expression);

        if ($OPER_SIGNADD == DUTOKGE_OPER_SIGNADD::DUTOKGE_MINUS) {
            switch (r_expr->_type->cat()) {
                case TCAT_INT:
                    r_expr->_constr->append<ai::MINUSI>();
                break;

                case TCAT_REAL:
                    r_expr->_constr->append<ai::MINUSR>();
                break;

                default:
                break;
            }
        }

        $$ = std::move(r_expr);
    }
    ;

add_expression:
    mul_expression { $$ = std::move($mul_expression); }
    | add_expression OPER_SIGNADD mul_expression
    | add_expression OR mul_expression
    ;

mul_expression:
    factor { $$ = std::move($factor); }
    | mul_expression OPER_MUL factor
    ;

factor:
    unsigned_constant_noidentifier
    | variable_noidentifier
    | IDENTIFIER  // IDENTIFIER: function || variable || unsigned_constant
    | IDENTIFIER LPAR real_par_list RPAR  // IDENTIFIER: function
    | LPAR expression RPAR { $$ = std::move($expression); }
    | NOT factor
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

