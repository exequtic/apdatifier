/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/


function Error(code, err) {
    if (err) {
        if (cfg.notifyErrors) sendNotify("error", "Exit code" + ": " + code, err.trim())
        sts.errMsg = err.trim().substring(0, 150) + "..."
        setStatusBar(code)
        return true
    }
    return false
}


const script = "$HOME/.local/share/plasma/plasmoids/com.github.exequtic.apdatifier/contents/tools/tools.sh"
const configDir = "$HOME/.config/apdatifier/"
const configFile = configDir + "config.conf"
const cacheFile1 = configDir + "updates.json"
const cacheFile2 = configDir + "updates_2.json"
const rulesFile = configDir + "rules.json"

const readFile = (file) => `[ -f "${file}" ] && cat "${file}"`
const writeFile = (data, file) => `echo '${data}' > "${file}"`
const removeFile = (file) => `[ -f "${file}" ] && rm "${file}"`

function start() {
    loadConfig()
    sh.exec(`${script} init`, (cmd, out, err, code) => {
        if (Error(code, err)) return
        sh.exec(readFile(cacheFile2), (cmd, out, err, code) => {
            if (Error(code, err)) return
            const cache2 = out ? JSON.parse(out.trim()) : []
            sh.exec(readFile(cacheFile1), (cmd, out, err, code) => {
                if (Error(code, err)) return
                cache = out ? keys(cache2.concat(JSON.parse(out.trim()))) : []
                checkDependencies()
            })
        })
    })
}


function saveConfig() {
    if (saveTimer.running) return
    let config = ""
    Object.keys(cfg).forEach(key => {
        if (key.endsWith("Default")) {
            let name = key.slice(0, -7)
            config += `${name}="${cfg[name]}"\n`
        }
    })

    sh.exec(writeFile(config, configFile))
}

function loadConfig() {
    sh.exec(readFile(configFile), (cmd, out, err, code) => {
        if (Error(code, err)) return
        if (!out) return
        const config = out.trim().split("\n")
        const convert = value => {
            if (!isNaN(parseFloat(value))) return parseFloat(value)
            if (value === "true" || value === "false") return value === 'true'
            return value
        }
        config.forEach(line => {
            const match = line.match(/(\w+)="([^"]*)"/)
            if (match) plasmoid.configuration[match[1]] = convert(match[2])
        })
    })

    sh.exec(readFile(rulesFile), (cmd, out, err, code) => {
        if (Error(code, err)) return
        plasmoid.configuration.rules = out
    })
}


function run() {
    sts.errMsg = ""

    if (sts.upgrading) return true
    if (sts.busy) {
        sh.stop()
        setStatusBar()
        return true
    }

    searchTimer.stop()
    sts.busy = true
    return false
}


function checkDependencies() {
    const pkgs = "pacman checkupdates flatpak paru trizen yay alacritty foot gnome-terminal konsole kitty lxterminal terminator tilix xterm yakuake"
    const checkPkg = (pkgs) => `for pkg in ${pkgs}; do command -v $pkg || echo; done`
    const populate = (data) => data.map(item => ({ "name": item.split("/").pop(), "value": item }))

    sh.exec(checkPkg(pkgs), (cmd, out, err, code) => {
        if (Error(code, err)) return

        const output = out.split("\n")

        const [pacman, checkupdates, flatpak] = output.map(Boolean)
        cfg.packages = { pacman, checkupdates, flatpak }

        const wrappers = populate(output.slice(3, 6).filter(Boolean))
        cfg.wrappers = wrappers.length > 0 ? wrappers : null

        const terminals = populate(output.slice(6).filter(Boolean))
        cfg.terminals = terminals.length > 0 ? terminals : null

        refreshListModel()
        upgradingState(true)
    })
}


