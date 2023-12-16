let timestamp
function debug(msg) {
    if (!debugging) return

    const date = new Date()
    const hms = date.toLocaleTimeString().slice(0, -4)
    const ms = date.getMilliseconds().toString().padStart(3, '0')
    let passed = ''

    if (typeof timestamp !== 'undefined') {
        const currTimestamp = date.getTime()
        const timeDiff = currTimestamp - timestamp
        const secDiff = Math.floor(timeDiff / 1000)
        const msDiff = timeDiff % 1000
        passed = `+${secDiff.toString().padStart(2, '0')}:${msDiff.toString().padStart(3, '0')}`
        timestamp = currTimestamp
    } else {
        passed = '+00:000'
        timestamp = date.getTime()
    }

    console.log(`Apdatifier debug mode: [${hms}:${ms} ${passed}] ${msg}`)
}


function debugButton() {
    debug(plasmoid.configuration.packages)
    debug(JSON.stringify(plasmoid.configuration.wrappers))
    debug(JSON.stringify(plasmoid.configuration.terminals))
    debug(shell[0])
    debug(shell[1])
    debug(shell[2])
    debug(shell[3])
    debug(shell[4])
    debug(shell[5])
    debug(shell[6])
    debug(shell[7])
    debug(shell[8])
    debug(shell[9])
    debug(shell[10])
    debug(shell[11])
}


function catchError(code, err, out) {
    if (code) {
        debug("exitCode: " + code)
        debug("stderr: " + err)
        debug("stdout: " + out)

        if (err) error = err.trim().split('\n')[0]
        if (!err && out) error = out.trim().split('\n')[0]
        if (!err && !out) error = "Unknown error. Try refresh package databases."

        statusIco = 'error'
        statusMsg = `Exit code: ${code}`
        busy = false
        return true
    }
    return false
}


function checkConnection() {
    statusIco = 'network-connect'
    statusMsg = 'Checking connection...'
    connection.sendMessage({})
}


function waitConnectionTimer(func) {
    error = null
    busy = true

    action = func

    if (responseCode !== 200) {
        if (!waitConnection.running) {
            waitConnection.triggered()
            waitConnection.start()
        }
        return true
    }

    waitConnection.stop()
    responseCode = action === checkUpdates ? 0 : responseCode
    action = null
    return false
}


function sendCode(code) {
    responseCode = code
    action()
}


function runScript() {
    let homeDir = StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().substring(7)
    let script = homeDir + "/.local/share/plasma/plasmoids/" + applet + "/contents/tools/_install.sh"
    let command = script + " " + homeDir + " " + applet

    sh.exec(command, (cmd, stdout, stderr, exitCode) => {
        if (catchError(exitCode, stderr, stdout)) return

        checkDependencies()
    })
}


function checkDependencies() {
    function check(packs) {
        return `for pgk in ${packs}; do command -v $pgk || echo; done`
    }

    function add(data) {
        let arr = []
        for (let i = 0; i < data.length; i++) {
            arr.push({'name': data[i].split('/').pop(), 'value': data[i]})
        }
        return arr
    }

    sh.exec(check(plasmoid.configuration.dependencies), (cmd, stdout, stderr, exitCode) => {
        if (catchError(exitCode, stderr, stdout)) return

        let out = stdout.split('\n')
        let packs = out.slice(0, 4)
        let wrappers = add(out.slice(4, 12).filter(Boolean))
        let terminals = add(out.slice(12).filter(Boolean))

        plasmoid.configuration.packages = packs
        plasmoid.configuration.wrappers = wrappers.length > 0 ? wrappers : null
        plasmoid.configuration.terminals = terminals.length > 0 ? terminals : null

        if (stop()) return

        timer.triggered()
    })
}


