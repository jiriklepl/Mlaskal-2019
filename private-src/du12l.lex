%{
    // this code is emitted into du12l.cpp 
    // avoid macro redefinition warnings when compiling du1l.cpp
    #pragma warning (disable:4005)
    // avoid unreferenced parameter warnings when compiling du1l.cpp
    #pragma warning (disable:4100)
    // avoid unreferenced function warnings when compiling du1l.cpp
    #pragma warning (disable:4505)

    // allow access to YY_DECL macro
    #include "bisonflex.hpp"

    // allow access to context 
    // CHANGE THIS LINE TO #include "du3456g.hpp" WHEN THIS FILE IS COPIED TO du3456l.lex
    #include "dummyg.hpp"
%}

/* DO NOT TOUCH THIS OPTIONS! */
%option noyywrap nounput batch noinput stack reentrant
%option never-interactive

WS          [ \r\t\f]
DIGIT       [0-9]
UINT        {DIGIT}+
ALPHA       [A-Za-z]
ALNUM       [0-9A-Za-z]
A           [Aa]
B           [Bb]
C           [Cc]
D           [Dd]
E           [Ee]
F           [Ff]
G           [Gg]
H           [Hh]
I           [Ii]
J           [Jj]
K           [Kk]
L           [Ll]
M           [Mm]
N           [Nn]
O           [Oo]
P           [Pp]
Q           [Qq]
R           [Rr]
S           [Ss]
T           [Tt]
U           [Uu]
V           [Vv]
W           [Ww]
X           [Xx]
Y           [Yy]
Z           [Zz]

%%

%{
    typedef yy::mlaskal_parser parser;
%}

{P}{R}{O}{G}{R}{A}{M}       return parser::make_PROGRAM(ctx->curline);

{L}{A}{B}{E}{L}             return parser::make_LABEL(ctx->curline);
{C}{O}{N}{S}{T}             return parser::make_CONST(ctx->curline);
{T}{Y}{P}{E}                return parser::make_TYPE(ctx->curline);
{V}{A}{R}                   return parser::make_VAR(ctx->curline);

{B}{E}{G}{I}{N}             return parser::make_BEGIN(ctx->curline);
{E}{N}{D}                   return parser::make_END(ctx->curline);



{F}{U}{N}{C}{T}{I}{O}{N}    return parser::make_FUNCTION(ctx->curline);
{P}{R}{O}{C}{E}{D}{U}{R}{E} return parser::make_PROCEDURE(ctx->curline);
{R}{E}{C}{O}{R}{D}          return parser::make_RECORD(ctx->curline);



{I}{F}                      return parser::make_IF(ctx->curline);
{T}{H}{E}{N}                return parser::make_THEN(ctx->curline);
{E}{L}{S}{E}                return parser::make_ELSE(ctx->curline);

{W}{H}{I}{L}{E}             return parser::make_WHILE(ctx->curline);
{F}{O}{R}                   return parser::make_FOR(ctx->curline);
{D}{O}                      return parser::make_DO(ctx->curline);

{T}{O}                      return parser::make_FOR_DIRECTION(mlc::DUTOKGE_FOR_DIRECTION::DUTOKGE_TO, ctx->curline);
{D}{O}{W}{N}{T}{O}          return parser::make_FOR_DIRECTION(mlc::DUTOKGE_FOR_DIRECTION::DUTOKGE_DOWNTO, ctx->curline);

{R}{E}{P}{E}{A}{T}          return parser::make_REPEAT(ctx->curline);
{U}{N}{T}{I}{L}             return parser::make_UNTIL(ctx->curline);

{G}{O}{T}{O}                return parser::make_GOTO(ctx->curline);

{N}{O}{T}                   return parser::make_NOT(ctx->curline);

=                           return parser::make_EQ(ctx->curline);

"<"                         return parser::make_OPER_REL(mlc::DUTOKGE_OPER_REL::DUTOKGE_LT, ctx->curline);
"<="                        return parser::make_OPER_REL(mlc::DUTOKGE_OPER_REL::DUTOKGE_LE, ctx->curline);
"<>"                        return parser::make_OPER_REL(mlc::DUTOKGE_OPER_REL::DUTOKGE_NE, ctx->curline);
">="                        return parser::make_OPER_REL(mlc::DUTOKGE_OPER_REL::DUTOKGE_GE, ctx->curline);
">"                         return parser::make_OPER_REL(mlc::DUTOKGE_OPER_REL::DUTOKGE_GT, ctx->curline);

"+"                         return parser::make_OPER_SIGNADD(mlc::DUTOKGE_OPER_SIGNADD::DUTOKGE_PLUS, ctx->curline);
"-"                         return parser::make_OPER_SIGNADD(mlc::DUTOKGE_OPER_SIGNADD::DUTOKGE_MINUS, ctx->curline);

"*"                         return parser::make_OPER_MUL(mlc::DUTOKGE_OPER_MUL::DUTOKGE_ASTERISK, ctx->curline);
"/"                         return parser::make_OPER_MUL(mlc::DUTOKGE_OPER_MUL::DUTOKGE_SOLIDUS, ctx->curline);
{D}{I}{V}                   return parser::make_OPER_MUL(mlc::DUTOKGE_OPER_MUL::DUTOKGE_DIV, ctx->curline);
{M}{O}{D}                   return parser::make_OPER_MUL(mlc::DUTOKGE_OPER_MUL::DUTOKGE_MOD, ctx->curline);
{A}{N}{D}                   return parser::make_OPER_MUL(mlc::DUTOKGE_OPER_MUL::DUTOKGE_AND, ctx->curline);

\(                          return parser::make_LPAR(ctx->curline);
\)                          return parser::make_RPAR(ctx->curline);
\[                          return parser::make_LSBRA(ctx->curline);
\]                          return parser::make_RSBRA(ctx->curline);

,                           return parser::make_COMMA(ctx->curline);
\.                          return parser::make_DOT(ctx->curline);
\.\.                        return parser::make_DOTDOT(ctx->curline);

:=                          return parser::make_ASSIGN(ctx->curline);
:                           return parser::make_COLON(ctx->curline);
;                           return parser::make_SEMICOLON(ctx->curline);

{ALPHA}{ALNUM}* {
    return parser::make_IDENTIFIER(mlc::ls_id_index(), ctx->curline);
}

{UINT} {
    return parser::make_UINT(mlc::ls_int_index(), ctx->curline);
}

{UINT}(\.|(\.{UINT})?{E}[+-]?){UINT} {
    return parser::make_REAL(mlc::ls_real_index(), ctx->curline);
}

{WS}+       /* go out with whitespaces */

\n          /* we do nothing yet */

.           message(mlc::DUERR_UNKCHAR, ctx->curline, *yytext, *yytext);

<<EOF>>     return parser::make_EOF(ctx->curline);

%%

namespace mlc {

    yyscan_t2 lexer_init(FILE * iff)
    {
        yyscan_t2 scanner;
        yylex_init(&scanner);
        yyset_in(iff, scanner);
        return scanner;
    }

    void lexer_shutdown(yyscan_t2 scanner)
    {
        yyset_in(nullptr, scanner);
        yylex_destroy(scanner);
    }

}
