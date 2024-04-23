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
file3="apdatifier.notifyrc"


copy() {
    [ -d $iconsdir ] || mkdir -p $iconsdir
    [ -f $iconsdir/$file1 ] || cp $plasmoid/contents/assets/$file1 $iconsdir
    [ -f $iconsdir/$file2 ] || cp $plasmoid/contents/assets/$file2 $iconsdir

    [ -d $notifdir ] || mkdir -p $notifdir
    [ -d $notifdir ] && cp $plasmoid/contents/notifyrc/$file3 $notifdir

    [ -d "$HOME/.cache/apdatifier" ] || mkdir -p "$HOME/.cache/apdatifier"
}


### Download and install with latest commit
install() {
    command -v git >/dev/null || { echo "git not installed" >&2; exit; }
    command -v zip >/dev/null || { echo "zip not installed" >&2; exit; }
    command -v kpackagetool6 >/dev/null || { echo "kpackagetool6 not installed" >&2; exit; }

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
    command -v kpackagetool6 >/dev/null || { echo "kpackagetool6 not installed" >&2; exit; }

    [ ! -f $iconsdir/$file1 ] || rm -f $iconsdir/$file1
    [ ! -f $iconsdir/$file2 ] || rm -f $iconsdir/$file2
    [ ! -f $notifdir/$file3 ] || rm -f $notifdir/$file3
    [ ! -d $iconsdir ] || rmdir -p --ignore-fail-on-non-empty $iconsdir
    [ ! -d $notifdir ] || rmdir -p --ignore-fail-on-non-empty $notifdir

    [ -z "$(kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep $applet)" ] || kpackagetool6 --type Plasma/Applet -r $applet 2>/dev/null

    sleep 2
}


setLanguage() {
    LANGUAGE=${LANG:0:2}
    MESSAGES_FILE="/home/$(logname)/.local/share/plasma/plasmoids/$applet/translate/$LANGUAGE.sh"

    if [ -f "$MESSAGES_FILE" ]; then
        source "$MESSAGES_FILE"
    fi
}


getIgnoredPackages() {
    conf="/etc/pacman.conf"
    if [ -s "$conf" ]; then
        grep -E "^\s*IgnorePkg\s*=" "$conf" | grep -v "^#" | awk -F '=' '{print $2}'
        grep -E "^\s*IgnoreGroup\s*=" "$conf" | grep -v "^#" | awk -F '=' '{print $2}'
    fi
}


r="\033[1;31m"
g="\033[1;32m"
b="\033[1;34m"
y="\033[0;33m"
c="\033[0m"

spinner() {
    spin="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    while kill -0 $1 2>/dev/null; do
        i=$(( (i+1) %10 ))
        printf "$r\r${spin:$i:1}$c $b$2$c"
        sleep .2
    done
}