function defineCommands() {
    shell[0] = packages[0] + " -c"
    shell[1] = searchMode[0] ? packages[1] + " -Qu" : searchMode[1] ? packages[2] : searchMode[2] ? plasmoid.configuration.selectedWrapper + " -Qu" : null
    shell[2] = packages[1] + " -Sl"
    shell[3] = packages[3] + " remote-ls --app --updates"
    shell[4] = packages[3] + " list --app"
    shell[5] = searchMode[0] || searchMode[1] ? packages[1] + " -Sy" : shell[1].replace("Qu", "Sy")
    shell[6] = plasmoid.configuration.selectedTerminal
    shell[7] = "-e"
    shell[8] = plasmoid.configuration.wrapperUpgrade ? plasmoid.configuration.selectedWrapper + " -Syu" : "sudo " + packages[1] + " -Syu"
    shell[8] = plasmoid.configuration.upgradeFlags ? shell[8] + ' ' + plasmoid.configuration.upgradeFlagsText : shell[8]
    shell[9] = searchMode[3] ? packages[3] + " update" : "echo "
    shell[10] = "trap '' SIGINT"
    shell[11] = "echo Executed: " + shell[8] + "; echo"
}


function stop() {
    if (!packages[0]) {
        error = "Not Arch Linux!"
        return true
    }
    return false
}


function downloadDatabase() {
    if (stop()) return
    if (waitConnectionTimer(downloadDatabase)) return

    statusIco = 'download'
    statusMsg = 'Download fresh package databases...'

    sh.exec('pkexec ' + shell[5], (cmd, stdout, stderr, exitCode) => {
        if (exitCode == 127) {
            statusIco = count > 0 ? 'update-none' : ''
            statusMsg = count > 0 ? count + ' updates total are pending' : ''
            busy = false
            return
        } else {
            if (catchError(exitCode, stderr, stdout)) return
        }

        checkUpdates()
    })
}


function checkUpdates() {
    if (stop()) return
    if (waitConnectionTimer(checkUpdates)) return

    defineCommands()
    timer.restart()

    let updArch
    let infArch
    let updFlpk
    let infFlpk
    let command = shell[1]

    statusIco = 'package'
    statusMsg = searchMode[2] ? 'Searching AUR for updates...'
                              : 'Searching arch repositories for updates...'

    sh.exec(command, (cmd, stdout, stderr, exitCode) => {
        if (catchError(exitCode, stderr, stdout)) return
        updArch = stdout ? stdout : null
        command = updArch ? shell[2] : ''

        sh.exec(command, (cmd, stdout, stderr, exitCode) => {
            if (catchError(exitCode, stderr, stdout)) return
            infArch = stdout ? stdout : null
            command = searchMode[3] ? shell[3] : 'exit 0'
            statusIco = searchMode[3] ? 'flatpak-discover' : statusIco
            statusMsg = searchMode[3] ? 'Searching flathub for updates...' : statusMsg

            sh.exec(command, (cmd, stdout, stderr, exitCode) => {
                if (catchError(exitCode, stderr, stdout)) return
                updFlpk = stdout ? stdout : null
                command = updFlpk ? shell[4] : ''

                sh.exec(command, (cmd, stdout, stderr, exitCode) => {
                    if (catchError(exitCode, stderr, stdout)) return
                    infFlpk = stdout ? stdout : null

                    updArch = updArch ? makeArchList(updArch, infArch) : null
                    updFlpk = updFlpk ? makeFlpkList(updFlpk, infFlpk) : null

                    updArch && !updFlpk ? finalize(sortList(formatList(updArch))) :
                    !updArch && updFlpk ? finalize(sortList(formatList(updFlpk))) :
                    !updArch && !updFlpk ? finalize() :
                    finalize(sortList(formatList(updArch.concat(updFlpk))))
                })
            })
        })
    })
}


function makeArchList(upd, inf) {
    upd = upd.trim().split('\n')
    inf = inf.trim().split('\n')
    let out = ''

    for (let i = 0; i < upd.length; i++) {
        let pkg = upd[i]
        let name = pkg.split(' ')[0]
        let aur = true

        for (let j = 0; j < inf.length; j++)
            if (inf[j].includes(' ' + name + ' ')) {
                let repo = inf[j].split(' ')[0]
                out += repo + ' ' + pkg + '\n'
                aur = false
                break
            }

        if (aur)
            pkg.split(' ').pop() === 'latest-commit' ?
                out += 'devel ' + pkg + '\n' :
                out += 'aur ' + pkg + '\n'
    }

    return out
}


