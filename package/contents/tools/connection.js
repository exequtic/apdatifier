WorkerScript.onMessage = (message) => {
    let xhr = new XMLHttpRequest()
    xhr.open('GET', 'https://www.google.com', true)
    xhr.onreadystatechange = () => {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            WorkerScript.sendMessage({code: xhr.status})
        }
    }
    xhr.send()
}
