#!/usr/bin/env sh

# SPDX-FileCopyrightText: 2023 Evgeny Kazantsev <exequtic@gmail.com>
# SPDX-License-Identifier: MIT

applet="com.github.exequtic.apdatifier"

localdir="/home/$(whoami)/.local/share"
plasmoid="$localdir/plasma/plasmoids/$applet"
iconsdir="$localdir/icons/breeze/status/24"
notifdir="$localdir/knotifications5"

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

### Download and install latest release
# install() {
#     command -v curl >/dev/null || { echo "curl not installed" >&2; exit 1; }
#     command -v kpackagetool5 >/dev/null || { echo "kpackagetool5 not installed" >&2; exit 1; }

#     if [ ! -z "$(kpackagetool5 -t Plasma/Applet -l | grep $applet)" ]; then
#         while true; do
#             echo "Plasmoid already installed"
#             read -p "Reinstall? [Y/n]: " reply
#             case $reply in
#                 [Yy]*|"") uninstall; sleep 2; break ;;
#                 [Nn]*) exit 0 ;;
#             esac
#         done
#     fi

#     releases=https://github.com/exequtic/apdatifier/releases
#     tag=$(curl -LsH 'Accept: application/json' $releases/latest)
#     tag=${tag%\,\"update_url*}
#     tag=${tag##*tag_name\":\"}
#     tag=${tag%\"}

#     file="apdatifier_KF5_$tag.plasmoid"
#     download="$releases/download/$tag/$file"
#     tempfile="/tmp/$file"

#     curl --fail --location --progress-bar --output $tempfile $download

#     if [ $? -eq 0 ]; then
#         [ -f $tempfile ] && kpackagetool5 -t Plasma/Applet -i $tempfile
#         rm $tempfile
#     fi
# }

### Download and install with latest commit
install() {
    command -v git >/dev/null || { echo "git not installed" >&2; exit 1; }
    command -v zip >/dev/null || { echo "zip not installed" >&2; exit 1; }
    command -v kpackagetool5 >/dev/null || { echo "kpackagetool5 not installed" >&2; exit 1; }

    if [ ! -z "$(kpackagetool5 -t Plasma/Applet -l | grep $applet)" ]; then
        echo "Plasmoid already installed"
        uninstall
        sleep 2
    fi

    savedir=$(pwd)
    cd /tmp && git clone -n --depth=1 --filter=tree:0 https://github.com/exequtic/apdatifier
    cd apdatifier && git sparse-checkout set --no-cone package && git checkout

    if [ $? -eq 0 ]; then
        cd package
        zip -rq apdatifier.plasmoid .
        [ ! -f apdatifier.plasmoid ] || kpackagetool5 -t Plasma/Applet -i apdatifier.plasmoid
    fi

    cd $savedir

    [ ! -d /tmp/apdatifier ] || rm -rf /tmp/apdatifier
}


uninstall() {
    command -v kpackagetool5 >/dev/null || { echo "kpackagetool5 not installed" >&2; exit 1; }

    [ ! -f $iconsdir/$file1 ] || rm -f $iconsdir/$file1
    [ ! -f $iconsdir/$file2 ] || rm -f $iconsdir/$file2
    [ ! -f $notifdir/$file3 ] || rm -f $notifdir/$file3
    [ ! -d $iconsdir ] || rmdir -p --ignore-fail-on-non-empty $iconsdir
    [ ! -d $notifdir ] || rmdir -p --ignore-fail-on-non-empty $notifdir

    [ -z "$(kpackagetool5 -t Plasma/Applet -l | grep $applet)" ] || kpackagetool5 --type Plasma/Applet -r $applet
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

$1