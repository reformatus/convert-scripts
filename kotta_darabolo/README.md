**Tartalom** (mert tudta automatikusan a .md extension, why not)
- [Kottadarabolási elvek](#kottadarabolási-elvek)
  - [1. Sorok száma szerint](#1-sorok-száma-szerint)
  - [2. Ellenőrzés: Képarány szerint](#2-ellenőrzés-képarány-szerint)
    - [Felbontás módja](#felbontás-módja)
- [Szövegdarabolási elvek](#szövegdarabolási-elvek)
    - [Sorok hosszának ellenőrzése abban az esetben, ha a `/` jellel elválasztott sorok is külön sorba kerülnek.](#sorok-hosszának-ellenőrzése-abban-az-esetben-ha-a--jellel-elválasztott-sorok-is-külön-sorba-kerülnek)
    - [Ha az ének maradék sorainak száma **páros**](#ha-az-ének-maradék-sorainak-száma-páros)
    - [Ha az ének maradék sorainak száma **páratlan**](#ha-az-ének-maradék-sorainak-száma-páratlan)

# Kottadarabolási elvek

## 1. Sorok száma szerint
A sorok pixeltartományából ciklussal 3 soronként diára illeszteni.

Ha 4 sor van hátra: 2 + 2 soros dia

## 2. Ellenőrzés: Képarány szerint
Egy dia képaránya **minimum** (pl.) **16:11**-et érheti el, ha közelebb van a négyzethez, fel kell bontani.

### Felbontás módja

Ha csak 2 sort tud hozzáadni, hozzáad annyit. Ha még úgy is rossz a képarány, csak 1 sort.

Végül figyelmeztetés konzolra és file-ba, ha
1. az utolsó dián csak egy sor van
2. van 1 soros dia

---

# Szövegdarabolási elvek

[Énekeskönyv konvertáló scriptben található.](https://github.com/reformatus/convert-scripts/tree/main/ujrek_to_opensong)

### Sorok hosszának ellenőrzése abban az esetben, ha a `/` jellel elválasztott sorok is külön sorba kerülnek.
 - Ha kevesebb, mint 4 soros az ének, mindenképp figyelembe vesszük a `/`-t.
 - Ha túl rövidek (szavak számának átlaga kevesebb, mint (pl.) 4), akkor csak a `\n`-el jelölt sortöréseket vesszük figyelembe.

### Ha az ének maradék sorainak száma **páros**
 - Legfeljebb 4 sor hozzáadása
 - Ha túl hosszú diát eredményez, 2 sor 
 - Ha túl hosszú, 1 sor

### Ha az ének maradék sorainak száma **páratlan**
 - Legfeljebb 3 sor hozzáadása
 - Ha túl hosszú, 2 sor
 - Ha túl hosszú, 1 sor