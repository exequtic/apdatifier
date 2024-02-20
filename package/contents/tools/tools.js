/*
    SPDX-FileCopyrightText: 2023 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/


function catchError(code, err, out) {
    if (code) {
        if (err) error = err.trim().split("\n")[0]
        if (!err && out) error = out.trim().split("\n")[0]
        if (!err && !out) return false

        setStatusBar(code)
        return true
    }
    return false
}


function waitConnection(func) {
    if (!connection()) {
        statusIco = "network-connect"
        statusMsg = i18n("Waiting for internet connection...")

        if (!connectionTimer.running) {
            action = func ? func : false
            connectionTimer.start()
        }
        return
    }

    connectionTimer.stop()

    if (action) return action()

    setStatusBar()
}


function connection() {
    searchTimer.stop()
    error = null
    busy = true

    const status = network.connectionIcon
    return network.connecting === true
            || status.includes("limited")
            || status.includes("unavailable")
            || status.includes("disconected")
                ? false
                : true
}


function runScript() {
    let homeDir = StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().substring(7)
    let script = homeDir + "/.local/share/plasma/plasmoids/" + applet + "/contents/tools/tools.sh"
    let command = `${script} copy`

    sh.exec(command, (cmd, stdout, stderr, exitCode) => {
        if (catchError(exitCode, stderr, stdout)) return
        checkDependencies()
    })
}


function checkDependencies() {
    function check(packs) {
        return `for pgk in ${packs}; do command -v $pgk || echo; done`
    }

    function populate(data) {
        let arr = []
        for (let i = 0; i < data.length; i++) {
            arr.push({"name": data[i].split("/").pop(), "value": data[i]})
        }
        return arr
    }

    sh.exec(check(plasmoid.configuration.dependencies), (cmd, stdout, stderr, exitCode) => {
        if (catchError(exitCode, stderr, stdout)) return

        let out = stdout.split("\n")
        let packs = out.slice(0, 4)
        let wrappers = populate(out.slice(4, 7).filter(Boolean))
        let terminals = populate(out.slice(7).filter(Boolean))

        plasmoid.configuration.packages = packs
        plasmoid.configuration.wrappers = wrappers.length > 0 ? wrappers : null
        plasmoid.configuration.terminals = terminals.length > 0 ? terminals : null

        searchTimer.triggered()
    })
}


function defineCommands() {
    let wrapper = plasmoid.configuration.selectedWrapper
    let terminal = plasmoid.configuration.selectedTerminal
    let wrapperUpgrade = plasmoid.configuration.wrapperUpgrade
    let checkupdatesAUR = plasmoid.configuration.checkupdatesAUR
    let flags = plasmoid.configuration.upgradeFlags ? plasmoid.configuration.upgradeFlagsText : ""
    let archCmd
    let flatpakCmd

    shell[0] = packages[0] + " -c"
    shell[1] = packages[1] ? `${shell[0]} ${defineArchCmd(searchMode, packages[1], packages[2])}` : null
    shell[2] = packages[1] + " -Sl"
    shell[3] = packages[3] + " remote-ls --app --updates"
    shell[4] = packages[3] + " list --app"
    shell[5] = searchMode[0] ? packages[1] + " -Sy" : wrapper + " -Sy"
    shell[6] = terminal + defineTermArg()
    shell[7] = defineUpgradeCmd()

    function defineArchCmd(mode, pacman, checkupdates) {
        if (mode[0] && pacman) {
            return `"${pacman} -Qu"`
        } else if (mode[1] && !checkupdatesAUR) {
            return `${checkupdates}`
        } else if (mode[1] && checkupdatesAUR) {
            return `"(${checkupdates}; ${wrapper} -${defineWrapperArg()} | sed 's/Get .*//') | sort -u -t' ' -k1,1"`
        } else if (mode[2]) {
            return `"${wrapper} -${defineWrapperArg()}"`
        } else {
            return
        }
    }

    function defineWrapperArg() {
        switch (wrapper.split("/").pop()) {
            case "trizen": return "Qu; trizen -Qu -a"
            default: return "Qu"
        }
    }

    function defineTermArg() {
        switch (terminal.split("/").pop()) {
            case "gnome-terminal": return " --"
            case "terminator": return " -x"
            case "yakuake": return false
            default: return " -e"
        }
    }
    
    function defineUpgradeCmd() {
        flatpakCmd = searchMode[3] ? `${packages[3]} update` : "echo"

        if (packages[1]) {
            if (wrapperUpgrade) {
                archCmd = `${wrapper} -Syu ${flags}`
                return `${archCmd}; ${flatpakCmd}`
            } else {
                archCmd = `sudo ${packages[1]} -Syu ${flags}`
                return `${archCmd}; ${flatpakCmd}`
            }
        } else {
            return flatpakCmd
        }
    }

    if (!defineTermArg()) {
        let QDBUS = "qdbus org.kde.yakuake /yakuake/sessions"
        shell[8] = `${QDBUS} addSession; ${QDBUS} runCommandInTerminal $(${QDBUS} org.kde.yakuake.activeSessionId) "${shell[7]}"`
    } else {
        let exec = i18n("Executed: ")
        let init = i18n("Full system upgrade")
        let done = i18n("Press Enter to close")
        let trap = "trap '' SIGINT"
        exec = packages[1] ? "echo " + exec + archCmd + "; echo"
                           : "echo " + exec + flatpakCmd + "; echo"

        shell[8] = `${shell[6]} ${shell[0]} "${trap}; ${print(init)}; ${exec}; ${shell[7]}; ${print(done)}; read"`
    }
}


