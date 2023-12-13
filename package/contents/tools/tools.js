const debugging = true

let timestamp
function debug(msg) {
    if (!debugging) return

    const date = new Date()
    const hms = date.toLocaleTimeString().slice(3, -4)
    const ms = date.getMilliseconds().toString().padStart(3, '0')
    let passed = ''

    if (typeof timestamp !== 'undefined') {
        const currTimestamp = date.getTime()
        const timeDiff = currTimestamp - timestamp
        const secDiff = Math.floor(timeDiff / 1000)
        const msDiff = timeDiff % 1000
        passed = `+${secDiff.toString().padStart(2, '0')}:${msDiff.toString().padStart(3, '0')} ↗`
        passed = passed === '+00:000 ↗' ? '         ' : passed
        timestamp = currTimestamp
    } else {
        timestamp = date.getTime()
    }

    console.log(`[${hms}:${ms}] ${passed}  ${msg}`)
}


function catchErr(code, err) {
    if (err) {
        error = err.trim().split('\n')[0]
        debug("ExitCode " + code + ': ' + error)
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

    let homeDir = StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().substring(7)
    let script = homeDir + "/.local/share/plasma/plasmoids/" + applet + "/contents/tools/_install.sh"
    let command = script + " " + homeDir + " " + applet

    sh.exec(command, (cmd, stdout, stderr, exitCode) => {
        if (catchErr(exitCode, stderr)) return

        sh.exec(check(plasmoid.configuration.dependencies), (cmd, stdout, stderr, exitCode) => {
            if (catchErr(exitCode, stderr)) return

            let out = stdout.split('\n')
            let packs = out.slice(0, 3)
            let wrappers = add(out.slice(3, 11).filter(Boolean))
            let terminals = add(out.slice(11).filter(Boolean))

            plasmoid.configuration.packages = packs
            plasmoid.configuration.wrappers = wrappers.length > 0 ? wrappers : null
            plasmoid.configuration.terminals = terminals.length > 0 ? terminals : null

            if (stop()) return

            commands[0] = searchMode[0] ? packages[0] + ' -Qu' :
                          searchMode[1] ? packages[1] :
                          searchMode[2] ? plasmoid.configuration.selectedWrapper + ' -Qu' : null
            commands[1] = packages[0] + ' -Sl'
            commands[2] = packages[2] + ' remote-ls --app --updates'
            commands[3] = packages[2] + ' list --app'
            commands[4] = searchMode[0] || searchMode[1]
                                        ? packages[0] + ' -Sy'
                                        : commands[0].replace('Qu', 'Sy')

            timer.triggered()
        })
    })
}


function stop() {
    if (!packages[0]) {
        error = "Not Arch Linux!"
        return true
    }
    return false
}


function refreshDatabase() {
    if (stop()) return

    listModel.clear()
    busy = true

    if (waitConnectionTimer(refreshDatabase)) return

    statusIco = 'download'
    statusMsg = 'Download fresh package databases...'

    sh.exec('pkexec ' + commands[4], (cmd, stdout, stderr, exitCode) => {
        if (exitCode == 127) {
            showListModel(updList)
            return
        }

        checkUpdates()
    })
}


function checkUpdates() {
    if (stop()) return

    timer.restart()
    listModel.clear()
    busy = true
    error = null

    if (waitConnectionTimer(checkUpdates)) return

    let updArch
    let infArch
    let updFlpk
    let infFlpk
    let command = commands[0]

    statusIco = 'package'
    statusMsg = searchMode[2] ? 'Searching AUR for updates...'
                              : 'Searching arch repositories for updates...'

    sh.exec(command, (cmd, stdout, stderr, exitCode) => {
        if (catchErr(exitCode, stderr)) return
        updArch = stdout ? stdout : null
        command = updArch ? commands[1] : ''

        sh.exec(command, (cmd, stdout, stderr, exitCode) => {
            if (catchErr(exitCode, stderr)) return
            infArch = stdout ? stdout : null
            command = searchMode[3] ? commands[2] : 'exit 0'
            statusIco = searchMode[3] ? 'flatpak-discover' : statusIco
            statusMsg = searchMode[3] ? 'Searching flathub for updates...' : statusMsg

            sh.exec(command, (cmd, stdout, stderr, exitCode) => {
                if (catchErr(exitCode, stderr)) return
                updFlpk = stdout ? stdout : null
                command = updFlpk ? commands[3] : ''

                sh.exec(command, (cmd, stdout, stderr, exitCode) => {
                    if (catchErr(exitCode, stderr)) return
                    infFlpk = stdout ? stdout : null

                    updArch = updArch ? getArchList(updArch, infArch) : null
                    updFlpk = updFlpk ? getFlpkList(updFlpk, infFlpk) : null

                    updArch && !updFlpk ? showListModel(sortList(formatList(updArch))) :
                    !updArch && updFlpk ? showListModel(sortList(formatList(updFlpk))) :
                    !updArch && !updFlpk ? showListModel() :
                    showListModel(sortList(formatList(updArch.concat(updFlpk))))

                    lastCheck = new Date().toLocaleTimeString().slice(0, -7)
                })
            })
        })
    })
}


function getArchList(upd, inf) {
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


function getFlpkList(upd, inf) {
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

        return sorting
            ? nameA.localeCompare(nameB)
            : ((repoA.includes('aur') || repoA.includes('devel')) &&
             !(repoB.includes('aur') || repoB.includes('devel')))
            ? -1
            : (!(repoA.includes('aur') || repoA.includes('devel')) &&
              (repoB.includes('aur') || repoB.includes('devel')))
            ? 1
            : repoA.localeCompare(repoB) || nameA.localeCompare(nameB)
    })
}