function defineCommands() {
    cmd.trizen = cfg.wrapper.split("/").pop() === "trizen"
    cmd.yakuake = cfg.terminal.split("/").pop() === "yakuake"

    const wrapperCmd = cmd.trizen ? `${cfg.wrapper} -Qu; ${cfg.wrapper} -Qu -a 2> >(grep ':: Unable' >&2)` : `${cfg.wrapper} -Qu`

    const yayOrParu = cfg.wrappers ? (cfg.wrappers.find(el => el.name === "paru" || el.name === "yay") || {}).value || "" : null
    cmd.news = yayOrParu ? yayOrParu + " -Pwwq" : null

    cmd.arch = pkg.checkupdates
                    ? cfg.aur ? `bash -c "(checkupdates; ${wrapperCmd}) | sort -u -t' ' -k1,1"` : "checkupdates"
                    : cfg.aur ? wrapperCmd : "pacman -Qu"

    if (!pkg.pacman || !cfg.arch) delete cmd.arch

    const flags = cfg.upgradeFlags ? cfg.upgradeFlagsText : ""
    const arch = cmd.arch ? (cfg.aur ? (`${cfg.wrapper} -Syu ${flags}`).trim() + ";" : (`${cfg.sudoBin} pacman -Syu ${flags}`).trim() + ";") : ""
    const flatpak = cfg.flatpak ? "flatpak update;" : ""
    const widgets = cfg.widgets && applyRules(cache).some(el => el.RE === "kde-store") ? `${script} upgradeAllWidgets ${cfg.restartShell} ${cfg.termFont} '${cfg.restartCommand}';` : ""
    const mirrorlist = cfg.mirrors ? `${cfg.sudoBin} ${script} mirrorlist ${cfg.mirrorCount} '${cfg.dynamicUrl}' ${cfg.termFont};` : ""
    const commands = (`${mirrorlist} ${arch} ${flatpak} ${widgets}`).trim()

    if (cmd.yakuake) {
        const qdbus = "qdbus6 org.kde.yakuake /yakuake/sessions"
        cmd.terminal = `${qdbus} addSession; ${qdbus} runCommandInTerminal $(${qdbus} org.kde.yakuake.activeSessionId)`
        cmd.upgrade = `${cmd.terminal} "tput sc; clear; ${commands}"`
        return
    }

    const init = cmd.arch ? i18n("Full system upgrade") : i18n("Upgrade")
    const done = i18n("Press Enter to close")
    const blue = "\x1B[1m\x1B[34m", bold = "\x1B[1m", reset = "\x1B[0m"
    const execIco = cfg.termFont ? "󰅱 " : ":: "
    const exec = blue + execIco + reset + bold + blue + i18n("Executed:") + " " + reset
    const executed = cmd.arch ? "echo; echo -e " + exec + arch + " echo" : "echo "
    const trap = "trap '' SIGINT"
    const terminalArg = { "gnome-terminal": " --", "terminator": " -x" }
    cmd.terminal = cfg.terminal + (terminalArg[cfg.terminal.split("/").pop()] || " -e")
    cmd.upgrade = `${cmd.terminal} bash -c "${trap}; ${print(init)}; ${executed}; ${commands} ${print(done)}; read" &`
}


function upgradePackage(name, id, contentID) {
    defineCommands()

    const init = i18n("Upgrade") + " " + name
    const done = i18n("Press Enter to close")
    const trap = "trap '' SIGINT"

    if (id) {
        cmd.yakuake ? sh.exec(`${cmd.terminal} "tput sc; clear; flatpak update ${id}"`)
                    : sh.exec(`${cmd.terminal} bash -c "${trap}; ${print(init)}; echo; flatpak update ${id}; ${print(done)}; read" &`)
        return
    }

    if (contentID) {
        const commands = `${script} upgradeWidget ${contentID} ${cfg.restartShell} ${cfg.termFont} ${name} '${cfg.restartCommand}'`
        cmd.yakuake ? sh.exec(`${cmd.terminal} "tput sc; clear; bash ${commands}"`)
                    : sh.exec(`${cmd.terminal} bash -c "${trap}; ${print(init)}; ${commands}; ${print(done)}; read" &`)
        return
    }

    const red = "\x1B[1m\x1B[31m", blue = "\x1B[1m\x1B[34m", bold = "\x1B[1m", reset = "\x1B[0m"
    const warningIco = cfg.termFont ? "  " : ":: "
    const warn1 = bold + red + warningIco + i18n("Read the Arch Wiki - Partial Upgrades") + reset
    const warn2 = bold + red + warningIco + i18n("Perform full system upgrade instead partial upgrade!") + reset
    const warning = "echo -e '\n" + warn1 + "\n" + warn2 + "'"
    const execIco = cfg.termFont ? "󰅱 " : ":: "
    const exec = blue + execIco + reset + bold + blue + i18n("Executed:") + " " + reset
    const command = cfg.aur ? `${cfg.wrapper} -Sy ${name}` : `${cfg.sudoBin} pacman -Sy ${name}`
    const executed = cfg.aur && cmd.trizen ? "echo " : "echo; echo -e " + exec + command + "; echo"

    cmd.yakuake ? sh.exec(`${cmd.terminal} "${command}"`)
                : sh.exec(`${cmd.terminal} bash -c "${trap}; ${print(init)}; ${warning}; ${executed}; ${command}; ${print(done)}; read" &`)
}

