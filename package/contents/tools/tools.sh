#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
# SPDX-License-Identifier: MIT

applet="com.github.exequtic.apdatifier"

scriptDir=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
configDir="$HOME/.config/apdatifier"
localDir="$HOME/.local/share"
iconsDir="$localDir/icons/breeze/status/24"
notifDir="$localDir/knotifications6"
appletDir="$localDir/plasma/plasmoids/$applet"

icon1="apdatifier-plasmoid.svg"
icon2="apdatifier-packages.svg"
icon3="apdatifier-package.svg"
notif="apdatifier.notifyrc"


init() {
    [ -d $iconsDir ] || mkdir -p $iconsDir
    [ -d $notifDir ] || mkdir -p $notifDir
    [ -d $configDir ] || mkdir -p $configDir
    [ -d $notifDir ] && notifyrc

    [ -f $iconsDir/$icon1 ] || cp $appletDir/contents/ui/assets/icons/$icon1 $iconsDir
    [ -f $iconsDir/$icon2 ] || cp $appletDir/contents/ui/assets/icons/$icon2 $iconsDir
    [ -f $iconsDir/$icon3 ] || cp $appletDir/contents/ui/assets/icons/$icon3 $iconsDir
}


install() {
    required="git zip kpackagetool6"
    for cmd in ${required}; do command -v "$cmd" >/dev/null || { echo -e "${r}${bold} Required installed ${cmd} ${c}"; exit; }; done;
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
    for cmd in "kpackagetool6"; do command -v "$cmd" >/dev/null || { echo -e "${r}${bold} Required installed ${cmd} ${c}"; exit; }; done;
    [ ! -f $iconsDir/$icon1 ] || rm -f $iconsDir/$icon1
    [ ! -f $iconsDir/$icon2 ] || rm -f $iconsDir/$icon2
    [ ! -f $iconsDir/$icon3 ] || rm -f $iconsDir/$icon3
    [ ! -f $notifDir/$notif ] || rm -f $notifDir/$notif
    [ ! -d $iconsDir ] || rmdir -p --ignore-fail-on-non-empty $iconsDir
    [ ! -d $notifDir ] || rmdir -p --ignore-fail-on-non-empty $notifDir
    [ -z "$(kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep $applet)" ] || kpackagetool6 --type Plasma/Applet -r $applet 2>/dev/null
    sleep 2
}

notifyrc() {
cat > "$notifDir/$notif" << EOF
[Global]
IconName=apdatifier-plasmoid
Comment=Apdatifier

[Event/updates]
Name=New updates
Comment=Event when updates notification enabled without sound
Action=Popup

[Event/updatesSound]
Name=New updates (with sound)
Comment=Event when updates notification enabled with sound
Action=Popup|Sound
Sound=service-login

[Event/error]
Name=Error
Comment=Event when error notification enabled without sound
Action=Popup

[Event/errorSound]
Name=Error (with sound)
Comment=Event when errors notification enabled with sound
Action=Popup|Sound
Sound=dialog-error-serious

[Event/news]
Name=News
Comment=Event when news notification without sound
Action=Popup

[Event/newsSound]
Name=News (with sound)
Comment=Event when news notification with sound
Action=Popup|Sound
Sound=dialog-information
EOF
}


