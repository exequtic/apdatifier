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
| Template |     317 |       |
| de       | 281/317 |   88% |
| es       | 281/317 |   88% |
| fr       | 281/317 |   88% |
| ko       | 281/317 |   88% |
| nl       | 281/317 |   88% |
| pl       | 281/317 |   88% |
| pt_BR    | 281/317 |   88% |
| ru       | 317/317 |  100% |
| tr       | 281/317 |   88% |
| uk       | 281/317 |   88% |
| zh       | 281/317 |   88% |
