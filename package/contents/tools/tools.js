function checkUpdates() {
    console.log(`\n\n     (${new Date().toLocaleTimeString().slice(0, -4)}) ----- Start checkUpdates() -----`)
    timer.restart()
    updatesListModel.clear()
    checkStatus = true
    errorStd = null
    updatesCount = null
    
    let helper = "$(command -v yay || command -v paru || command -v picaur || command -v pacman)"
    let search = '$(command -v checkupdates) || $(command -v pacman) -Qu'

    if (wrapper) {
        search = helper + ' -Qu'
    }

    let checkUpdatesCmd = `\
        upd=$(${search})
        if [ ! -z "$upd" ]; then
            all=$(${helper} -Sl)
            while IFS= read -r pkg; do
                name=$(echo "$pkg" | awk '{print $1}')
                repo=$(echo "$all" | grep " $name " | awk '{print $1}')
                pkgs+="$repo $pkg\n"
            done <<< "$upd"
            echo -en "$pkgs"
        fi`

    if (flatpak) {
        let checkFlatpakCmd = `\
            upd=$(flatpak remote-ls --columns=name,application,version --app --updates | \
            sed 's/ /-/g' | sed 's/\t/ /g')
            if [ ! -z "$upd" ]; then
                while IFS= read -r app; do
                    name=$(echo "$app" | awk '{print $2}')
                    vers=$(flatpak info "$name" | grep "Version:" | awk '{print $2}')
                    apps+="flathub $(echo "$app" | sed "s/$name/$vers/")"$'\n'
                done <<< "$upd"
                echo -en "$apps"
            fi`

        checkUpdatesCmd = `${checkUpdatesCmd} && ${checkFlatpakCmd}`
    }
    
    sh.exec(checkUpdatesCmd)
}



function makeList() {
    if (errorStd || !updatesListOut) {
        errorStd = errorStd.split("\n")
        checkStatus = false
        return
    }

    updatesListObj = updatesListOut
        .replace(/ ->/g, "")
            .trim()
                .split("\n")
                    .map(str => {
                        const col = str.split(' ');
                        [col[0], col[1]] = [col[1], col[0]]
                        return col.join(' ')
                    })

    updatesListObj.sort((a, b) => {
        const [nameA, repoA] = a.split(' ');
        const [nameB, repoB] = b.split(' ');
        return sort === 0 ?
            nameA.localeCompare(nameB) :
            repoA.localeCompare(repoB) || nameA.localeCompare(nameB)
    })

    updatesCount = updatesListObj.length

    updatesListModel.clear()

    for (var i = 0; i < updatesCount; i++) {
        let item = updatesListObj[i].toLowerCase()
        updatesListModel.append({"text": item})
    }

    checkStatus = false
}
