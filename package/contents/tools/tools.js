const scriptDir = "$HOME/.local/share/plasma/plasmoids/com.github.exequtic.apdatifier/contents/tools/sh/"
const configDir = "$HOME/.config/apdatifier/"
const configFile = configDir + "config.conf"
const cacheFile = configDir + "updates.json"
const rulesFile = configDir + "rules.json"
const newsFile = configDir + "news.json"

function execute(command, callback, stoppable) {
    const component = Qt.createComponent("../ui/components/Shell.qml")
    if (component.status === Component.Ready) {
        const componentObject = component.createObject(root)
        if (componentObject) {
            if (typeof sts !== "undefined") sts.proc = componentObject
            componentObject.exec(command, callback)
        } else {
            Error(1, "Failed to create executable DataSource object")
        }
    } else {
        Error(1, "Executable DataSource component not ready")
    }
}

const readFile = (file) => `[ -f "${file}" ] && cat "${file}"`
const writeFile = (data, redir, file) => `echo '${data}' ${redir} "${file}"`

const bash = (script, ...args) => scriptDir + script + ' ' + args.join(' ')
const runInTerminal = (script, ...args) => {
    execute('kstart ' + bash('terminal', script, ...args))
    script === "upgrade" && upgradeTimer.start()
}

const debug = true
function log(message) {
    if (debug) console.log("[" + new Date().getTime().toString() + "] "+ "APDATIFIER: " + message)
}

function Error(code, err) {
    if (err) {
        sts.errors = sts.errors.concat([{code: code, message: err.trim(), type: ""}])
        cfg.notifyErrors && notify.send("error", i18n("Exit code: ") + code, err.trim())
        setStatusBar()
        return true
    }
    return false
}

function handleError(code, err, type, onError) {
    if (code && err) {
        sts.errors = sts.errors.concat([{code: code, message: err.trim(), type: type}])
        onError()
        return true
    }
    return false
}

function init() {
    execute(bash('init'), (cmd, out, err, code) => {
        if (Error(code, err)) return
        loadConfig()
    })

    function loadConfig() {
        execute(readFile(configFile), (cmd, out, err, code) => {
            if (Error(code, err)) return
            if (out) {
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
            }

            loadCache()
        })
    }

    function loadCache() {
        execute(readFile(cacheFile), (cmd, out, err, code) => {
            if (Error(code, err)) return
            if (out && validJSON(out, cacheFile)) cache = keys(JSON.parse(out.trim()))
            loadRules()
        })
    }

    function loadRules() {
        execute(readFile(rulesFile), (cmd, out, err, code) => {
            if (Error(code, err)) return
            if (out && validJSON(out, rulesFile)) plasmoid.configuration.rules = out
            loadNews()
        })
    }

    function loadNews() {
        execute(readFile(newsFile), (cmd, out, err, code) => {
            if (Error(code, err)) return
            if (out && validJSON(out, newsFile)) JSON.parse(out.trim()).forEach(item => newsModel.append(item))
            onStartup()
        })
    }

    function onStartup() {
        sts.init = true
        checkDependencies()
        refreshListModel()
        updateActiveNews()
        upgradingState()
    }
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
    execute(writeFile(config, ">", configFile))
}

function checkDependencies() {
    const pkgs = "pacman flatpak fwupdmgr paru pikaur yay jq tmux alacritty foot ghostty gnome-terminal kitty konsole lxterminal ptyxis terminator tilix wezterm xterm yakuake"
    const checkPkg = (pkgs) => `for pkg in ${pkgs}; do command -v $pkg || echo; done`
    const populate = (data) => data.map(item => ({ "name": item.split("/").pop(), "value": item }))

    execute(checkPkg(pkgs), (cmd, out, err, code) => {
        if (Error(code, err)) return

        const output = out.split("\n")

        const [pacman, flatpak, fwupdmgr, paru, pikaur, yay, jq, tmux ] = output.map(Boolean)
        cfg.packages = { pacman, flatpak, fwupdmgr, paru, pikaur, yay, jq, tmux }
        if (!cfg.wrapper) cfg.wrapper = paru ? "paru" : yay ? "yay" : pikaur ? "pikaur" : ""

        const terminals = populate(output.slice(8).filter(Boolean))
        cfg.terminals = terminals.length > 0 ? terminals : null
        if (!cfg.terminal) cfg.terminal = cfg.terminals.length > 0 ? cfg.terminals[0].value : ""

        if (!pacman) plasmoid.configuration.arch = false
        if (!pacman || (!yay && !paru && !pikaur)) plasmoid.configuration.aur = false
        if (!flatpak) plasmoid.configuration.flatpak = false
        if (!fwupdmgr) plasmoid.configuration.fwupd = false
        if (!tmux) plasmoid.configuration.tmuxSession = false
        if (!jq) {
            plasmoid.configuration.widgets = false
            plasmoid.configuration.newsArch = false
            plasmoid.configuration.newsKDE = false
            plasmoid.configuration.newsTWIK = false
            plasmoid.configuration.newsTWIKA = false
        }
    })
}


