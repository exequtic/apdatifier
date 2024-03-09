<div align="center">

<img src="./screenshots/screenshot_1.png" width="500px" alt="banner"/>

![License](https://img.shields.io/github/license/exequtic/apdatifier?style=plastic&logo=gnu&color=red)
![Stars](https://img.shields.io/github/stars/exequtic/apdatifier?style=plastic&logo=github&color=blue)
![Badge](https://img.shields.io/badge/Beep-Boop-green?style=plastic&logo=dependabot)

# Apdatifier
## Arch Update Notifier

</div>

# Features
- Supports [AUR](#supported-pacman-wrappers) and Flatpak (without showing the runtime updates)
- Notification for new updates
- Button to initiate a full system upgrade in the selected [terminal](#supported-terminals)
- Customizable icon on the panel

<br>

<div align="center">
<img src="./screenshots/screenshot_2.jpg" width="350px" alt="banner"/>
<img src="./screenshots/screenshot_3.jpg" width="350px" alt="banner"/>
</div>

<br>

# Requirements
[pacman-contrib](https://archlinux.org/packages/extra/x86_64/pacman-contrib) - optional, but recommended

### Supported pacman wrappers
paru, trizen, yay

### Supported terminals
alacritty, foot, gnome-terminal, konsole, kitty, lxterminal, terminator, tilix, xterm, yakuake

<br>

# Installation

Just install directly from KDE Widget Store.

Or download with latest commit and install in one line command:
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