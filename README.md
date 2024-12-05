<div align="center">

<img src="./screenshots/header.png" width="200px" alt="banner"/>

<br>

![License](https://img.shields.io/github/license/exequtic/apdatifier?style=flat&logo=gnu&logoColor=white&label=License&color=brown)&nbsp;&nbsp;
![Downloads](https://img.shields.io/github/downloads/exequtic/apdatifier/total?style=flat&logo=kdeplasma&logoColor=white&label=Downloads&color=red)&nbsp;&nbsp;
![Stars](https://img.shields.io/github/stars/exequtic/apdatifier?style=flat&logo=github&logoColor=white&label=Stars&color=blue)

<br>

# Apdatifier
## Arch Update Notifier

</div>

# Features
- Notification for updates and news
- Searching updates for [Arch](https://archlinux.org/packages/) (+[AUR](https://aur.archlinux.org/packages)), [Plasma Widgets](https://store.kde.org/browse?cat=705), [Flatpak](https://flathub.org)
- Bash script with useful options for managing packages
- Two types of lists: compact and extended with additional information
- Button to initiate a full system upgrade in the selected [terminal](#supported-terminals)
- Option to refresh the [mirrorlist](https://archlinux.org/mirrorlist) with the latest mirrors filtered by speed
- Customizable icon on the panel and package icons in the list
- Also should work on non-Arch-based systems (for Plasma Widgets and Flatpak)

<br>

# Screenshots

<div align="center">

#### Compact/Extended list
<img src="./screenshots/screenshot_1.png" width="300px" alt="screenshot"/>
&nbsp;&nbsp;&nbsp;
<img src="./screenshots/screenshot_2.png" width="300px" alt="screenshot"/>
&nbsp;&nbsp;&nbsp;

<br>

#### Full system upgrade
<img src="./screenshots/screenshot_4.png" width="600px" alt="screenshot"/>

<br>

#### Management
<img src="./screenshots/screenshot_3.png" width="600px" alt="screenshot"/>

<br><br>

https://github.com/exequtic/apdatifier/assets/29355358/9751fc8f-29c2-4f7d-8f1f-c346c0748df3

</div>

<br>

# Requirements
[pacman-contrib](https://archlinux.org/packages/extra/x86_64/pacman-contrib) - optional, but <b>HIGHLY RECOMMENDED</b>. For checkupdates and rankmirrors scripts.

### Supported pacman wrappers
paru, yay

### Supported terminals
alacritty, foot, gnome-terminal, konsole, kitty, lxterminal, terminator, tilix, xterm, yakuake, wezterm

<!-- *yakuake used the D-Bus method runCommand via the qdbus6. -->

### Required utilities for options:
<b>Plasma Widgets:</b> curl, jq, unzip, tar<br>
<b>Mirrorlist Generator:</b> curl, pacman-contrib<br>
<b>Management</b>: fzf<br>
<b>News:</b> curl, jq<br>

<br>

# Translation
Feel free to help translate to new languages or update and improve the ones that are already available. Please refer to the [ReadMe.md](https://github.com/exequtic/apdatifier/blob/main/package/translate/ReadMe.md) for instructions on how to do it.

### Current status:
```markdown
|   Locale  |  Lines  | % Done|
|-----------|---------|-------|
| English   |     232 |       |
| Brazilian | 232/232 |  100% |
| Dutch     | 185/232 |   79% |
| French    | 184/232 |   79% |
| German    | 184/232 |   79% |
| Spanish   | 232/232 |  100% |
| Korean    | 136/232 |   58% |
| Russian   | 232/232 |  100% |
|-----------|---------|-------|
```

<br>

# Installation

Just install directly from KDE Widget Store ("+ Add widgets..." -> "Get New Widgets..." -> "Download New Plasma Widgets").

After installation, the widget icon should <b>automatically</b> appear in the system tray.

>[!IMPORTANT]
>If you are upgrading from a previous version, you need to log out or restart plasmashell for the new features to work properly.
>```bash
>systemctl --user restart plasma-plasmashell.service
>```

<br>

<!-- ### Uninstall
```bash
bash ~/.local/share/plasma/plasmoids/com.github.exequtic.apdatifier/contents/tools/tools.sh uninstall
``` -->

# Support the project

If you like this project, you can

<a href="https://www.buymeacoffee.com/evgk" target="_blank" title="buymeacoffee">
  <img src="https://iili.io/JoQ1MeS.md.png" alt="buymeacoffee-yellow-badge" style="width: 192px;">
</a>

<br>

