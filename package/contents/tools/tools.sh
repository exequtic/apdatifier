#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
# SPDX-License-Identifier: MIT

applet="com.github.exequtic.apdatifier"

localdir="$HOME/.local/share"
plasmoid="$localdir/plasma/plasmoids/$applet"
iconsdir="$localdir/icons/breeze/status/24"
notifdir="$localdir/knotifications6"
file1="apdatifier-plasmoid.svg"
file2="apdatifier-packages.svg"
file3="apdatifier-package.svg"


copy() {
    [ -d $iconsdir ] || mkdir -p $iconsdir
    [ -f $iconsdir/$file1 ] || cp $plasmoid/contents/ui/assets/icons/$file1 $iconsdir
    [ -f $iconsdir/$file2 ] || cp $plasmoid/contents/ui/assets/icons/$file2 $iconsdir
    [ -f $iconsdir/$file3 ] || cp $plasmoid/contents/ui/assets/icons/$file3 $iconsdir
    [ -d $notifdir ] || mkdir -p $notifdir
    [ -d $notifdir ] && notifyrc
    [ -d "$HOME/.cache/apdatifier" ] || mkdir -p "$HOME/.cache/apdatifier"
}


install() {
    getTxt; checkPkg "git zip kpackagetool6"
    if [ ! -z "$(kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep $applet)" ]; then
        echo "Plasmoid already installed"
        uninstall
        sleep 2
    fi

    savedir=$(pwd)
    echo; cd /tmp && git clone -n --depth=1 --filter=tree:0 -b main https://github.com/exequtic/apdatifier
    cd apdatifier && git sparse-checkout set --no-cone package && git checkout; echo    

    if [ $? -eq 0 ]; then
        cd package
        zip -rq apdatifier.plasmoid .
        [ ! -f apdatifier.plasmoid ] || kpackagetool6 -t Plasma/Applet -i apdatifier.plasmoid
    fi

    cd $savedir

    [ ! -d /tmp/apdatifier ] || rm -rf /tmp/apdatifier
}


uninstall() {
    getTxt; checkPkg "kpackagetool6"

    [ ! -f $iconsdir/$file1 ] || rm -f $iconsdir/$file1
    [ ! -f $iconsdir/$file2 ] || rm -f $iconsdir/$file2
    [ ! -f $notifdir/$file3 ] || rm -f $notifdir/$file3
    [ ! -d $iconsdir ] || rmdir -p --ignore-fail-on-non-empty $iconsdir
    [ ! -d $notifdir ] || rmdir -p --ignore-fail-on-non-empty $notifdir

    [ -z "$(kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep $applet)" ] || kpackagetool6 --type Plasma/Applet -r $applet 2>/dev/null

    sleep 2
}

notifyrc() {
cat > "$notifdir/apdatifier.notifyrc" << EOF
[Global]
IconName=apdatifier-plasmoid
Comment=Apdatifier

[Event/popup]
Name=Only popup
Comment=Popup option enabled
Action=Popup

[Event/sound]
Name=Sound popup
Comment=Popup and sound options enabled
Action=Popup|Sound
Sound=service-login
EOF
}


getIgnorePkg() {
    conf=$(pacman -Qv | awk 'NR==2 {print $NF}')
    if [ -s "$conf" ]; then
        grep -E "^\s*IgnorePkg\s*=" "$conf" | grep -v "^#" | awk -F '=' '{print $2}'
        grep -E "^\s*IgnoreGroup\s*=" "$conf" | grep -v "^#" | awk -F '=' '{print $2}'
    fi
}


