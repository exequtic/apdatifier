/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

const scriptDir = "$HOME/.local/share/plasma/plasmoids/com.github.exequtic.apdatifier/contents/tools/sh/"
const configDir = "$HOME/.config/apdatifier/"
const configFile = configDir + "config.conf"
const cacheFile = configDir + "updates.json"
const rulesFile = configDir + "rules.json"
const newsFile = configDir + "news.json"

const readFile = (file) => `[ -f "${file}" ] && cat "${file}"`
const writeFile = (data, redir, file) => `echo '${data}' ${redir} "${file}"`

const bash = (script, ...args) => scriptDir + script + ' ' + args.join(' ')
const runInTerminal = (script, ...args) => sh.exec('kstart ' + bash('terminal', script, ...args))

function Error(code, err) {
    if (err) {
        cfg.notifyErrors && sendNotify("error", i18n("Exit code: ") + code, err.trim())
        sts.errMsg = err.trim().substring(0, 150) + "..."
        setStatusBar(code)
        return true
    }
    return false
}

function init() {
    loadConfig()
    sh.exec(bash('init'))
    sh.exec(readFile(cacheFile), (cmd, out, err, code) => {
        if (Error(code, err)) return
        cache = out ? keys(JSON.parse(out.trim())) : []
        checkDependencies()
        refreshListModel()
        upgradingState(true)
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

    sh.exec(writeFile(config, ">", configFile))
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

    sh.exec(readFile(newsFile), (cmd, out, err, code) => {
        if (Error(code, err)) return
        JSON.parse(out.trim()).forEach(item => newsModel.append(item))
        updateActiveNews()
    })
}


function checkDependencies() {
    const pkgs = "pacman checkupdates flatpak paru yay alacritty foot gnome-terminal kitty konsole lxterminal terminator tilix wezterm xterm yakuake"
    const checkPkg = (pkgs) => `for pkg in ${pkgs}; do command -v $pkg || echo; done`
    const populate = (data) => data.map(item => ({ "name": item.split("/").pop(), "value": item }))

    sh.exec(checkPkg(pkgs), (cmd, out, err, code) => {
        if (Error(code, err)) return

        const output = out.split("\n")

        const [pacman, checkupdates, flatpak ] = output.map(Boolean)
        cfg.packages = { pacman, checkupdates, flatpak }

        const wrappers = populate(output.slice(3, 5).filter(Boolean))
        cfg.wrappers = wrappers.length > 0 ? wrappers : null

        const terminals = populate(output.slice(5).filter(Boolean))
        cfg.terminals = terminals.length > 0 ? terminals : null
    })
}


function upgradePackage(name, id, contentID) {
    if (id) {
        runInTerminal("upgrade", "flatpak", id, name)
    } else if (contentID) {
        runInTerminal("upgrade", "widget", contentID, name)
    } else {
        runInTerminal("upgrade", "arch", name)
    }
}

function management() {
    runInTerminal("management")
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
    sh.exec(`ps aux | grep "[a]pdatifier/contents/tools/sh/upgrade full"`, (cmd, out, err, code) => {
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
    enableUpgrading(true)
    runInTerminal("upgrade", "full")
}


function checkUpdates() {
    if (sts.upgrading) return
    if (sts.busy) {
        sh.stop()
        setStatusBar()
        return
    }

    searchTimer.stop()
    sts.busy = true
    sts.errMsg = ""

    let arch = [], flatpak = [], widgets = []

    let archCmd = pkg.checkupdates
                        ? cfg.aur ? `checkupdates; ${cfg.wrapper} -Qua` : "checkupdates"
                        : cfg.aur ? cfg.wrapper + " -Qu" : "pacman -Qu"

    if (!pkg.pacman || !cfg.arch) delete archCmd

    const feeds = [
        cfg.newsArch  && "'https://archlinux.org/feeds/news/'",
        cfg.newsKDE   && "'https://kde.org/index.xml'",
        cfg.newsTWIK  && "'https://blogs.kde.org/categories/this-week-in-plasma/index.xml'",
        cfg.newsTWIKA && "'https://blogs.kde.org/categories/this-week-in-kde-apps/index.xml'"
    ].filter(Boolean).join(' ')

            feeds ? checkNews() :
          archCmd ? checkArch() :
      cfg.flatpak ? checkFlatpak() :
      cfg.widgets ? checkWidgets() :
                    merge()

    function checkNews() {
        sts.statusIco = cfg.ownIconsUI ? "status_news" : "news-subscribe"
        sts.statusMsg = i18n("Checking latest news...")

        sh.exec(bash('utils', 'rss', feeds), (cmd, out, err, code) => {
            if (Error(code, err)) return
            if (out) updateNews(out)
            archCmd ? checkArch() : cfg.flatpak ? checkFlatpak() : cfg.widgets ? checkWidgets() : merge()
    })}

    function checkArch() {
        sts.statusIco = cfg.ownIconsUI ? "status_package" : "apdatifier-package"
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
        sts.statusIco = cfg.ownIconsUI ? "status_flatpak" : "apdatifier-flatpak"
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
        sts.statusIco = cfg.ownIconsUI ? "status_widgets" : "start-here-kde-plasma-symbolic"
        sts.statusMsg = i18n("Checking widgets updates...")

        sh.exec(bash('widgets', 'check'), (cmd, out, err, code) => {
            if (Error(code, err)) return
            out = out.trim()

            const errorTexts = {
                "127": i18n("Unable check widgets: ") + i18n("some required utilities are not installed (curl, jq)"),
                  "1": i18n("Unable check widgets: ") + i18n("Failed to retrieve data from the API"),
                  "2": i18n("Unable check widgets: ") + i18n("Too many API requests in the last 15 minutes from your IP address, please try again later"),
                  "3": i18n("Unable check widgets: ") + i18n("Unkwnown error")
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


function updateNews(out) {
    const news = JSON.parse(out.trim())

    if (cfg.notifyNews) {
        const currentNews = Array.from(Array(newsModel.count), (_, i) => newsModel.get(i))
        news.forEach(item => {
            if (!currentNews.some(currentItem => currentItem.link === item.link)) {
                sendNotify("news", item.title, item.article)
            }
        })
    }

    newsModel.clear()
    news.forEach(item => newsModel.append(item))
    updateActiveNews()
}

function updateActiveNews() {
    const activeItems = Array.from({ length: newsModel.count }, (_, i) => newsModel.get(i)).filter(item => !item.removed)
    activeNewsModel.clear()
    activeItems.forEach(item => activeNewsModel.append(item))
}

function removeNewsItem(index) {
    for (let i = 0; i < newsModel.count; i++) {
        if (newsModel.get(i).link === activeNewsModel.get(index).link) {
            newsModel.setProperty(i, "removed", true)
            activeNewsModel.remove(index)
            break
        }
    }
    let array = Array.from(Array(newsModel.count), (_, i) => newsModel.get(i))
    sh.exec(writeFile(toFileFormat(array), '>', newsFile))
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
        sh.exec(writeFile("[]", '>', cacheFile))
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

    const json = toFileFormat(keys(sortList(JSON.parse(JSON.stringify(list)), true)))
    if (json.length > 130000) {
        let start = 0
        const chunkSize = 200
        const lines = json.split("\n")
        while (start < lines.length) {
            const chunk = lines.slice(start, start + chunkSize).join("\n")
            const redir = start === 0 ? ">" : ">>"
            sh.exec(writeFile(chunk, redir, `${cacheFile}_${Math.ceil(start / chunkSize)}`))
            start += chunkSize
        }
        sh.exec(bash('utils', 'combineFiles', cacheFile))
    } else {
        sh.exec(writeFile(json, '>', cacheFile))
    }
}


function setStatusBar(code) {
    sts.statusIco = sts.err ? "0" : sts.count > 0 ? "1" : "2"
    sts.statusMsg = sts.err ? "Exit code: " + code : sts.count > 0 ? sts.count + " " + i18np("update is pending", "updates are pending", sts.count) : ""
    sts.busy = false
    !cfg.interval ? searchTimer.stop() : searchTimer.restart()
}


let notifyParams = { "event": "", "title": "", "body": "", "icon": "", "urgency": "" }
function sendNotify(event, title, body) {
    const eventParams = {
        updates: { icon: "apdatifier-packages", urgency: "DefaultUrgency" },
        news: { icon: "news-subscribe", urgency: "HighUrgency" },
        error: { icon: "error", urgency: "HighUrgency" }
    }

    let { icon, urgency } = eventParams[event]

    if (cfg.notifySound) event += "Sound"

    notify = { event, title, body, icon, urgency }
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

    list.forEach(el => {
        el.IC = el.IN ? el.IN : el.ID ? el.ID : "apdatifier-package"
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

function switchInterval() {
    cfg.interval = !cfg.interval
}

function toFileFormat(obj) {
    const jsonStringWithSpace = JSON.stringify(obj, null, 2)
    const writebleJsonStrings = jsonStringWithSpace.replace(/'/g, "")
    return writebleJsonStrings
}
