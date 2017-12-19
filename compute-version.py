#!/usr/bin/python3
# Compute version number from Git tags in current working directory
#
# - If the current commit has a tag starting with "yubioath-desktop-":
#   - The rest of that tag is the version number.
#   - If this version number has only two parts (X.Y), append ".0".
#
# - If the current commit does not have a tag:
#   - Find the closest ancestor commit with a tag starting with
#     "yubioath-desktop-", and use the rest of the tag as the version number.
#     - If this version number has three parts ending with zero (X.Y.0), remove
#       the ".0".
#   - Append ".Z-gCOMMIT", where Z is the number of commits since the tagged
#     ancestor commit and COMMIT is the short commit ID of the current commit
#   - This will always be different from the latest tagged version number, and
#     will always be a prerelease version because of the "-gCOMMIT" suffix
#
# - Finally, if the repository has uncommitted or untracked changes, append
#   "-dirty".
# - For the VERSIONINFO in the Windows resource file, reformat the version
#   number "X.Y.Z[-gCOMMIT][-dirty]" to 4 numeric parts:
#   - Discard the "-gCOMMIT" and "-dirty" suffixes if present
#   - If the "-dirty" suffix was present, append ".0".
#   - If the "-dirty" suffix was not present, append ".1".

import argparse
import os
import re
import subprocess
import sys


def promote_commit_distance_to_patch_version(version):
    '''If version starts with `X.Y-Z-g*`, and X, Y and Z are numeric, reformat
    it to `X.Y.Z-g*`'''
    return re.sub(
        r'^([0-9]+\.[0-9]+)-([0-9]+)(-g.*)$', r'\1.\2\3',
        version
    )


def replace_zero_patch_version_with_commit_distance(version):
    '''If version starts with `X.Y.0-Z-g*`, and X, Y and Z are numeric,
    reformat it to `X.Y.Z-g*`'''
    return re.sub(
        r'^([0-9]+\.[0-9]+)\.0-([0-9]+)(-g.*)$', r'\1.\2\3',
        version
    )


def append_missing_patch_version(version):
    '''If version is plain `X.Y`, append `.0`'''
    return re.sub(
        r'^([0-9]+\.[0-9]+)(-dirty)?$', r'\1.0\2',
        version
    )


def prepend_zero_version_to_raw_commit_id(version):
    '''If version is raw abbreviated commit ID, prepend `0.0.0-`'''
    return re.sub(
        r'^([0-9a-f]{7}(-dirty)?)$', r'0.0.0-\1',
        version
    )


def compute_version(tag_prefix=None):
    git_result = subprocess.run(
        ['git', 'describe',
            '--tags',
            '--dirty=-dirty',
            '--always',
         ] + (
           ['--match=%s*' % tag_prefix] if tag_prefix else []
         ),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True
    )

    if git_result.returncode is not 0:
        raise ChildProcessError(git_result.stderr)

    git_version = git_result.stdout.strip()

    if tag_prefix:
        # Remove tag prefix
        git_version = re.sub(r'^' + tag_prefix, '', git_version)

    git_version = prepend_zero_version_to_raw_commit_id(git_version)

    return git_version


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Compute version number from Git tags',
        add_help=True
    )
    parser.add_argument('-f', '--version-file',
                        action='store', dest='version_file',
                        help='Read version from VERSION_FILE if it exists')
    parser.add_argument('tag_prefix',
                        action='store',
                        help='Prefix for git tags eligible as version tags')
    args = parser.parse_args()

    if args.version_file is not None and os.path.isfile(args.version_file):
        with open(args.version_file) as f:
            sys.stdout.write(f.read())
    else:
        print(compute_version(tag_prefix=args.tag_prefix))
