# The Third Lecture


## FEEERST($\alpha$)

- operator, co ze slova terminalu/neterrminalu $\alpha$ vrati mnozinu terminalu (abecedy), kterejma muzou vsechny vysledky zacinat (muze tam ale i patrit prazdny slovo, pokud se alpha da prepsat na prazdny slovo!!!)

konstrukce pro terminaky/neterminaly:

1. if X je terminal, dej X do FIRST
1. if X je neterminal a X->prazdny slovo je v produkci, tak dej prazdny slovo do FIRST(X)
1. if X je neterminal a X->Y1Y2Y3... a vsechny Y1..Yi maj FIRST(Yi) v soube prazdny slovo a FIRST(Y(i+1)) ma v sobe naky a, tak dej do FIRST(X) taky a

konstrukce pro slova:

1. pro FIRST(X1...Xi) postupuj stejne jako bys postupoval s FIRST(S'), kde S' -> X1...Xi.

## FOLLOW(A)
- A je neterminal, tenhle operator vrati zase mnozinu, ale vsech terminalu (abecednich symbolu), ktery se mohou bezprostredne objevit za A. Pridavame zde jeste bonusovej symbol $ (jako je v regexech)

konstrukce pro neterminal A:
1. plejsuj \$ do FOLLOW(S) - S je startovni symbol a \$ je konecnej
1. kdyz mame A -> $\alpha B\beta$ tak vsechno z FIRST($\beta$) dej do FOLLOW(B)
1. pokud mame A -> $\alpha B$ nebo i A -> $\alpha B\beta$, kde prazdny slovo je ve FOLLOW($\beta$), tak dej vsechno z FOLLOW(A) do FOLLOW(B).


## Jak to udelat

1. se udelaj FIRST (a nejdriv pro terminaly, pak neterminaly).
1. ted dem na FOLLOW - jen pro neterminaly (nastesti).
    1. dame dolar do FOLLOW pocatecniho symbolu
    1. zacneme z pocatecnim symbolem
    1. kdyz neco delame, tak si to hledame na pravej stranach pravidel (to jest v prepisech (ne uplne nakonci)!!!) a divej se co se muze vyskytnout po tom, pokud je to v tom pravidlu v prepisu uplne na konci, dej tam veci z FOLLOW prepisovanyho pravidla, jinak kdyz to neni na konci, tak tam dej FIRST z toho co je hned potom
        - treba u S -> xAa | xAB | xA, tak u FOLLOW(A) bude a, vsechno z FIRST(B) a kvuli poslednimu prepisu i vsechno z FOLLOW(S).
- NEMELI BY TO DELAT LIDI

## TOP-DOWN prasovani

Metody:

1. Rekurzivni sestup -- to je treba GCC (i G++, oboji psano rucne).
    - udelame si procedury (zasobnik schovanej ve volani procedur) -- pro kazdej neterminal jedna funkce - spocitame FIRST pravejch stran a na zaklade lookaheadu se vybere pravidlo.
        - lambda ve FIRST znamena konec (to matchuje jakoby lookahead neznamyho symbolu)
        - neprazdnej prunik FIRST dvou ruznejch prepisu symbolu znamena fail (proto delat faktorizaci - to jest nahradit stejny zacatky pravidel novym pravidlem - A -> aB | aC zmenime na A -> aA', A' -> B | C).
        - kdyz to co ocekavame ve FIRST a je na pasce si odpovida, tak to sezerem a podle toho co je v tom pravidle, odkud ta vec ve FIRST je, se zachovame zavolanim procedury pro kazdy neterminal: A -> aBC a na pasce je 'a', tak zereme 'a' a volame (v poradi) B a C.
1. Poctivej zasobnikovej automat s tabulkama (to je program toho samotnyho parseru)

- ANTLR, CocoR -- to sou LL1 gramatiky a divame se jen na jeden symbol, konflikty se resi look-aheadem LL(k) az do k = 5.