mirrorlistGenerator() {
    count=$1; link=$2; icons=$3; wrapper=$4; sudoCmd=$5; menu=$6; selected=$7
    mirrorfile="/etc/pacman.d/mirrorlist"
    getTxt $icons

    returnMenu() { printMenu; management $count $link $icons $wrapper $sudoCmd $selected; }

    if [ -f $mirrorlist ]; then
        FILE_TIME=$(date -r "$mirrorfile" +%s)
        NORM_TIME=$(date -d @$FILE_TIME +"%d %b %H:%M:%S")
        echo -en "\n${y}${ICO_WARN}${c}${y}${bold} ${MIRROR_TIME}${c} $NORM_TIME"
    fi

    while true; do
        printQuestion "$MNG_OPT_11?"; read -r answer
        case "$answer" in
                [Yy]*) echo; break;;
             [Nn]*|"") [[ "$menu" = "true" ]] && { returnMenu; } || { echo; exit; };;
                    *)  ;;
        esac
    done

    checkPkg "curl rankmirrors" $5
    rankmirrors -V &>/dev/null || {
        countries=$(echo "$2" | grep -oP '(?<=country=)[^&]+')
        countries=$(echo "$countries" | tr '\n' ' ')
        countries=$(echo "$countries" | sed 's/ *$//')

        if [ -z "$countries" ]; then
            printError "$MIRRORS_ERR"
        else
            echo "Selected countries: $countries"
            ${sudoCmd} rankmirrors -c ${countries}
            echo
        fi

        [[ "$menu" = "true" ]] && returnMenu || exit
    }

    tempfile=$(mktemp)
    tput sc; curl -m 30 -s -o $tempfile "$2" 2>/dev/null &
    spinner $! "$MIRRORS_FETCH"; tput rc; tput ed
    if [[ -s "$tempfile" && $(head -n 1 "$tempfile" | grep -c "^##") -gt 0 ]]; then
        printDone "$MIRRORS_FETCH"
    else
        printError "$MIRRORS_FETCH"
        printError "$MIRRORS_ERR"
        [[ "$menu" = "true" ]] && returnMenu || exit
    fi

    sed -i -e "s/^#Server/Server/" -e "/^#/d" "$tempfile"
    tempfile2=$(mktemp)
    tput sc; rankmirrors -n "$1" "$tempfile" > "$tempfile2" &
    spinner $! "$MIRRORS_RANK"; tput rc; tput ed
    if [[ -s "$tempfile2" && $(head -n 1 "$tempfile2" | grep -c "^# S") -gt 0 ]]; then
        printDone "$MIRRORS_RANK"
    else
        printError "$MIRRORS_RANK"
        [[ "$menu" = "true" ]] && returnMenu || exit
    fi

    sed -i '1d' "$tempfile2"
    sed -i "1s/^/##\n## Arch Linux repository mirrorlist\n## Generated on $(date '+%Y-%m-%d %H:%M:%S')\n##\n\n/" "$tempfile2"

    if [[ "$menu" = "true" ]]; then
        ${sudoCmd} -n true 2>/dev/null || { printImportant "$MIRRORS_SUDO"; }
        cat $tempfile2 | ${sudoCmd} tee $mirrorfile > /dev/null
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
    count=$1; link=$2; icons=$3; wrapper=$4; sudoCmd=$5; [ "$6" ] && selected="$6" || selected=0
    wrapper="${wrapper##*/}"; wrapper_sudo=$wrapper
    [[ $wrapper = "trizen" ]] && wrapper="pacman"
    [[ $wrapper = "pacman" ]] && wrapper_sudo="$sudoCmd pacman"

    getTxt $icons

    returnMenu() { printMenu; showOptions $selected; }

    options=(
        "${ICO_MNG_OPT_01}${MNG_OPT_01}"
        "${ICO_MNG_OPT_02}${MNG_OPT_02}"
        "${ICO_MNG_OPT_03}${MNG_OPT_03}"
        "${ICO_MNG_OPT_04}${MNG_OPT_04}"
        "${ICO_MNG_OPT_05}${MNG_OPT_05}"
        "${ICO_MNG_OPT_06}${MNG_OPT_06}"
        "${ICO_MNG_OPT_07}${MNG_OPT_07}"
        "${ICO_MNG_OPT_08}${MNG_OPT_08}"
        "${ICO_MNG_OPT_09}${MNG_OPT_09}"
        "${ICO_MNG_OPT_10}${MNG_OPT_10}"
        "${ICO_MNG_OPT_11}${MNG_OPT_11}"
        "${ICO_MNG_OPT_12}${MNG_OPT_12}"
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
           10) mirrorlistGenerator $count $link $icons $wrapper $sudoCmd true $selected;;
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
            packages=$(echo "$packages" | oneLine)
            printExec $3 "$packages"
            $wrapper_sudo $3 $packages
            returnMenu
        fi
    }

    uninstallOrphans() {
        if [[ -n $($wrapper -Qdt) ]]; then
            printExec -Rsn "$($wrapper -Qqtd | oneLine)"
            printImportant "$MNG_WARN"; echo
            $wrapper_sudo -Rsn $($wrapper -Qqtd)
        else
            printDone "$MNG_DONE"
        fi

        returnMenu
    }

    downgradePackage() {
        checkPkg "fzf" true
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
        [[ $wrapper = "pacman" ]] && { printDone "$MNG_DONE"; returnMenu; }
        rebuild_dir=$(find /usr/lib -maxdepth 1 -type d -name "python*.*" | oneLine)

        if [ $(echo "$rebuild_dir" | wc -w) -gt 1 ]; then
            rebuild_dir="${rebuild_dir#* }"
            rebuild_packages=$( { pacman -Qqo "$rebuild_dir" | pacman -Qqm - | oneLine; } 2>/dev/null)
            if [[ -z "$rebuild_packages" ]]; then
                printDone "$MNG_DONE"
            else
                printExec "-S --rebuild" "$rebuild_packages"
                while true; do
                    printQuestion "$MNG_RESUME"; read -r answer
                    case "$answer" in
                           [Yy]*) echo; break;;
                        [Nn]*|"") echo; showOptions;;
                               *)  ;;
                    esac
                done
                pacman -Qqo "$rebuild_dir" | pacman -Qqm - | $wrapper -S --rebuild -
            fi
        else
            printDone "$MNG_DONE"
        fi

        returnMenu
    }

    showOptions
}


