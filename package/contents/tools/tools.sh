#!/usr/bin/env sh

# SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
# SPDX-License-Identifier: MIT

applet="com.github.exequtic.apdatifier"

localdir="/home/$(whoami)/.local/share"
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
    [ -f $notifdir/$file3 ] || cp $plasmoid/contents/notifyrc/$file3 $notifdir
}


### Download and install with latest commit
install() {
    command -v git >/dev/null || { echo "git not installed" >&2; exit 1; }
    command -v zip >/dev/null || { echo "zip not installed" >&2; exit 1; }
    command -v kpackagetool6 >/dev/null || { echo "kpackagetool6 not installed" >&2; exit 1; }

    if [ ! -z "$(kpackagetool6 -t Plasma/Applet -l | grep $applet)" ]; then
        echo "Plasmoid already installed"
        uninstall
        sleep 2
    fi

    savedir=$(pwd)
    cd /tmp && git clone -n --depth=1 --filter=tree:0 -b main https://github.com/exequtic/apdatifier
    cd apdatifier && git sparse-checkout set --no-cone package && git checkout

    if [ $? -eq 0 ]; then
        cd package
        zip -rq apdatifier.plasmoid .
        [ ! -f apdatifier.plasmoid ] || kpackagetool6 -t Plasma/Applet -i apdatifier.plasmoid
    fi

    cd $savedir

    [ ! -d /tmp/apdatifier ] || rm -rf /tmp/apdatifier
}


uninstall() {
    command -v kpackagetool6 >/dev/null || { echo "kpackagetool6 not installed" >&2; exit 1; }

    [ ! -f $iconsdir/$file1 ] || rm -f $iconsdir/$file1
    [ ! -f $iconsdir/$file2 ] || rm -f $iconsdir/$file2
    [ ! -f $notifdir/$file3 ] || rm -f $notifdir/$file3
    [ ! -d $iconsdir ] || rmdir -p --ignore-fail-on-non-empty $iconsdir
    [ ! -d $notifdir ] || rmdir -p --ignore-fail-on-non-empty $notifdir

    [ -z "$(kpackagetool6 -t Plasma/Applet -l | grep $applet)" ] || kpackagetool6 --type Plasma/Applet -r $applet
}


mirrorlist_generator() {
    if $1; then
        r="\033[1;31m"
        g="\033[1;32m"
        b="\033[1;34m"
        c="\033[0m"

        echo
        [[ $EUID -ne 0 ]] && { echo -e "$r✘ Requires sudo permissions$c\n"; exit 1; }
        command -v curl >/dev/null || { echo -e "$r✘ Unable to retrieve mirrorlist - curl is not installed$c\n"; exit 1; }

        mirrorfile="/etc/pacman.d/mirrorlist"
        count="$2"
        url="$3"

        spinner() {
            spin="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
            while kill -0 $1 2>/dev/null; do
                i=$(( (i+1) %10 ))
                printf "$r\r${spin:$i:1}$c $b$2$c"
                sleep .2
            done
        }

        tput sc
        tempfile=$(mktemp)
        curl -s -o $tempfile "$url" 2>/dev/null &
        pid=$!
        text="Fetching filtered list by mirror score..."
        spinner $pid "$text"
        tput rc
        tput ed
        [[ -s "$tempfile" && $(head -n 1 "$tempfile" | grep -c "^##") -gt 0 ]] || { echo -e "$r✘ $text$c\n$r✘ Check your mirrorlist generator settings$c\n"; rm $tempfile; exit 1; }
        echo -e "$g✔ $text$c"

        tput sc
        sed -i -e "s/^#Server/Server/" -e "/^#/d" "$tempfile"
        tempfile2=$(mktemp)
        rankmirrors -n $count "$tempfile" > "$tempfile2" &
        pid=$!
        text="Ranking a mirrorlist by open speed..."
        spinner $pid "$text"
        tput rc
        tput ed
        [[ -s "$tempfile2" && $(head -n 1 "$tempfile2" | grep -c "^# S") -gt 0 ]] || { echo -e "$r✘ $text$c"; rm $tempfile2; exit 1; }
        echo -e "$g✔ $text$c"

        sed -i '1d' "$tempfile2"
        sed -i "1s/^/##\n## Arch Linux repository mirrorlist\n## Generated on $(date '+%Y-%m-%d %H:%M:%S')\n##\n\n/" "$tempfile2"
        cat $tempfile2 > $mirrorfile

        echo -e "$g✔ Update mirrorlist file$c"
        echo -e "\n$g$mirrorfile was updated with following servers:$c"
        tail -n +6 $mirrorfile | sed 's/Server = //g'
        echo

        rm $tempfile2
        rm $tempfile
    fi
}


help() {
    cat <<EOF

Usage: sh tools.sh [option]

Options:
    copy        Copy files
    install     Download and install
    uninstall   Remove files and plasmoid

EOF
}


[ -z $1 ] && help && exit 0

case "$1" in
    "mirrorlist_generator") mirrorlist_generator $2 $3 $4;;
    *) "$1" ;;
esac