function makeFlpkList(upd, inf) {
    upd = upd.trim().replace(/ /g, '-').replace(/\t/g, ' ').split('\n')
    inf = inf.trim().replace(/ /g, '-').replace(/\t/g, ' ').split('\n')
    let out = ''

    upd.forEach(pkg => {
        let name = pkg.split(' ')[1]
        let vers = inf.find(line => line.includes(name)).split(' ')[2]
        out += `flathub ${pkg.replace(name, vers)}\n`
    })

    return out
}


function formatList(list) {
    return list
        .replace(/ ->/g, '')
        .trim()
        .toLowerCase()
        .split('\n')
        .map(str => {
            const col = str.split(' ');
            [col[0], col[1]] = [col[1], col[0]]
            return col.join(' ')
        })
}


function sortList(list) {
    return list.sort((a, b) => {
        const [nameA, repoA] = a.split(' ')
        const [nameB, repoB] = b.split(' ')

        return plasmoid.configuration.sortByName ? nameA.localeCompare(nameB)
                : ((repoA.includes('aur') || repoA.includes('devel'))
                    &&
                  !(repoB.includes('aur') || repoB.includes('devel')))
                    ? -1
                : (!(repoA.includes('aur') || repoA.includes('devel'))
                    &&
                  (repoB.includes('aur') || repoB.includes('devel')))
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

        let lines = ''
        for (let i = 0; i < newCount; i++) {
            let col = newList[i].split(' ')
            lines += col[0] + '  -> ' + col[3] + '\n'
        }

        notifyTitle = "+" + newCount + " new updates"
        notifyBody = lines
        notify.sendEvent()
    }

    if (prev === undefined && curr > 0 && plasmoid.configuration.notifyStartup) {
        notifyTitle = "Updates available"
        notifyBody = curr + " updates total are pending"
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
        let item = list[i].split(' ')
        listModel.append({
            'name': item[0],
            'repo': item[1],
            'curr': item[2],
            'newv': item[3]
        })
    }
}


function finalize(list) {
    lastCheck = new Date().toLocaleTimeString().slice(0, -7)

    if (!list) {
        count = 0
        updList = ['']
        statusIco = ''
        statusMsg = ''
        listModel.clear()
        busy = false
        return
    }

    refreshListModel(list)

    if (plasmoid.configuration.notifications) setNotify(list)

    count = list.length
    updList = list
    statusIco = 'update-none'
    statusMsg = count + ' updates total are pending'
    busy = false
}


function setIndex(value, arr) {
    let index = 0
    for (let i = 0; i < arr.length; i++) {
        if (arr[i]['value'] == value) {
            index = i
            break
        }
    }
    return index
}


function getFonts(defaultFont, fonts) {
    let arr = []
    arr.push({'name': 'Default system font', 'value': defaultFont})
    for (let i = 0; i < fonts.length; i++) {
        arr.push({'name': fonts[i], 'value': fonts[i]})
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


function upgradeSystem() {
    defineCommands()

    if (!shell[6]) return

    busy = true
    upgrade = true
    timer.stop()

    statusIco = 'accept_time_event'
    statusMsg = 'Full upgrade running...'

    let init = "Full system upgrade"
    let done = "Press Enter to close"

    let command = `${shell[6]} ${shell[7]} ${shell[0]} "${shell[10]}; ${print(init)}; ${shell[11]}; ${shell[8]}; ${shell[9]}; ${print(done)}; read"`

    sh.exec(command, (cmd, stdout, stderr, exitCode) => {
        if (catchError(exitCode, stderr, stdout)) return

        upgrade = false
        timer.triggered()
        timer.start()        
    })
}