function upgradeSystem() {
    if (!connection()) return waitConnection()

    statusIco = "accept_time_event"
    statusMsg = i18n("Full upgrade running...")
    upgrading = true

    defineCommands() 

    sh.exec(shell[8], (cmd, stdout, stderr, exitCode) => {
        upgrading = false

        if (catchError(exitCode, stderr, stdout)) return

        searchTimer.triggered()
    })
}


function downloadDatabase() {
    if (!connection()) return waitConnection()

    statusIco = "download"
    statusMsg = i18n("Download fresh package databases...")
    downloading = true

    defineCommands()

    sh.exec("pkexec " + shell[5], (cmd, stdout, stderr, exitCode) => {
        downloading = false

        if (exitCode == 127) {
            setStatusBar()
            return
        }

        if (catchError(exitCode, stderr, stdout)) return

        searchTimer.triggered()
    })
}


function checkUpdates() {
    if (!connection()) return waitConnection(checkUpdates)

    defineCommands()

    let updArch
    let infArch
    let updFlpk
    let infFlpk

    shell[1] ? archCheck() : searchMode[3] ? flpkCheck() : merge()

    function archCheck() {
        statusIco = "package"
        statusMsg = searchMode[2] ? i18n("Searching AUR for updates...")
                                  : i18n("Searching arch repositories for updates...")

        sh.exec(shell[1], (cmd, stdout, stderr, exitCode) => {
            if (catchError(exitCode, stderr, stdout)) return
            updArch = stdout ? stdout : null
            updArch ? archList() : searchMode[3] ? flpkCheck() : merge()
    })}

    function archList() {
        sh.exec(shell[2], (cmd, stdout, stderr, exitCode) => {
            if (catchError(exitCode, stderr, stdout)) return
            infArch = stdout ? stdout : null
            searchMode[3] ? flpkCheck() : merge()
    })}

    function flpkCheck() {
        statusIco = "flatpak-discover"
        statusMsg = i18n("Searching flathub for updates...")

        sh.exec(shell[3], (cmd, stdout, stderr, exitCode) => {
            if (catchError(exitCode, stderr, stdout)) return
            updFlpk = stdout ? stdout : null
            updFlpk ? flpkList() : merge()
    })}

    function flpkList() {
        sh.exec(shell[4], (cmd, stdout, stderr, exitCode) => {
            if (catchError(exitCode, stderr, stdout)) return
            infFlpk = stdout ? stdout : null
            merge()
    })}

    function merge() {
        updArch = updArch ? makeArchList(updArch, infArch) : null
        updFlpk = updFlpk ? makeFlpkList(updFlpk, infFlpk) : null
    
        updArch && !updFlpk ? finalize(sortList(formatList(updArch))) :
        !updArch && updFlpk ? finalize(sortList(formatList(updFlpk))) :
        !updArch && !updFlpk ? finalize() :
        finalize(sortList(formatList(updArch.concat(updFlpk))))
    }
}


function makeArchList(upd, inf) {
    upd = upd.trim().split("\n")
    inf = inf.trim().split("\n")
    let out = ""

    for (let i = 0; i < upd.length; i++) {
        let pkg = upd[i]
        let name = pkg.split(" ")[0]
        let aur = true

        for (let j = 0; j < inf.length; j++)
            if (inf[j].includes(" " + name + " ")) {
                let repo = inf[j].split(" ")[0]
                out += repo + " " + pkg + "\n"
                aur = false
                break
            }

        if (aur)
            pkg.split(" ").pop() === "latest-commit" ?
                out += "devel " + pkg + "\n" :
                out += "aur " + pkg + "\n"
    }

    return out
}


function makeFlpkList(upd, inf) {
    upd = upd.trim().replace(/ /g, "-").replace(/\t/g, " ").split("\n")
    inf = inf.trim().replace(/ /g, "-").replace(/\t/g, " ").split("\n")
    let out = ""

    upd.forEach(pkg => {
        let name = pkg.split(" ")[1]
        let vers = inf.find(line => line.includes(name)).split(" ")[2]
        out += `flathub ${pkg.replace(name, vers)}\n`
    })

    return out
}


function formatList(list) {
    return list
        .replace(/ ->/g, "")
        .trim()
        .toLowerCase()
        .split("\n")
        .map(str => {
            const col = str.split(" ");
            [col[0], col[1]] = [col[1], col[0]]
            return col.join(" ")
        })
}


