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

/* MORE OPTIONS */
%option caseless

WS          [ \r\t\f]
DIGIT       [0-9]
UINT        {DIGIT}+
ALPHA       [A-Z]
ALNUM       [A-Z0-9]

%%

%{
    typedef yy::mlaskal_parser parser;
%}

PROGRAM     return parser::make_PROGRAM(ctx->curline);

LABEL       return parser::make_LABEL(ctx->curline);
CONST       return parser::make_CONST(ctx->curline);
TYPE        return parser::make_TYPE(ctx->curline);
VAR         return parser::make_VAR(ctx->curline);

BEGIN       return parser::make_BEGIN(ctx->curline);
END         return parser::make_END(ctx->curline);



FUNCTION    return parser::make_FUNCTION(ctx->curline);
PROCEDURE   return parser::make_PROCEDURE(ctx->curline);
RECORD      return parser::make_RECORD(ctx->curline);



IF          return parser::make_IF(ctx->curline);
THEN        return parser::make_THEN(ctx->curline);
ELSE        return parser::make_ELSE(ctx->curline);

WHILE       return parser::make_WHILE(ctx->curline);
FOR         return parser::make_FOR(ctx->curline);
DO          return parser::make_DO(ctx->curline);

(DOWN)?TO {
    return parser::make_FOR_DIRECTION(
        ((yytext[0] | 32) == 'd')
            ? mlc::DUTOKGE_FOR_DIRECTION::DUTOKGE_DOWNTO
            : mlc::DUTOKGE_FOR_DIRECTION::DUTOKGE_TO,
        ctx->curline);
}

REPEAT      return parser::make_REPEAT(ctx->curline);
UNTIL       return parser::make_UNTIL(ctx->curline);

GOTO        return parser::make_GOTO(ctx->curline);

NOT         return parser::make_NOT(ctx->curline);

=           return parser::make_EQ(ctx->curline);

[<>]=?|<> {
    mlc::DUTOKGE_OPER_REL tmp;
    switch(yytext[1]) {
        case '=':
            tmp = (mlc::DUTOKGE_OPER_REL)1;
        break;

        case '>':
            tmp = (mlc::DUTOKGE_OPER_REL)2;
        break;
        
        default:
            tmp = (mlc::DUTOKGE_OPER_REL)0;
        break;
    }

    return parser::make_OPER_REL(
        (yytext[0] == '>')
            ? (mlc::DUTOKGE_OPER_REL)(4 - (int)tmp)
            : tmp,
        ctx->curline);
}

[+-] {
    return parser::make_OPER_SIGNADD(
        (yytext[0] == '+')
            ? mlc::DUTOKGE_OPER_SIGNADD::DUTOKGE_PLUS
            : mlc::DUTOKGE_OPER_SIGNADD::DUTOKGE_MINUS,
        ctx->curline);
}

[*/]|DIV|(MO|AN)D {
    mlc::DUTOKGE_OPER_MUL tmp;
    switch(yytext[0] | 32) {
        case '*':
            tmp = mlc::DUTOKGE_OPER_MUL::DUTOKGE_ASTERISK;
        break;
        
        case '/':
            tmp = mlc::DUTOKGE_OPER_MUL::DUTOKGE_SOLIDUS;
        break;
        
        case 'd':
            tmp = mlc::DUTOKGE_OPER_MUL::DUTOKGE_DIV;
        break;
        
        case 'm':
            tmp = mlc::DUTOKGE_OPER_MUL::DUTOKGE_MOD;
        break;
        
        case 'a':
            tmp = mlc::DUTOKGE_OPER_MUL::DUTOKGE_AND;
        break;
    }

    return parser::make_OPER_MUL(tmp, ctx->curline);
}

\(          return parser::make_LPAR(ctx->curline);
\)          return parser::make_RPAR(ctx->curline);
\[          return parser::make_LSBRA(ctx->curline);
\]          return parser::make_RSBRA(ctx->curline);

,           return parser::make_COMMA(ctx->curline);
\.          return parser::make_DOT(ctx->curline);
\.\.        return parser::make_DOTDOT(ctx->curline);

:=          return parser::make_ASSIGN(ctx->curline);
:           return parser::make_COLON(ctx->curline);
;           return parser::make_SEMICOLON(ctx->curline);

{ALPHA}{ALNUM}* {
    return parser::make_IDENTIFIER(mlc::ls_id_index(), ctx->curline);
}

{UINT} {
    return parser::make_UINT(mlc::ls_int_index(), ctx->curline);
}

{UINT}(\.|(\.{UINT})?E[+-]?){UINT} {
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
