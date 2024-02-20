<div align="center">

<img src="./screenshots/screenshot_1.png" width="500px" alt="banner"/>

![License](https://img.shields.io/github/license/exequtic/apdatifier?style=plastic&logo=gnu&color=red)
![Stars](https://img.shields.io/github/stars/exequtic/apdatifier?style=plastic&logo=github&color=blue)
![Badge](https://img.shields.io/badge/Beep-Boop-green?style=plastic&logo=dependabot)

# Apdatifier
## Arch Update Notifier

</div>

# Features
- Choice between pacman, checkupdates, pacman [wrappers](#supported-pacman-wrappers)
- Supports Flatpak (without showing the runtime updates)
- Should work on other distributions, but only Arch Linux will support system updates, while in other only Flatpak will be supported.
- Notification for new updates
- Button for downloading fresh package databases
- Button to initiate a full system upgrade in the selected [terminal](#supported-terminals)
- Customizable icon on the panel and update list
- The list with updates is presented as a table, so you can rearrange columns, resize them, and sort by name/repository.

<div align="center">

<br>

![screenshot](./screenshots/screenshot_2.png)

</div>

<br>

# Requirements
>[!WARNING]
>Before install plasmoid, make sure you have the org.kde.notification qml module installed

Arch Linux
```bash
sudo pacman -S knotifications5
```

KDE Neon
```bash
sudo apt install qml-module-org-kde-notification
```

Kubuntu
```bash
sudo apt install qml-module-org-kde-notifications
```

Fedora
```bash
sudo dnf install kf5-knotification
```

### For Steam Deck
If you haven't done this before:
```bash
sudo steamos-readonly disable
sudo pacman-key --init
sudo pacman-key --populate archlinux
```

### Supported pacman wrappers
paru, trizen, yay

### Supported terminals
alacritty, foot, gnome-terminal, konsole, kitty, lxterminal, terminator, tilix, xterm, yakuake

<br>

# Installation
Just install directly from KDE Widget Store.

Or download with latest commit and install in one line command:
```bash
curl -fsSL https://raw.githubusercontent.com/exequtic/apdatifier/KF5/package/contents/tools/tools.sh | sh -s install
```

After installation, the widget icon should automatically appear in the system tray. If this does not happen, Log Out or restart plasmashell/latte-dock.

### Uninstall
```bash
sh ~/.local/share/plasma/plasmoids/com.github.exequtic.apdatifier/contents/tools/tools.sh uninstall
```

<br>

# Translation
You can help translate this widget into other languages, please refer to the [ReadMe.md](https://github.com/exequtic/apdatifier/blob/main/package/translate/ReadMe.md) for instructions on how to do it.

### Current status:
```markdown
|  Locale  |  Lines  | % Done|
|----------|---------|-------|
| English  |      78 |       |
| Russian  |   78/78 |  100% |
| Dutch    |   78/78 |  100% |
|----------|---------|-------|
```


<div align="center">

<br>

# Screenshots

![screenshot](./screenshots/screenshot_3.png)
---
![screenshot](./screenshots/screenshot_4.png)
---
![screenshot](./screenshots/screenshot_5.png)
---
![screenshot](./screenshots/screenshot_6.png)
---
![screenshot](./screenshots/screenshot_7.png)

</div>
