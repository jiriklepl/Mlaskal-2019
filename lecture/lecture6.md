# BISON

- Přepsat vše z diagramů do gramatiky Bisonu (co obrázek, to jedno pravidlo)
- Nic neměnit v definicích nahoře

+ **%start mlaskal**: určuje počáteční neterminál
+ **%token EOF**: definuje token EOF
+ **%token XXX\<PAR>**: definuje token XXX s parametrem PAR

Pravidlo se třemi přepisy (afa, beta, gama = TOKEN):

```bison
a
    : alfa
      alfa2
      alfa3 { c++; }
    | beta beta2 beta3 { c++; }
    | TOKEN { c++; }
    ;
```

- Je zvyk psát tokeny velkejma a neterminály malejma
- nemáme cykly - použijem rekurzi

```bison
blblabels
    : %empty
    | LABEL hnus SEMICOLON { c++; }

/* A(BA)* (cyklus) */
aba
    : A
    | aba B A
```

- Je dobrý rozdělovat pravidla... Kdyby náhodou záleželo na nákym něčem

**Konflikty:**

- Pozor na if then else
- Některý různý věci sou vlastně stejný
- Musíme si někam zapamatovat co vlastně máme  (do komentáře):

```bison
expression
    : expression AND expression /* boolean expression TODO in ass4,5,6 */
```

```bison
factor
    : const_no_id
    | variable_no_id
    | ID ( ... )
    | ID
    ;

const
    : ID
    | UINT
    | STRING
    | REAL
    ;

const_no_id
    : UINT
    | STRING
    | REAL
    ;

variable
    : ID
    | variable DOT id
    ;

variable_no_id
    : variable DOT id
    ;

```