mirrorlist_generator() {
    QUESTION_TEXT="Refresh mirrorlist? [y/N]:"
    CMD_ERROR_TEXT="Unable to generate mirrorlist - not installed:"
    FETCHING_MIRRORS_TEXT="Fetching the latest filtered mirror list..."
    RANKING_MIRRORS_TEXT="Ranking mirrors by their connection and opening speed..."
    MIRRORS_ERROR_TEXT="Check your mirrorlist generator settings..."
    MIRRORS_UPDATED_TEXT="was updated with the following servers:"
    setLanguage

    echo
    while true; do
        echo -n "$QUESTION_TEXT "
        read -r answer
        case "$answer" in
                [Yy]*) echo; break;;
             [Nn]*|"") echo; exit;;
                    *)  ;;
        esac
    done

    [[ $EUID -ne 0 ]] && { echo -e "$r\u2718 Requires sudo permissions$c\n"; exit; }
    for cmd in curl rankmirrors; do
        command -v "$cmd" >/dev/null || { echo -e "$r\u2718 $CMD_ERROR_TEXT $cmd $c\n"; exit; }
    done

    tput sc
    tempfile=$(mktemp)
    text=$FETCHING_MIRRORS_TEXT
    curl -s -o $tempfile "$2" 2>/dev/null &
    spinner $! "$text"
    tput rc
    tput ed
    [[ -s "$tempfile" && $(head -n 1 "$tempfile" | grep -c "^##") -gt 0 ]] || { echo -e "$r\u2718 $text $c\n$r\u2718 $MIRRORS_ERROR_TEXT $c\n"; exit; }
    echo -e "$g\u2714 $text$c"

    tput sc
    sed -i -e "s/^#Server/Server/" -e "/^#/d" "$tempfile"
    tempfile2=$(mktemp)
    text=$RANKING_MIRRORS_TEXT
    rankmirrors -n "$1" "$tempfile" > "$tempfile2" &
    spinner $! "$text"
    tput rc
    tput ed
    [[ -s "$tempfile2" && $(head -n 1 "$tempfile2" | grep -c "^# S") -gt 0 ]] || { echo -e "$r\u2718 $text $c"; exit; }
    echo -e "$g\u2714 $text$c"

    mirrorfile="/etc/pacman.d/mirrorlist"
    sed -i '1d' "$tempfile2"
    sed -i "1s/^/##\n## Arch Linux repository mirrorlist\n## Generated on $(date '+%Y-%m-%d %H:%M:%S')\n##\n\n/" "$tempfile2"
    cat $tempfile2 > $mirrorfile

    echo -e "$g\n$mirrorfile $MIRRORS_UPDATED_TEXT $c"
    echo -e "$y$(tail -n +6 $mirrorfile | sed 's/Server = //g')$c"
    echo

    rm $tempfile
    rm $tempfile2
}


getId() {
    case "$1" in
        com.bxabi.bumblebee-indicator)              echo "998890";;
        org.kde.plasma.shutdownorswitch)            echo "1288430";;
        org.kde.mediabar)                           echo "1377704";;
        com.github.heqro.day-night-switcher)        echo "1804745";;
        org.nielsvm.plasma.menupager)               echo "1898708";;
        org.kde.mcwsremote)                         echo "2100417";;
        org.kde.olib.thermalmonitor)                echo "2100418";;
        org.kde.panel.transparency.toggle)          echo "2107649";;
        com.github.tilorenz.compact_pager)          echo "2112443";;
        com.github.korapp.cloudflare-warp)          echo "2113872";;
        de.davidhi.ddcci-brightness)                echo "2114471";;
        org.kde.plasma.simplekickoff)               echo "2115883";;
        com.dv.fokus)                               echo "2117117";;
        com.github.stepan-zubkov.days-to-new-year)  echo "2118132";;
        com.github.korapp.nordvpn)                  echo "2118492";;
        com.github.tilorenz.timeprogressbar)        echo "2126775";;
        luisbocanegra.panelspacer.extended)         echo "2128047";;
        plasmusic-toolbar)                          echo "2128143";;
        luisbocanegra.intel.gpu.monitor)            echo "2128477";;
        org.kde.windowtitle)                        echo "2129423";;
        luisbocanegra.panel.modes.switcher)         echo "2130222";;
        org.kde.archupdatechecker)                  echo "2130541";;
        luisbocanegra.panel.colorizer)              echo "2130967";;
        com.github.korapp.homeassistant)            echo "2131364";;
        org.kde.plasma.plasm6desktopindicator)      echo "2131462";;
        com.github.dhruv8sh.year-progress-mod)      echo "2132405";;
        com.himdek.kde.plasma.overview)             echo "2132554";;
        com.himdek.kde.plasma.runcommand)           echo "2132555";;
        a2n.archupdate.plasmoid)                    echo "2134470";;
        com.github.antroids.application-title-bar)  echo "2135509";;
        org.kde.placesWidget)                       echo "2135511";;
        org.kde.plasma.yesplaymusic-lyrics)         echo "2135552";;
        com.github.prayag2.minimalistclock)         echo "2135642";;
        com.github.prayag2.modernclock)             echo "2135653";;
        com.github.exequtic.apdatifier)             echo "2135796";;
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
        org.kde.netspeedWidget)                     echo "2136505";;
        com.nemmayan.clock)                         echo "2136546";;
        com.github.scriptinator)                    echo "2136631";;
        com.github.zren.commandoutput)              echo "2136636";;
        org.kde.latte.separator)                    echo "2136852";;
        com.github.zren.alphablackcontrol)          echo "2136860";;
        org.kde.plasma.advancedradio)               echo "2136933";;
        luisbocanegra.kdematerialyou.colors)        echo "2136963";;
        org.kde.plasma.Beclock)                     echo "2137016";;
        com.github.zren.dailyforecast)              echo "2137185";;
        com.github.zren.condensedweather)           echo "2137197";;
        org.kde.plasma.scpmk)                       echo "2137217";;
        com.github.eatsu.spaceraspager)             echo "2137231";;
        zayron.simple.separator)                    echo "2137418";;
        com.github.zren.simpleweather)              echo "2137431";;
        com.gitlab.scias.advancedreboot)            echo "2137675";;
        org.zayronxio.vector.clock)                 echo "2137726";;
        org.kde.plasma.catwalk)                     echo "2137844";;
        ink.chyk.plasmaDesktopLyrics)               echo "2138202";;
        org.kpple.kppleMenu)                        echo "2138251";;
        ink.chyk.minimumMediaController)            echo "2138283";;
        optimus-gpu-switcher)                       echo "2138365";;
        org.kde.plasma.videocard)                   echo "2138473";;
        lenovo-conservation-mode-switcher)          echo "2138476";;
        com.github.boraerciyas.controlcentre)       echo "2138485";;
        org.kde.plasma.pminhibition)                echo "2138746";;
        org.kde.Date.Bubble.P6)                     echo "2138853";;
        org.kde.latte.spacer)                       echo "2138907";;
        split-clock)                                echo "2139337";;
        com.github.configurable_button)             echo "2139541";;
        Plasma.Control.Hub)                         echo "2139890";;
        com.github.davide-sd.ip_address)            echo "2140275";;
        d4rkwzd.colorpicker-tray)                   echo "2140856";;
        org.kde.MinimalMusic.P6)                    echo "2141133";;
        Audio.Wave.Widget)                          echo "2142681";;
        com.github.zren.tiledmenu)                  echo "2142716";;
        AndromedaLauncher)                          echo "2144212";;
        org.previewqt.previewqt.plasmoidpreviewqt)  echo "2144426";;
        SoloDay.P6)                                 echo "2144969";;
        com.github.liujed.rssfeeds)                 echo "2145065";;
        com.github.DenysMb.Kicker-AppsOnly)         echo "2145280";;
        luisbocanegra.desktop.wallpaper.effects)    echo "2145723";;
    esac
}


