#/bin/env python 

import os
from subprocess import check_output

OTOOL = "otool"
INT = "install_name_tool"
BASE = "@executable_path/../Frameworks/"


REPLACEMENTS = {
    'libjson-c.2.dylib': 'libjson-c.dylib',
    'libjson.0.dylib': 'libjson.dylib',
    'libhidapi.0.dylib': 'libhidapi.dylib',
    'libu2f-host.0.dylib': 'libu2f-host.dylib',
    'libykpers-1.1.dylib': 'libykpers-1.dylib',
    'libyubikey.0.dylib': 'libyubikey.dylib'
}


def relink(dylib, local=[]):
    # Fix ID
    replacement = REPLACEMENTS.get(dylib, dylib)
    check_output([INT, '-id', BASE+replacement, dylib])

    # Relink local dylibs.
    out = check_output([OTOOL, '-L', dylib])
    for line in out.splitlines()[2:]:
        for l in local:
            l_rep = REPLACEMENTS.get(l, l)
            if l in line or l_rep in line:
                line = line.strip().split()[0]
                check_output([INT, '-change', line, BASE+l_rep, dylib])


def main():
    dylibs = [f for f in os.listdir('.') if f.endswith('.dylib')]
    hits = REPLACEMENTS.keys() + dylibs
    for lib in dylibs:
        print(lib)
        relink(lib, hits)


if __name__ == '__main__':
    main()