mirrorlistGenerator() {
    count=$1; link=$2; icons=$3; wrapper=$4; menu=$5; selected=$6
    getTxt $icons

    returnMenu() { printMenu; management $count $link $icons $wrapper $selected; }

    if [[ "$menu" != "true" ]]; then
        while true; do
            printQuestion "$MNG_OPT_11?"; read -r answer
            case "$answer" in
                    [Yy]*) echo; break;;
                 [Nn]*|"") echo; exit;;
                        *)  ;;
            esac
        done
    fi

    checkPkg "curl rankmirrors" $5

    tput sc
    tempfile=$(mktemp)
    curl -m 30 -s -o $tempfile "$2" 2>/dev/null &
    spinner $! "$MIRRORS_FETCH"
    tput rc; tput ed
    if [[ -s "$tempfile" && $(head -n 1 "$tempfile" | grep -c "^##") -gt 0 ]]; then
        printDone "$MIRRORS_FETCH"
    else
        printError "$MIRRORS_FETCH"
        printError "$MIRRORS_ERR"
        [[ "$menu" = "true" ]] && returnMenu || exit
    fi

    tput sc
    sed -i -e "s/^#Server/Server/" -e "/^#/d" "$tempfile"
    tempfile2=$(mktemp)
    rankmirrors -n "$1" "$tempfile" > "$tempfile2" &
    spinner $! "$MIRRORS_RANK"
    tput rc; tput ed
    if [[ -s "$tempfile2" && $(head -n 1 "$tempfile2" | grep -c "^# S") -gt 0 ]]; then
        printDone "$MIRRORS_RANK"
    else
        printError "$MIRRORS_RANK"
        [[ "$menu" = "true" ]] && returnMenu || exit
    fi

    mirrorfile="/etc/pacman.d/mirrorlist"
    sed -i '1d' "$tempfile2"
    sed -i "1s/^/##\n## Arch Linux repository mirrorlist\n## Generated on $(date '+%Y-%m-%d %H:%M:%S')\n##\n\n/" "$tempfile2"

    if [[ "$menu" = "true" ]]; then
        sudo -n true 2>/dev/null || { printImportant "$MIRRORS_SUDO"; }
        cat $tempfile2 | sudo tee $mirrorfile > /dev/null
    else
        cat $tempfile2 > $mirrorfile
    fi

    if [ $? -eq 0 ]; then
        printDone "$mirrorfile $MIRRORS_UPD"
        echo -e "$y$(tail -n +6 $mirrorfile | sed 's/Server = //g')$c\n"
        rm $tempfile; rm $tempfile2
        [[ "$menu" = "true" ]] && returnMenu
    else
        printError "$MIRRORS_SUDO"
        [[ "$menu" = "true" ]] && returnMenu || exit
    fi
}


