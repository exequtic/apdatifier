> Version 7 of Zren's i18n scripts.

## New Translations

Fill out [`template.pot`](template.pot) with your translations then open a [new issue](https://github.com/exequtic/apdatifier/issues/new), name the file with the extension `.txt`, attach the txt file to the issue (drag and drop).

Or if you know how to make a pull request:

Copy the [`template.pot`](template.pot) file to [`./po`](po) directory and name it your locale's code (Eg: `en`/`de`/`fr`) with the extension `.po`. Then fill out all the `msgstr ""`.

## Scripts

* `sh ./merge` will parse the `i18n()` calls in the `*.qml` files and write it to the `template.pot` file. Then it will merge any changes into the `*.po` language files.
* `sh ./build` will convert the `*.po` files to it's binary `*.mo` version and move it to `contents/locale/...`

## Links

* https://zren.github.io/kde/docs/widget/#translations-i18n
* https://github.com/Zren/plasma-applet-lib/tree/master/package/translate

## Status
|  Locale  |  Lines  | % Done|
|----------|---------|-------|
| Template |     256 |       |
| de       | 256/256 |  100% |
| es       | 256/256 |  100% |
| fr       | 256/256 |  100% |
| ko       | 130/256 |   50% |
| nl       | 256/256 |  100% |
| pl       | 256/256 |  100% |
| pt_BR    | 256/256 |  100% |
| ru       | 256/256 |  100% |
| zh       | 256/256 |  100% |