checkPlasmoidsUpdates() {
    [ $1 ] || exit

    for cmd in curl jq xmlstarlet; do
        command -v "$cmd" >/dev/null || { echo 127; exit; }
    done

    plasmoids=$(find $HOME/.local/share/plasma/plasmoids/ -mindepth 1 -maxdepth 1 -type d -printf "%f\n")
    [ -z "$plasmoids" ] && exit

    tempXML=$(mktemp)
    curl -s -o "$tempXML" --request GET --url "https://api.opendesktop.org/ocs/v1/content/data?categories=705&sort=new&page=0&pagesize=100"

    if [ -s "$tempXML" ]; then
        statuscode=$(xmlstarlet sel -t -m "//ocs/meta/statuscode" -v . -n $tempXML)
        if [ $statuscode = 200 ]; then
            rm "$tempXML"
            echo 200
            exit
        fi
    else
        exit
    fi

    xmlstarlet ed -L -d "//content[@details='summary']/*[not(self::id or self::name or self::version)]" "$tempXML"


    declare -a lines
    while IFS= read -r line; do
        lines+=("$line")
    done <<< "$plasmoids"

    output=""
    for plasmoid in "${lines[@]}"; do
        dir="$HOME/.local/share/plasma/plasmoids/$plasmoid"
        json="$dir/metadata.json"
        [[ -s "$json" ]] || continue

        if ! jq -e '.KPackageStructure' "$json" >/dev/null 2>&1; then
            jq '. + { "KPackageStructure": "Plasma/Applet" }' $json > $dir/tmp.json && mv $dir/tmp.json $json
        fi

        name=$(jq -r '.KPlugin.Name' $json)
        contentId=$(xmlstarlet sel -t -m "//name[text()='$name']/.." -v "id" -n $tempXML)
        [ -z "$contentId" ] && contentId="$(getId "$plasmoid")"
        if [ -z "$contentId" ]; then
            knsregistry="$HOME/.local/share/knewstuff3/plasmoids.knsregistry"
            if [ -f "$knsregistry" ]; then
                contentId=$(xmlstarlet sel -t -m "//installedfile[contains(text(), 'plasma/plasmoids/$plasmoid')]/.." -v "id" -n $knsregistry)
            fi
        fi
        [ -z "$contentId" ] && continue

        current_version=$(jq -r '.KPlugin.Version' $json)
        current_version_clean=$(echo $current_version | sed 's/[^0-9.]*//g')
        current_version_clean=$(echo "$current_version_clean" | sed 's/^\.//')
        latest_version=$(xmlstarlet sel -t -m "//id[text()='$contentId']/.." -v "version" -n $tempXML)
        latest_version_clean=$(echo $latest_version | sed 's/[^0-9.]*//g')
        latest_version_clean=$(echo "$latest_version_clean" | sed 's/^\.//')
        [ -z "$latest_version_clean" ] || [ -z "$current_version_clean" ] && continue

        description=$(jq -r '.KPlugin.Description' $json | tr -d '\n')
        [ -z "$description" ] || [ "$description" = "null" ] && description="-"

        author=$(jq -r '.KPlugin.Authors[0].Name' $json)
        [ -z "$author" ] || [ "$author" = "null" ] && author="-"

        url="https://store.kde.org/p/"$contentId

        if [ "$(printf '%s\n' "$latest_version_clean" "$current_version_clean" | sort -V | head -n1)" != "$latest_version_clean" ]; then 
            output+="${name}@${contentId}@${description}@${author}@${current_version}@${latest_version}@${url}\n"
        fi
    done

    rm $tempXML
    echo -e "$output"
}


