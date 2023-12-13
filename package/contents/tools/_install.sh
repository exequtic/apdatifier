#!/usr/bin/env sh

[ -z $1 ] || [ -z $2 ] && exit 1

localdir="$1/.local/share"
plasmoid="$localdir/plasma/plasmoids/$2"
iconsdir="$localdir/icons/breeze/status/24"
notifdir="$localdir/knotifications5"

file1="apdatifier-plasmoid-none.svg"
file2="apdatifier-plasmoid-pending.svg"
file3="apdatifier-plasmoid-updates.svg"
file4="apdatifier.notifyrc"

[ -d $iconsdir ] || mkdir -p $iconsdir
[ -f $iconsdir/$file1 ] || cp $plasmoid/contents/icons/$file1 $iconsdir
[ -f $iconsdir/$file2 ] || cp $plasmoid/contents/icons/$file2 $iconsdir
[ -f $iconsdir/$file3 ] || cp $plasmoid/contents/icons/$file3 $iconsdir

[ -d $notifdir ] || mkdir -p $notifdir
[ -f $notifdir/$file4 ] || cp $plasmoid/contents/notifyrc/$file4 $notifdir
