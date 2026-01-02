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
### Supported pacman wrappers
paru, yay, pikaur

### Supported terminals
alacritty, foot, gnome-terminal, ghostty, konsole, kitty, lxterminal, ptyxis, terminator, tilix, xterm, yakuake, wezterm

<br>

# Translation
Feel free to help translate to new languages or update and improve the ones that are already available. Please refer to the [ReadMe.md](https://github.com/exequtic/apdatifier/blob/main/package/translate/ReadMe.md) for instructions on how to do it.

### Current status:
```markdown
|   Locale  |  Lines  | % Done|
|-----------|---------|-------|
| English   |     282 |       |
| Brazilian | 275/282 |   97% |
| Chinese   | 275/282 |   97% |
| Dutch     | 275/282 |   97% |
| French    | 275/282 |   97% |
| German    | 275/282 |   97% |
| Spanish   | 275/282 |   97% |
| Korean    | 275/282 |   97% |
| Polish    | 275/282 |   97% |
| Russian   | 275/282 |   97% |
| Turkish   | 275/282 |   97% |
| Ukrainian | 275/282 |   97% |
|-----------|---------|-------|
```

<br>

# Installation

Just install directly from KDE Widget Store ("+ Add widgets..." -> "Get New Widgets..." -> "Download New Plasma Widgets").

After installation, you can either enable it to appear in the system tray or place it on the panel or desktop instead.

>[!IMPORTANT]
>If you are upgrading from a previous version, you need to log out or restart plasmashell for the new features to work properly.
>```bash
>systemctl --user restart plasma-plasmashell.service
>```

### Update to the latest commit
```
Settings -> General -> Misc -> Install Development version
```

<br>

# Uninstalling
Uninstall plasmoid and remove all related files (config, icons, notifyrc):

```bash
bash ~/.local/share/plasma/plasmoids/com.github.exequtic.apdatifier/contents/tools/sh/utils uninstall
```

<br>

# Support the project
<a href="https://www.buymeacoffee.com/evgk" target="_blank" title="buymeacoffee.com">
  <img src="https://iili.io/JoQ1MeS.md.png" alt="buymeacoffee-badge" style="width: 256px;">
</a>
<br>
<a href="https://nowpayments.io/donation/exequtic" target="_blank" title="nowpayments.io">
   <img src="https://nowpayments.io/images/embeds/donation-button-black.svg" alt="nowpayments-badge" style="width: 256px;">
</a>

<br>
