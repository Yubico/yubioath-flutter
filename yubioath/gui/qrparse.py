# Copyright (c) 2014 Yubico AB
# All rights reserved.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# Additional permission under GNU GPL version 3 section 7
#
# If you modify this program, or any covered work, by linking or
# combining it with the OpenSSL project's OpenSSL library (or a
# modified version of that library), containing parts covered by the
# terms of the OpenSSL or SSLeay licenses, We grant you additional
# permission to convey the resulting work. Corresponding Source for a
# non-source form of such a combination shall include the source code
# for the parts of OpenSSL used as well as that of the covered work.

"""
Given an image, locates and parses the pixel data in QR codes.
"""

from __future__ import division
from yubioath.yubicommon.compat import byte2int
from collections import namedtuple


__all__ = ['parse_qr_codes']


Box = namedtuple('Box', ['x', 'y', 'w', 'h'])


def is_dark(color):  # If any R, G, or B value is < 200 we consider it dark.
    return any(byte2int(c) < 200 for c in color)


def buffer_matches(matched):
    return len(matched) == 5 \
        and max(matched[:2] + matched[3:]) <= matched[2] // 2 \
        and min(matched[:2] + matched[3:]) >= matched[2] // 6


def check_line(pixels):
    matching_dark = False
    matched = [0, 0, 0, 0, 0]
    for (i, pixel) in enumerate(pixels):
        if is_dark(pixel):  # Dark pixel
            if matching_dark:
                matched[-1] += 1
            else:
                matched = matched[1:] + [1]
                matching_dark = True
        else:  # Light pixel
            if not matching_dark:
                matched[-1] += 1
            else:
                if buffer_matches(matched):
                    width = sum(matched)
                    yield i - width, width
                matched = matched[1:] + [1]
                matching_dark = False

    # Check final state of buffer
    if matching_dark and buffer_matches(matched):
        width = sum(matched)
        yield i - width, width


def check_row(line, bpp, x_offs, x_width):
    return check_line([line[i*bpp:(i+1)*bpp]
                       for i in range(x_offs, x_offs + x_width)])


def check_col(image, bpp, x, y_offs, y_height):
    return check_line([image.scanLine(i)[x*bpp:(x+1)*bpp]
                       for i in range(y_offs, y_offs + y_height)])


def read_line(line, bpp, x_offs, x_width):
    matching_dark = not is_dark(line[x_offs*bpp:(x_offs+1)*bpp])
    matched = []
    for x in range(x_offs, x_offs + x_width):
        pixel = line[x*bpp:(x+1)*bpp]
        if is_dark(pixel):  # Dark pixel
            if matching_dark:
                matched[-1] += 1
            else:
                matched.append(1)
                matching_dark = True
        else:  # Light pixel
            if not matching_dark:
                matched[-1] += 1
            else:
                matched.append(1)
                matching_dark = False
    return matching_dark, matched


def read_bits(image, bpp, img_x, img_y, img_w, img_h, size):
    qr_x_w = img_w / size
    qr_y_h = img_h / size
    qr_data = []
    for qr_y in range(size):
        y = img_y + int(qr_y_h / 2 + qr_y * qr_y_h)
        img_line = image.scanLine(y)
        qr_line = []
        for qr_x in range(size):
            x = img_x + int(qr_x_w / 2 + qr_x * qr_x_w)
            qr_line.append(is_dark(img_line[x * bpp:(x+1) * bpp]))
        qr_data.append(qr_line)
    return qr_data


FINDER = [
    [True, True, True, True, True, True, True],
    [True, False, False, False, False, False, True],
    [True, False, True, True, True, False, True],
    [True, False, True, True, True, False, True],
    [True, False, True, True, True, False, True],
    [True, False, False, False, False, False, True],
    [True, True, True, True, True, True, True]
]


def parse_qr_codes(image, min_res=2):
    size = image.size()
    bpp = image.bytesPerLine() // size.width()

    finders = locate_finders(image, min_res)

    # Arrange finders into QR codes and extract data
    for (tl, tr, bl) in identify_groups(finders):
        min_x = min(tl.x, bl.x)
        min_y = min(tl.y, tr.y)
        width = tr.x + tr.w - min_x
        height = bl.y + bl.h - min_y

        # Determine resolution by reading timing pattern
        line = image.scanLine(min_y + int(6.5 / 7 * max(tl.h, tr.h)))
        _, line_data = read_line(line, bpp, min_x, width)
        size = len(line_data) + 12

        # Read QR code data
        yield read_bits(image, bpp, min_x, min_y, width, height, size)


def locate_finders(image, min_res):
    size = image.size()
    bpp = image.bytesPerLine() // size.width()
    finders = set()
    for y in range(0, size.height(), min_res * 3):
        for (x, w) in check_row(image.scanLine(y), bpp, 0, size.width()):
            x_offs = x + w // 2
            y_offs = max(0, y - w)
            y_height = min(size.height() - y_offs, 2 * w)
            match = next(check_col(image, bpp, x_offs, y_offs, y_height), None)
            if match:
                (pos, h) = match
                y2 = y_offs + pos
                if read_bits(image, bpp, x, y2, w, h, 7) == FINDER:
                    finders.add(Box(x, y2, w, h))
    return list(finders)


def identify_groups(locators):
    # Find top left
    for tl in locators:
        x_tol = tl.w / 14
        y_tol = tl.h / 14

        # Find top right
        for tr in locators:
            if tr.x > tl.x and abs(tl.y - tr.y) <= y_tol:

                # Find bottom left
                for bl in locators:
                    if bl.y > tl.y and abs(tl.x - bl.x) <= x_tol:
                        yield tl, tr, bl
