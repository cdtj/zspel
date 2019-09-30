# zspel

zspel is a set of tools for CA Service Desk packed to reduce routine operations and ease spel coding.

### why is zpsel
zspel is about *z* which is prefix for all CA SDM customization forms/scripts/schemas and *spel* which is CA SDM inner programming language.

## Installing

Copy zspel.frg to folder which can be accessed by SDM daemon controlled user.

### majic installation

* Create `zinclude.spl` file within `$NX_ROOT/site/mods/majic` folder with followed notation:
```
#include "<full_path>/zspel.frg"
```
* Restart services

### webengine installation

* Create `zinclude.spl` file within `$NX_ROOT/site/mods/www` folder with followed notation:
```
#include "<full_path>/zspel.frg"
```
* Restart services

### bop_cmd installation

* Simply include `zpsel.frg` in your frg script file:
```
#include "<full_path>/zspel.frg"
```

## Running the tests

All test units provided in `zspel_test.frg`
