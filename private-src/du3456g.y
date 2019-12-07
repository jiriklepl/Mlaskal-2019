%language "c++"
%require "3.0.4"
%defines
%define api.parser.class { mlaskal_parser }
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
    function_def_list
    block_body
    ;

block_header:
    block_header_label
    block_header_const
    block_header_type
    block_header_var
    ;

block_header_label: /* TODO: do labels */
    /* empty */
    | LABEL uint_list SEMICOLON
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

uint_list:
    UINT
    | uint_list COMMA UINT
    ;

const_def_list:
    const_def SEMICOLON
    | const_def_list const_def SEMICOLON
    ;

const_def:
    IDENTIFIER EQ constant {
        switch($3->get_type()) {
            case constant_value::constant_value_type::ID_CONSTANT: {
                auto value = ((id_constant*)&*$3)->_val;
                mlc::symbol_pointer sp = ctx->tab->find_symbol(value);
                if (sp->kind() != SKIND_CONST) {
                    message(DUERR_NOTCONST, @3, *value);
                }

                switch(sp->access_const()->type()->cat()) {
                    case TCAT_REAL:
                        ctx->tab->add_const_real(
                            @1,
                            $1,
                            sp->access_const()->access_real_const()->real_value());

                    break;

                    case TCAT_INT:
                        ctx->tab->add_const_int(
                            @1,
                            $1,
                            sp->access_const()->access_int_const()->int_value());
                    break;

                    case TCAT_STR:
                        ctx->tab->add_const_str(
                            @1,
                            $1,
                            sp->access_const()->access_str_const()->str_value());
                    break;
                }
            } break;

            case constant_value::constant_value_type::UINT_CONSTANT:
                ctx->tab->add_const_int( @1, $1, ((uint_constant*)&*$3)->_val);
            break;

            case constant_value::constant_value_type::STR_CONSTANT:
                ctx->tab->add_const_str( @1, $1, ((str_constant*)&*$3)->_val);
            break;

            case constant_value::constant_value_type::REAL_CONSTANT:
                ctx->tab->add_const_real( @1, $1, ((real_constant*)&*$3)->_val);
            break;

            case constant_value::constant_value_type::SIGNED_UINT_CONSTANT:
                if (
                    ((signed_uint_constant*)&*$3)->_oper ==
                        DUTOKGE_OPER_SIGNADD::DUTOKGE_PLUS
                ) {
                    ctx->tab->add_const_int(
                        @1,
                        $1,
                        ((signed_uint_constant*)&*$3)->_val);
                } else {
                    ctx->tab->add_const_int(
                        @1,
                        $1,
                        ctx->tab->ls_int().add(
                            -*((signed_uint_constant*)&*$3)->_val));
                }
            break;

            case constant_value::constant_value_type::SIGNED_REAL_CONSTANT:
                if (
                    ((signed_real_constant*)&*$3)->_oper ==
                        DUTOKGE_OPER_SIGNADD::DUTOKGE_PLUS
                ) {
                    ctx->tab->add_const_real(
                        @1,
                        $1,
                        ((signed_real_constant*)&*$3)->_val);
                } else {
                    ctx->tab->add_const_real(
                        @1,
                        $1,
                        ctx->tab->ls_real().add(
                            -*((signed_real_constant*)&*$3)->_val));
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
    IDENTIFIER EQ type
    ;

var_def_list:
    var_def SEMICOLON
    | var_def_list var_def SEMICOLON
    ;

var_def:
    identifier_list COLON type
    ;

identifier_list:
    IDENTIFIER
    | identifier_list COMMA IDENTIFIER
    ;

function_def_list:
    /* empty */
    | function_def_list procedure_header SEMICOLON block SEMICOLON
    | function_def_list function_header SEMICOLON block SEMICOLON
    ;

procedure_header:
    PROCEDURE profun_header
    ;

function_header:
    FUNCTION profun_header COLON IDENTIFIER  // IDENTIFIER: scalar type
    ;

profun_header:
    IDENTIFIER
    | IDENTIFIER LPAR formal_par_list RPAR
    ;

formal_par_list:
    formal_par
    | formal_par_list SEMICOLON formal_par
    ;

formal_par:
    identifier_list COLON IDENTIFIER  // IDENTIFIER: type
    | VAR identifier_list COLON IDENTIFIER  // IDENTIFIER: type
    ;

type:
    IDENTIFIER  // IDENTIFIER: type
    | structured_type
    ;

structured_type:
    RECORD END
    | RECORD record_body END
    ;

record_body:
    field_list
    | field_list SEMICOLON
    ;

field_list:
    var_def
    | field_list SEMICOLON var_def
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
    | variable_noidentifier
    ;

variable_noidentifier:
    variable DOT IDENTIFIER  // IDENTIFIER: record_variable, field_identifier
    ;

real_par_list:
    expression
    | real_par_list COMMA expression
    ;

expression:
    simple_expression
    | simple_expression OPER_REL simple_expression
    ;

simple_expression:
    add_expression
    | OPER_SIGNADD add_expression
    ;

add_expression:
    mul_expression
    | add_expression OPER_SIGNADD mul_expression
    | add_expression OR mul_expression
    ;

mul_expression:
    factor
    | mul_expression OPER_MUL factor
    ;

factor:
    unsigned_constant_noidentifier
    | variable_noidentifier
    | IDENTIFIER  // IDENTIFIER: function || variable || unsigned_constant
    | IDENTIFIER LPAR real_par_list RPAR  // IDENTIFIER: function
    | LPAR expression RPAR
    | NOT factor
    ;

constant:
    unsigned_constant { $$ = std::move($1); }
    | OPER_SIGNADD UINT { $$ = std::make_unique<signed_uint_constant>($1, $2); }
    | OPER_SIGNADD REAL { $$ = std::make_unique<signed_real_constant>($1, $2); }
    ;

unsigned_constant:
    IDENTIFIER  { $$ = std::make_unique<id_constant>($1); }
    | unsigned_constant_noidentifier { $$ = std::move($1); }
    ;

unsigned_constant_noidentifier:
    UINT { $$ = std::make_unique<uint_constant>($1); }
    | REAL { $$ = std::make_unique<real_constant>($1); }
    | STRING { $$ = std::make_unique<str_constant>($1); }
    ;

%%


namespace yy {

    void mlaskal_parser::error(const location_type& l, const std::string& m)
    {
        message(DUERR_SYNTAX, l, m);
    }

}