downloadXML() {
    page=0
    while true; do
        tempXML=$(mktemp)
        api_url="https://api.opendesktop.org/ocs/v1/content/data?categories=705&sort=new&page=$page&pagesize=100"
        curl -m 30 -s -o "$tempXML" --request GET --url "$api_url"

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
            if [[ $1 = "check" ]]; then
                echo 999; rm "$tempXML"; exit
            else
                printError "$WIDGETS_CHECK"; rm "$tempXML"; exit
            fi
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
        if [[ $totalitems > $items ]]; then
            ((page++))
        else
            break
        fi
    done
}

getWidgets() {
    plasmoids=$(find "$HOME/.local/share/plasma/plasmoids" -mindepth 1 -maxdepth 1 -type d -printf "%f\n")
    if [ -z "$plasmoids" ]; then
        exit
    else
        while IFS= read -r line; do lines+=("$line"); done <<< "$plasmoids"
    fi
}

getWidgetInfo() {
    dir="$HOME/.local/share/plasma/plasmoids/$plasmoid"
    json="$dir/metadata.json"
    [ -s "$json" ] || return 1

    jq . $json >/dev/null 2>&1 || return 1
    if ! jq -e '.KPackageStructure == "Plasma/Applet"' "$json" >/dev/null 2>&1; then
        jq '. + { "KPackageStructure": "Plasma/Applet" }' $json > $dir/tmp.json && mv $dir/tmp.json $json
    fi

    name=$(jq -r '.KPlugin.Name' $json)
    contentId=$(xmlstarlet sel -t -m "//name[text()='$name']/.." -v "id" -n $XML)
    [ -z "$contentId" ] && contentId="$(getId "$plasmoid")"
    if [ -z "$contentId" ]; then
        knsregistry="$HOME/.local/share/knewstuff3/plasmoids.knsregistry"
        [ -s "$knsregistry" ] && contentId=$(xmlstarlet sel -t -m "//installedfile[contains(text(), 'plasma/plasmoids/$plasmoid')]/.." -v "id" -n $knsregistry)
    fi
    [ -z "$contentId" ] && return 1

    currentVer=$(jq -r '.KPlugin.Version' $json)
    latestVer=$(xmlstarlet sel -t -m "//id[text()='$contentId']/.." -v "version" -n $XML)
    [ -z "$currentVer" ] || [ -z "$latestVer" ] && return 1

    compareVer $(clearVer "$currentVer") $(clearVer "$latestVer")
    [[ $? != 2 ]] && return 1

    description=$(jq -r '.KPlugin.Description' $json | tr -d '\n')
    [ -z "$description" ] || [ "$description" = "null" ] && description="-"

    author=$(jq -r '.KPlugin.Authors[].Name' $json | paste -sd "," - | sed 's/,/, /g')
    [ -z "$author" ] || [ "$author" = "null" ] && author="-"

    icon=$(jq -r '.KPlugin.Icon' $json)
    if [ -z "$icon" ]; then
        icon="start-here-kde"
    else
        ! find /usr/share/icons "$HOME/.local/share/icons" -name "$icon.svg" 2>/dev/null | grep -q . && icon="start-here-kde"
    fi

    url="https://store.kde.org/p/$contentId"
    name=$(echo "$name" | sed 's/ /-/g; s/.*/\L&/')
    repo="kde-store"

    return 0
}

