/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/


function catchError(code, err) {
    if (err) {
        error = err.trim().substring(0, 100) + "..."
        setStatusBar(code)
        return true
    }
    return false
}

const script = "$HOME/.local/share/plasma/plasmoids/com.github.exequtic.apdatifier/contents/tools/tools.sh"
const cachefile = "$HOME/.local/share/plasma/plasmoids/com.github.exequtic.apdatifier/cache"
function runScript() {
    sh.exec(`${script} copy`, (cmd, stdout, stderr, exitCode) => {
        if (catchError(exitCode, stderr)) return

        sh.exec(`[ -f "${cachefile}" ] && cat "${cachefile}"`, (cmd, stdout, stderr, exitCode) => {
            if (catchError(exitCode, stderr)) return
            cache = stdout ? JSON.parse(stdout.trim()) : []
            checkDependencies()
        })
    })
}


function runAction() {
    searchTimer.stop()
    error = null
    busy = true
}


function checkDependencies() {
    const populate = (data) => data.map(item => ({ "name": item.split("/").pop(), "value": item }))
    const checkPkg = (pkgs) => `for pgk in ${pkgs}; do command -v $pgk || echo; done`
    const pkgs = "pacman checkupdates flatpak paru trizen yay alacritty foot gnome-terminal konsole kitty lxterminal terminator tilix xterm yakuake"

    sh.exec(checkPkg(pkgs),(cmd, stdout, stderr, exitCode) => {
        if (catchError(exitCode, stderr)) return

        const out = stdout.split("\n")

        const [pacman, checkupdates, flatpak] = out.map(Boolean)
        cfg.packages = { pacman, checkupdates, flatpak }

        const wrappers = populate(out.slice(3, 6).filter(Boolean))
        cfg.wrappers = wrappers.length > 0 ? wrappers : null

        const terminals = populate(out.slice(6).filter(Boolean))
        cfg.terminals = terminals.length > 0 ? terminals : null

        if (!cfg.interval) {
            refreshListModel()
            return
        }
    
        if (!cfg.checkOnStartup) {
            refreshListModel()
            searchTimer.start()
            return
        }

        searchTimer.triggered()
    })
}


function defineCommands() {
    const mirrorlist = `sudo ${script} mirrorlist_generator ${cfg.mirrors} ${cfg.mirrorCount} '${cfg.dynamicUrl}'`
    const trizen = cfg.wrapper.split("/").pop() === "trizen"
    const wrapperCmd = trizen ? `${cfg.wrapper} -Qu; ${cfg.wrapper} -Qu -a 2> >(grep ':: Unable' >&2)` : `${cfg.wrapper} -Qu`

    cmd.arch = pkg.checkupdates
        ? cfg.aur
            ? `bash -c "(checkupdates; ${wrapperCmd}) | sort -u -t' ' -k1,1"`
            : "checkupdates"
        : cfg.aur
            ? wrapperCmd
            : "ping -c 1 archlinux.org >/dev/null 2>&1 || { echo 'No internet' >&2; exit 1; }; pacman -Qu"     

    if (!pkg.pacman) delete cmd.arch

    const flatpak = cfg.flatpak ? "; flatpak update" : ""
    const flags = cfg.upgradeFlags ? ` ${cfg.upgradeFlagsText}` : " "
    const arch = cfg.wrapperUpgrade ? cfg.wrapper + " -Syu" + flags : "sudo pacman -Syu" + flags

    if (cfg.terminal.split("/").pop() === "yakuake") {
        const qdbus = "qdbus org.kde.yakuake /yakuake/sessions"
        cmd.terminal = `${qdbus} addSession; ${qdbus} runCommandInTerminal $(${qdbus} org.kde.yakuake.activeSessionId)`
        cmd.upgrade = `${cmd.terminal} "${arch}${flatpak}"`
        return
    }

    const init = i18n("Full system upgrade")
    const done = i18n("Press Enter to close")
    const blue = "\x1B[1m\x1B[34m", bold = "\x1B[1m", reset = "\x1B[0m"
    const exec = blue + ":: " + reset + bold + i18n("Executed: ") + reset
    const executed = cfg.wrapperUpgrade && trizen ? "echo " : "echo; echo -e " + exec + arch + "; echo"

    const trap = "trap '' SIGINT"
    const terminalArg = { "gnome-terminal": " --", "terminator": " -x" }
    cmd.terminal = cfg.terminal + (terminalArg[cfg.terminal.split("/").pop()] || " -e")
    cmd.upgrade = `${cmd.terminal} sh -c "${trap}; ${print(init)}; ${executed}; ${mirrorlist}; ${arch}${flatpak}; ${print(done)}; read"`
}


function updatePackage(id) {
    defineCommands()

    if (cfg.terminal.split("/").pop() === "yakuake")
        sh.exec(`${cmd.terminal} "flatpak update ${id}"`,(cmd, stdout, stderr, exitCode) => {})
    else
        sh.exec(`${cmd.terminal} flatpak update ${id}`,(cmd, stdout, stderr, exitCode) => {})
}