upgradePlasmoid() {
    [ $1 ] || exit

    for cmd in curl jq xmlstarlet unzip tar; do
        command -v "$cmd" >/dev/null || { echo -e "\n$r\u2718 $cmd not installed$c"; exit; }
    done

    WARNING_TEXT_1="For some widgets you may need to Log Out or restart plasmashell after upgrade"
    WARNING_TEXT_2="(kquitapp6 plasmashell && kstart plasmashell) so that they work correctly."
    FETCHING_INFO_TEXT="Fetching information about widget..."
    DOWNLOADING_TEXT="Downloading widget..."
    API_ERROR_TEXT="Too many API requests in the last 15 minutes from your IP address. Please try again later."
    METADATA_ERROR_TEXT="File metadata.json not found"
    setLanguage

    if $2; then
        echo -e "\n"
        sleep 1
    else
        echo -e "\n${y}${WARNING_TEXT_1}\n${WARNING_TEXT_2}${c}\n"
        sleep 2
    fi

    contentId="$1"
    tempDir=$(mktemp -d)
    mkdir $tempDir/unpacked
    tempXML="$tempDir/data.xml"

    tput sc
    text=$FETCHING_INFO_TEXT
    curl -s -o $tempXML --request GET --url "https://api.opendesktop.org/ocs/v1/content/data/$contentId" 2>/dev/null &
    spinner $! "$text"
    tput rc
    tput ed

    if [ ! -s $tempXML ]; then
        echo -e "$r\u2718 $text$c"
        exit
    fi

    statuscode=$(xmlstarlet sel -t -m "//ocs/meta/statuscode" -v . -n $tempXML)
    if [ $statuscode = 100 ]; then
        echo -e "$g\u2714 $text $c"
    elif [ $statuscode = 200 ]; then
        echo -e "$r\u2718 $API_ERROR_TEXT $c"
        exit
    else
        echo -e "$r\u2718 $text $c"
    fi

    tput sc
    text=$DOWNLOADING_TEXT
    link=$(xmlstarlet sel -t -m "//id[text()='$contentId']/.." -v "downloadlink1[not(.='')] | downloadlink2[not(.='')] | downloadlink3[not(.='')] | downloadlink4[not(.='')] | downloadlink5[not(.='')] | downloadlink6[not(.='')]" -n $tempXML | tail -1 | tr -d '\n')
    tempFile="$tempDir/$(basename "${link}")"
    curl -s -o $tempFile --request GET --location "$link" 2>/dev/null &
    spinner $! "$text"
    tput rc
    tput ed

    if [ -s "$tempFile" ]; then
        echo -e "$g\u2714 $text $c"
    else
        echo -e "$r\u2718 $text $c"
        exit
    fi


    if [[ "$tempFile" == *.xz || "$tempFile" == *.gz ]]; then
        tar -xf "$tempFile" -C "$tempDir/unpacked"
    else
        unzip -q "$tempFile" -d "$tempDir/unpacked"
    fi


    metadata_path=$(find "$tempDir/unpacked" -name "metadata.json")
    if [ -z "$metadata_path" ]; then
        echo -e "$r\u2718 $METADATA_ERROR_TEXT $c"
        exit
    fi

    unpacked=$(dirname "$metadata_path")
    cd "$unpacked"


    if ! jq -e '.KPackageStructure' metadata.json >/dev/null 2>&1; then
        jq '. + { "KPackageStructure": "Plasma/Applet" }' metadata.json > tmp.json && mv tmp.json metadata.json
    fi

    version=$(xmlstarlet sel -t -m "//id[text()='$contentId']/.." -v "version" -n $tempXML | tr -d '\n')
    jq --arg new_value "$version" '.KPlugin.Version = $new_value' metadata.json > tmp.json && mv tmp.json metadata.json


    if [ "$1" = "2135796" ]; then
        if [ "$2" = "true" ]; then
            nohup kpackagetool6 -t Plasma/Applet -u . && systemctl --user restart plasma-plasmashell.service &
        else
            echo -e "$r Log out or restart plasmashell after upgrade $c"
            sleep 2
            kpackagetool6 -t Plasma/Applet -u .
        fi
    else
        echo
        kpackagetool6 -t Plasma/Applet -u .

        if [ "$2" = "true" ]; then
            sleep 2
            systemctl --user restart plasma-plasmashell.service
        fi
    fi
}