management() {
    trap '' SIGINT
    count=$1; link=$2; icons=$3; wrapper=$4; [ "$5" ] && selected="$5" || selected=0
    wrapper="${wrapper##*/}"; wrapper_sudo=$wrapper
    [[ $wrapper = "pacman" ]] && wrapper_sudo="sudo pacman"

    getTxt $icons

    returnMenu() { printMenu; showOptions $selected; }

    options=(
        "$ICO_MNG_OPT_01 $MNG_OPT_01"
        "$ICO_MNG_OPT_02 $MNG_OPT_02"
        "$ICO_MNG_OPT_03 $MNG_OPT_03"
        "$ICO_MNG_OPT_04 $MNG_OPT_04"
        "$ICO_MNG_OPT_05 $MNG_OPT_05"
        "$ICO_MNG_OPT_06 $MNG_OPT_06"
        "$ICO_MNG_OPT_07 $MNG_OPT_07"
        "$ICO_MNG_OPT_08 $MNG_OPT_08"
        "$ICO_MNG_OPT_08 $MNG_OPT_09"
        "$ICO_MNG_OPT_10 $MNG_OPT_10"
        "$ICO_MNG_OPT_11 $MNG_OPT_11"
        "$ICO_MNG_OPT_12 $MNG_OPT_12"
    )

    showOptions() {
        while true; do
            clear; tput civis
            for i in "${!options[@]}"; do
                if [[ $i -eq $selected ]]; then
                    echo -e "${g}$ICO_SELECT${c} ${bold}${g}${options[$i]}${c}"
                else
                    echo -e "  ${options[$i]}"
                fi
            done

            read -rsn1 input
            case $input in
                A) ((selected--));;
                B) ((selected++));;
                "") break;;
            esac

            if [[ $selected -lt 0 ]]; then
                selected=$(( ${#options[@]} - 1 ))
            elif [ $selected -ge ${#options[@]} ]; then
                selected=0
            fi
        done

        clear; tput cnorm

        case $selected in
            0) fzfPreview Slq;;
            1) fzfPreview Qq;;
            2) fzfPreview Qqe;;
            3) fzfPreview Qqet;;
            4) fzfPreview Qqtd;;
            5) uninstallOrphans;;
            6) downgradePackage;;
            7) printExec -Scc; $wrapper_sudo -Scc; returnMenu;;
            8) printExec -Sc; $wrapper_sudo -Sc; returnMenu;;
            9) rebuildPython;;
           10) mirrorlistGenerator $count $link $icons $wrapper true $selected;;
           11) exit;;
        esac
    }

    fzfPreview() {
        checkPkg "fzf" true
        fzf_settings="--preview-window "right:70%" --height=100% \
                      --layout=reverse --info=right --border=none \
                      --multi --track --exact  --margin=0 --padding=0 \
                      --cycle --prompt=$MNG_SEARCH⠀ --marker=•"

        case $1 in
                         Slq) fzfExec -$1 -Si -S;;
            Qq|Qqe|Qqet|Qqtd) fzfExec -$1 -Qil -Rsn;;
        esac
    }

    fzfExec() {
        packages=$($wrapper $1 | fzf $fzf_settings --preview "$wrapper $2 {}")
        if [[ -z "$packages" ]]; then
            showOptions $selected
        else
            packages=$(echo $packages | oneLine)
            printExec $3 "$packages"
            $wrapper_sudo $3 $packages
            returnMenu
        fi
    }

    uninstallOrphans() {
        if [[ -n $($wrapper -Qdt) ]]; then
            printExec -Rsn "$($wrapper -Qqtd | oneLine)"
            $wrapper_sudo -Rsn $($wrapper -Qqtd)
        else
            printDone "$MNG_DONE"
        fi

        returnMenu
    }

    downgradePackage() {
        checkPkg "fzf"
        pacman_cache=$(pacman -Qv | awk 'NR==4 {print $NF}')
        wrapper_cache="$HOME/.cache/$wrapper"

        cache=$(find $pacman_cache $wrapper_cache -type f -name "*.pkg.tar.zst" -printf "%f\n" 2>/dev/null | sort | \
                fzf --exact --layout=reverse | oneLine)

        if [[ -z "$cache" ]]; then
            showOptions $selected
        else
            if [ -f "${pacman_cache}${cache}" ]; then
                printExec -U "${pacman_cache}${cache}"
                $wrapper_sudo -U "${pacman_cache}${cache}"
            else
                cache=$(find $wrapper_cache -type f -name $cache 2>/dev/null)
                printExec -U "${cache}"
                $wrapper_sudo -U $cache
            fi
            returnMenu
        fi
    }

    rebuildPython() {
        [[ $wrapper = "pacman" ]] && { echo "Need wrapper"; returnMenu; }
        rebuild_dir=$(find /usr/lib -type d -name "python*.*" | oneLine)

        if [ $(echo "$rebuild_dir" | wc -w) -gt 1 ]; then
            rebuild_dir="${rebuild_dir#* }"
            rebuild_packages=$(pacman -Qqo "$rebuild_dir" | pacman -Qqm - | oneLine)

            if [[ -z "$rebuild_packages" ]]; then
                printDone "$MNG_DONE"
            else
                printExec -S "$rebuild_packages --rebuild"
                while true; do
                    printQuestion "$MNG_RESUME"
                    read -r answer
                    case "$answer" in
                           [Yy]*) echo; break;;
                        [Nn]*|"") echo; showOptions;;
                               *)  ;;
                    esac
                done
                pacman -Qqo "$rebuild" | pacman -Qqm - | $wrapper -S --rebuild -
            fi
            
        else
            printDone "$MNG_DONE"
        fi

        returnMenu
    }

    showOptions
}


