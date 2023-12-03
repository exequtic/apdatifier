const debugging = true

let timestamp
function debug(msg) {
    if(!debugging) {
        return
    }

    const date = new Date()
    const hms = date.toLocaleTimeString().slice(3, -4)
    const ms = date.getMilliseconds().toString().padStart(3, '0')
    let pass = ''

    if (typeof timestamp !== "undefined") {
        const currTimestamp = date.getTime()
        const timeDiff = currTimestamp - timestamp
        const secDiff = Math.floor(timeDiff / 1000)
        const msDiff = timeDiff % 1000
        pass = `+${secDiff.toString().padStart(2, '0')}:${msDiff.toString().padStart(3, '0')} ↗`
        pass = pass === '+00:000 ↗' ? '         ' : pass
        timestamp = currTimestamp
    } else {
        timestamp = date.getTime()
    }

    console.log(`[${hms}:${ms}] ${pass}  ${msg}`)
}


function catchErr(code, err) {
    if (err) {
        debug('✖ Error - stopping function')
        error = `[ExitCode: ${code}] ${err.trim().split('\n')[0]}`
        busy = false
        return true
    }
    return false
}


function checkUpdates() {
    debug(' ')
    debug('--------- Start checkUpdates ---------')

    timer.restart()
    updListModel.clear()
    updListOut = ''
    busy = true
    error = null
    updCount = null

    let listArchUpdate
    let listFlatpakUpdate
    let listFlatpakInfo


    debug('➤ Arch: checking updates...')
    sh.exec('yay -Qu', function(cmd, stdout, stderr, exitCode) {
        if (catchErr(exitCode, stderr)) {
            return
        }

        listArchUpdate = stdout ? stdout.split('\n') : null

        function checkListAll() {
            if (listArchUpdate) {
                debug('✦ Arch: updates found!')
                if (!cache) {
                    debug('➤ Arch: cache not found - creating cache...')
                    return 'yay -Sl'
                } else {
                    debug('✦ Arch: cache found - skipping cache creation')
                    return ''
                }
            } else {
                debug('✦ Arch: updates not found - skipping cache check')
                return ''
            }
        }

        sh.exec(checkListAll(), function(cmd, stdout, stderr, exitCode) {
            if (catchErr(exitCode, stderr)) {
                return
            }

            if (cmd == 'yay -Sl') {
                debug('➤ Arch: saving cache...')
                cache = stdout ? stdout.split('\n') : null
            } else {
                debug('✦ Arch: updates not found - skipping saving cache')
            }

            if (listArchUpdate) {
                debug('➤ Arch: searching repository names in cache...')
                for (let i = 0; i < listArchUpdate.length; i++) {
                    let pkg = listArchUpdate[i]
                    let name = pkg.split(' ')[0]
            
                    for (let j = 0; j < cache.length; j++) {
                        let line = cache[j]
                        if (line.includes(' ' + name + ' ')) {
                            let repo = line.split(' ')[0]
                            updListOut += repo + ' ' + pkg + '\n'
                            break
                        }
                    }
                }
            } else {
                debug('✦ Arch: updates not found - skipping search repository names')
            }

            if (!flatpak) {
                debug('✦ Flatpak: option disabled - skipping checking updates')

                makeList()
            } else {
                debug('➤ Flatpak: option enabled - checking updates...')
                sh.exec('flatpak remote-ls --app --updates', function(cmd, stdout, stderr, exitCode) {
                    if (catchErr(exitCode, stderr)) {
                        return
                    }

                    listFlatpakUpdate = stdout ? stdout : null

                    if(listFlatpakUpdate) {
                        debug('➤ Flatpak: updates found! - searching current versions')
                        sh.exec('flatpak list --app', function(cmd, stdout, stderr, exitCode) {
                            if (catchErr(exitCode, stderr)) {
                                return
                            }

                            listFlatpakInfo = stdout ? stdout : null

                            let upd = listFlatpakUpdate.trim().replace(/ /g, '-').replace(/\t/g, ' ')
                            let inf = listFlatpakInfo.trim().replace(/ /g, '-').replace(/\t/g, ' ')
                            let pkg

                            upd.split('\n').forEach(app => {
                                let name = app.split(' ')[1]
                                let vers = inf.split('\n').find(line => line.includes(name)).split(' ')[2]
                                pkg += `flathub ${app.replace(name, vers)}\n`
                            })
                            debug('➤ Concatenating Arch and Flatpak lists')
                            updListOut = updListOut.concat(pkg)

                            makeList()
                        })
                    } else {
                        debug('✦ Flatpak: updates not found - skipping search current versions')
                    }
                })
            }
        })
    })
}


function makeList() {
    debug(' ')
    debug('----------- Start makeList -----------')
    busy = false

    if (!updListOut) {
        updCount = 0
        debug('✦ Updates not found - interrupting function makeList')
        debug(' ')
        debug('----------------- End ----------------')
        return
    }

    debug('➤ Formatting text...')

    updListObj = updListOut
        .replace(/ ->/g, '')
        .trim()
        .toLowerCase()
        .split('\n')
        .map(str => {
            const col = str.split(' ');
            [col[0], col[1]] = [col[1], col[0]]
            return col.join(' ')
        })
        .sort((a, b) => {
            const [nameA, repoA] = a.split(' ');
            const [nameB, repoB] = b.split(' ');
            return sortingMode == 0 ?
                nameA.localeCompare(nameB) :
                repoA.localeCompare(repoB) || nameA.localeCompare(nameB)
        })

    updCount = updListObj.length

    updListModel.clear()

    debug('➤ Writing formatted text in model...')
    for (var i = 0; i < updCount; i++) {
        updListModel.append({'text': updListObj[i]})
    }
    
    debug(' ')
    debug('----------------- End ----------------')
}


function columnWidth(column, width) {
    switch (column) {
        case 0: return width * [0.40, 0.40, 0.65, 1.00, 0.80, 0.50][columnsMode]
        case 1: return width * [0.10, 0.00, 0.00, 0.00, 0.20, 0.15][columnsMode]
        case 2: return width * [0.25, 0.30, 0.00, 0.00, 0.00, 0.00][columnsMode]
        case 3: return width * [0.25, 0.30, 0.35, 0.00, 0.00, 0.35][columnsMode]
    }
}