function upgradeSystem() {
    runAction()
    defineCommands()

    statusIco = "accept_time_event"
    statusMsg = i18n("Full upgrade running...")
    upgrading = true

    sh.exec(cmd.upgrade, (cmd, stdout, stderr, exitCode) => {
        upgrading = false
        cfg.interval ? searchTimer.triggered() : refreshListModel()
    })
}


function checkUpdates() {
    runAction()
    defineCommands()

    let updArch
    let infArch
    let descArch
    let updFlpk
    let infFlpk

    cmd.arch ? archCheck() : cfg.flatpak ? flpkCheck() : merge()

    function archCheck() {
        statusIco = "package"
        statusMsg = cfg.aur ? i18n("Searching AUR for updates...")
                            : i18n("Searching arch repositories for updates...")
        sh.exec(cmd.arch, (cmd, stdout, stderr, exitCode) => {
            if (catchError(exitCode, stderr)) return
            updArch = stdout ? stdout.trim().split("\n") : null
            updArch ? archList() : cfg.flatpak ? flpkCheck() : merge()
    })}

    function archList() {
        sh.exec("pacman -Sl", (cmd, stdout, stderr, exitCode) => {
            if (catchError(exitCode, stderr)) return
            infArch = stdout.trim().split("\n")
            archDesc()
    })}

    function archDesc() {
        let list = updArch.map(s => s.split(" ")[0]).join(' ')
        sh.exec(`pacman -Qi ${list}`, (cmd, stdout, stderr, exitCode) => {
            if (catchError(exitCode, stderr)) return
            descArch = stdout
            cfg.flatpak ? flpkCheck() : merge()
    })}

    function flpkCheck() {
        statusIco = "flatpak-discover"
        statusMsg = i18n("Searching flathub for updates...")
        sh.exec("flatpak remote-ls --app --updates --show-details", (cmd, stdout, stderr, exitCode) => {
            if (catchError(exitCode, stderr)) return
            updFlpk = stdout ? stdout : null
            updFlpk ? flpkList() : merge()
    })}

    function flpkList() {
        sh.exec("flatpak list --app --columns=application,version", (cmd, stdout, stderr, exitCode) => {
            if (catchError(exitCode, stderr)) return
            infFlpk = stdout ? stdout : null
            merge()
    })}

    function merge() {
        updArch = updArch ? makeArchList(updArch, infArch, descArch) : null
        updFlpk = updFlpk ? makeFlpkList(updFlpk, infFlpk) : null
    
        updArch && !updFlpk ? finalize(sortList(updArch)) :
        !updArch && updFlpk ? finalize(sortList(updFlpk)) :
        !updArch && !updFlpk ? finalize() :
        finalize(sortList(updArch.concat(updFlpk)))
    }
}


function makeArchList(upd, inf, desc) {
    const packagesData = desc.split("\n\n")
    const skip = [1, 3, 5, 9, 11, 15, 16, 19, 20]
    const keyNames = {
        0: 'name', 2: 'desc', 4: 'link', 6: 'group', 7: 'provides',
        8: 'depends', 10: 'required', 12: 'conflicts', 13: 'replaces',
        14: 'installedsize', 17: 'installdate', 18: 'reason'
    }

    let extendedInfo = packagesData.map(function(packageData) {
        packageData = packageData.split('\n').filter(line => line.includes(" : ")).join('\n')
        const lines = packageData.split("\n")
        
        let packageObj = {}
        lines.forEach(function(line, index) {
            if (skip.includes(index)) return

            const parts = line.split(/\s* : \s*/)
            if (parts.length === 2) {
                packageObj[keyNames[index]] = parts[1].trim()
            }
        })
        return packageObj
    })

    extendedInfo.forEach(el => {
        let found = false

        inf.forEach(str => {
            const parts = str.split(" ")
            if (el.name === parts[1]) {
                el.repository = parts[0]
                found = true
            }
        })

        if (!found) {
            el.repository = "aur"
        }

        upd.forEach(str => {
            const parts = str.split(" ")
            if (el.name === parts[0]) {
                el.verold = parts[1]
                el.vernew = parts[3]
            }
        })
    })

    extendedInfo.pop()

    return extendedInfo
}


function makeFlpkList(upd, inf) {
    const list = inf.split('\n').slice(1).reduce((map, line) => {
        const [appID, verold] = line.split('\t').map(entry => entry.trim())
        map.set(appID, verold)
        return map
    }, new Map())

    return upd.split('\n').map(line => {
        const [name, desc, appID, vernew, branch, , repository, , commit, runtime, installedsize, downloadsize] = line.split('\t').map(entry => entry.trim())
        return name ? {
            name: name.replace(/ /g, "-").toLowerCase(),
            desc: desc,
            appID: appID,
            verold: list.get(appID),
            vernew: list.get(appID) === vernew ? "refresh of " + vernew : vernew,
            branch: branch,
            repository: repository,
            commit: commit,
            runtime: runtime,
            installedsize: installedsize,
            downloadsize: downloadsize,
        } : null
    }).filter(Boolean)
}