function management() {
    defineCommands()
    const wrapper = cfg.aur && cfg.wrapper ? cfg.wrapper : "pacman"
    const commands = `${script} management ${cfg.mirrorCount} '${cfg.dynamicUrl}' ${cfg.termFont} ${wrapper} ${cfg.sudoBin}`

    cmd.yakuake ? sh.exec(`${cmd.terminal} "${commands}"`)
                : sh.exec(`${cmd.terminal} bash -c "${commands}" &`)
}


function enableUpgrading(state) {
    sts.busy = sts.upgrading = state
    if (state) {
        upgradeTimer.start()
        searchTimer.stop()
        sts.statusMsg = i18n("Full system upgrade")
        sts.statusIco = cfg.ownIconsUI ? "toolbar_upgrade" : "akonadiconsole"
    } else {
        upgradeTimer.stop()
        searchTimer.triggered()
    }
}

function upgradingState(startup) {
    sh.exec(`ps aux | grep "${"[:]" + ":".repeat(47)}" | grep -v "${cmd.terminal}"`, (cmd, out, err, code) => {
        if (out || err) {
            enableUpgrading(true)
        } else if (startup) {
            if (!cfg.interval) return
            cfg.checkOnStartup ? searchTimer.triggered() : searchTimer.start()
        } else {
            enableUpgrading(false)
        }
    })
}

function upgradeSystem() {
    if (sts.upgrading) return
    defineCommands()
    if (!cmd.yakuake) enableUpgrading(true)
    sh.exec(cmd.upgrade)
}


function checkUpdates() {
    if (run()) return
    defineCommands()

    let arch = [], flatpak = [], widgets = []

    const archCmd = cmd.arch

     cfg.archNews ? checkNews() :
          archCmd ? checkArch() :
      cfg.flatpak ? checkFlatpak() :
      cfg.widgets ? checkWidgets() :
                    merge()

    function checkNews() {
        sts.statusIco = cfg.ownIconsUI ? "status_news" : "news-subscribe"
        sts.statusMsg = i18n("Checking latest news...")

        if (!cmd.news) checkArch()
        if (!cmd.news) return

        sh.exec(cmd.news, (cmd, out, err, code) => {
            if (Error(code, err)) return
            if (out) makeNewsArticle(out)
            archCmd ? checkArch() : cfg.flatpak ? checkFlatpak() : cfg.widgets ? checkWidgets() : merge()
    })}

    function checkArch() {
        sts.statusIco = cfg.ownIconsUI ? "status_package" : "server-database"
        sts.statusMsg = i18n("Checking system updates...")

        sh.exec(archCmd, (cmd, out, err, code) => {
            if (Error(code, err)) return
            out ? allArch(out.split("\n")) : cfg.flatpak ? checkFlatpak() : cfg.widgets ? checkWidgets() : merge()
    })}

    function allArch(upd) {
        sh.exec("pacman -Sl", (cmd, out, err, code) => {
            if (Error(code, err)) return
            descArch(upd, out.split("\n").filter(line => /\[.*\]/.test(line)))
    })}

    function descArch(upd, all) {
        sh.exec(`pacman -Qi ${upd.map(s => s.split(" ")[0]).join(' ')}`, (cmd, out, err, code) => {
            if (Error(code, err)) return
            arch = makeArchList(upd, all, out)
            cfg.flatpak ? checkFlatpak() : cfg.widgets ? checkWidgets() : merge()
    })}

    function checkFlatpak() {
        sts.statusIco = cfg.ownIconsUI ? "status_flatpak" : "flatpak-discover"
        sts.statusMsg = i18n("Checking flatpak updates...")
        sh.exec("flatpak update --appstream >/dev/null 2>&1; flatpak remote-ls --app --updates --show-details", (cmd, out, err, code) => {
            if (Error(code, err)) return
            out ? descFlatpak(out.trim()) : cfg.widgets ? checkWidgets() : merge()
    })}

    function descFlatpak(upd) {
        sh.exec("flatpak list --app --columns=application,version", (cmd, out, err, code) => {
            if (Error(code, err)) return
            flatpak = out ? makeFlatpakList(upd, out.trim()) : []
            cfg.widgets ? checkWidgets() : merge()
    })}

    function checkWidgets() {
        sts.statusIco = cfg.ownIconsUI ? "status_widgets" : "start-here-kde"
        sts.statusMsg = i18n("Checking widgets updates...")

        sh.exec(`${script} checkWidgets`, (cmd, out, err, code) => {
            if (Error(code, err)) return
            out = out.trim()

            const errorTexts = {
                "200": i18n("Unable check widgets: ") + i18n("Too many API requests in the last 15 minutes from your IP address, please try again later"),
                "127": i18n("Unable check widgets: ") + i18n("some required utilities are not installed (curl, jq, xmlstarlet)"),
                "999": i18n("Unable check widgets: ") + i18n("could not get data from the API")
            }
            
            if (out in errorTexts) {
                Error(out, errorTexts[out])
                return
            }

            widgets = JSON.parse(out)
            merge()
        })
    }

    function merge() {
        finalize(keys(arch.concat(flatpak, widgets)))
    }
}