function sortList(list) {
    return list.sort((a, b) => {
        const [nameA, repoA] = a.split(" ")
        const [nameB, repoB] = b.split(" ")

        return plasmoid.configuration.sortByName ? nameA.localeCompare(nameB)
                : ((repoA.includes("aur") || repoA.includes("devel"))
                    &&
                  !(repoB.includes("aur") || repoB.includes("devel")))
                    ? -1
                : (!(repoA.includes("aur") || repoA.includes("devel"))
                    &&
                  (repoB.includes("aur") || repoB.includes("devel")))
                    ? 1
                : repoA.localeCompare(repoB) || nameA.localeCompare(nameB)
    })
}


function setNotify(list) {
    let prev = count
    let curr = list.length

    if (prev !== undefined && prev < curr) {
        let newList = list.filter(item => !updList.includes(item))
        let newCount = newList.length

        let lines = ""
        for (let i = 0; i < newCount; i++) {
            let col = newList[i].split(" ")
            lines += col[0] + "  -> " + col[3] + "\n"
        }

        notifyTitle = i18np("+%1 new update", "+%1 new updates", newCount)
        notifyBody = lines
        notify.sendEvent()
    }

    if (prev === undefined && curr > 0 && plasmoid.configuration.notifyStartup) {
        notifyTitle = i18np("Update available", "Updates available", curr)
        notifyBody = i18np("One update is pending", "%1 updates total are pending", curr)
        notify.sendEvent()
    }
}


function refreshListModel(list) {
    if (!list) {
        if (updList.length == 0) return
        list = sortList(updList)
    }

    listModel.clear()

    for (let i = 0; i < list.length; i++) {
        let item = list[i].split(" ")
        listModel.append({
            "name": item[0],
            "repo": item[1],
            "curr": item[2],
            "newv": item[3]
        })
    }
}


function finalize(list) {
    timestamp = new Date().getTime()

    if (!list) {
        listModel.clear()
        updList = [""]
        count = 0
        setStatusBar()
        return
    }

    refreshListModel(list)

    if (plasmoid.configuration.notifications) setNotify(list)

    count = list.length
    updList = list
    setStatusBar()
}


function setStatusBar(code) {
    statusIco = error ? "error" : count > 0 ? "update-none" : ""
    statusMsg = error ? "Exit code: " + code : count > 0 ? i18np("%1 update is pending", "%1 updates total are pending", count) : ""
    busy = false
    searchTimer.restart()
}


function getLastCheck() {
    if (!timestamp) return ""

    let diff = new Date().getTime() - timestamp
    let sec = Math.floor((diff % (1000 * 60)) / 1000)
    let min = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
    let hrs = Math.floor(diff / (1000 * 60 * 60))

    let text = i18n("Last check:")
    let secText = i18np("%1 second", "%1 seconds", sec)
    let minText = i18np("%1 minute", "%1 minutes", min)
    let hrsText = i18np("%1 hour", "%1 hours", hrs)
    let ago = i18n("ago")

    if (hrs === 0 && min === 0) return text + " " + secText + " " + ago
    if (hrs === 0) return text + " " + minText + " " + secText + " " + ago
    if (min === 0) return text + " " + hrsText + " " + ago
    return text + " " + hrsText + " " + minText + " " + ago
}


function setIndex(value, arr) {
    let index = 0
    for (let i = 0; i < arr.length; i++) {
        if (arr[i]["value"] == value) {
            index = i
            break
        }
    }
    return index
}


const defaultIcon = "apdatifier-plasmoid"
function setIcon(icon) {
    return icon === "" ? defaultIcon : icon
}


function indicatorFrameSize() {
    const multiplier = plasmoid.configuration.indicatorCounter ? 1 : plasmoid.configuration.indicatorCircle ? 0.85 : 0

    return plasmoid.location === 5 || plasmoid.location === 6 ? icon.height * multiplier :     
           plasmoid.location === 3 || plasmoid.location === 4 ? icon.width * multiplier : 0
}


function indicatorAnchors(pos) {
    switch (pos) {
        case "top": return plasmoid.configuration.indicatorTop && !plasmoid.configuration.indicatorBottom ? frame.top : undefined
        case "bottom": return plasmoid.configuration.indicatorBottom && !plasmoid.configuration.indicatorTop ? frame.bottom : undefined
        case "right": return plasmoid.configuration.indicatorRight && !plasmoid.configuration.indicatorLeft ? frame.right : undefined
        case "left": return plasmoid.configuration.indicatorLeft && !plasmoid.configuration.indicatorRight ? frame.left : undefined
        default: return undefined
    }
}


function getFonts(defaultFont, fonts) {
    let arr = []
    arr.push({"name": i18n("Default system font"), "value": defaultFont})
    for (let i = 0; i < fonts.length; i++) {
        arr.push({"name": fonts[i], "value": fonts[i]})
    }
    return arr
}


function print(text) {
    let ooo = ":".repeat(48)
    let oo = ":".repeat(Math.ceil((ooo.length - text.length - 2)/2))
    let o = text.length % 2 !== 0 ? oo.substring(1) : oo

    return `echo; echo ${ooo}
            echo ${oo} ${text} ${o}
            echo ${ooo}; echo`
}
