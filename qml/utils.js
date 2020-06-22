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

/**
 * Add `value` to `arr` if `arr` does not already include `value`.
 *
 * @param arr an array
 * @param value a value to add to `arr` if not already present
 *
 * @return a new array that is the union of `arr` and `[value]` - unless `arr`
 * already includes `value`, in which case `arr` is returned unchanged.
 */
function including(arr, value) {
    if (arr.includes(value)) {
        return arr;
    } else {
        return arr.concat(value);
    }
}

/**
 * Remove `value` from `arr`.
 *
 * @param arr an array
 * @param value a value to remove from `arr`
 *
 * @return a new array that contains each element `e` of `arr` such that `e !==
 * value`.
 */
function without(arr, value) {
    return arr.filter(function(item) { return item !== value; });
}