getId() {
    case "$1" in
        com.bxabi.bumblebee-indicator)              echo "998890";;
        org.nielsvm.plasma.menupager)               echo "1898708";;
        dev.vili.sahkoporssi)                       echo "2079446";;
        org.kde.mcwsremote)                         echo "2100417";;
        com.github.korapp.cloudflare-warp)          echo "2113872";;
        de.davidhi.ddcci-brightness)                echo "2114471";;
        org.kde.plasma.simplekickoff)               echo "2115883";;
        com.github.stepan-zubkov.days-to-new-year)  echo "2118132";;
        com.github.korapp.nordvpn)                  echo "2118492";;
        plasmusic-toolbar)                          echo "2128143";;
        org.kde.windowtitle)                        echo "2129423";;
        luisbocanegra.panel.colorizer)              echo "2130967";;
        com.github.dhruv8sh.year-progress-mod)      echo "2132405";;
        com.himdek.kde.plasma.overview)             echo "2132554";;
        com.himdek.kde.plasma.runcommand)           echo "2132555";;
        a2n.archupdate.plasmoid)                    echo "2134470";;
        org.kde.plasma.yesplaymusic-lyrics)         echo "2135552";;
        com.github.prayag2.minimalistclock)         echo "2135642";;
        com.github.prayag2.modernclock)             echo "2135653";;
        com.github.k-donn.plasmoid-wunderground)    echo "2135799";;
        com.dv.uswitcher)                           echo "2135898";;
        org.kde.Big.Clock)                          echo "2136288";;
        zayron.chaac.weather)                       echo "2136291";;
        Clock.Asitoki.Color)                        echo "2136295";;
        CircleClock)                                echo "2136299";;
        zayron.almanac)                             echo "2136302";;
        Minimal.chaac.weather)                      echo "2136307";;
        com.Petik.clock)                            echo "2136321";;
        weather.bicolor.widget)                     echo "2136329";;
        com.nemmayan.clock)                         echo "2136546";;
        com.github.zren.commandoutput)              echo "2136636";;
        org.kde.latte.separator)                    echo "2136852";;
        org.kde.plasma.Beclock)                     echo "2137016";;
        com.github.zren.dailyforecast)              echo "2137185";;
        com.github.zren.condensedweather)           echo "2137197";;
        org.kde.plasma.scpmk)                       echo "2137217";;
        zayron.simple.separator)                    echo "2137418";;
        com.github.zren.simpleweather)              echo "2137431";;
        com.gitlab.scias.advancedreboot)            echo "2137675";;
        org.zayronxio.vector.clock)                 echo "2137726";;
        org.kpple.kppleMenu)                        echo "2138251";;
        ink.chyk.minimumMediaController)            echo "2138283";;
        optimus-gpu-switcher)                       echo "2138365";;
        org.kde.plasma.videocard)                   echo "2138473";;
        lenovo-conservation-mode-switcher)          echo "2138476";;
        com.github.boraerciyas.controlcentre)       echo "2138485";;
        org.kde.Date.Bubble.P6)                     echo "2138853";;
        org.kde.latte.spacer)                       echo "2138907";;
        split-clock)                                echo "2139337";;
        d4rkwzd.colorpicker-tray)                   echo "2140856";;
        org.kde.MinimalMusic.P6)                    echo "2141133";;
        com.github.zren.tiledmenu)                  echo "2142716";;
        org.kde.plasma.resources-monitor)           echo "2143899";;
        AndromedaLauncher)                          echo "2144212";;
        org.previewqt.previewqt.plasmoidpreviewqt)  echo "2144426";;
        SoloDay.P6)                                 echo "2144969";;
        com.github.DenysMb.Kicker-AppsOnly)         echo "2145280";;
        zayron.almanac.V2)                          echo "2147850";;
        org.kde.plasma.clearclock)                  echo "2147871";;
        org.kde.windowtitle.Fork)                   echo "2147882";;
        thot.observer.ram)                          echo "2148469";;
        thot.observer.cpu)                          echo "2148472";;
        org.kde.paneltransparencybutton)            echo "2150916";;
        org.kde.plasma.win7showdesktop)             echo "2151247";;
    esac
}

downloadXML() {
    page=0
    while true; do
        tempXML=$(mktemp)
        url="https://api.opendesktop.org/ocs/v1/content/data?categories=705&sort=new&page=$page&pagesize=100"
        curl -m 30 -s -o "$tempXML" --request GET --url "$url"

        if [ -s "$tempXML" ]; then
            statuscode=$(xmlstarlet sel -t -m "//ocs/meta/statuscode" -v . -n $tempXML)
            totalitems=$(xmlstarlet sel -t -m "//ocs/meta/totalitems" -v . -n "$tempXML")

            onError() { rm "$XML" "$tempXML"; exit; }

            if [[ $1 = "check" ]]; then
                [[ $statuscode = 200 ]] && { echo 200; onError; }
                [[ $statuscode != 100 ]] && { echo 999; onError; }
            else
                [[ $statuscode = 200 ]] && { printError "$WIDGETS_API_ERR"; onError; }
                [[ $statuscode != 100 ]] && { printError "$WIDGETS_CHECK"; onError; }
            fi

        else
            [[ $1 = "check" ]] && { echo 999; rm "$tempXML"; exit; } || { printError "$WIDGETS_CHECK"; rm "$tempXML"; exit; }
        fi

        formatXML $tempXML

        if [ -s $XML ]; then
            temp2XML=$(mktemp)
            head -n -2 $XML > $temp2XML && mv $temp2XML $XML
            tail -n +11 $tempXML > $temp2XML && mv $temp2XML $tempXML
            cat $tempXML >> $XML
        else
            cat $tempXML > $XML
        fi

        rm $tempXML

        items=$(((page + 1) * 100))
        [[ $totalitems > $items ]] && { ((page++)); } || { break; }
    done
}

