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
| Template |     315 |       |
| de       | 282/315 |   89% |
| es       | 282/315 |   89% |
| fr       | 282/315 |   89% |
| ko       | 282/315 |   89% |
| nl       | 282/315 |   89% |
| pl       | 282/315 |   89% |
| pt_BR    | 282/315 |   89% |
| ru       | 282/315 |   89% |
| tr       | 282/315 |   89% |
| uk       | 282/315 |   89% |
| zh       | 282/315 |   89% |