downloadWidget() {
    tput sc; curl -s -o $tempFile --request GET --location "$link" 2>/dev/null &
    spinner $! "$WIDGETS_DOWNLOADING $1"; tput rc; tput ed

    if [ -s "$tempFile" ]; then
        printDone "$WIDGETS_DOWNLOADING $1"
    else
        printError "$WIDGETS_DOWNLOADING $1"; return 1
    fi

    case "$tempFile" in
         *.zip | *.plasmoid) unzip -q "$tempFile" -d "$tempDir/unpacked";;
        *.xz | *.gz | *.tar) tar -xf "$tempFile" -C "$tempDir/unpacked";;
                          *) printError "$WIDGETS_EXT_ERR"; return 1;;
    esac

    metadata_path=$(find "$tempDir/unpacked" -name "metadata.json")
    [ -z "$metadata_path" ] && { printError "$WIDGETS_JSON_ERR"; return 1; }

    unpacked=$(dirname "$metadata_path"); cd "$unpacked"

    jq . metadata.json >/dev/null 2>&1 || { printError "$WIDGETS_JSON_ERR2"; return 1; }
    if ! jq -e '.KPackageStructure == "Plasma/Applet"' metadata.json >/dev/null 2>&1; then
        jq '. + { "KPackageStructure": "Plasma/Applet" }' metadata.json > tmp.json && mv tmp.json metadata.json
    fi

    jq --arg new_value "$latestVer" '.KPlugin.Version = $new_value' metadata.json > tmp.json && mv tmp.json metadata.json

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

    first=true; out="["
    source "$scriptDir/widgets.sh"
    for plasmoid in "${lines[@]}"; do
        getWidgetInfo; [[ $? -ne 0 ]] && continue
        compareVer $(clearVer "$currentVer") $(clearVer "$latestVer")
        if [[ $? = 2 ]]; then
            [ "$first" = false ] && out+=","
            out+="{\"NM\": \"${name}\","
            out+="\"RE\": \"${repo}\","
            out+="\"CN\": \"${contentId}\","
            out+="\"IN\": \"${icon}\","
            out+="\"DE\": \"${description}\","
            out+="\"AU\": \"${author}\","
            out+="\"VO\": \"${currentVer}\","
            out+="\"VN\": \"${latestVer}\","
            out+="\"LN\": \"${url}\"}"
            first=false
        fi
    done

    rm $XML
    echo -e "$out]"
}

upgradeAllWidgets() {
    getTxt $2
    checkPkg "curl jq xmlstarlet unzip tar"

    declare -a plasmoid lines; getWidgets

    XML=$(mktemp)
    echo; tput sc; downloadXML &
    spinner $! "$WIDGETS_CHECK"
    tput rc; tput ed; printDone "$WIDGETS_CHECK"

    hasUpdates="false"
    source "$scriptDir/widgets.sh"
    for plasmoid in "${lines[@]}"; do
        getWidgetInfo; [[ $? -ne 0 ]] && continue
        compareVer $(clearVer "$currentVer") $(clearVer "$latestVer")
        if [[ $? = 2 ]]; then
            link=$(xmlstarlet sel -t -m "//id[text()='$contentId']/.." -v "downloadlink" -n $XML)
            tempDir=$(mktemp -d)
            tempFile="$tempDir/$(basename "${link}")"
            mkdir $tempDir/unpacked
            downloadWidget "$name"; [[ $? -ne 0 ]] && continue
            hasUpdates="true"
        fi
    done

    rm $XML

    [[ "$1" = "true" ]] && [[ "$hasUpdates" = "true" ]] && {
        sleep 1
        while true; do
            printQuestion "$WIDGETS_RESTART"; read -r answer
            case "$answer" in
                    [Yy]*) echo; break;;
                 [Nn]*|"") echo; exit;;
                        *)  ;;
            esac
        done
        eval ${3}
    }
}

