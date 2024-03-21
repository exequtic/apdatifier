<div align="center">

<img src="./screenshots/header.png" width="200px" alt="banner"/>

<!-- ![License](https://img.shields.io/github/license/exequtic/apdatifier?style=plastic&logo=gnu&color=red)
![Stars](https://img.shields.io/github/stars/exequtic/apdatifier?style=plastic&logo=github&color=blue) -->


# Apdatifier
## Arch Update Notifier

</div>

# Features
- Notification for new updates
- Supports [AUR](#supported-pacman-wrappers) and Flatpak (without showing the runtime updates)
- Button to initiate a full system upgrade in the selected [terminal](#supported-terminals)
- Option to refresh the mirrorlist with the latest mirrors filtered by speed
- Customizable icon on the panel

<br>

<div align="center">
<img src="./screenshots/screenshot_2.jpg" width="300px" alt="screenshot"/>
<img src="./screenshots/screenshot_1.jpg" width="300px" alt="screenshot"/>
<img src="./screenshots/screenshot_3.jpg" width="300px" alt="screenshot"/>
</div>

<br>

# Requirements
[pacman-contrib](https://archlinux.org/packages/extra/x86_64/pacman-contrib) - optional, but <b>recommended</b>. For checkupdates and rankmirrors scripts.

### Supported pacman wrappers
paru, trizen, yay

### Supported terminals
alacritty, foot, gnome-terminal, konsole, kitty, lxterminal, terminator, tilix, xterm, yakuake

<br>

# Installation

Just install directly from KDE Widget Store ("+ Add widgets..." -> "Get New Widgets..." -> "Download New Plasma Widgets").

After installation, the widget icon should <b>automatically</b> appear in the system tray.

>[!WARNING]
>If you had the previous version installed, you may need to Log Out or restart plasmashell after install.
>```bash
>killall plasmashell && kstart plasmashell
>```

### Uninstall
```bash
sh ~/.local/share/plasma/plasmoids/com.github.exequtic.apdatifier/contents/tools/tools.sh uninstall
```

<br>

## Settings
<div align="center">

<img src="./screenshots/settings_1.png" width="500px" alt="Settings"/>

<img src="./screenshots/settings_2.png" width="500px" alt="Settings"/>

<img src="./screenshots/settings_3.png" width="500px" alt="Settings"/>

</div>