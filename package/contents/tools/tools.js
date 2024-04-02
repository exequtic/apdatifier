/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/


function Error(code, err) {
    if (err) {
        error = err.trim().substring(0, 150) + "..."
        setStatusBar(code)
        return true
    }
    return false
}

const script = "$HOME/.local/share/plasma/plasmoids/com.github.exequtic.apdatifier/contents/tools/tools.sh"
const cachefile1 = "$HOME/.local/share/plasma/plasmoids/com.github.exequtic.apdatifier/cache.json"
const cachefile2 = cachefile1.replace(/\.json$/, "2.json")
function runScript() {
    sh.exec(`${script} copy`, (cmd, out, err, code) => {
        if (Error(code, err)) return

        sh.exec(`[ -f "${cachefile2}" ] && cat "${cachefile2}"`, (cmd, out, err, code) => {
            const cache2 = out ? JSON.parse(out.trim()) : []

            sh.exec(`[ -f "${cachefile1}" ] && cat "${cachefile1}"`, (cmd, out, err, code) => {
                cache = out ? cache2.concat(JSON.parse(out.trim())) : []
                checkDependencies()
            })
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

    sh.exec(checkPkg(pkgs), (cmd, out, err, code) => {
        if (Error(code, err)) return

        const output = out.split("\n")

        const [pacman, checkupdates, flatpak] = output.map(Boolean)
        cfg.packages = { pacman, checkupdates, flatpak }

        const wrappers = populate(output.slice(3, 6).filter(Boolean))
        cfg.wrappers = wrappers.length > 0 ? wrappers : null

        const terminals = populate(output.slice(6).filter(Boolean))
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

    const yayOrParu = (cfg.wrappers.find(el => el.name === "paru" || el.name === "yay") || {}).value || ""
    cmd.news = yayOrParu ? yayOrParu + " -Pwwq" : null

    cmd.arch = pkg.checkupdates
                    ? cfg.aur ? `bash -c "(checkupdates; ${wrapperCmd}) | sort -u -t' ' -k1,1"` : "checkupdates"
                    : cfg.aur ? wrapperCmd : "pacman -Qu"

    if (!pkg.pacman) delete cmd.arch

    const flatpak = (cfg.flatpak ? "; flatpak update" : " ").trim()
    const flags = (cfg.upgradeFlags ? ` ${cfg.upgradeFlagsText}` : " ").trim()
    const arch = (cfg.aur ? cfg.wrapper + " -Syu" + " " + flags : "sudo pacman -Syu" + " " + flags).trim()

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
    const executed = cfg.aur && trizen ? "echo " : "echo; echo -e " + exec + arch + "; echo"

    const trap = "trap '' SIGINT"
    const terminalArg = { "gnome-terminal": " --", "terminator": " -x" }
    cmd.terminal = cfg.terminal + (terminalArg[cfg.terminal.split("/").pop()] || " -e")
    cmd.upgrade = `${cmd.terminal} sh -c "${trap}; ${print(init)}; ${executed}; ${mirrorlist}; ${arch}${flatpak}; ${print(done)}; read"`
}


function updatePackage(id) {
    defineCommands()

    cfg.terminal.split("/").pop() === "yakuake"
        ? sh.exec(`${cmd.terminal} "flatpak update ${id}"`)
        : sh.exec(`${cmd.terminal} flatpak update ${id}`)
}


function upgradeSystem() {
    runAction()
    defineCommands()

    statusIco = "accept_time_event"
    statusMsg = i18n("Full upgrade running...")
    upgrading = true

    sh.exec(cmd.upgrade, (cmd, out, err, code) => {
        upgrading = false
        cfg.interval ? searchTimer.triggered() : refreshListModel()
    })
}


function checkUpdates() {
    runAction()
    defineCommands()

    let updArch, infArch, descArch, updFlpk, infFlpk, ignored

    cmd.arch && cfg.archNews ? checkNews() : cmd.arch ? checkArch() : cfg.flatpak ? checkFlatpak() : merge()

    function checkNews() {
        statusIco = "news-subscribe"
        statusMsg = "Checking latest Arch Linux news..."

        if (!cmd.news) checkArch()
        if (!cmd.news) return

        sh.exec(cmd.news, (cmd, out, err, code) => {
            if (Error(code, err)) return
            makeNewsArticle(out)
            checkArch()
    })}

    function checkArch() {
        statusIco = "package"
        statusMsg = cfg.aur ? i18n("Searching AUR for updates...")
                            : i18n("Searching arch repositories for updates...")
        sh.exec(cmd.arch, (cmd, out, err, code) => {
            if (Error(code, err)) return
            updArch = out ? out.trim().split("\n") : null
            updArch ? listArch() : cfg.flatpak ? checkFlatpak() : merge()
    })}

    function listArch() {
        sh.exec("pacman -Sl", (cmd, out, err, code) => {
            if (Error(code, err)) return
            infArch = out.trim().split("\n")
            descriptionArch()
    })}

    function descriptionArch() {
        let list = updArch.map(s => s.split(" ")[0]).join(' ')
        sh.exec(`pacman -Qi ${list}`, (cmd, out, err, code) => {
            if (Error(code, err)) return
            descArch = out
            checkIgnored()
    })}

    function checkIgnored() {
        sh.exec(`${script} getIgnoredPackages`, (cmd, out, err, code) => {
            ignored = out.trim()
            cfg.flatpak ? checkFlatpak() : merge()
    })}

    function checkFlatpak() {
        statusIco = "flatpak-discover"
        statusMsg = i18n("Searching for flatpak updates...")
        sh.exec("flatpak update --appstream >/dev/null 2>&1; flatpak remote-ls --app --updates --show-details",
            (cmd, out, err, code) => {
            if (Error(code, err)) return
            updFlpk = out ? out : null
            updFlpk ? listFlatpak() : merge()
    })}

    function listFlatpak() {
        sh.exec("flatpak list --app --columns=application,version",
            (cmd, out, err, code) => {
            if (Error(code, err)) return
            infFlpk = out ? out : null
            merge()
    })}

    function merge() {
        updArch = updArch ? makeArchList(updArch, infArch, descArch, ignored) : null
        updFlpk = updFlpk ? makeFlatpakList(updFlpk, infFlpk) : null
    
        updArch && !updFlpk ? finalize(sortList(updArch)) :
        !updArch && updFlpk ? finalize(sortList(updFlpk)) :
        !updArch && !updFlpk ? finalize() :
        finalize(sortList(updArch.concat(updFlpk)))
    }
}


function makeNewsArticle(news) {
    let article = news.trim().split("\n")
    if (article.length > 10) article = article.filter(line => !line.startsWith(' '))
    article = article[article.length - 1]

    let lastNews = {}
    lastNews["article"] = article.split(" ").slice(1).join(" ")

    const prevArticle = cfg.lastNews ? JSON.parse(cfg.lastNews).article : ""

    if (lastNews.article !== prevArticle) {
        lastNews["date"] = article.split(" ")[0]
        lastNews["link"] = "https://archlinux.org/news/" + lastNews.article.toLowerCase().replace(/\s+/g, "-").replace(/[^a-z0-9\-]/g, "")
        lastNews["dismissed"] = false
        cfg.lastNews = JSON.stringify(lastNews)

        if (cfg.notifications) {
            notifyTitle = "Arch Linux News"
            notifyBody = "<b>Latest news:</b> " + lastNews.article + "\n⠀\n" + `<a href="${lastNews.link}">Open full article in browser</a>`
            notify.sendEvent()
        }
    }
}


function makeArchList(updates, information, description, ignored) {
    const packagesData = description.split("\n\n")
    const skip = [1, 3, 5, 9, 11, 15, 16, 19, 20]
    const keyNames = {
         0: "NM",  2: "DE",  4: "LN",  6: "GR",  7: "PR",  8: "DP",
        10: "RQ", 12: "CF", 13: "RP", 14: "IS", 17: "DT", 18: "RN"
    }

    let extendedList = packagesData.map(function(packageData) {
        packageData = packageData.split('\n').filter(line => line.includes("  : ")).join('\n')
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

    extendedList.pop()

    extendedList.forEach(el => {
        ["ID", "BR", "CM", "RT", "DS"].forEach(prop => el[prop] = "")
    })

    extendedList.forEach(el => {
        ["GR", "PR", "DP", "RQ", "CF", "RP"].forEach(prop => {
            if (el[prop].charAt(0) === el[prop].charAt(0).toUpperCase()) el[prop] = ""
        })

        el.LN = el.LN.replace(/\/+$/, '')

        let found = false
        information.forEach(str => {
            const parts = str.split(" ")
            if (el.NM === parts[1]) {
                el.RE = parts[0]
                found = true
            }
        })

        if (!found) el.RE = el.NM.slice(-4) === "-git" ? "devel" : "aur"

        updates.forEach(str => {
            const parts = str.split(" ")
            if (el.NM === parts[0]) {
                el.VO = parts[1]
                el.VN = parts[3]
            }
        })
    })

    return ignorePackagesAndGroups(extendedList, ignored)
}


function makeFlatpakList(updates, information) {
    const list = information.split("\n").slice(1).reduce((map, line) => {
        const [ID, VO] = line.split("\t").map(entry => entry.trim())
        map.set(ID, VO)
        return map
    }, new Map())

    return updates.split("\n").map(line => {
        const [NM, DE, ID, VN, BR, , RE, , CM, RT, IS, DS] = line.split("\t").map(entry => entry.trim())
        return NM ? {
            NM: NM.replace(/ /g, "-").toLowerCase(),
            DE: DE, ID: ID, BR: BR, RE: RE, CM: CM, RT: RT, IS: IS, DS: DS,
            VO: list.get(ID),
            VN: list.get(ID) === VN ? "refresh of " + VN : VN,
        } : null
    }).filter(Boolean)
}


function ignorePackagesAndGroups(list, ignored) {
    if (!ignored) return list

    const [ignoredPkgs, ignoredGroups] = ignored.split("\n").map(str => str.trim())

    if (ignoredPkgs) {
        const ignorePkg = new Set(ignoredPkgs.split(" "))
        list = list.filter(el => !ignorePkg.has(el.NM.trim()))
    }

    if (ignoredGroups) {
        const ignoreGroup = new Set(ignoredGroups.split(" "))
        list = list.filter(el => !ignoreGroup.has(el.GR.trim()))
    }

    return list
}


function sortList(list) {
    return list.sort((a, b) => {
        const [nameA, repoA] = [a.NM, a.RE]
        const [nameB, repoB] = [b.NM, b.RE]

        if (cfg.sortByName) return nameA.localeCompare(nameB)

        const isRepoDevelA = repoA.includes("devel")
        const isRepoDevelB = repoB.includes("devel")

        if (isRepoDevelA && !isRepoDevelB) return -1
        if (!isRepoDevelA && isRepoDevelB) return 1

        const isRepoAURorDevelA = repoA.includes("aur")
        const isRepoAURorDevelB = repoB.includes("aur")

        return isRepoAURorDevelA !== isRepoAURorDevelB
            ? isRepoAURorDevelA
                ? -1
                : 1
            : repoA.localeCompare(repoB) || nameA.localeCompare(nameB)
    })    
}


function setNotify(list) {
    const newList = list.filter(el => {
        if (!cache.some(elCache => elCache.NM === el.NM)) return true
        if (cfg.notifyEveryBump && cache.some(elCache => elCache.NM === el.NM && elCache.VN !== el.VN)) return true
        return false
    })

    const newCount = newList.length

    if (newCount > 0) {
        let lines = ""
        newList.forEach(item => {
            lines += item["NM"] + "   → " + item["VN"] + "\n"
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
    cfg.timestamp = new Date().getTime().toString()

    if (!list) {
        listModel.clear()
        sh.exec(`[ -f "${cachefile1}" ] && rm "${cachefile1}";\
                 [ -f "${cachefile2}" ] && rm "${cachefile2}"`)
        cache = []
        count = 0
        setStatusBar()
        return
    }

    refreshListModel(list)

    if (cfg.notifications) setNotify(list)

    count = list.length
    cache = list

    let json1, json2
    const json = JSON.stringify(list).replace(/},/g, "},\n").replace(/'/g, "")

    if (json.length > 130000) {
        const lines = json.split("\n")
        const half = Math.floor(lines.length / 2)
        json1 = lines.slice(0, half).join("\n").replace(/,$/, "]")
        json2 = "[" + lines.slice(half).join("\n")
    } else {
        json1 = json
        json2 = null
        sh.exec(`[ -f "${cachefile2}" ] && rm "${cachefile2}"`)
    }

    sh.exec(`echo '${json1}' > ${cachefile1}`)
    if (json2) sh.exec(`echo '${json2}' > ${cachefile2}`)

    setStatusBar()
}


function setStatusBar(code) {
    statusIco = error ? "error" : count > 0 ? "update-none" : ""
    statusMsg = error ? "Exit code: " + code : count > 0 ? i18np("%1 update is pending", "%1 updates total are pending", count) : ""
    busy = false
    !cfg.interval ? searchTimer.stop() : searchTimer.restart()
}


function getLastCheckTime() {
    if (!cfg.timestamp) return ""

    const diff = new Date().getTime() - parseInt(cfg.timestamp)
    const sec = Math.round((diff / 1000) % 60)
    const min = Math.floor((diff / (1000 * 60)) % 60)
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


function setIcon(icon) {
    return icon === "" ? "apdatifier-plasmoid" : icon
}


function setPackageIcon(icons, name, repo, group, appID) {
    if (appID && appID === "org.libreoffice.LibreOffice") return appID + ".main"
    if (appID) return appID

    let icon = "server-database"
    if (cfg.customIconsEnabled) {
        icons = icons.replace(/\n+$/, '').split("\n")
        for (let rule of icons) if (!/^([^>]*>){2}[^>]*$/.test(rule)) return icon

        icons.filter(Boolean)
             .map(l => ({ type: l.split(">")[0].trim(), value: l.split(">")[1].trim(), icon: l.split(">")[2].trim() }))
             .forEach(el => {
                icon = el.type === "default" ? el.icon : icon
                icon = el.type === "repo" && el.value === repo ? el.icon : icon
                icon = el.type === "group" && el.value === group ? el.icon : icon
                icon = el.type === "match" && name.indexOf(el.value) !== -1 ? el.icon : icon
                icon = el.type === "name" && el.value === name ? el.icon : icon
             })
    }

    return icon
}


function setFrameSize() {
    const multiplier = cfg.indicatorCounter ? 1.1 : 0.9

    return plasmoid.location === 5 || plasmoid.location === 6 ? icon.height * multiplier :     
           plasmoid.location === 3 || plasmoid.location === 4 ? icon.width * multiplier : 0
}


function setAnchor(position, stopIndicator) {
    const anchor = {
        top: cfg.indicatorBottom && !cfg.indicatorTop,
        bottom: cfg.indicatorTop && !cfg.indicatorBottom,
        right: cfg.indicatorLeft && !cfg.indicatorRight,
        left: cfg.indicatorRight && !cfg.indicatorLeft
    }

    const Position = stopIndicator ? anchor[position] :
                      { parent: cfg.indicatorCenter ? parent : undefined,
                        top: anchor.bottom,
                        bottom: anchor.top,
                        right: anchor.left,
                        left: anchor.right }[position]
    
    return Position ? frame[position] : undefined
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
