#!/usr/bin/env sh

[ -z $1 ] || [ -z $2 ] && exit 1

localdir="$1/.local/share"
plasmoid="$localdir/plasma/plasmoids/$2"
iconsdir="$localdir/icons/breeze/status/24"
notifdir="$localdir/knotifications5"

file1="apdatifier-plasmoid.svg"
file2="apdatifier-package.svg"
file3="apdatifier.notifyrc"

[ -d $iconsdir ] || mkdir -p $iconsdir
[ -f $iconsdir/$file1 ] || cp $plasmoid/contents/icons/$file1 $iconsdir
[ -f $iconsdir/$file2 ] || cp $plasmoid/contents/icons/$file2 $iconsdir

[ -d $notifdir ] || mkdir -p $notifdir
[ -f $notifdir/$file3 ] || cp $plasmoid/contents/notifyrc/$file3 $notifdir