function upgradePackage(name, appID, contentID) {
    if (sts.upgrading) return

    if (appID) {
        runInTerminal("upgrade", "flatpak", appID, name)
    } else if (contentID) {
        runInTerminal("upgrade", "widget", contentID, name)
    }
}

function management() {
    runInTerminal("management")
}


function upgradingState() {
    const checkProc = `ps aux | grep "[a]pdatifier/contents/tools/sh/upgrade"`
    execute(checkProc, (cmd, out, err, code) => {
        const state = !!(out || err)
        sts.busy = sts.upgrading = state

        if (state) {
            upgradeTimer.start()
            scheduler.stop()
            sts.statusMsg = i18n("Upgrade in progress") + "..."
            sts.statusIco = cfg.ownIconsUI ? "toolbar_upgrade" : "akonadiconsole"
        } else {
            upgradeTimer.stop()
            execute(bash('utils', "currentVersions"), (cmd, out, err, code) => {
                if (Error(code, err)) return
                if (!out || !validJSON(out)) return
                const currentVersions = JSON.parse(out)
                const newList = cache.filter(cached => {
                    const current = currentVersions.find(pkg => pkg.NM.replace(/ /g, "-").toLowerCase() === cached.NM)
                    return current && current.VO === cached.VO + cached.AC
                })
                if (JSON.stringify(cache) !== JSON.stringify(newList)) {
                    cache = newList
                    refreshListModel()
                    saveCache(cache)
                }
                setStatusBar()
                resumeScheduler()
            })
        }
    })
}


function upgradeSystem() {
    if (sts.upgrading && !cfg.tmuxSession) return
    runInTerminal("upgrade", "full")
}


