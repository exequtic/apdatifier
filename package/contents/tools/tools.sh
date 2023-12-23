#!/usr/bin/env sh

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


uninstall() {
    rm -f $iconsdir/$file1
    rm -f $iconsdir/$file2
    rmdir -p --ignore-fail-on-non-empty $iconsdir

    rm -f $notifdir/$file3
    rmdir -p --ignore-fail-on-non-empty $notifdir

    [ -d $plasmoid ] && rm -rf $plasmoid
    killall plasmashell && kstart5 plasmashell
}


help() {
    cat <<EOF

Options:
    -i  install     Copy files
    -u  uninstall   Remove plasmoid and files
EOF
}

$1