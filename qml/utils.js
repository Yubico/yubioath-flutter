function versionString(version) {
  return version.join('.')
}

function versionGE(version, major, minor, micro) {
  if(version != undefined) {
    return (version[0] > major || (version[0] == major && (version[1] > minor || (version[1] == minor && version[2] >= micro))))
  }
  return false
}
