function getNow() {
    // Use seconds since epoch, because
    // that is what we get from the python layer.
    return Math.floor(Date.now() / 1000)
}