function checkUpdates() {
    if (sts.upgrading) return

    sts.errors = []

    if (sts.busy) {
        sts.busy = false
        sts.proc.cleanup()
        setStatusBar()
        resumeScheduler()
        return
    }

    scheduler.stop()
    sts.busy = true

    let archRepos = [], archAur = [], flatpak = [], widgets = [], firmwares = []

    const feeds = [
        cfg.newsArch  && "'https://archlinux.org/feeds/news/'",
        cfg.newsKDE   && "'https://kde.org/index.xml'",
        cfg.newsTWIK  && "'https://blogs.kde.org/categories/this-week-in-plasma/index.xml'",
        cfg.newsTWIKA && "'https://blogs.kde.org/categories/this-week-in-kde-apps/index.xml'"
    ].filter(Boolean).join(' ')

            feeds ? checkNews() :
         cfg.arch ? checkRepos() :
          cfg.aur ? checkAur() :
      cfg.flatpak ? checkFlatpak() :
      cfg.widgets ? checkWidgets() :
        cfg.fwupd ? checkFirmwares() :
                    merge()

    function checkNews() {
        const next = () => cfg.arch ? checkRepos() : cfg.aur ? checkAur() : cfg.flatpak ? checkFlatpak() :
                           cfg.widgets ? checkWidgets() : cfg.fwupd ? checkFirmwares() : merge()
        sts.statusIco = cfg.ownIconsUI ? "status_news" : "news-subscribe"
        sts.statusMsg = i18n("Checking latest news...")
        execute(bash('utils', 'rss', feeds), (cmd, out, err, code) => {
            if (out) updateNews(out)
            if (handleError(code, err, "news", next)) return
            next()
         })
    }

    function checkRepos() {
        const next = () => cfg.aur ? checkAur() : cfg.flatpak ? checkFlatpak() :
                           cfg.widgets ? checkWidgets() : cfg.fwupd ? checkFirmwares() : merge()
        sts.statusIco = cfg.ownIconsUI ? "status_package" : "apdatifier-package"
        sts.statusMsg = i18n("Synchronizing pacman databases...")
        execute(bash('utils', 'syncdb'), (cmd, out, err, code) => {
            if (handleError(code, err, "repositories", next)) return
            sts.statusIco = cfg.ownIconsUI ? "status_package" : "apdatifier-package"
            sts.statusMsg = i18n("Checking system updates...")
            execute(`pacman -Qu --dbpath "${cfg.dbPath}" 2>&1`, (cmd, out, err, code) => {
                if (handleError(code, err, "repositories", next)) return
                const updates = out ? out.trim().split("\n") : []
                makeArchList(updates, "repositories").then(result => {
                    archRepos = result
                    next()
                })
            })
        })
    }

    function checkAur() {
        const next = () => cfg.flatpak ? checkFlatpak() : cfg.widgets ? checkWidgets() : cfg.fwupd ? checkFirmwares() : merge()
        sts.statusIco = cfg.ownIconsUI ? "status_package" : "apdatifier-package"
        sts.statusMsg = i18n("Checking AUR updates...")
        const cmdArg = cfg.wrapper === "pikaur" ? " -Qua --noconfirm" : " -Qua"
        execute(cfg.wrapper + cmdArg, (cmd, out, err, code) => {
            if (handleError(code, err, "aur", next)) return
            const updates = out ? out.trim().split("\n") : []
            makeArchList(updates, "aur").then(result => {
                archAur = result
                next()
            })
        })
    }

    function checkFlatpak() {
        const next = () => cfg.widgets ? checkWidgets() : cfg.fwupd ? checkFirmwares() : merge()
        sts.statusIco = cfg.ownIconsUI ? "status_flatpak" : "apdatifier-flatpak"
        sts.statusMsg = i18n("Synchronizing flatpak appstream...")
        execute("flatpak update --appstream >/dev/null 2>&1", (cmd, out, err, code) => {
            if (handleError(code, err, "flatpak", next)) return
            sts.statusIco = cfg.ownIconsUI ? "status_flatpak" : "apdatifier-flatpak"
            sts.statusMsg = i18n("Checking flatpak updates...")
            execute("flatpak remote-ls --app --updates --show-details", (cmd, out, err, code) => {
                if (handleError(code, err, "flatpak", next)) return
                const updates = out.trim()
                makeFlatpakList(updates, "flatpak").then(result => {
                    flatpak = result
                    next()
                })
            })
        })
    }

    function checkWidgets() {
        const next = () => cfg.fwupd ? checkFirmwares() : merge()
        sts.statusIco = cfg.ownIconsUI ? "status_widgets" : "start-here-kde-plasma-symbolic"
        sts.statusMsg = i18n("Checking widgets updates...")
        execute(bash('widgets', 'check'), (cmd, out, err, code) => {
            if (handleError(code, err, "widgets", next)) return
            widgets = JSON.parse(out.trim())
            next()
        })
    }

    function checkFirmwares() {
        sts.statusIco = cfg.ownIconsUI ? "status_package" : "apdatifier-package"
        sts.statusMsg = i18n("Checking firmware updates...")
        execute("fwupdmgr refresh --force", (cmd, out, err, code) => {
            if (handleError(code, err, "fwupdmgr", merge)) return
            execute("fwupdmgr get-updates --json", (cmd, out, err, code) => {
                if (handleError(code, err, "fwupdmgr", merge)) return
                firmwares = JSON.parse(out).Devices.map(device => ({
                    NM: `${device.Vendor}-${device.Name}`.replace(/ /g, "-").toLowerCase(),
                    RE: "fwupd",
                    DE: device.Releases?.[0]?.Summary || "",
                    LN: device.Releases?.[0]?.Homepage || "",
                    IN: device.Icons?.[0] || "",
                    VO: device.Version || "",
                    VN: device.Releases?.[0]?.Version || ""
                }))

                merge()
            })
        })
    }

    function merge() {
        finalize(keys(archRepos.concat(archAur, flatpak, widgets, firmwares)))
    }
}


