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
| Template |     342 |       |
| de       | 332/342 |   97% |
| es       | 332/342 |   97% |
| fr       | 332/342 |   97% |
| hu_HU    | 332/342 |   97% |
| ko       | 332/342 |   97% |
| nl       | 332/342 |   97% |
| pl       | 332/342 |   97% |
| pt_BR    | 332/342 |   97% |
| ru       | 342/342 |  100% |
| tr       | 332/342 |   97% |
| uk       | 332/342 |   97% |
| zh_CN    | 332/342 |   97% |
| zh_HK    | 332/342 |   97% |
| zh_TW    | 332/342 |   97% |
