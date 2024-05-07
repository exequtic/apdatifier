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


get_ignored_packages() {
    conf=$(pacman -Qv | awk 'NR==2 {print $NF}')
    if [ -s "$conf" ]; then
        grep -E "^\s*IgnorePkg\s*=" "$conf" | grep -v "^#" | awk -F '=' '{print $2}'
        grep -E "^\s*IgnoreGroup\s*=" "$conf" | grep -v "^#" | awk -F '=' '{print $2}'
    fi
}


mirrorlist_generator() {
    count=$1; link=$2; icons=$3; wrapper=$4; menu=$5; selected=$6
    define_text_icons $icons

    return_menu() { print_menu; management $count $link $icons $wrapper $selected; }

    if [[ "$menu" != "true" ]]; then
        while true; do
            print_question "$QUESTION_TEXT"; read -r answer
            case "$answer" in
                    [Yy]*) echo; break;;
                 [Nn]*|"") echo; exit;;
                        *)  ;;
            esac
        done
    fi

    check_pkg "curl rankmirrors" $5

    tput sc
    tempfile=$(mktemp)
    curl -m 30 -s -o $tempfile "$2" 2>/dev/null &
    spinner $! "$FETCHING_MIRRORS_TEXT"
    tput rc; tput ed
    if [[ -s "$tempfile" && $(head -n 1 "$tempfile" | grep -c "^##") -gt 0 ]]; then
        print_done "$FETCHING_MIRRORS_TEXT"
    else
        print_error "$FETCHING_MIRRORS_TEXT"
        print_error "$MIRRORS_ERROR_TEXT"
        [[ "$menu" = "true" ]] && return_menu || exit
    fi

    tput sc
    sed -i -e "s/^#Server/Server/" -e "/^#/d" "$tempfile"
    tempfile2=$(mktemp)
    rankmirrors -n "$1" "$tempfile" > "$tempfile2" &
    spinner $! "$RANKING_MIRRORS_TEXT"
    tput rc; tput ed
    if [[ -s "$tempfile2" && $(head -n 1 "$tempfile2" | grep -c "^# S") -gt 0 ]]; then
        print_done "$RANKING_MIRRORS_TEXT"
    else
        print_error "$RANKING_MIRRORS_TEXT"
        [[ "$menu" = "true" ]] && return_menu || exit
    fi

    mirrorfile="/etc/pacman.d/mirrorlist"
    sed -i '1d' "$tempfile2"
    sed -i "1s/^/##\n## Arch Linux repository mirrorlist\n## Generated on $(date '+%Y-%m-%d %H:%M:%S')\n##\n\n/" "$tempfile2"

    if [[ "$menu" = "true" ]]; then
        sudo -n true 2>/dev/null || { print_important "$MIRRORLIST_SUDO_TEXT"; }
        cat $tempfile2 | sudo tee $mirrorfile > /dev/null
    else
        cat $tempfile2 > $mirrorfile
    fi

    if [ $? -eq 0 ]; then
        print_done "$mirrorfile $MIRRORS_UPDATED_TEXT"
        echo -e "$y$(tail -n +6 $mirrorfile | sed 's/Server = //g')$c\n"
        rm $tempfile; rm $tempfile2
        [[ "$menu" = "true" ]] && return_menu
    else
        print_error "$MIRRORLIST_SUDO_TEXT"
        [[ "$menu" = "true" ]] && return_menu || exit
    fi
}


