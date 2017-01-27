#!/usr/bin/env python

import os
import sys
import json


def read_conf(fname):
    if not os.path.isfile(fname):
        return {}

    with open(fname, 'r') as conf:
        return json.load(conf)


def build_qrc(resources):
    yield '<RCC>'
    yield '<qresource>'
    for d in resources:
        for root, dirs, files in os.walk(d):
            for f in files:
                yield '<file>{}</file>'.format(os.path.join(root, f))
    yield '</qresource>'
    yield '</RCC>'


def build_resources(resources, target):
    with open(target, 'w') as f:
        for line in build_qrc(resources):
            f.write(line + os.linesep)


def build(source):
    conf = read_conf(source)
    target = os.path.basename(source)
    if '.' in target:
        target = target.rsplit('.', 1)[0]
    target += '.qrc'
    build_resources(conf.get('resources', []), target)


if __name__ == '__main__':
    build(sys.argv[1] if len(sys.argv) >= 1 else 'resources.json')