function applySort() {
    if (updList.length == 0) return

    let sorted = sortList(updList)

    listModel.clear()

    for (var i = 0; i < count; i++) {
        listModel.append({'text': sorted[i]})
    }
}


function setNotify(list) {
    let prev = count
    let curr = list.length

    if (prev && prev < curr) {
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

    if (!prev && curr > 0 && plasmoid.configuration.notifyStartup) {
        notifyTitle = "Updates avialable"
        notifyBody = curr + " total updates pending"
        notify.sendEvent()
    }
}


function showListModel(list) {
    if (!list) {
        count = 0
        statusIco = ''
        statusMsg = ''
        busy = false
        return
    }

    listModel.clear()

    for (var i = 0; i < list.length; i++) {
        listModel.append({'text': list[i]})
    }

    if (plasmoid.configuration.notifications) setNotify(list)

    updList = list
    count = list.length
    statusIco = 'update-none'
    statusMsg = 'Total updates pending: ' + count
    busy = false
}


function columnWidth(column, width) {
    switch (column) {
        case 0: return width * [0.40, 0.40, 0.65, 1.00, 0.80, 0.50][columns]
        case 1: return width * [0.10, 0.00, 0.00, 0.00, 0.20, 0.15][columns]
        case 2: return width * [0.25, 0.30, 0.00, 0.00, 0.00, 0.00][columns]
        case 3: return width * [0.25, 0.30, 0.35, 0.00, 0.00, 0.35][columns]
    }
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

function upgradeSystem() {
    let trap = "trap exit INT"
    let term = plasmoid.configuration.selectedTerminal
    let termArg = "-e"
    let cmdArg = " -Syu"
    let archCmd = plasmoid.configuration.wrapperUpgrade
                    ? plasmoid.configuration.selectedWrapper + cmdArg
                    : "sudo " + packages[0] + cmdArg

    let flpkCmd = searchMode[3] ? "flatpak update" : "echo "

    let line = "::::::::::::::::::::::::::::::::::::::::"
    let initMsg = `echo ${line}
                   echo :::::::::: Full system upgrade :::::::::
                   echo ${line}; echo
                   echo Executed: ${archCmd}; echo`

    let doneMsg = `echo; echo ${line}
                   echo ::::::::: Press Enter to close :::::::::
                   echo ${line}
                   read`

    let command = `${term} ${termArg} sh -c "${initMsg}; ${trap}; ${archCmd}; ${flpkCmd}; ${doneMsg}"`

    sh.exec(command, (cmd, stdout, stderr, exitCode) => {
        if (catchErr(exitCode, stderr)) return
    })
}