checkPlasmoidsAndUpgrade() {
    echo
    for cmd in curl jq xmlstarlet unzip tar; do
        command -v "$cmd" >/dev/null || { echo "$cmd not installed"; exit; }
    done

    plasmoids=$(find $HOME/.local/share/plasma/plasmoids/ -mindepth 1 -maxdepth 1 -type d -printf "%f\n")
    [ -z "$plasmoids" ] && exit

    declare -a lines
    while IFS= read -r line; do
        lines+=("$line")
    done <<< "$plasmoids"

    tput sc
    text="Checking widgets for updates..."
    tempXML=$(mktemp)
    curl -s -o "$tempXML" --request GET --url "https://api.opendesktop.org/ocs/v1/content/data?categories=705&sort=new&page=0&pagesize=100" &
    spinner $! "$text"
    tput rc
    tput ed

    if [ -s "$tempXML" ]; then
        statuscode=$(xmlstarlet sel -t -m "//ocs/meta/statuscode" -v . -n $tempXML)
        if [ $statuscode = 200 ]; then
            rm "$tempXML"
            echo 200
            exit
        fi
    else
        exit
    fi

    output=""
    hasUpdates="false"
    for plasmoid in "${lines[@]}"; do
        dir="$HOME/.local/share/plasma/plasmoids/$plasmoid"
        json="$dir/metadata.json"
        [[ -s "$json" ]] || continue

        if ! jq -e '.KPackageStructure' "$json" >/dev/null 2>&1; then
            jq '. + { "KPackageStructure": "Plasma/Applet" }' $json > $dir/tmp.json && mv $dir/tmp.json $json
        fi

        name=$(jq -r '.KPlugin.Name' $json)
        contentId=$(xmlstarlet sel -t -m "//name[text()='$name']/.." -v "id" -n $tempXML)
        [ -z "$contentId" ] && contentId="$(getId "$plasmoid")"
        if [ -z "$contentId" ]; then
            knsregistry="$HOME/.local/share/knewstuff3/plasmoids.knsregistry"
            if [ -s "$knsregistry" ]; then
                contentId=$(xmlstarlet sel -t -m "//installedfile[contains(text(), 'plasma/plasmoids/$plasmoid')]/.." -v "id" -n $knsregistry)
            fi
        fi
        [ -z "$contentId" ] && continue

        current_version=$(jq -r '.KPlugin.Version' $json)
        current_version_clean=$(echo $current_version | sed 's/[^0-9.]*//g')
        current_version_clean=$(echo "$current_version_clean" | sed 's/^\.//')
        latest_version=$(xmlstarlet sel -t -m "//id[text()='$contentId']/.." -v "version" -n $tempXML)
        latest_version_clean=$(echo $latest_version | sed 's/[^0-9.]*//g')
        latest_version_clean=$(echo "$latest_version_clean" | sed 's/^\.//')
        [ -z "$latest_version_clean" ] || [ -z "$current_version_clean" ] && continue

        if [ "$(printf '%s\n' "$latest_version_clean" "$current_version_clean" | sort -V | head -n1)" != "$latest_version_clean" ]; then
            if [ "$contentId" = "2135796" ]; then
                echo
                echo -e "$r Upgrade Apdatifier manually $c"
                echo
            fi
            [ "$contentId" = "2135796" ] && continue

            tempDir=$(mktemp -d)
            mkdir $tempDir/unpacked

            tput sc
            text="Downloading $name"
            link=$(xmlstarlet sel -t -m "//id[text()='$contentId']/.." -v "downloadlink1[not(.='')] | downloadlink2[not(.='')] | downloadlink3[not(.='')] | downloadlink4[not(.='')] | downloadlink5[not(.='')] | downloadlink6[not(.='')]" -n $tempXML | tail -1 | tr -d '\n')
            tempFile="$tempDir/$(basename "${link}")"
            curl -s -o $tempFile --request GET --location "$link" 2>/dev/null &
            spinner $! "$text"
            tput rc
            tput ed

            if [ -s "$tempFile" ]; then
                echo -e "$g\u2714 $text $c"
            else
                echo -e "$r\u2718 $text $c"
                exit
            fi

            if [[ "$tempFile" == *.xz || "$tempFile" == *.gz ]]; then
                tar -xf "$tempFile" -C "$tempDir/unpacked"
            else
                unzip -q "$tempFile" -d "$tempDir/unpacked"
            fi

            metadata_path=$(find "$tempDir/unpacked" -name "metadata.json")
            if [ -z "$metadata_path" ]; then
                echo -e "$r\u2718 $METADATA_ERROR_TEXT $c"
                exit
            fi

            unpacked=$(dirname "$metadata_path")
            cd "$unpacked"

            if ! jq -e '.KPackageStructure' metadata.json >/dev/null 2>&1; then
                jq '. + { "KPackageStructure": "Plasma/Applet" }' metadata.json > tmp.json && mv tmp.json metadata.json
            fi

            jq --arg new_value "$latest_version" '.KPlugin.Version = $new_value' metadata.json > tmp.json && mv tmp.json metadata.json

            kpackagetool6 -t Plasma/Applet -u .
            sleep 1
            hasUpdates="true"
        fi
    done

    if [ "$1" = "true" ] && [ "$hasUpdates" = "true" ]; then
        sleep 2
        systemctl --user restart plasma-plasmashell.service
    fi
}



case "$1" in
                    "copy") copy;;
                 "install") install;;
               "uninstall") uninstall;;
              "getIgnored") getIgnoredPackages;;
          "checkPlasmoids") checkPlasmoidsUpdates $2;;
         "upgradePlasmoid") upgradePlasmoid $2 $3;;
"checkPlasmoidsAndUpgrade") checkPlasmoidsAndUpgrade $2;;
              "mirrorlist") mirrorlist_generator $2 $3;;
                         *) exit 0;;
esac
