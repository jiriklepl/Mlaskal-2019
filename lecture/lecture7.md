# HW4 assignment

## Typy v bisonu

Tokeny:

```bison
%token<T> TOKEN
```

Neterminaly:

```bison
%type<T> neterminal
```

## C++ kod v bisonu

```bison
// 1 2 3 4 5 -> dolarova notace B == $1 atd
A: B C D E F; {
    // $$ znaci A (jakoby to co vraci)

    // A.a = B.a + D.a:
    $$.a = $1.a + $3.a

    // @ pak znaci pozici toho neterminalu a podobne @@
    }
// 1    2    3
P: A { c++ } B {
    // v ty dvojce jde pouzivat jenom od 2 doleva
    c++ kod
}
```