management() {
    trap '' SIGINT
    count=$1; link=$2; icons=$3; wrapper=$4; [ "$5" ] && selected="$5" || selected=0
    wrapper="${wrapper##*/}"; wrapper_sudo=$wrapper
    [[ $wrapper = "pacman" ]] && wrapper_sudo="sudo pacman"

    define_text_icons $icons

    return_menu() { print_menu; show_options $selected; }

    options=(
        "$LIST_ALL_ICO $LIST_ALL_TEXT"
        "$LIST_INSTALLED_ICO $LIST_INSTALLED_TEXT"
        "$LIST_EXPL_ICO $LIST_EXPL_TEXT"
        "$LIST_EXPL_NODEP_ICO $LIST_EXPL_NODEP_TEXT"
        "$LIST_DEPS_ICO $LIST_DEPS"
        "$REMOVE_ORPHANS_ICO $REMOVE_ORPHANS_TEXT"
        "$DOWNGRADE_ICO $DOWNGRADE_TEXT"
        "$REMOVE_CACHED_ICO $REMOVE_CACHED_TEXT"
        "$REMOVE_CACHED_ICO $REMOVE_CACHED_NOTINST_TEXT"
        "$REBUILD_PYTHON_ICO $REBUILD_PYTHON_TEXT"
        "$REFRESH_MIRRORLIST_ICO $REFRESH_MIRRORLIST_TEXT"
        "$EXIT_ICO $EXIT_TEXT"
    )

    show_options() {
        while true; do
            clear
            tput civis
            for i in "${!options[@]}"; do
                if [[ $i -eq $selected ]]; then
                    echo -e "${g}$SELECTOR_ICO${c} ${bold}${g}${options[$i]}${c}"
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

        clear
        tput cnorm

        case $selected in
            0) fzf_preview Slq;;
            1) fzf_preview Qq;;
            2) fzf_preview Qqe;;
            3) fzf_preview Qqet;;
            4) fzf_preview Qqtd;;
            5) uninstall_orphans;;
            6) downgrade_package;;
            7) print_executed -Scc; $wrapper_sudo -Scc; return_menu;;
            8) print_executed -Sc; $wrapper_sudo -Sc; return_menu;;
            9) rebuild_python;;
           10) mirrorlist_generator $count $link $icons $wrapper true $selected;;
           11) exit;;
        esac
    }

    fzf_preview() {
        check_pkg "fzf" true
        fzf_settings="--preview-window "right:70%" --height=100% \
                      --layout=reverse --info=right --border=none \
                      --multi --track --exact  --margin=0 --padding=0 \
                      --cycle --prompt=$SEARCH_TEXT⠀ --marker=•"

        case $1 in
                         Slq) fzf_exec -$1 -Si -S;;
            Qq|Qqe|Qqet|Qqtd) fzf_exec -$1 -Qil -Rsn;;
        esac
    }

    fzf_exec() {
        packages=$($wrapper $1 | fzf $fzf_settings --preview "$wrapper $2 {}")
        if [[ -z "$packages" ]]; then
            show_options $selected
        else
            packages=$(echo $packages | oneline)
            print_executed $3 "$packages"
            $wrapper_sudo $3 $packages
            return_menu
        fi
    }

    uninstall_orphans() {
        print_executed -Rsn "$($wrapper -Qqtd | oneline)"
        if [[ -n $($wrapper -Qdt) ]]; then
            $wrapper_sudo -Rsn $($wrapper -Qqtd)
        else
            print_done "$NO_ORPHANS_TEXT"
        fi

        return_menu
    }

    downgrade_package() {
        pacman_cache=$(pacman -Qv | awk 'NR==4 {print $NF}')
        wrapper_cache="$HOME/.cache/$wrapper"

        cache=$(find $pacman_cache $wrapper_cache -type f -name "*.pkg.tar.zst" -printf "%f\n" 2>/dev/null | sort | \
                fzf --exact --layout=reverse | oneline)

        if [[ -z "$cache" ]]; then
            show_options $selected
        else
            if [ -f "${pacman_cache}${cache}" ]; then
                print_executed -U "${pacman_cache}${cache}"
                $wrapper_sudo -U "${pacman_cache}${cache}"
            else
                cache=$(find $wrapper_cache -type f -name $cache 2>/dev/null)
                print_executed -U "${cache}"
                $wrapper_sudo -U $cache
            fi
            return_menu
        fi
    }

    rebuild_python() {
        [[ $wrapper = "pacman" ]] && { echo "Need wrapper"; return_menu; }
        rebuild_dir=$(find /usr/lib -type d -name "python*.*" | oneline)

        if [ $(echo "$rebuild_dir" | wc -w) -gt 1 ]; then
            rebuild_dir="${rebuild_dir#* }"
            rebuild_packages=$(pacman -Qqo "$rebuild_dir" | pacman -Qqm - | oneline)

            if [[ -z "$rebuild_packages" ]]; then
                print_done "$NOTHING_TEXT"
            else
                print_executed -S "$rebuild_packages --rebuild"
                while true; do
                    print_question "$RESUME_TEXT"
                    read -r answer
                    case "$answer" in
                           [Yy]*) echo; break;;
                        [Nn]*|"") echo; show_options;;
                               *)  ;;
                    esac
                done
                pacman -Qqo "$rebuild" | pacman -Qqm - | $wrapper -S --rebuild -
            fi
            
        else
            print_done "$NOTHING_TEXT"
        fi

        return_menu
    }

    show_options
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

