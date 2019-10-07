function getNow() {
    // Use seconds since epoch, because
    // that is what we get from the python layer.
    return Math.floor(Date.now() / 1000)
}

/*
 * Returns a hash code for a string.
 * (Compatible to Java's String.hashCode())
 *  See: https://gist.github.com/hyamamoto/fd435505d29ebfa3d9716fd2be8d42f0
 */
function hashCode(s) {
  var h = 0, l = s.length, i = 0;
  if ( l > 0 )
    while (i < l)
      h = (h << 5) - h + s.charCodeAt(i++) | 0;
  return h;
}