function updateNews(out) {
    const news = JSON.parse(out.trim())

    if (cfg.notifyNews) {
        const currentNews = Array.from(Array(newsModel.count), (_, i) => newsModel.get(i))
        news.forEach(item => {
            if (!currentNews.some(currentItem => currentItem.link === item.link)) {
                notify.send("news", item.title, item.article, item.link)
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
    execute(writeFile(toFileFormat(array), '>', newsFile))
}
function restoreNewsList() {
    let array = []
    for (let i = 0; i < newsModel.count; i++) {
        newsModel.setProperty(i, "removed", false)
        array.push(newsModel.get(i))
    }
    execute(writeFile(toFileFormat(array), '>', newsFile))
    updateActiveNews()
}


function makeArchList(updates, source) {
    return new Promise((resolve) => {
        if (updates.length === 0) {
            resolve([])
        } else {
            const updateRe = /^([A-Za-z0-9@._+-]+)\s+(\S+)\s+->\s+(\S+)/
            const parsed = updates.map(l => l.trim()).map(l => l.match(updateRe)).filter(Boolean)
            if (parsed.length === 0) {
                resolve([])
                return
            }

            const pkgs = parsed.map(m => m[1]).join(' ')
            execute(`LC_ALL=C.UTF-8 pacman -Sl --dbpath "${cfg.dbPath}" | awk 'index($0,"[installed:")>0'`, (cmd, out, err, code) => {
                if (code && handleError(code, err, source, () => resolve([]))) return
                const repositories = out.trim().split('\n')

                execute("LC_ALL=C.UTF-8 pacman -Qi " + pkgs, (cmd, out, err, code) => {
                    if (code && handleError(code, err, source, () => resolve([]))) return
                    const descriptions = out.trim().split('\n\n')

                    execute(bash('utils', 'getIcons', pkgs), (cmd, out, err, code) => {
                        if (code && handleError(code, err, source, () => resolve([]))) return
                        const icons = out.split('\n')

                        const iconsMap = new Map()
                        icons.map(l => l.split(' ', 2))
                             .filter(([name, icon]) => name && icon)
                             .forEach(([name, icon]) => iconsMap.set(name, icon))

                        const versionsMap = new Map()
                        parsed.forEach(m => versionsMap.set(m[1], { currentVer: m[2], newVer: m[3] }))

                        const repositoriesMap = new Map()
                        repositories.forEach(line => {
                            const [repo, name] = line.trim().split(/\s+/)
                            if (!repositoriesMap.has(name)) {
                                repositoriesMap.set(name, repo)
                            }
                        })

                        const keyMap = {
                            'Name':           'NM',
                            'Description':    'DE',
                            'URL':            'LN',
                            'Groups':         'GR',
                            'Provides':       'PR',
                            'Depends On':     'DP',
                            'Required By':    'RQ',
                            'Conflicts With': 'CF',
                            'Replaces':       'RP',
                            'Installed Size': 'IS',
                            'Install Date':   'DT',
                            'Install Reason': 'RN'
                        }

                        const packagesData = descriptions.map(description => {
                            const pkg = {}
                            const lines = description.split('\n')
                            for (const line of lines) {
                                const match = line.match(/^(\w+(?:\s+\w+)*)\s+:\s*(.*)/)
                                if (match) {
                                    const key = match[1].trim()
                                    const value = match[2].trim()
                                    if (value === "None") continue
                                    const mappedKey = keyMap[key]
                                    if (mappedKey) pkg[mappedKey] = value
                                }
                            }

                            if (iconsMap.has(pkg.NM)) pkg.IN = iconsMap.get(pkg.NM)

                            const versions = versionsMap.get(pkg.NM) || {}
                            pkg.VO = versions.currentVer || ""
                            pkg.VN = (versions.newVer === "latest-commit") ? i18n("latest commit") : (versions.newVer || "")
                            pkg.RE = repositoriesMap.get(pkg.NM) || (pkg.NM.endsWith("-git") || pkg.VN === i18n("latest commit") ? "devel" : "aur")
                            pkg.RN = pkg.RN.includes("Explicitly") ? i18n("Explicitly installed") : i18n("Installed as a dependency")

                            return pkg
                        })

                        resolve([...new Map(packagesData.map(item => [item.NM, item])).values()])
                    })
                })
            })
        }
    })
}


function makeFlatpakList(updates) {
    return new Promise((resolve) => {
        if (!updates) {
            resolve([])
        } else {
            execute("flatpak list --app --columns=application,version,active", (cmd, out, err, code) => {
                if (code && handleError(code, err, "flatpak", () => resolve([]))) return
                const description = out.trim().split("\n").reduce((obj, line) => {
                    const [ID, VO, AC] = line.split("\t").map(entry => entry.trim())
                    obj[ID] = { VO, AC }
                    return obj
                }, {})
                const extendedList = updates.split("\n").map(line => {
                    const [NM, DE, ID, VN, BR, , RE, , CM, RT, IS, DS] = line.split("\t").map(entry => entry.trim())
                    const { VO, AC } = description[ID]
                    return {
                        NM: NM.replace(/ /g, "-").toLowerCase(),
                        DE, LN: "https://flathub.org/apps/" + ID,
                        ID, BR, RE, AC, CM, RT, IS, DS, VO,
                        VN: VO === VN ? i18n("latest commit") : VN
                    }
                })
                resolve(extendedList)
            })
        }
    })
}


function sortList(list, byName) {
    if (!list) return

    return list.sort((a, b) => {
        const name = a.NM.localeCompare(b.NM)
        const repo = a.RE.localeCompare(b.RE)
        if (byName || !cfg.sorting) return name

        if (a.IM !== b.IM) return a.IM ? -1 : 1

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
    sts.busy = false
    resumeScheduler()

    cfg.timestamp = new Date().getTime().toString()

    if (cfg.notifyErrors && sts.error) {
        const notifyMsg = sts.errors.map(err => `<b>${err.type}</b> => ${err.message} (Exit code ${err.code})`).join('\n\n')
        notify.send("error", i18np("%1 error occurred", "%1 errors occurred", sts.errors.length), notifyMsg)
    }

    if (!list) {
        listModel.clear()
        execute(writeFile("[]", '>', cacheFile))
        cache = []
        sts.count = 0
        setStatusBar()
        return
    }

    if (sts.error && cache.length > 0) {
        var errorTypes = {}
        for (var i = 0; i < sts.errors.length; i++) errorTypes[sts.errors[i].type] = true

        var currentNames = {}
        for (var j = 0; j < list.length; j++) currentNames[list[j].NM] = true
        
        var cachedPackages = []
        for (var k = 0; k < cache.length; k++) {
            var cached = cache[k]
            if (currentNames[cached.NM]) continue
            
            if (errorTypes.repositories && cached.RE && cached.RE !== "aur" && cached.RE !== "devel") {
                cachedPackages.push(cached)
            } else if (errorTypes.aur && (cached.RE === "aur" || cached.RE === "devel")) {
                cachedPackages.push(cached)
            } else if (errorTypes.flatpak && cached.ID) { 
                cachedPackages.push(cached)
            } else if (errorTypes.widgets && cached.CN) {
                cachedPackages.push(cached)
            }
        }

        list = list.concat(cachedPackages)
    }

    refreshListModel(list)

    if (cfg.notifyUpdates) {
        const cached = new Map(cache.map(el => [el.NM, el.VN]))
        const newList = applyRules(list).filter(el => !cached.has(el.NM) || (cfg.notifyEveryBump && cached.get(el.NM) !== el.VN))
    
        if (newList.length > 0) {
            const title = i18np("+%1 new update", "+%1 new updates", newList.length)
            const body = newList.map(pkg => `${pkg.NM} → ${pkg.VN}`).join("\n")
            notify.send("updates", title, body)
        }
    }

    cache = list
    saveCache(cache)
}

function saveCache(list) {
    if (JSON.stringify(list).length > 130000) {
        let start = 0
        const chunkSize = 200
        const json = JSON.stringify(keys(sortList(JSON.parse(JSON.stringify(list)), true))).replace(/},/g, "},\n").replace(/'/g, "")
        const lines = json.split("\n")
        while (start < lines.length) {
            const chunk = lines.slice(start, start + chunkSize).join("\n")
            const redir = start === 0 ? ">" : ">>"
            execute(writeFile(chunk, redir, `${cacheFile}_${Math.ceil(start / chunkSize)}`))
            start += chunkSize
        }
        execute(bash('utils', 'combineFiles', cacheFile))
    } else {
        const json = toFileFormat(keys(sortList(JSON.parse(JSON.stringify(list)), true)))
        execute(writeFile(json, '>', cacheFile))
    }
}


function setStatusBar() {
    if (sts.count > 0) {
        sts.statusIco = cfg.ownIconsUI ? "status_pending" : "accept_time_event"
        sts.statusMsg = sts.count + " " + i18np("update is pending", "updates are pending", sts.count)
    } else {
        sts.statusIco = cfg.ownIconsUI ? "status_blank" : ""
        sts.statusMsg = ""
    }
}

function resumeScheduler() {
    if (cfg.checkMode !== "manual") {
        scheduler.start()
    }
}

function searchScheduler(options) {
    const mode = cfg.checkMode
    if (mode === "manual") {
        scheduler.stop()
        return
    }

    const currTime = new Date().getTime()
    const lastCheck = parseInt(cfg.timestamp) || 0
    let nextCheck = null

    if (mode === "interval") {
        const interval = parseFloat(cfg.intervalMinutes)
        const intervalMs = interval * 60 * 1000
        nextCheck = lastCheck ? (lastCheck + intervalMs) : (currTime + intervalMs)
    } else if (mode === "daily") {
        const scheduled = new Date(currTime)
        scheduled.setHours(cfg.dailyHour, cfg.dailyMinute, 0, 0)
        if (scheduled.getTime() <= currTime) scheduled.setDate(scheduled.getDate() + 1)
        nextCheck = scheduled.getTime()
    } else if (mode === "weekly") {
        const scheduled = new Date(currTime)
        const targetDay = Number(cfg.weeklyDay)
        const daysAhead = (targetDay - scheduled.getDay() + 7) % 7
        scheduled.setDate(scheduled.getDate() + daysAhead)
        scheduled.setHours(cfg.weeklyHour, cfg.weeklyMinute, 0, 0)
        if (scheduled.getTime() <= currTime) scheduled.setDate(scheduled.getDate() + 7)
        nextCheck = scheduled.getTime()
    }

    options = options || {}
    if (options.simulate) return nextCheck

    if (nextCheck && nextCheck <= (currTime + 10000) && nextCheck > lastCheck) {
        checkUpdates()
    }

    return
}


function getCheckTime() {
    const currTime = new Date().getTime()
    const lastCheck = parseInt(cfg.timestamp) || currTime

    const formatDelta = (ms1, ms2) => {
        const diff = Math.max(0, Math.floor((ms1 - ms2) / 1000))
        const days = Math.floor(diff / 86400)
        const hours = Math.floor((diff % 86400) / 3600)
        const minutes = Math.floor((diff % 3600) / 60)
        const seconds = diff % 60
        const parts = []
        if (days > 0) parts.push([days, i18np("%1 day", "%1 days", days)])
        if (hours > 0) parts.push([hours, i18np("%1 hour", "%1 hours", hours)])
        if (minutes > 0) parts.push([minutes, i18np("%1 minute", "%1 minutes", minutes)])
        if (parts.length === 0 && seconds > 0) return i18n("less than a minute")
        if (seconds > 0) parts.push([seconds, i18np("%1 second", "%1 seconds", seconds)])
        const take = parts.slice(0, 2).map(p => p[1])
        return take.join(' ')
    }

    const lastCheckStr = (currTime > lastCheck) ? `${i18n("Last check:")} ${formatDelta(currTime, lastCheck)} ${i18n("ago")}` : ""

    if (!scheduler.running) return lastCheckStr

    const nextCheck = searchScheduler({ simulate: true })
    if (!nextCheck) return lastCheckStr

    const nextCheckStr = (currTime < nextCheck) ? `${i18n("Next check in:")} ${formatDelta(nextCheck, currTime)}` : ""

    if (lastCheckStr && nextCheckStr) return `${lastCheckStr}\n${nextCheckStr}`
    if (lastCheckStr && !nextCheckStr) return lastCheckStr
    if (!lastCheckStr && nextCheckStr) return nextCheckStr
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
        el.IM = false
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
            el.IM = rule.important
        }
    }

    rules.forEach(rule => list.forEach(el => applyRule(el, rule)))
    return list.filter(el => !el.EX)
}


function keys(list) {
    const keysList = ["GR", "PR", "DP", "RQ", "CF", "RP", "IS", "DT", "RN", "ID", "BR", "AC", "CM", "RT", "DS", "CN", "AU"]

    list.forEach(el => {
        keysList.forEach(key => {
            if (!el.hasOwnProperty(key)) el[key] = ""
            else if (el[key] === "") delete el[key]
        })

        if (el.hasOwnProperty("IC")) delete el["IC"]
        if (el.hasOwnProperty("EX")) delete el["EX"]
        if (el.hasOwnProperty("IM")) delete el["IM"]
    })

    return list
}


function switchScheduler() {
    if (cfg.checkMode === "manual" || sts.busy) return
    scheduler.running ? scheduler.stop() : scheduler.start()
}

function toFileFormat(obj) {
    const jsonStringWithSpace = JSON.stringify(obj, null, 2)
    const writebleJsonStrings = jsonStringWithSpace.replace(/'/g, "")
    return writebleJsonStrings
}

function validJSON(string, file) {
    try {
        const json = JSON.parse(string)
        if (json && typeof json === "object") return json
    }
    catch (e) {
        file ? Error(1, `JSON data at ${file} is corrupted or broken and cannot be processed`)
             : Error(1, "JSON data is broken and cannot be processed")
    }

    return false
}
