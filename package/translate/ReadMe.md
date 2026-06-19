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
| Template |     330 |       |
| de       | 261/330 |   79% |
| es       | 261/330 |   79% |
| fr       | 316/330 |   95% |
| hu_HU    | 306/330 |   92% |
| ko       | 261/330 |   79% |
| nl       | 261/330 |   79% |
| pl       | 261/330 |   79% |
| pt_BR    | 299/330 |   90% |
| ru       | 330/330 |  100% |
| tr       | 261/330 |   79% |
| uk       | 261/330 |   79% |
| zh_CN    | 294/330 |   89% |
| zh_HK    | 294/330 |   89% |
| zh_TW    | 294/330 |   89% |