download_xml() {
    XML=$(mktemp)
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
                tput rc; tput ed
                [[ $statuscode = 200 ]] && { print_error "$API_ERROR_TEXT"; onError; }
                [[ $statuscode != 100 ]] && { print_error "$CHECKING_WIDGETS_TEXT"; onError; }
                print_done "$CHECKING_WIDGETS_TEXT"
            fi

        else
            [[ $1 = "check" ]] && { echo 999; rm "$tempXML"; exit; } || { print_error "$CHECKING_WIDGETS_TEXT"; rm "$tempXML"; exit; }
        fi

        format_xml $tempXML

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

get_widget_list() {
    plasmoids=$(find $HOME/.local/share/plasma/plasmoids/ -mindepth 1 -maxdepth 1 -type d -printf "%f\n")
    [ -z "$plasmoids" ] && { exit; } || { while IFS= read -r line; do lines+=("$line"); done <<< "$plasmoids"; }
}

get_widget_info() {
    dir="$HOME/.local/share/plasma/plasmoids/$plasmoid"
    json="$dir/metadata.json"
    [ -s "$json" ] || return 1

    jq . $json >/dev/null 2>&1 || return 1
    if ! jq -e '.KPackageStructure' "$json" >/dev/null 2>&1; then
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

download_upgrade_widget() {
    tput sc; curl -m 30 -s -o $tempFile --request GET --location "$link" 2>/dev/null &
    spinner $! "$DOWNLOAD_TEXT $1"; tput rc; tput ed

    [ -s "$tempFile" ] && { print_done "$DOWNLOAD_TEXT $1"; } || { print_error "$DOWNLOAD_TEXT $1"; return 1; }

    if [[ "$tempFile" == *.xz || "$tempFile" == *.gz || "$tempFile" == *.tar ]]; then
        tar -xf "$tempFile" -C "$tempDir/unpacked"
    else
        unzip -q "$tempFile" -d "$tempDir/unpacked"
    fi

    metadata_path=$(find "$tempDir/unpacked" -name "metadata.json")
    [ -z "$metadata_path" ] && { print_error "$METADATA_ERROR_TEXT"; return 1; }

    unpacked=$(dirname "$metadata_path"); cd "$unpacked"

    jq . metadata.json >/dev/null 2>&1 || { print_error "$METADATA_ERROR2_TEXT"; return 1; }
    if ! jq -e '.KPackageStructure' metadata.json >/dev/null 2>&1; then
        jq '. + { "KPackageStructure": "Plasma/Applet" }' metadata.json > tmp.json && mv tmp.json metadata.json
    fi

    jq --arg new_value "$latest_version" '.KPlugin.Version = $new_value' metadata.json > tmp.json && mv tmp.json metadata.json

    kpackagetool6 -t Plasma/Applet -u .
    sleep 1

    return 0
}





check_widgets_updates() {
    define_text_icons true
    for cmd in curl jq xmlstarlet; do command -v "$cmd" >/dev/null || { echo 127; exit; }; done

    declare -a plasmoid lines; get_widget_list
    download_xml check

    output=""
    for plasmoid in "${lines[@]}"; do
        get_widget_info; [[ $? -ne 0 ]] && continue

        if [[ "$(printf '%s\n' "$latest_version_clean" "$current_version_clean" | sort -V | head -n1)" != "$latest_version_clean" ]]; then 
            output+="${name}@${contentId}@${description}@${author}@${current_version}@${latest_version}@${url}\n"
        fi
    done

    rm $XML
    echo -e "$output"
}

check_widgets_and_upgrade() {
    define_text_icons $2
    check_pkg "curl jq xmlstarlet unzip tar"

    declare -a plasmoid lines; get_widget_list

    echo; tput sc; download_xml &
    spinner $! "$CHECKING_WIDGETS_TEXT"

    for plasmoid in "${lines[@]}"; do
        get_widget_info; [[ $? -ne 0 ]] && continue

        if [[ "$(printf '%s\n' "$latest_version_clean" "$current_version_clean" | sort -V | head -n1)" != "$latest_version_clean" ]]; then
            link=$(xmlstarlet sel -t -m "//id[text()='$1']/.." -v "downloadlink" -n $XML)
            tempDir=$(mktemp -d)
            tempFile="$tempDir/$(basename "${link}")"
            mkdir $tempDir/unpacked
            download_upgrade_widget "$name"; [[ $? -ne 0 ]] && continue
        fi
    done

    rm $XML

    [ "$1" = "true" ] && [ "$hasUpdates" = "true" ] && { sleep 2; systemctl --user restart plasma-plasmashell.service; }
}

upgrade_widget() {
    [ $1 ] || exit

    define_text_icons $3
    check_pkg "curl jq xmlstarlet unzip tar"

    [[ "$2" = "true" ]] && { echo -e "\n"; } || { print_important "${WARNING_TEXT_1}\n${WARNING_TEXT_2}\n"; }; sleep 1

    tempDir=$(mktemp -d); mkdir $tempDir/unpacked; XML="$tempDir/data.xml"

    tput sc; curl -m 30 -s -o $XML --request GET --url "https://api.opendesktop.org/ocs/v1/content/data/$1" 2>/dev/null &
    spinner $! "$FETCHING_INFO_TEXT"; tput rc; tput ed

    onError() { rm -rf "$tempDir"; exit; }

    if [ -s "$XML" ]; then
        statuscode=$(xmlstarlet sel -t -m "//ocs/meta/statuscode" -v . -n $XML)
        [[ $statuscode = 200 ]] && { print_error "$API_ERROR_TEXT"; onError; }
        [[ $statuscode != 100 ]] && { print_error "$FETCHING_INFO_TEXT"; onError; }
        print_done "$FETCHING_INFO_TEXT"
    else
        print_error "$FETCHING_INFO_TEXT"; onError
    fi

    format_xml $XML
    link=$(xmlstarlet sel -t -m "//id[text()='$1']/.." -v "downloadlink" -n $XML)
    latest_version=$(xmlstarlet sel -t -m "//id[text()='$1']/.." -v "version" -n $XML)
    tempFile="$tempDir/$(basename "${link}")"

    download_upgrade_widget $4; [[ $? -ne 0 ]] && exit

    [[ "$2" = "true" ]] && { sleep 2; systemctl --user restart plasma-plasmashell.service; }
}






define_text_icons() {
    CMD_ERROR_TEXT="Required installed"

    QUESTION_TEXT="Refresh mirrorlist?"
    FETCHING_MIRRORS_TEXT="Fetching the latest filtered mirror list..."
    RANKING_MIRRORS_TEXT="Ranking mirrors by their connection and opening speed..."
    MIRRORS_ERROR_TEXT="Check your mirrorlist generator settings..."
    MIRRORS_UPDATED_TEXT="was updated with the following servers:"
    MIRRORLIST_SUDO_TEXT="To write to a mirrorlist file, sudo rights are required"
    RETURN_MENU_TEXT="Press Enter to return menu"

    WARNING_TEXT_1="For some widgets you may need to Log Out or restart plasmashell after upgrade"
    WARNING_TEXT_2="(kquitapp6 plasmashell && kstart plasmashell) so that they work correctly."
    CHECKING_WIDGETS_TEXT="Checking widgets for updates..."
    FETCHING_INFO_TEXT="Fetching information about widget..."
    DOWNLOADING_TEXT="Downloading widget..."
    DOWNLOAD_TEXT="Downloading"
    API_ERROR_TEXT="Too many API requests in the last 15 minutes from your IP address. Please try again later."
    METADATA_ERROR_TEXT="File metadata.json not found"
    METADATA_ERROR2_TEXT="Errors in metadata.json file"
    MANUALLY_TEXT="Upgrade Apdatifier manually"
    LOGOUT_TEXT="Log out or restart plasmashell after upgrade"

    LIST_ALL_TEXT="List all available packages from repositories"
    LIST_INSTALLED_TEXT="List all installed packages"
    LIST_EXPL_TEXT="List explicitly installed packages"
    LIST_EXPL_NODEP_TEXT="List explicitly installed and isn't a dependency of anything"
    LIST_DEPS="List installed as a dependency but isn't needed anymore (orphans)"
    REMOVE_ORPHANS_TEXT="Uninstall orphans packages"
    NO_ORPHANS_TEXT="No orphans to remove"
    DOWNGRADE_TEXT="Downgrade package from cache"
    REMOVE_CACHED_TEXT="Remove ALL cached packages"
    REMOVE_CACHED_NOTINST_TEXT="Remove cached packages that are not currently installed"
    REBUILD_PYTHON_TEXT="Rebuild python packages"
    RESUME_TEXT="Resume?"
    NOTHING_TEXT="Nothing to do"
    REFRESH_MIRRORLIST_TEXT="Refresh mirrorlist"
    EXIT_TEXT="Exit"
    RETURN_MENU_TEXT="Press Enter to return menu"
    EXECUTED_TEXT="Executed:"
    SEARCH_TEXT="Search:"

    LANGUAGE=${LANG:0:2}
    MESSAGES_FILE="/home/$(logname)/.local/share/plasma/plasmoids/$applet/translate/$LANGUAGE.sh"
    [ -f "$MESSAGES_FILE" ] && source "$MESSAGES_FILE"

    if [[ $1 = "true" ]]; then
        ERROR_ICO=""
        DONE_ICO=""
        IMPORTANT_ICO="󱇎"
        QUESTION_ICO="󰆆"
        EXECUTED_ICO="󰅱"
        RETURN_ICO="󰄽"
        SELECTOR_ICO="󰄾"
        LIST_ALL_ICO="󱝩"
        LIST_INSTALLED_ICO="󱝫"
        LIST_EXPL_ICO="󱝭"
        LIST_EXPL_NODEP_ICO="󱝭"
        LIST_DEPS_ICO="󱝧"
        REMOVE_ORPHANS_ICO=""
        DOWNGRADE_ICO="󱝥"
        REMOVE_CACHED_ICO="󱝝"
        REMOVE_CACHED_NOTINST_ICO="󱝝"
        REBUILD_PYTHON_ICO="󰌠"
        REFRESH_MIRRORLIST_ICO="󱘴"
        EXIT_ICO=""
    else
        ERROR_ICO="\u2718"
        DONE_ICO="\u2714"
        IMPORTANT_ICO="::"
        QUESTION_ICO="::"
        RETURN_ICO="::"
        EXECUTED_ICO="::"
        SELECTOR_ICO=">"
        LIST_ALL_ICO=""
        LIST_INSTALLED_ICO=""
        LIST_EXPL_ICO=""
        LIST_EXPL_NODEP_ICO=""
        LIST_DEPS_ICO=""
        REMOVE_ORPHANS_ICO=""
        DOWNGRADE_ICO=""
        REMOVE_CACHED_ICO=""
        REMOVE_CACHED_NOTINST_ICO=""
        REBUILD_PYTHON_ICO=""
        REFRESH_MIRRORLIST_ICO=""
        EXIT_ICO=""
    fi
}

r="\033[1;31m"; g="\033[1;32m"; b="\033[1;34m"; y="\033[0;33m"; c="\033[0m"; bold="\033[1m"
print_menu() { tput civis; echo -e "\n${b}${RETURN_ICO}${c} ${bold}${RETURN_MENU_TEXT}${c}"; read -r; tput cnorm; }
print_done() { echo -e "${g}${DONE_ICO} $1 ${c}"; }
print_error() { echo -e "${r}${ERROR_ICO} $1 ${c}"; }
print_important() { echo -e "${y}${bold}${IMPORTANT_ICO} $1 ${c}"; }
print_question() { echo -en "\n${y}${QUESTION_ICO}${c}${y}${bold} $1 ${c}[y/${bold}N${c}]: "; }
print_executed() { echo -e "${b}${EXECUTED_ICO}${c}${bold} ${EXECUTED_TEXT}${c} $wrapper_sudo $1 $2 \n"; }
oneline() { tr '\n' ' ' | sed 's/ $//'; }
check_pkg() { for cmd in ${1}; do command -v "$cmd" >/dev/null || { print_error "${CMD_ERROR_TEXT} ${cmd}"; [ $2 ] && return_menu || exit; }; done; }
spinner() { spin="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"; while kill -0 $1 2>/dev/null; do i=$(( (i+1) %10 )); printf "${r}\r${spin:$i:1}${c} ${b}$2${c}"; sleep .2; done; }
format_xml() { sed -i 's/downloadlink[1-9]>/downloadlink>/g' $1; xmlstarlet ed -L -d "//content[@details='summary']/downloadlink[position() < last()]" -d "//content[@details='summary']/*[not(self::id or self::name or self::version or self::downloadlink)]" $1; }



case "$1" in
                        "copy") copy;;
                     "install") install;;
                   "uninstall") uninstall;;
                  "getIgnored") get_ignored_packages;;
                  "management") shift; management $1 $2 $3 $4;;
              "checkPlasmoids") shift; check_widgets_updates;;
              "upgrade_widget") shift; upgrade_widget $1 $2 $3 $4;;
   "check_widgets_and_upgrade") shift; check_widgets_and_upgrade $1 $2;;
                  "mirrorlist") shift; mirrorlist_generator $1 $2 $3;;
                             *) exit;;
esac
