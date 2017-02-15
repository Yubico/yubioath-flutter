"""
Given an image, locates and parses the pixel data in QR codes.
"""

from __future__ import division
from collections import namedtuple


__all__ = ['parse_qr_codes']


Box = namedtuple('Box', ['x', 'y', 'w', 'h'])


def is_dark(pixel):
    return pixel == 1


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


def check_row(line, x_offs, x_width):
    return check_line(line[x_offs:x_offs+x_width])


def check_col(image, x, y_offs, y_height):
    return check_line(bytes([image.get_line(i)[x]
                       for i in range(y_offs, y_offs + y_height)]))


def read_line(line, x_offs, x_width):
    matching_dark = not is_dark(line[x_offs])
    matched = []
    for x in range(x_offs, x_offs + x_width):
        pixel = line[x]
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


def read_bits(image, img_x, img_y, img_w, img_h, size):
    qr_x_w = img_w / size
    qr_y_h = img_h / size
    qr_data = []
    for qr_y in range(size):
        y = img_y + int(qr_y_h / 2 + qr_y * qr_y_h)
        img_line = image.get_line(y)
        qr_line = []
        for qr_x in range(size):
            x = img_x + int(qr_x_w / 2 + qr_x * qr_x_w)
            qr_line.append(is_dark(img_line[x]))
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
    finders = locate_finders(image, min_res)

    # Arrange finders into QR codes and extract data
    for (tl, tr, bl) in identify_groups(finders):
        min_x = min(tl.x, bl.x)
        min_y = min(tl.y, tr.y)
        width = tr.x + tr.w - min_x
        height = bl.y + bl.h - min_y

        # Determine resolution by reading timing pattern
        line = image.get_line(min_y + int(6.5 / 7 * max(tl.h, tr.h)))
        _, line_data = read_line(line, min_x, width)
        size = len(line_data) + 12

        # Read QR code data
        yield read_bits(image, min_x, min_y, width, height, size)


def locate_finders(image, min_res):
    finders = set()
    for y in range(0, image.height, min_res * 3):
        for (x, w) in check_row(image.get_line(y), 0, image.width):
            x_offs = x + w // 2
            y_offs = max(0, y - w)
            y_height = min(image.height - y_offs, 2 * w)
            match = next(check_col(image, x_offs, y_offs, y_height), None)
            if match:
                (pos, h) = match
                y2 = y_offs + pos
                if read_bits(image, x, y2, w, h, 7) == FINDER:
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