getWidgets() {
    plasmoids=$(find $HOME/.local/share/plasma/plasmoids/ -mindepth 1 -maxdepth 1 -type d -printf "%f\n")
    [ -z "$plasmoids" ] && { exit; } || { while IFS= read -r line; do lines+=("$line"); done <<< "$plasmoids"; }
}

getWidgetInfo() {
    dir="$HOME/.local/share/plasma/plasmoids/$plasmoid"
    json="$dir/metadata.json"
    [ -s "$json" ] || return 1

    jq . $json >/dev/null 2>&1 || return 1
    if ! jq -e '.KPackageStructure' "$json" >/dev/null 2>&1; then
        jq '. + { "KPackageStructure": "Plasma/Applet" }' $json > $dir/tmp.json && mv $dir/tmp.json $json
    fi

    name=$(jq -r '.KPlugin.Name' $json)

    icon=$(jq -r '.KPlugin.Icon' $json)
    [ -z "$icon" ] && icon="start-here-kde"

    contentId=$(xmlstarlet sel -t -m "//name[text()='$name']/.." -v "id" -n $XML)
    [ -z "$contentId" ] && contentId="$(getId "$plasmoid")"
    if [ -z "$contentId" ]; then
        knsregistry="$HOME/.local/share/knewstuff3/plasmoids.knsregistry"
        [ -s "$knsregistry" ] && contentId=$(xmlstarlet sel -t -m "//installedfile[contains(text(), 'plasma/plasmoids/$plasmoid')]/.." -v "id" -n $knsregistry)
    fi
    [ -z "$contentId" ] && return 1

    current_version=$(jq -r '.KPlugin.Version' $json)
    current_version_clean=$(echo $current_version | sed 's/[^0-9.]*//g')
    current_version_clean=$(echo "$current_version_clean" | sed 's/^\.//')

    latest_version=$(xmlstarlet sel -t -m "//id[text()='$contentId']/.." -v "version" -n $XML)
    latest_version_clean=$(echo $latest_version | sed 's/[^0-9.]*//g')
    latest_version_clean=$(echo "$latest_version_clean" | sed 's/^\.//')

    [ -z "$latest_version_clean" ] || [ -z "$current_version_clean" ] && return 1

    description=$(jq -r '.KPlugin.Description' $json | tr -d '\n')
    [ -z "$description" ] || [ "$description" = "null" ] && description="-"

    author=$(jq -r '.KPlugin.Authors[].Name' $json | paste -sd "," - | sed 's/,/, /g')
    [ -z "$author" ] || [ "$author" = "null" ] && author="-"

    url="https://store.kde.org/p/"$contentId
    return 0
}

downloadWidget() {
    tput sc; curl -m 30 -s -o $tempFile --request GET --location "$link" 2>/dev/null &
    spinner $! "$WIDGETS_DOWNLOADING $1"; tput rc; tput ed

    [ -s "$tempFile" ] && { printDone "$WIDGETS_DOWNLOADING $1"; } || { printError "$WIDGETS_DOWNLOADING $1"; return 1; }

    case "$tempFile" in
         *.zip | *.plasmoid) unzip -q "$tempFile" -d "$tempDir/unpacked";;
        *.xz | *.gz | *.tar) tar -xf "$tempFile" -C "$tempDir/unpacked";;
                          *) printError "$WIDGETS_EXT_ERR"; return 1;;
    esac

    metadata_path=$(find "$tempDir/unpacked" -name "metadata.json")
    [ -z "$metadata_path" ] && { printError "$WIDGETS_JSON_ERR"; return 1; }

    unpacked=$(dirname "$metadata_path"); cd "$unpacked"

    jq . metadata.json >/dev/null 2>&1 || { printError "$WIDGETS_JSON_ERR2"; return 1; }
    if ! jq -e '.KPackageStructure' metadata.json >/dev/null 2>&1; then
        jq '. + { "KPackageStructure": "Plasma/Applet" }' metadata.json > tmp.json && mv tmp.json metadata.json
    fi

    jq --arg new_value "$latest_version" '.KPlugin.Version = $new_value' metadata.json > tmp.json && mv tmp.json metadata.json

    kpackagetool6 -t Plasma/Applet -u .
    sleep 1

    return 0
}





