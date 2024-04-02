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
    command -v kpackagetool6 >/dev/null || { echo "kpackagetool6 not installed" >&2; exit 1; }

    [ ! -f $iconsdir/$file1 ] || rm -f $iconsdir/$file1
    [ ! -f $iconsdir/$file2 ] || rm -f $iconsdir/$file2
    [ ! -f $notifdir/$file3 ] || rm -f $notifdir/$file3
    [ ! -d $iconsdir ] || rmdir -p --ignore-fail-on-non-empty $iconsdir
    [ ! -d $notifdir ] || rmdir -p --ignore-fail-on-non-empty $notifdir

    [ -z "$(kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep $applet)" ] || kpackagetool6 --type Plasma/Applet -r $applet 2>/dev/null
}


mirrorlist_generator() {
    if $1; then
        r="\033[1;31m"
        g="\033[1;32m"
        b="\033[1;34m"
        y="\033[0;33m"
        c="\033[0m"

        echo
        [[ $EUID -ne 0 ]] && { echo -e "$r\u2718 Requires sudo permissions$c\n"; exit 1; }
        command -v curl >/dev/null || { echo -e "$r\u2718 Unable to retrieve mirrorlist - curl is not installed$c\n"; exit 1; }

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
        text="Fetching the latest filtered mirror list..."
        curl -s -o $tempfile "$3" 2>/dev/null &
        spinner $! "$text"
        tput rc
        tput ed
        [[ -s "$tempfile" && $(head -n 1 "$tempfile" | grep -c "^##") -gt 0 ]] || { echo -e "$r\u2718 $text$c\n$r\u2718 Check your mirrorlist generator settings$c\n"; rm $tempfile; exit 1; }
        echo -e "$g\u2714 $text$c"

        tput sc
        sed -i -e "s/^#Server/Server/" -e "/^#/d" "$tempfile"
        tempfile2=$(mktemp)
        text="Ranking mirrors by their connection and opening speed..."
        rankmirrors -n "$2" "$tempfile" > "$tempfile2" &
        spinner $! "$text"
        tput rc
        tput ed
        [[ -s "$tempfile2" && $(head -n 1 "$tempfile2" | grep -c "^# S") -gt 0 ]] || { echo -e "$r\u2718 $text$c"; rm $tempfile2; exit 1; }
        echo -e "$g\u2714 $text$c"

        mirrorfile="/etc/pacman.d/mirrorlist"
        sed -i '1d' "$tempfile2"
        sed -i "1s/^/##\n## Arch Linux repository mirrorlist\n## Generated on $(date '+%Y-%m-%d %H:%M:%S')\n##\n\n/" "$tempfile2"
        cat $tempfile2 > $mirrorfile

        echo -e "$g\u2714 Update mirrorlist file$c"
        echo -e "$g\nFile $mirrorfile was updated with the following servers:$c"
        echo -e "$y$(tail -n +6 $mirrorfile | sed 's/Server = //g')$c"
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
