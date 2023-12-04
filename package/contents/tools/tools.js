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

    if (typeof timestamp !== 'undefined') {
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


function checkDependencies() {
    debug(' ')
    debug('------------- Dependencies -----------')
    debug('Checking dependencies...')

    function check(pkgs) {
        return `for pgk in ${pkgs}; do command -v $pgk || echo; done`
    }

    function fill(out) {
        let obj = []
        for (let i = 0; i < out.length; i++) {
            obj.push({'name': out[i].split('/').pop(), 'bin': out[i]})
        }
        return obj
    }

    sh.exec(check(plasmoid.configuration.dependencies), function(cmd, stdout, stderr, exitCode) {
        if (catchErr(exitCode, stderr)) return

        let obj = stdout.trim().split('\n')

        plasmoid.configuration.depsBin = obj.slice(0, 3)

        let wrappers = fill(obj.slice(3, 11).filter(Boolean))
        plasmoid.configuration.wrappersBin = wrappers.length > 0 ? wrappers : null

        if(!plasmoid.configuration.searchCmd) {
            setBin()
        }

        timer.triggered()
    })
}


function checkUpdates() {
    debug(' ')
    debug('--------- Start checkUpdates ---------')

    timer.restart()
    updListModel.clear()
    let updListOut = ''
    busy = true
    error = null
    updCount = null

    debug(`✦ Arch: search command - ${plasmoid.configuration.searchCmd}`)
    debug(`✦ Arch: cache command - ${plasmoid.configuration.cacheCmd}`)

    debug('➤ Arch: checking updates...')
    sh.exec(plasmoid.configuration.searchCmd, function(cmd, stdout, stderr, exitCode) {
        if (catchErr(exitCode, stderr)) return

        let listArch = stdout ? stdout.trim().split('\n') : null

        function checkCache() {
            if (listArch) {
                debug('✦ Arch: updates found!')
                if (!cache) {
                    debug('➤ Arch: cache not found - creating cache...')
                    return plasmoid.configuration.cacheCmd
                } else {
                    debug('✦ Arch: cache found - skipping cache creation')
                    return 'exit 0'
                }
            } else {
                debug('✦ Arch: updates not found - skipping cache check')
                return 'exit 0'
            }
        }

        sh.exec(checkCache(), function(cmd, stdout, stderr, exitCode) {
            if (catchErr(exitCode, stderr)) return

            if (cmd !== 'exit 0') {
                debug('➤ Arch: saving cache...')
                cache = stdout ? stdout.trim().split('\n') : null
            } else {
                debug('✦ Arch: updates not found - skipping saving cache')
            }

            if (listArch) {
                debug('➤ Arch: searching repository names in cache...')
                for (let i = 0; i < listArch.length; i++) {
                    let pkg = listArch[i]
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

            if (!plasmoid.configuration.flatpakEnabled) {
                debug('✦ Flatpak: option disabled - skipping checking updates')

                makeList(updListOut)
            } else {
                debug('➤ Flatpak: option enabled - checking updates...')
                sh.exec('flatpak remote-ls --app --updates', function(cmd, stdout, stderr, exitCode) {
                    if (catchErr(exitCode, stderr)) return

                    let listFlatpak = stdout ? stdout : null

                    if(listFlatpak) {
                        debug('➤ Flatpak: updates found! - searching current versions')
                        sh.exec('flatpak list --app', function(cmd, stdout, stderr, exitCode) {
                            if (catchErr(exitCode, stderr)) return

                            let listFlatpakInfo = stdout ? stdout : null
                            let upd = listFlatpak.trim().replace(/ /g, '-').replace(/\t/g, ' ')
                            let inf = listFlatpakInfo.trim().replace(/ /g, '-').replace(/\t/g, ' ')
                            let pkg = ''

                            upd.split('\n').forEach(app => {
                                let name = app.split(' ')[1]
                                let vers = inf.split('\n').find(line => line.includes(name)).split(' ')[2]
                                pkg += `flathub ${app.replace(name, vers)}\n`
                            })
                            debug('➤ Concatenating Arch and Flatpak lists')
                            updListOut = updListOut.concat(pkg)

                            makeList(updListOut)
                        })
                    } else {
                        debug('✦ Flatpak: updates not found - skipping search current versions')
                    }
                })
            }
        })
    })
}


function makeList(out) {
    debug(' ')
    debug('----------- Start makeList -----------')
    busy = false

    if (!out) {
        updCount = 0
        debug('✦ Updates not found - interrupting function makeList')
        debug(' ')
        return
    }

    debug('➤ Formatting text...')

    if (out !== 'sort' ) {
        updListObj = out
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

    updListObj.sort((a, b) => {
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
}


function columnWidth(column, width) {
    switch (column) {
        case 0: return width * [0.40, 0.40, 0.65, 1.00, 0.80, 0.50][columnsMode]
        case 1: return width * [0.10, 0.00, 0.00, 0.00, 0.20, 0.15][columnsMode]
        case 2: return width * [0.25, 0.30, 0.00, 0.00, 0.00, 0.00][columnsMode]
        case 3: return width * [0.25, 0.30, 0.35, 0.00, 0.00, 0.35][columnsMode]
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


function setBin() {
    cache = null
    let deps = plasmoid.configuration.depsBin
    let wrapper = plasmoid.configuration.selectedWrapperBin

    if (deps === undefined) return

    function setArg(searchCmd, cacheCmd) {
        cacheCmd = `${cacheCmd} -Sl`
        searchCmd = !searchMode[0] && !searchMode[1] ?
                    searchCmd : `${searchCmd} -Qu`
    
        plasmoid.configuration.cacheCmd = cacheCmd
        plasmoid.configuration.searchCmd = searchCmd
    }

    searchMode[0] && !searchMode[1] ? setArg(deps[0], deps[0]) :
    !searchMode[0] && searchMode[1] ? setArg(wrapper, wrapper) :
    !searchMode[0] && !searchMode[1] ? setArg(deps[1], deps[0]) :
    null

    checkUpdates()
}