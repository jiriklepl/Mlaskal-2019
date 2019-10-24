# BOTTOM-UP analysis

- provadeni redukci odspoda nahoru (od listu ke korenu)
- LR (dela to prave (ne derivace) redukce)
- dela to i Bison trebaaa
- vsechny rozumny jazyky sou LR(1) - jinak mame problem (muzeme hackovat treba tabulkama - jinak nejde parsovat treba ani cecko)
- **YAGHOB je ma radsi**

---

## Automat

- paska je paska, na zasobniku je dvojce (stav : cislo, symbol) + nakej pocatecni stav
- Bison podvadi - ma vic zasobniku, ale chovaj se jak jeden jakoby
- dve tabulky: action a goto
- vystup: pri kazdy redukci vystup + ano/ne

1) paska ukazuje na prvni terminal a mame pocatecni stav na zasobniku
2) vzdycky se divame do tabulky action (souradnice terminal stav) a tam sou ctyri ruzny mozny akce co provist - stav podle stacku, akce mame shift, reduce, accept a error
    - shift: posunuti pasky o jedna
        - terminal se z pasky ulozi na zasobnik, posune se stav, divame se na dalsi terminal (je to zraci)
    - reduce: podle prepisovaciho pravidla
        - podle poctu symbolu na pravy strane pravidla odebereme pocet dvojic ze stacku, pak se podivame do tabulky goto na stav co je ted na vrsku zasobniku a sparovanyho s levou stranou provedeneho pravidla (souradnice neterminal stav)

---

## Rozsirovani automatu

```lex

"stavy": (lex tomu tak rika)
INITIAL <- to je implicitni nazev hlavniho automatu
%s INCL <- tohle rozsiri ten automat
%x STR <- jakoby jinej automat uplne, nerozpoznava INITIAL veci

<STR,INITIAL> RV5 <- cteny INITIAL, INCL, STR>
<INCL> RV1 <- cteny INCL
RV2 <- cteny INCL a INITIAL
<STR>{ <- vse tady cteny jen STR...
RV3
RV4
}

BEGIN(STR) <- prepneme do STR
BEGIN(INITIAL) <- prepneme se do zakladniho automatu

\n inkrementujeme ctx->curline;
```

NL na konci stringu je chyba.. ALE POZOR! EOF na konci stringu je uplne jina chyba, ale zachovavame se na to normalne, dame to proste do tabulky... jooo a ten newline se furt pocita (jen aby nebyly nejasnosti).

je i chyba na neukoncenej komentar (az u EOFu), nebo na spatny parovani komentarovejch zavorek.

musime prevadet  inty rucne (floaty ne, na to mame pouzit naky std) - to co rozeznavame musime kontrolovat ze se vejde do uint31, kdyby ne, tak udelame WARNING a ulozime dolnich 31 bitu.

slozity chyby: (malformovany elementy)
- treba 12xy (takle to vypada jako uint identifikator), ale je to spatnej integer (malformovanej integer), vratime tu 12 a zahlasime chybu (muze to bejt jeste kombinovany s tim dlouhym cislem)
- 3. je treba malformovanej real, nebo 3.1E, atd
    - to se zase muze kombit s pravidlem nad
    - furt se to dava do ty tabulky ale
    - 3EAB je malformovanej int furt s prilepenym EAB
    - 3..4 takle se v pascalu zapisuje interval
        - uint dotdot uint

+ lex.backup: nemel by tam bejt (resp 'no backup'), ale neni to rozhodna vec (je to jen vec vykonu)