checkWidgets() {
    getTxt true
    for cmd in curl jq xmlstarlet; do command -v "$cmd" >/dev/null || { echo 127; exit; }; done

    declare -a plasmoid lines; getWidgets
    XML=$(mktemp)
    downloadXML check

    output=""
    for plasmoid in "${lines[@]}"; do
        getWidgetInfo; [[ $? -ne 0 ]] && continue

        if [[ "$(printf '%s\n' "$latest_version_clean" "$current_version_clean" | sort -V | head -n1)" != "$latest_version_clean" ]]; then 
            output+="${name}@${contentId}@${icon}@${description}@${author}@${current_version}@${latest_version}@${url}\n"
        fi
    done

    rm $XML
    echo -e "$output"
}

upgradeAllWidgets() {
    getTxt $2
    checkPkg "curl jq xmlstarlet unzip tar"

    declare -a plasmoid lines; getWidgets

    XML=$(mktemp)
    echo; tput sc; downloadXML &
    spinner $! "$WIDGETS_CHECK"
    tput rc; tput ed; printDone "$WIDGETS_CHECK"

    for plasmoid in "${lines[@]}"; do
        getWidgetInfo; [[ $? -ne 0 ]] && continue

        if [[ "$(printf '%s\n' "$latest_version_clean" "$current_version_clean" | sort -V | head -n1)" != "$latest_version_clean" ]]; then
            link=$(xmlstarlet sel -t -m "//id[text()='$contentId']/.." -v "downloadlink" -n $XML)
            tempDir=$(mktemp -d)
            tempFile="$tempDir/$(basename "${link}")"
            mkdir $tempDir/unpacked
            downloadWidget "$name"; [[ $? -ne 0 ]] && continue
        fi
    done

    rm $XML

    [ "$1" = "true" ] && [ "$hasUpdates" = "true" ] && { sleep 2; systemctl --user restart plasma-plasmashell.service; }
}

upgradeWidget() {
    [ $1 ] || exit

    getTxt $3
    checkPkg "curl jq xmlstarlet unzip tar"

    [[ "$2" = "true" ]] && { echo -e "\n"; } || { printImportant "${WIDGETS_WARN}\n"; }; sleep 1

    tempDir=$(mktemp -d); mkdir $tempDir/unpacked; XML="$tempDir/data.xml"

    tput sc; curl -m 30 -s -o $XML --request GET --url "https://api.opendesktop.org/ocs/v1/content/data/$1" 2>/dev/null &
    spinner $! "$WIDGETS_FETCHING"; tput rc; tput ed

    onError() { rm -rf "$tempDir"; exit; }

    if [ -s "$XML" ]; then
        statuscode=$(xmlstarlet sel -t -m "//ocs/meta/statuscode" -v . -n $XML)
        [[ $statuscode = 200 ]] && { printError "$WIDGETS_API_ERR"; onError; }
        [[ $statuscode != 100 ]] && { printError "$WIDGETS_FETCHING"; onError; }
        printDone "$WIDGETS_FETCHING"
    else
        printError "$WIDGETS_FETCHING"; onError
    fi

    formatXML $XML
    link=$(xmlstarlet sel -t -m "//id[text()='$1']/.." -v "downloadlink" -n $XML)
    latest_version=$(xmlstarlet sel -t -m "//id[text()='$1']/.." -v "version" -n $XML)
    tempFile="$tempDir/$(basename "${link}")"

    downloadWidget $4; [[ $? -ne 0 ]] && exit

    [[ "$2" = "true" ]] && { sleep 2; systemctl --user restart plasma-plasmashell.service; }
}






