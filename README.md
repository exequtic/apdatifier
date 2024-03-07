<div align="center">

<img src="./screenshots/screenshot_1.png" width="500px" alt="banner"/>

<!-- ![License](https://img.shields.io/github/license/exequtic/apdatifier?style=plastic&logo=gnu&color=red) -->
<!-- ![Stars](https://img.shields.io/github/stars/exequtic/apdatifier?style=plastic&logo=github&color=blue) -->
<!-- ![Badge](https://img.shields.io/badge/Beep-Boop-green?style=plastic&logo=dependabot) -->

# Apdatifier
## Arch Update Notifier

</div>


## Beta version for Plasma 6

### Installation

Download with latest commit and install in one line command:
```bash
curl -fsSL https://raw.githubusercontent.com/exequtic/apdatifier/main/package/contents/tools/tools.sh | sh -s install
```

>[!WARNING]
>After installation, the widget icon should automatically appear in the system tray. If this does not happen, Log Out or restart plasmashell
>```bash
>killall plasmashell && kstart plasmashell
>```

### Uninstall
```bash
sh ~/.local/share/plasma/plasmoids/com.github.exequtic.apdatifier/contents/tools/tools.sh uninstall
```