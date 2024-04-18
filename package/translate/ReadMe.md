> Version 7 of Zren's i18n scripts.

## Install Translations
The `*.mo` files are not included in the `.plasmoid` file, so they need to be created manually.

```
cd ~/.local/share/plasma/plasmoids/com.github.exequtic.apdatifier/translate/
sh ./build
```

Afterwards, restart plasmashell.

## New Translations

1. Fill out [`template.pot`](template.pot) and [`template.sh`](template.sh) with your translations then open a [new issue](https://github.com/exequtic/apdatifier/issues/new), name the files with the extension `.txt`, attach the txt files to the issue (drag and drop).

Or if you know how to make a pull request

1. Copy the `template.pot` file and name it your locale's code (Eg: `en`/`de`/`fr`) with the extension `.po`. Then fill out all the `msgstr ""`.
2. Copy the `template.sh` file and name it your locale's code (Eg: `en`/`de`/`fr`) with the extension `.sh`. Then fill out all the `VAR=""`.

## Scripts

* `sh ./merge` will parse the `i18n()` calls in the `*.qml` files and write it to the `template.pot` file. Then it will merge any changes into the `*.po` language files.
* `sh ./build` will convert the `*.po` files to it's binary `*.mo` version and move it to `contents/locale/...`

## Links

* https://zren.github.io/kde/docs/widget/#translations-i18n
* https://github.com/Zren/plasma-applet-lib/tree/master/package/translate

## Status
|  Locale  |  Lines  | % Done|
|----------|---------|-------|
| Template |     132 |       |
| nl       |  47/132 |   35% |
| ru       | 132/132 |  100% |
