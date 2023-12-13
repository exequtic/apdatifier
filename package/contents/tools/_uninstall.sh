#!/usr/bin/env sh

name="com.github.exequtic.apdatifier"
localdir="/home/$(whoami)/.local/share"
plasmoid="$localdir/plasma/plasmoids/$name"
iconsdir="$localdir/icons/breeze/status/24"
notifdir="$localdir/knotifications5"

function uninstall() {
    rm -f $iconsdir/apdatifier-plasmoid-*
    rmdir -p --ignore-fail-on-non-empty $iconsdir

    rm -f $notifdir/apdatifier.*
    rmdir -p --ignore-fail-on-non-empty $notifdir

    [ -d $plasmoid ] && rm -rf $plasmoid

    killall plasmashell && kstart5 plasmashell
}

function dialog() {
    dia=$(command -v kdialog || echo)

    if [ ! -z $dia ]; then
        if test -d "$plasmoid"; then
            $dia --title " " --yesno "Uninstall $name?"
            if [[ $? == 0 ]]; then
                $dia --title " " --yesno "You sure? It will completly uninstall plasmoid and restart plasmashell"
                if [[ $? == 0 ]]; then
                    uninstall
                fi
            fi
        fi
    else
        usage
    fi
}

usage() {
    cat <<EOF

Options:
    -u      Remove plasmoid and files

EOF
}

case "$1" in
        -u) uninstall;;
        -h|--help) usage;;
         *) dialog;;
esac