upgradeWidget() {
    [ $1 ] || exit

    getTxt $3
    checkPkg "curl jq xmlstarlet unzip tar"

    [[ "$2" != "true" ]] && printImportant "${WIDGETS_WARN}\n"

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
    latestVer=$(xmlstarlet sel -t -m "//id[text()='$1']/.." -v "version" -n $XML)
    tempFile="$tempDir/$(basename "${link}")"

    downloadWidget $4; [[ $? -ne 0 ]] && exit

    [[ "$2" = "true" ]] && {
        sleep 1
        while true; do
            printQuestion "$WIDGETS_RESTART"; read -r answer
            case "$answer" in
                    [Yy]*) echo; break;;
                 [Nn]*|"") echo; exit;;
                        *)  ;;
            esac
        done
        eval ${5}
    }
}


getTxt() {
    export TEXTDOMAINDIR="$scriptDir/../locale"
    export TEXTDOMAIN="plasma_applet_${applet}"

    declare -a var_names=(
    MIRRORS_FETCH MIRRORS_RANK MIRRORS_ERR MIRRORS_UPD MIRRORS_SUDO MIRROR_TIME
    WIDGETS_WARN WIDGETS_CHECK WIDGETS_FETCHING WIDGETS_DOWNLOADING WIDGETS_RESTART
    WIDGETS_API_ERR WIDGETS_JSON_ERR WIDGETS_JSON_ERR2 WIDGETS_EXT_ERR
    MNG_OPT_01 MNG_OPT_02 MNG_OPT_03 MNG_OPT_04 MNG_OPT_05 MNG_OPT_06
    MNG_OPT_07 MNG_OPT_08 MNG_OPT_09 MNG_OPT_10 MNG_OPT_11 MNG_OPT_12
    MNG_WARN MNG_RESUME MNG_RETURN MNG_SEARCH MNG_EXEC MNG_DONE CMD_ERR)

    i=0
    while IFS= read -r line && [ $i -lt ${#var_names[@]} ]; do
        i=$((i+1))
        text=$(echo "$line" | grep -oP '(?<=\().*(?=\))' | sed 's/"//g')
        eval "${var_names[$((i-1))]}=\"$(gettext "$text")\""
    done < "$scriptDir/../ui/components/Messages.qml"

    if [[ $1 = "true" ]]; then
        ICO_MNG_OPT_01="󱝩 "; ICO_MNG_OPT_02="󱝫 "; ICO_MNG_OPT_03="󱝭 "; ICO_MNG_OPT_04="󱝭 "
        ICO_MNG_OPT_05="󱝧 "; ICO_MNG_OPT_06=" "; ICO_MNG_OPT_07="󱝥 "; ICO_MNG_OPT_08="󱝝 "
        ICO_MNG_OPT_09="󱝝 "; ICO_MNG_OPT_10="󰌠 "; ICO_MNG_OPT_11="󱘴 "; ICO_MNG_OPT_12=" "
        
        ICO_ERR=""; ICO_DONE=""; ICO_WARN="󱇎"; ICO_QUESTION=""; ICO_EXEC="󰅱"; ICO_RETURN="󰄽"; ICO_SELECT="󰄾"
    else
        ICO_ERR="✘"; ICO_DONE="✔"; ICO_WARN="::"; ICO_QUESTION="::"; ICO_EXEC="::"; ICO_RETURN="<<"; ICO_SELECT=">"
    fi
}

r="\033[1;31m"; g="\033[1;32m"; b="\033[1;34m"; y="\033[0;33m"; c="\033[0m"; bold="\033[1m"
printMenu() { tput civis; echo -e "\n${b}${ICO_RETURN}${c} ${bold}${MNG_RETURN}${c}"; read -r; tput cnorm; }
printDone() { echo -e "${g}${ICO_DONE} $1 ${c}"; }
printError() { echo -e "${r}${ICO_ERR} $1 ${c}"; }
printImportant() { echo -e "${y}${bold}${ICO_WARN} $1 ${c}"; }
printQuestion() { echo -en "\n${y}${ICO_QUESTION}${c}${y}${bold} $1 ${c}[y/N]: "; }
printExec() { echo -e "${b}${ICO_EXEC}${c}${bold} ${MNG_EXEC}${c} $wrapper_sudo $1 $2 \n"; }

oneLine() { tr '\n' ' ' | sed 's/ $//'; }
checkPkg() { for cmd in ${1}; do command -v "$cmd" >/dev/null || { printError "${CMD_ERR} ${cmd}"; [ $2 ] && returnMenu || exit; }; done; }
spinner() { spin="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"; while kill -0 $1 2>/dev/null; do i=$(( (i+1) %10 )); printf "${r}\r${spin:$i:1}${c} ${b}$2${c}"; sleep .2; done; }

formatXML() { sed -i -E 's/downloadlink[0-9]+>/downloadlink>/g' $1; sed -i 's/details="full"/details="summary"/g' $1; \
              xmlstarlet ed -L -d "//content[@details='summary']/downloadlink[position() < last()]" \
                               -d "//content[@details='summary']/*[not(self::id or self::name or self::version or self::downloadlink)]" $1; }

clearVer() { local ver="${1}"; ver="${ver#.}"; ver="${ver%.}"; ver="${ver//[!0-9.]}"; echo "${ver}"; }
compareVer() {
    [[ $1 == $2 ]] && return 0
    local IFS=.; local i ver1=($1) ver2=($2)
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do ver1[i]=0; done
    for ((i=0; i<${#ver1[@]}; i++)); do
        [[ -z ${ver2[i]} ]] && ver2[i]=0
        ((10#${ver1[i]} > 10#${ver2[i]})) && return 1
        ((10#${ver1[i]} < 10#${ver2[i]})) && return 2
    done
    return 0
}

convertRules() {
    old_file="$HOME/.cache/apdatifier/packages_icons"
    new_file="$HOME/.config/apdatifier/rules.json"
    [ ! -s $old_file ] && { echo -e "${r}Empty or not exist ->${c} $old_file"; exit; }
    [ -s $new_file ] && { echo -e "${r}Already exist and not empty ->${c} $new_file"; exit; }
    first=true; buffer=""; echo "[" > "$new_file"
    while IFS= read -r line || [ -n "$line" ]; do
        IFS='>' read -r type value icon <<< "$line"
        type="${type// /}"; value="${value// /}"; icon="${icon// /}"
        if [ -n "$type" ] && [ -n "$value" ] && [ -n "$icon" ]; then
            if [[ "$type" =~ ^(repo|group|match|name)$ ]]; then
                [ "$first" = false ] && buffer+=",\n"
                first=false
                buffer+="{\"type\":\"$type\",\"value\":\"$value\",\"icon\":\"$icon\",\"excluded\":false}"
            fi
        fi
    done < "$old_file"
    echo -e "$buffer\n]" >> "$new_file"
    [ -s $new_file ] && { echo -e "${g}Created ->${c} $new_file"; exit; }
}


case "$1" in
                        "init") init;;
                     "install") install;;
                   "uninstall") uninstall;;
                  "management") shift; management $1 $2 $3 $4 $5;;
                "checkWidgets") shift; checkWidgets;;
               "upgradeWidget") shift; upgradeWidget $1 $2 $3 $4 "$5";;
           "upgradeAllWidgets") shift; upgradeAllWidgets $1 $2 "$3";;
                  "mirrorlist") shift; mirrorlistGenerator $1 $2 $3;;
                "convertRules") convertRules;;
                             *) exit;;
esac
