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
| Template |     318 |       |
| de       | 279/318 |   87% |
| es       | 279/318 |   87% |
| fr       | 313/318 |   98% |
| ko       | 279/318 |   87% |
| nl       | 279/318 |   87% |
| pl       | 279/318 |   87% |
| pt_BR    | 279/318 |   87% |
| ru       | 317/318 |   99% |
| tr       | 279/318 |   87% |
| uk       | 279/318 |   87% |
| zh_CN    | 313/318 |   98% |
| zh_HK    | 313/318 |   98% |
| zh_TW    | 313/318 |   98% |