getTxt() {
    DIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
    export TEXTDOMAINDIR="$DIR/../locale"
    export TEXTDOMAIN="plasma_applet_${applet}"

    declare -a var_names=(
    MIRRORS_FETCH MIRRORS_RANK MIRRORS_ERR MIRRORS_UPD MIRRORS_SUDO
    WIDGETS_WARN WIDGETS_CHECK WIDGETS_FETCHING WIDGETS_DOWNLOADING
    WIDGETS_API_ERR WIDGETS_JSON_ERR WIDGETS_JSON_ERR2 WIDGETS_EXT_ERR
    MNG_OPT_01 MNG_OPT_02 MNG_OPT_03 MNG_OPT_04 MNG_OPT_05 MNG_OPT_06
    MNG_OPT_07 MNG_OPT_08 MNG_OPT_09 MNG_OPT_10 MNG_OPT_11 MNG_OPT_12
    MNG_RESUME MNG_RETURN MNG_SEARCH MNG_EXEC MNG_DONE NO_CMD_ERR)

    i=0
    while IFS= read -r line && [ $i -lt ${#var_names[@]} ]; do
        i=$((i+1))
        text=$(echo "$line" | grep -oP '(?<=\().*(?=\))' | sed 's/"//g')
        eval "${var_names[$((i-1))]}=\"$(gettext "$text")\""
    done < "$DIR/../ui/components/Messages.qml"

    if [[ $1 = "true" ]]; then
        ICO_ERR=""; ICO_DONE=""; ICO_WARN="󱇎"; ICO_QUESTION=""; ICO_EXEC="󰅱"; ICO_RETURN="󰄽"; ICO_SELECT="󰄾"
        ICO_MNG_OPT_01="󱝩"; ICO_MNG_OPT_02="󱝫"; ICO_MNG_OPT_03="󱝭"; ICO_MNG_OPT_04="󱝭"
        ICO_MNG_OPT_05="󱝧"; ICO_MNG_OPT_06=""; ICO_MNG_OPT_07="󱝥"; ICO_MNG_OPT_08="󱝝"
        ICO_MNG_OPT_09="󱝝"; ICO_MNG_OPT_10="󰌠"; ICO_MNG_OPT_11="󱘴"; ICO_MNG_OPT_12=""
    else
        ICO_ERR="\u2718"; ICO_DONE="\u2714"; ICO_WARN="::"; ICO_QUESTION="::"; ICO_EXEC="::"; ICO_RETURN="<<"; ICO_SELECT=">"
    fi
}

r="\033[1;31m"; g="\033[1;32m"; b="\033[1;34m"; y="\033[0;33m"; c="\033[0m"; bold="\033[1m"
printMenu() { tput civis; echo -e "\n${b}${ICO_RETURN}${c} ${bold}${MNG_RETURN}${c}"; read -r; tput cnorm; }
printDone() { echo -e "${g}${ICO_DONE} $1 ${c}"; }
printError() { echo -e "${r}${ICO_ERR} $1 ${c}"; }
printImportant() { echo -e "${y}${bold}${ICO_WARN} $1 ${c}"; }
printQuestion() { echo -en "\n${y}${ICO_QUESTION}${c}${y}${bold} $1 ${c}[y/${bold}N${c}]: "; }
printExec() { [[ $wrapper_sudo == "trizen" ]] && { return 0; } || { echo -e "${b}${ICO_EXEC}${c}${bold} ${MNG_EXEC}${c} $wrapper_sudo $1 $2 \n"; } }
oneLine() { tr '\n' ' ' | sed 's/ $//'; }
checkPkg() { for cmd in ${1}; do command -v "$cmd" >/dev/null || { printError "${NO_CMD_ERR} ${cmd}"; [ $2 ] && returnMenu || exit; }; done; }
spinner() { spin="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"; while kill -0 $1 2>/dev/null; do i=$(( (i+1) %10 )); printf "${r}\r${spin:$i:1}${c} ${b}$2${c}"; sleep .2; done; }
formatXML() { sed -i 's/downloadlink[1-9]>/downloadlink>/g' $1; xmlstarlet ed -L -d "//content[@details='summary']/downloadlink[position() < last()]" -d "//content[@details='summary']/*[not(self::id or self::name or self::version or self::downloadlink)]" $1; }


case "$1" in
                        "copy") copy;;
                     "install") install;;
                   "uninstall") uninstall;;
                  "getIgnored") getIgnorePkg;;
                  "management") shift; management $1 $2 $3 $4;;
                "checkWidgets") shift; checkWidgets;;
               "upgradeWidget") shift; upgradeWidget $1 $2 $3 $4;;
           "upgradeAllWidgets") shift; upgradeAllWidgets $1 $2;;
                  "mirrorlist") shift; mirrorlistGenerator $1 $2 $3;;
                             *) exit;;
esac
