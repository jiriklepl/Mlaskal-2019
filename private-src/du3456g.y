%language "c++"
%require "3.0.4"
%defines
%define parser_class_name{ mlaskal_parser }
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

%start program

%%

program
	: PROGRAM IDENTIFIER SEMICOLON program_block DOT
	;

program_block
	: block_header
	  function_def_list
	  block_body
	;

block_header
	: block_header_label
	  block_header_const
	  block_header_type
	  block_header_var
	;

block_header_label
	: /* empty */
	| LABEL uint_list SEMICOLON

block_header_const
	: /* empty */
	| CONST const_def_list
	;

block_header_type
	: /* empty */
	| TYPE type_def_list
	;

block_header_var
	: /* empty */
	| VAR var_def_list
	;

block
	: block_header block_body
	;

block_body
	: BEGIN statement_list END
	;

statement_list
	: statement  // TODO(jiriklepl): statement
	| statement_list SEMICOLON statement
	;

uint_list
	: UINT
	| uint_list COMMA UINT
	;

const_def_list
	: const_def SEMICOLON
	| const_def_list const_def SEMICOLON
	;

const_def
	: IDENTIFIER EQ constant  // TODO(jiriklepl): constant
	;

type_def_list
	: type_def SEMICOLON
	| type_def_list type_def SEMICOLON
	;

type_def
	: IDENTIFIER EQ type
	;

var_def_list
	: var_def SEMICOLON
	| var_def_list var_def SEMICOLON
	;

var_def
	: identifier_list COMMA type
	;

identifier_list
	: IDENTIFIER
	| identifier_list COMMA IDENTIFIER
	;

function_def_list
	: /* empty */
	| function_def_list procedure_header SEMICOLON block SEMICOLON
	| function_def_list function_header SEMICOLON block SEMICOLON
	;

procedure_header
	: PROCEDURE profun_header
	;

function_header
	: FUNCTION profun_header SEMICOLON IDENTIFIER  // IDENTIFIER: scalar type
	;

profun_header
	: IDENTIFIER
	| IDENTIFIER LPAR formal_par_list RPAR
	;

formal_par_list
	: formal_par
	| formal_par_list SEMICOLON formal_par
	;

formal_par
	: VAR identifier_list COLON IDENTIFIER  // IDENTIFIER: type
	;

type
	: ordinal_type
	| IDENTIFIER  // IDENTIFIER: type
	| structured_type
	;

ordinal_type
	: IDENTIFIER // IDENTIFIER: ordinal type
	;
/* ignoring the green */

structured_type
	: IDENTIFIER  // IDENTIFIER: structured type
	| RECORD END
	| RECORD record_body END
	;

record_body
	: field_list
	| field_list SEMICOLON
	;

field_list
	: var_def
	| field_list SEMICOLON var_def
	;

statement
	: label_header safe_statement
	| label_header if_statement

whilefor_header
	: WHILE expression DO  // expression: bool
	| FOR IDENTIFIER ASSIGN  // IDENTIFIER: ordinal type variable
		expression FOR_DIRECTION expression  // expression: ordinal
		DO
	;

safe_statement
	: IF expression THEN label_header safe_statement ELSE label_header safe_statement
	| REPEAT statement UNTIL expression
	| whilefor_header label_header safe_statement
	| simple_statement_body
	;

if_statement
	: IF expression THEN statement
	| IF expression THEN label_header safe_statement ELSE label_header if_statement
	| whilefor_header label_header if_statement
	;

label_header
	: /* empty */
	| UINT COLON
	;

simple_statement_body
	: IDENTIFIER ASSIGN expression  // IDENTIFIER: variable || function identifier (return value)
	| IDENTIFIER  // IDENTIFIER: function || procedure
	| IDENTIFIER LPAR real_par_list RPAR  // IDENTIFIER: function || procedure
	| GOTO UINT
	| block_body
	;

variable
	: IDENTIFIER  // IDENTIFIER: variable
	| variable_noidentifier

variable_noidentifier
	: IDENTIFIER DOT IDENTIFIER  // IDENTIFIER: record_variable, field_identifier

real_par_list
	: expression
	| variable
	| real_par_list COMMA expression
	| real_par_list COMMA variable

expression
	: simple_expression
	| simple_expression OPER_REL simple_expression

simple_expression
	: add_expression
	| OPER_SIGNADD add_expression

add_expression
	: mul_expression
	| add_expression OPER_SIGNADD mul_expression
	| add_expression OR mul_expression

mul_expression
	: factor
	| mul_expression OPER_MUL factor

factor
	: unsigned_constant
	| variable_noidentifier
	| function_call
	| LPAR expression RPAR
	| NOT factor

function_call
	: IDENTIFIER  // IDENTIFIER: function
	| IDENTIFIER LPAR real_par_list RPAR  // IDENTIFIER: function

constant
	: unsigned_constant
	| OPER_SIGNADD UINT
	| OPER_SIGNADD REAL

unsigned_constant
	: IDENTIFIER  // IDENTIFIER: constant
	| UINT
	| REAL
	| STRING

%%


namespace yy {

    void mlaskal_parser::error(const location_type& l, const std::string& m)
    {
        message(DUERR_SYNTAX, l, m);
    }

}