function sortList(list) {
    return list.sort((a, b) => {
        const [nameA, repoA] = [a.name, a.repository]
        const [nameB, repoB] = [b.name, b.repository]

        if (cfg.sortByName) return nameA.localeCompare(nameB)

        const isRepoAURorDevelA = repoA.includes("aur") || repoA.includes("devel")
        const isRepoAURorDevelB = repoB.includes("aur") || repoB.includes("devel")

        return isRepoAURorDevelA !== isRepoAURorDevelB ? isRepoAURorDevelA ? -1 : 1 : repoA.localeCompare(repoB) || nameA.localeCompare(nameB)
    })    
}


function setNotify(list) {
    const newList = list.filter(el => {
        if (!cache.some(elCache => elCache.name === el.name)) return true
        if (cfg.notifyEveryBump && cache.some(elCache => elCache.name === el.name && elCache.vernew !== el.vernew)) return true
        return false
    })

    const newCount = newList.length

    if (newCount > 0) {
        let lines = ""
        newList.forEach(item => {
            lines += item["name"] + "   → " + item["vernew"] + "\n"
        })

        notifyTitle = i18np("+%1 new update", "+%1 new updates", newCount)
        notifyBody = lines
        notify.sendEvent()
    }
}


function refreshListModel(list) {
    list = list || (cache ? sortList(cache) : 0)
    count = list.length || 0
    setStatusBar()

    if (!count || !list) return

    listModel.clear()
    list.forEach(item => listModel.append(item))
}


function finalize(list) {
    cfg.timestamp = new Date().getTime()

    if (!list) {
        listModel.clear()
        sh.exec(`[ -f "${cachefile}" ] && rm "${cachefile}"`, (cmd, stdout, stderr, exitCode) => {})
        cache = []
        count = 0
        setStatusBar()
        return
    }

    refreshListModel(list)

    if (cfg.notifications) setNotify(list)

    count = list.length
    cache = list
    sh.exec(`echo '${JSON.stringify(list).replace(/'/g, '')}' > ${cachefile}`, (cmd, stdout, stderr, exitCode) => {})
    setStatusBar()
}


function setStatusBar(code) {
    statusIco = error ? "error" : count > 0 ? "update-none" : ""
    statusMsg = error ? "Exit code: " + code : count > 0 ? i18np("%1 update is pending", "%1 updates total are pending", count) : ""
    busy = false
    !cfg.interval ? searchTimer.stop() : searchTimer.restart()
}


function getLastCheck() {
    if (!cfg.timestamp) return ""

    const diff = new Date().getTime() - cfg.timestamp
    const sec = Math.floor((diff % (1000 * 60)) / 1000)
    const min = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
    const hrs = Math.floor(diff / (1000 * 60 * 60))

    const lastcheck = i18n("Last check:")
    const second = i18np("%1 second", "%1 seconds", sec)
    const minute = i18np("%1 minute", "%1 minutes", min)
    const hour = i18np("%1 hour", "%1 hours", hrs)
    const ago = i18n("ago")

    if (hrs === 0 && min === 0) return `${lastcheck} ${second} ${ago}`
    if (hrs === 0) return `${lastcheck} ${minute} ${second} ${ago}`
    if (min === 0) return `${lastcheck} ${hour} ${ago}`
    return `${lastcheck} ${hour} ${minute} ${ago}`
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


function setFrameSize() {
    const multiplier = cfg.indicatorCounter && cfg.indicatorScale ? 1.1 :  
                       cfg.indicatorCounter && !cfg.indicatorScale ? 1 : 0.85

    return plasmoid.location === 5 || plasmoid.location === 6 ? icon.height * multiplier :     
           plasmoid.location === 3 || plasmoid.location === 4 ? icon.width * multiplier : 0
}


function setAnchor(pos, stop) {
    const anchors = {
        top: cfg.indicatorBottom && !cfg.indicatorTop,
        bottom: cfg.indicatorTop && !cfg.indicatorBottom,
        right: cfg.indicatorLeft && !cfg.indicatorRight,
        left: cfg.indicatorRight && !cfg.indicatorLeft
    }

    return (stop ? anchors[pos] : {
        top: anchors.bottom,
        bottom: anchors.top,
        right: anchors.left,
        left: anchors.right
    }[pos]) ? frame[pos] : undefined
}


function print(text) {
    let ooo = ":".repeat(48)
    let oo = ":".repeat(Math.ceil((ooo.length - text.length - 2) / 2))
    let o = text.length % 2 !== 0 ? oo.substring(1) : oo

    const green = "\x1B[1m\x1B[32m", bold = "\x1B[1m", reset = "\x1B[0m"
    text = bold + text + reset
    ooo = green + ooo + reset
    oo =  green + oo + reset
    o =  green + o + reset

    return `echo; echo -e ${ooo}
            echo -e ${oo} ${text} ${o}
            echo -e ${ooo}`
}


function switchInterval() {
    cfg.interval = !cfg.interval
}
