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

__all__ = ['parse_qr_codes']


def parse_qr_codes(image, min_res=2):
    size = image.size()
    bpp = image.bytesPerLine() / size.width()

    def data_to_line(data):
        buf = ''
        for segment in data:
            (_, color, width) = segment
            buf += color*width
        return buf

    def check_square_dir(data, x, y_start, y_inc=1):
        data = list_copy(data)
        refs = []  # row of pixels to match against from the middle going out.
        refs.append(data_to_line(data))  # Middle row:   1011101
        data[2][1] = data[1][1]
        refs.append(data_to_line(data))  # Inner border: 1000001
        data[1][1] = data[0][1]
        data[2][1] = data[0][1]
        data[3][1] = data[0][1]
        refs.append(data_to_line(data))  # Outer border: 1111111

        d_width = len(refs[0])
        y_end = -1 if y_inc < 0 else size.height()
        prev_line = ''
        for y in range(y_start, y_end, y_inc):
            line = image.scanLine(y)[x*bpp:x*bpp+d_width]
            if line != prev_line:
                if not refs:
                    return y - y_inc
                ref = refs.pop(0)
                if not ref == line:
                    return None
                prev_line = line
        # Reach image upper/lower bound, stop.
        return y if not refs else None

    def image_to_bitmap(box):
        (x, y, w, h) = box
        c = image.scanLine(y)[x*bpp:(x+1)*bpp]
        data = []
        for line_i in xrange(y, y+h):
            line_data = []
            line = image.scanLine(line_i)
            for pixel_i in xrange(x, x+w):
                pixel = line[pixel_i*bpp:(pixel_i+1)*bpp]
                line_data.append(1 if pixel == c else 0)
            data.append(line_data)
        return data

    def find_squares():
        found = set()
        for y in range(0, size.height(), min_res*3):
            line = image.scanLine(y)
            read = [[-1, None, 0]]
            for x in range(size.width()):
                color = line[x*bpp:(x+1)*bpp]
                if read[-1][1] == color:
                    read[-1][2] += 1
                else:  # Pixel does not match, check
                    if len(read) == 5:
                        color_p = zip(*read)[1]
                        c1, c2 = color_p[0], color_p[1]
                        lens = zip(*read)[2]
                        mid_len = lens[2]
                        max_other_len = max(lens[:2] + lens[3:])
                        if color_p == (c1, c2, c1, c2, c1) \
                                and mid_len >= min_res*3 \
                                and max_other_len <= (mid_len+1) / 2:
                            # We have a match, check for whole square
                            width = sum(zip(*read)[2])
                            up_check = check_square_dir(read, x-width, y-1, -1)
                            dn_check = check_square_dir(read, x-width, y+1, 1)
                            if up_check is not None and dn_check is not None:
                                height = dn_check - up_check + 1
                                found.add((x-width, up_check, height, width))
                        read.pop(0)
                    read.append([x, color, 1])
        return found

    found = find_squares()
    qrs = []
    for qr in identify_qrs(found):
        bitmap = image_to_bitmap(qr)
        qr_data = bitmap_to_data(bitmap)
        qrs.append(qr_data)
    return qrs


def list_copy(l):
    return [x[:] for x in l]


def bitmap_to_data(bitmap):
    data = bitmap
    for _ in range(2):
        new_data = []
        prevline = []
        for line in data:
            if line != prevline:
                new_data.append(line)
                prevline = line
        data = map(list, zip(*new_data))
    return data


def identify_qrs(boxes):
    qrs = []
    for box in boxes:
        for right in boxes:
            if box[0] != right[0] and box[1] == right[1] and box[3] == right[3]:
                for under in boxes:
                    if box[0] == under[0] and box[1] != under[1] \
                            and box[2] == under[2]:
                        qrs.append((
                            box[0],
                            box[1],
                            right[0]+right[2] - box[0],
                            under[1]+under[3] - box[1]))
    return qrs