function makeNewsArticle(news) {
    news = news.trim().replace(/'/g, "").split("\n")
    if (news.length > 10) news = news.filter(line => !line.startsWith(' '))
    const lastArticle = news[news.length - 1].replace(/(\d{4}-\d{2}-\d{2})/, "[$1]")
    if (lastArticle !== cfg.news) {
        cfg.news = lastArticle
        cfg.newsMsg = true
        if (cfg.notifyUpdates) sendNotify("news", i18n("Arch Linux News"), lastArticle.split(" ").slice(1).join(" "))
    }
}


function makeArchList(updates, all, description) {
    if (!updates || !all || !description) return []
    description = description.replace(/^Installed From\s*:.+\n?/gm, '')
    const packagesData = description.split("\n\n")
    const skip = new Set([1, 3, 5, 9, 11, 15, 16, 19, 20])
    const empty = new Set([6, 7, 8, 10, 12, 13])
    const keyNames = {
         0: "NM",  2: "DE",  4: "LN",  6: "GR",  7: "PR",  8: "DP",
        10: "RQ", 12: "CF", 13: "RP", 14: "IS", 17: "DT", 18: "RN"
    }

    let extendedList = packagesData.map(packageData => {
        packageData = packageData.split('\n').filter(line => line.includes(" : "))
        let packageObj = {}
        packageData.forEach((line, index) => {
            if (skip.has(index)) return
            const [, value] = line.split(/\s* : \s*/)
            if (empty.has(index) && value.charAt(0) === value.charAt(0).toUpperCase()) return
            if (keyNames[index]) packageObj[keyNames[index]] = value.trim()
        })

        if (Object.keys(packageObj).length > 0) {
            const found = all.find(str => packageObj.NM === str.split(" ")[1])
            packageObj.RE = found ? found.split(" ")[0] : (packageObj.NM.endsWith("-git") ? "devel" : "aur")
            packageObj.LN = packageObj.LN.replace(/\/+$/, '')
            updates.forEach(str => {
                const [name, verold, , vernew] = str.split(" ")
                if (packageObj.NM === name) Object.assign(packageObj, { VO: verold, VN: vernew })
            })
        }

        return packageObj
    })

    extendedList.pop()
    return extendedList
}


function makeFlatpakList(updates, description) {
    if (!updates || !description) return []
    const list = description.split("\n").slice(1).reduce((map, line) => {
        const [ID, VO] = line.split("\t").map(entry => entry.trim())
        map.set(ID, VO)
        return map
    }, new Map())

    return updates.split("\n").map(line => {
        const [NM, DE, ID, VN, BR, , RE, , CM, RT, IS, DS] = line.split("\t").map(entry => entry.trim())
        const VO = list.get(ID)
        return {
            NM: NM.replace(/ /g, "-").toLowerCase(),
            DE, LN: "https://flathub.org/apps/" + ID,
            ID, BR, RE, CM, RT, IS, DS, VO,
            VN: VO === VN ? "refresh " + VN : VN
        }
    })
}


function sortList(list, byName) {
    if (!list) return

    return list.sort((a, b) => {
        const name = a.NM.localeCompare(b.NM)
        const repo = a.RE.localeCompare(b.RE)
        if (byName || !cfg.sorting) return name

        const develA = a.RE.includes("devel")
        const develB = b.RE.includes("devel")
        if (develA !== develB) return develA ? -1 : 1

        const aurA = a.RE.includes("aur")
        const aurB = b.RE.includes("aur")
        if (aurA !== aurB) return aurA ? -1 : 1

        return repo || name
    })
}


function refreshListModel(list) {
    list = sortList(applyRules(list || cache)) || []
    sts.count = list.length || 0
    setStatusBar()

    if (!list) return

    listModel.clear()
    list.forEach(item => listModel.append(item))
}


function finalize(list) {
    cfg.timestamp = new Date().getTime().toString()

    if (!list) {
        listModel.clear()
        sh.exec(removeFile(cacheFile1))
        sh.exec(removeFile(cacheFile2))
        cache = []
        sts.count = 0
        setStatusBar()
        return
    }

    refreshListModel(list)

    if (cfg.notifyUpdates) {
        const cached = new Map(cache.map(el => [el.NM, el.VN]))
        const newList = applyRules(list).filter(el => !cached.has(el.NM) || (cfg.notifyEveryBump && cached.get(el.NM) !== el.VN))
    
        if (newList.length > 0) {
            const title = i18np("+%1 new update", "+%1 new updates", newList.length)
            const body = newList.map(pkg => `${pkg.NM} → ${pkg.VN}`).join("\n")
            sendNotify("updates", title, body)
        }
    }

    cache = list

    const json = formatJson(JSON.stringify(keys(sortList(JSON.parse(JSON.stringify(list)), true))))
    if (json.length > 130000) {
        let json1, json2
        const lines = json.split("\n")
        const half = Math.floor(lines.length / 2)
        json1 = lines.slice(0, half).join("\n").replace(/,$/, "]")
        json2 = "[" + lines.slice(half).join("\n")
        sh.exec(writeFile(json1, cacheFile1))
        sh.exec(writeFile(json2, cacheFile2))
    } else {
        sh.exec(writeFile(json, cacheFile1))
        sh.exec(removeFile(cacheFile2))
    }
}


function setStatusBar(code) {
    sts.statusIco = sts.err ? "0" : sts.count > 0 ? "1" : "2"
    sts.statusMsg = sts.err ? "Exit code" + ": " + code : sts.count > 0 ? sts.count + " " + i18np("update is pending", "updates are pending", sts.count) : ""
    sts.busy = false
    !cfg.interval ? searchTimer.stop() : searchTimer.restart()
}


let notifyParams = { "event": "", "title": "", "body": "", "icon": "", "label": "", "action": "", "urgency": "" }
function sendNotify(event, title, body) {
    const eventParams = {
        updates: { icon: "apdatifier-packages", label: i18n("Upgrade system"), action: "upgradeSystem", urgency: "DefaultUrgency" },
        news: { icon: "news-subscribe", label: i18n("Read article"), action: "openNewsLink", urgency: "HighUrgency" },
        error: { icon: "error", label: i18n("Check updates"), action: "checkUpdates", urgency: "HighUrgency" }
    }

    let { icon, label, action, urgency } = eventParams[event]

    if (cfg.notifySound) event += "Sound"

    notify = { event, title, body, icon, label, action, urgency }
    notification.sendEvent()
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

const defaultIcon = "apdatifier-plasmoid"
function setIcon(icon) {
    return icon === "" ? defaultIcon : icon
}


function applyRules(list) {
    const rules = !cfg.rules ? [] : JSON.parse(cfg.rules)
    const def = cfg.ownIconsUI ? "apdatifier-package" : "server-database"

    list.forEach(el => {
        el.IC = el.IN ? el.IN : el.ID ? el.ID : def
        el.EX = false
    })

    function applyRule(el, rule) {
        const types = {
            'all'    : () => true,
            'repo'   : () => el.RE === rule.value,
            'group'  : () => el.GR.includes(rule.value),
            'match'  : () => el.NM.includes(rule.value),
            'name'   : () => el.NM === rule.value
        }

        if (types[rule.type]()) {
            el.IC = rule.icon
            el.EX = rule.excluded
        }
    }

    rules.forEach(rule => list.forEach(el => applyRule(el, rule)))
    return list.filter(el => !el.EX)
}


function keys(list) {
    const keysList = [
        "GR", "PR", "DP", "RQ", "CF", "RP", "IS", "DT",
        "RN", "ID", "BR", "CM", "RT", "DS", "CN", "AU"
    ]

    list.forEach(el => {
        keysList.forEach(key => {
            if (!el.hasOwnProperty(key)) el[key] = ""
            else if (el[key] === "") delete el[key]
        })

        if (el.hasOwnProperty("IC")) delete el["IC"]
        if (el.hasOwnProperty("EX")) delete el["EX"]
    })

    return list
}


function setAnchor(position, stopIndicator) {
    const anchor = {
        top: cfg.counterBottom && !cfg.counterTop,
        bottom: cfg.counterTop && !cfg.counterBottom,
        right: cfg.counterLeft && !cfg.counterRight,
        left: cfg.counterRight && !cfg.counterLeft
    }

    const Position = stopIndicator ? anchor[position] :
                      { parent: cfg.counterCenter ? parent : undefined,
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

function openNewsLink() {
    const path = cfg.news.split(" ").slice(1).join(" ").toLowerCase().replace(/\s+/g, "-").replace(/[^a-z0-9\-_]/g, "")
    return Qt.openUrlExternally("https://archlinux.org/news/" + path)
}

function formatJson(data) {
    return data.replace(/},/g, "},\n").replace(/'/g, "")
}
