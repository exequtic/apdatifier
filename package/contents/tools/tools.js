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
        debug('✖ Error - stopping function')
        error = err.trim().split('\n')[0]
        statusMsg = `✖ Exit code: ${code}`
        busy = false
        return true
    }
    return false
}


function checkDependencies() {
    debug(' ')
    debug('------------- Dependencies -----------')

    function check(packs) {
        return `for pgk in ${packs}; do command -v $pgk || echo; done`
    }

    function add(data) {
        let obj = []
        for (let i = 0; i < data.length; i++) {
            obj.push({'name': data[i].split('/').pop(), 'bin': data[i]})
        }
        return obj
    }

    sh.exec(check(plasmoid.configuration.dependencies), (cmd, stdout, stderr, exitCode) => {
        if (catchErr(exitCode, stderr)) return

        let out = stdout.trim().split('\n')
        let packs = out.slice(0, 3)
        let wrappers = add(out.slice(3, 11).filter(Boolean))

        plasmoid.configuration.packages = packs
        plasmoid.configuration.wrappers = wrappers.length > 0 ? wrappers : null

        commands[0] = searchMode[0] ? packages[0] + ' -Qu' :
                      searchMode[1] ? packages[1] :
                      searchMode[2] ? plasmoid.configuration.selectedWrapper + ' -Qu' : null

        commands[1] = packages[0] + ' -Sl'
        commands[2] = packages[2] + ' remote-ls --app --updates'
        commands[3] = packages[2] + ' list --app'

        timer.triggered()
    })
}


function checkUpdates() {
    debug('--------- Start checkUpdates ---------')
    statusMsg = 'Checking updates...'
    timer.restart()
    listModel.clear()
    busy = true
    error = null
    updCount = null

    let updArch
    let infArch
    let updFlpk
    let infFlpk
    let command = commands[0]

    statusMsg = searchMode[2] ? '➤ Searching AUR for updates...'
                              : '➤ Searching arch repositories for updates...'

    debug('➤ Arch: checking updates...')
    sh.exec(command, (cmd, stdout, stderr, exitCode) => {
        if (catchErr(exitCode, stderr)) return
        updArch = stdout ? stdout : null
        command = updArch ? commands[1] : ''

        sh.exec(command, (cmd, stdout, stderr, exitCode) => {
            if (catchErr(exitCode, stderr)) return
            infArch = stdout ? stdout : null
            command = searchMode[3] ? commands[2] : 'exit 0'
            statusMsg = searchMode[3] ? '➤ Searching flathub for updates...' : statusMsg

            sh.exec(command, (cmd, stdout, stderr, exitCode) => {
                if (catchErr(exitCode, stderr)) return
                updFlpk = stdout ? stdout : null
                command = updFlpk ? commands[3] : ''

                sh.exec(command, (cmd, stdout, stderr, exitCode) => {
                    if (catchErr(exitCode, stderr)) return
                    infFlpk = stdout ? stdout : null

                    updArch = updArch ? getArchList(updArch, infArch) : null
                    updFlpk = updFlpk ? getFlpkList(updFlpk, infFlpk) : null

                    updArch && !updFlpk ? sortList(formatList(updArch)) :
                    !updArch && updFlpk ? sortList(formatList(updFlpk)) :
                    !updArch && !updFlpk ? showListModel() :
                    sortList(formatList(updArch.concat(updFlpk)))
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
    showListModel(list.sort((a, b) => {
        const [nameA, repoA] = a.split(' ')
        const [nameB, repoB] = b.split(' ')

        return plasmoid.configuration.sortByName
            ? nameA.localeCompare(nameB)
            : ((repoA.includes('aur') || repoA.includes('devel')) &&
             !(repoB.includes('aur') || repoB.includes('devel')))
            ? -1
            : (!(repoA.includes('aur') || repoA.includes('devel')) &&
              (repoB.includes('aur') || repoB.includes('devel')))
            ? 1
            : repoA.localeCompare(repoB) || nameA.localeCompare(nameB)
    }))
}


function showListModel(list) {
    busy = false

    if (!list) {
        debug('✦ Updates not found')
        updCount = 0
        statusMsg = ''
        return
    }

    updList = list
    updCount = list.length
    statusMsg = '✦ Total updates pending: ' + updCount

    listModel.clear()

    for (var i = 0; i < updCount; i++) {
        listModel.append({'text': list[i]})
    }

    debug('✦ Total updates pending: ' + updCount)
}


function columnWidth(column, width) {
    switch (column) {
        case 0: return width * [0.40, 0.40, 0.65, 1.00, 0.80, 0.50][columns]
        case 1: return width * [0.10, 0.00, 0.00, 0.00, 0.20, 0.15][columns]
        case 2: return width * [0.25, 0.30, 0.00, 0.00, 0.00, 0.00][columns]
        case 3: return width * [0.25, 0.30, 0.35, 0.00, 0.00, 0.35][columns]
    }
}


function setIndexInit(cfg) {
    return cfg ? cfg : 0
}


function setIndex(bin, cfg) {
    for (let i = 0; i < cfg.length; i++) {
        return cfg[i]['bin'] == bin ? i : 0
    }
}
