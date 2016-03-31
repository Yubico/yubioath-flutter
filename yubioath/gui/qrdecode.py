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
Given a 2D matrix of pixel data from a QR code, this module will decode and
return the data contained within. Note that error correction is not implemented,
and the input will thus have to be without any errors. Only supports numeric,
alphanumeric and byte encodings.
"""

from __future__ import division

__all__ = ['decode_qr_data']


def decode_qr_data(qr_data):
    """Given a 2D matrix of QR data, returns the encoded string"""
    size = len(qr_data)
    version = (size - 17) // 4
    level = bits_to_int(qr_data[8][:2])
    mask = bits_to_int(qr_data[8][2:5]) ^ 0b101

    read_mask = [x[:] for x in [[1]*size]*size]

    # Verify/Remove alignment patterns
    remove_locator_patterns(qr_data, read_mask)
    remove_alignment_patterns(read_mask, version)
    remove_timing_patterns(read_mask)

    if version >= 7:  # QR Codes version 7 or larger have version info.
        remove_version_info(read_mask)

    # Read and deinterleave
    buf = bits_to_bytes(read_bits(qr_data, read_mask, mask))
    buf = deinterleave(buf, INTERLEAVE_PARAMS[version][level])
    bits = bytes_to_bits(buf)

    # Decode data
    buf = ''
    while bits:
        data, bits = parse_bits(bits, version)
        buf += data
    return buf


LOCATOR_BOX = [
    [1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 1, 0, 1],
    [1, 0, 1, 1, 1, 0, 1],
    [1, 0, 1, 1, 1, 0, 1],
    [1, 0, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1, 1]
]

MASKS = [
    lambda x, y: (y+x) % 2 == 0,
    lambda x, y: y % 2 == 0,
    lambda x, y: x % 3 == 0,
    lambda x, y: (y+x) % 3 == 0,
    lambda x, y: (y/2 + x/3) % 2 == 0,
    lambda x, y: (y*x) % 2 + (y*x) % 3 == 0,
    lambda x, y: ((y*x) % 2 + (y*x) % 3) % 2 == 0,
    lambda x, y: ((y+x) % 2 + (y*x) % 3) % 2 == 0
]

ALPHANUM = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:'

EC_LEVELS = ['H', 'Q', 'M', 'L']

INTERLEAVE_PARAMS = [  # From ISO/IEC 18004:2006
    [],  #  H,         Q,         M,         L
    [1 * (9,), 1 * (13,), 1 * (16,), 1 * (19,)],  # Version 1
    [1 * (16,), 1 * (22,), 1 * (28,), 1 * (34,)],
    [2 * (13,), 2 * (17,), 1 * (44,), 1 * (55,)],
    [4 * (9,), 2 * (24,), 2 * (32,), 1 * (80,)],
    [2 * (11,) + 2 * (12,), 2 * (15,) + 2 * (16,), 2 * (43,), 1 * (108,)],
    [4 * (15,), 4 * (19,), 4 * (27,), 2 * (68,)],
    [4 * (13,) + 1 * (14,), 2 * (14,) + 4 * (15,), 4 * (31,), 2 * (78,)],
    [4 * (14,) + 2 * (15,), 4 * (18,) + 2 * (19,), 2 * (38,) + 2 * (39,), 2 * (97,)],
    [4 * (12,) + 4 * (13,), 4 * (16,) + 4 * (17,), 3 * (36,) + 2 * (37,), 2 * (116,)],
    [6 * (15,) + 2 * (16,), 6 * (19,) + 2 * (20,), 4 * (43,) + 1 * (44,), 2 * (68,) + 2 * (69,)],
    [3 * (12,) + 8 * (13,), 4 * (22,) + 4 * (23,), 1 * (50,) + 4 * (51,), 4 * (81,)],
    [7 * (14,) + 4 * (15,), 4 * (20,) + 6 * (21,), 6 * (36,) + 2 * (37,), 2 * (92,) + 2 * (93,)],
    [12 * (11,) + 4 * (12,), 8 * (20,) + 4 * (21,), 8 * (37,) + 1 * (38,), 4 * (107,)],
    [11 * (12,) + 5 * (13,), 11 * (16,) + 5 * (17,), 4 * (40,) + 5 * (41,), 3 * (115,) + 1 * (116,)],
    [11 * (12,) + 7 * (13,), 5 * (24,) + 7 * (25,), 5 * (41,) + 5 * (42,), 5 * (87,) + 1 * (88,)],
    [3 * (15,) + 13 * (16,), 15 * (19,) + 2 * (20,), 7 * (45,) + 3 * (46,), 5 * (98,) + 1 * (99,)],
    [2 * (14,) + 17 * (15,), 1 * (22,) + 15 * (23,), 10 * (46,) + 1 * (47,), 1 * (107,) + 5 * (108,)],
    [2 * (14,) + 19 * (15,), 17 * (22,) + 1 * (23,), 9 * (43,) + 4 * (44,), 5 * (120,) + 1 * (121,)],
    [9 * (13,) + 16 * (14,), 17 * (21,) + 4 * (22,), 3 * (44,) + 11 * (45,), 3 * (113,) + 4 * (114,)],
    [15 * (15,) + 10 * (16,), 15 * (24,) + 5 * (25,), 3 * (41,) + 13 * (42,), 3 * (107,) + 5 * (108,)],
    [19 * (16,) + 6 * (17,), 17 * (22,) + 6 * (23,), 17 * (42,), 4 * (116,) + 4 * (117,)],
    [34 * (13,), 7 * (24,) + 16 * (25,), 17 * (46,), 2 * (111,) + 7 * (112,)],
    [16 * (15,) + 14 * (16,), 11 * (24,) + 14 * (25,), 4 * (47,) + 14 * (48,), 4 * (121,) + 5 * (122,)],
    [30 * (16,) + 2 * (17,), 11 * (24,) + 16 * (25,), 6 * (45,) + 14 * (46,), 6 * (117,) + 4 * (118,)],
    [22 * (15,) + 13 * (16,), 7 * (24,) + 22 * (25,), 8 * (47,) + 13 * (48,), 8 * (106,) + 4 * (107,)],
    [33 * (16,) + 4 * (17,), 28 * (22,) + 6 * (23,), 19 * (46,) + 4 * (47,), 10 * (114,) + 2 * (115,)],
    [12 * (15,) + 28 * (16,), 8 * (23,) + 26 * (24,), 22 * (45,) + 3 * (46,), 8 * (122,) + 4 * (123,)],
    [11 * (15,) + 31 * (16,), 4 * (24,) + 31 * (25,), 3 * (45,) + 23 * (46,), 3 * (117,) + 10 * (118,)],
    [19 * (15,) + 26 * (16,), 1 * (23,) + 37 * (24,), 21 * (45,) + 7 * (46,), 7 * (116,) + 7 * (117,)],
    [23 * (15,) + 25 * (16,), 15 * (24,) + 25 * (25,), 19 * (47,) + 10 * (48,), 5 * (115,) + 10 * (116,)],
    [23 * (15,) + 28 * (16,), 42 * (24,) + 1 * (25,), 2 * (46,) + 29 * (47,), 13 * (115,) + 3 * (116,)],
    [19 * (15,) + 35 * (16,), 10 * (24,) + 35 * (25,), 10 * (46,) + 23 * (47,), 17 * (115,)],
    [11 * (15,) + 46 * (16,), 29 * (24,) + 19 * (25,), 14 * (46,) + 21 * (47,), 17 * (115,) + 1 * (116,)],
    [59 * (16,) + 1 * (17,), 44 * (24,) + 7 * (25,), 14 * (46,) + 23 * (47,), 13 * (115,) + 6 * (116,)],
    [22 * (15,) + 41 * (16,), 39 * (24,) + 14 * (25,), 12 * (47,) + 26 * (48,), 12 * (121,) + 7 * (122,)],
    [2 * (15,) + 64 * (16,), 46 * (24,) + 10 * (25,), 6 * (47,) + 34 * (48,), 6 * (121,) + 14 * (122,)],
    [24 * (15,) + 46 * (16,), 49 * (24,) + 10 * (25,), 29 * (46,) + 14 * (47,), 17 * (122,) + 4 * (123,)],
    [42 * (15,) + 32 * (16,), 48 * (24,) + 14 * (25,), 13 * (46,) + 32 * (47,), 4 * (122,) + 18 * (123,)],
    [10 * (15,) + 67 * (16,), 43 * (24,) + 22 * (25,), 40 * (47,) + 7 * (48,), 20 * (117,) + 4 * (118,)],
    [20 * (15,) + 61 * (16,), 34 * (24,) + 34 * (25,), 18 * (47,) + 31 * (48,), 19 * (118,) + 6 * (119,)],
]


ALIGNMENT_POSITIONS = [  # From ISO/IEC 18004:2006
    [],
    [],
    [18],  # Version 2
    [22],
    [26],
    [30],
    [34],
    [6, 22, 38],
    [6, 24, 42],
    [6, 26, 46],
    [6, 28, 50],
    [6, 30, 54],
    [6, 32, 58],
    [6, 34, 62],
    [6, 26, 46, 66],
    [6, 26, 48, 70],
    [6, 26, 50, 74],
    [6, 30, 54, 78],
    [6, 30, 56, 82],
    [6, 30, 58, 86],
    [6, 34, 62, 90],
    [6, 28, 50, 72, 94],
    [6, 26, 50, 74, 98],
    [6, 30, 54, 78, 102],

    [6, 28, 54, 80, 106],  # Version 24
    [6, 32, 58, 84, 110],
    [6, 30, 58, 86, 114],
    [6, 34, 62, 90, 118],
    [6, 26, 50, 74, 98, 122],
    [6, 30, 54, 78, 102, 126],
    [6, 26, 52, 78, 104, 130],
    [6, 30, 56, 82, 108, 134],
    [6, 34, 60, 86, 112, 138],
    [6, 30, 58, 86, 114, 142],
    [6, 34, 62, 90, 118, 146],
    [6, 30, 54, 78, 102, 126, 150],
    [6, 24, 50, 76, 102, 128, 154],
    [6, 28, 54, 80, 106, 132, 158],
    [6, 32, 58, 84, 110, 136, 162],
    [6, 26, 54, 82, 110, 138, 166],
    [6, 30, 58, 86, 114, 142, 170]
]


def check_region(data, x, y, match):
    """Compares a region to the given """
    w = len(match[0])
    for cy in range(len(match)):
        if match[cy] != data[y+cy][x:x+w]:
            return False
    return True


def zero_region(data, x, y, w, h):
    """Fills a region with zeroes."""
    for by in range(y, y+h):
        line = data[by]
        data[by] = line[:x] + [0]*w + line[x+w:]


def bits_to_int(bits):
    """Convers a list of bits into an integer"""
    val = 0
    for bit in bits:
        val = (val << 1) | bit
    return val


def bits_to_bytes(bits):
    """Converts a list of bits into a string of bytes"""
    return ''.join([chr(bits_to_int(bits[i:i+8]))
                    for i in range(0, len(bits), 8)])


def bytes_to_bits(buf):
    """Converts a string of bytes to a list of bits"""
    return [b >> i & 1 for b in map(ord, buf) for i in range(7, -1, -1)]


def deinterleave(data, b_cap):
    """De-interleaves the bytes from a QR code"""
    n_bufs = len(b_cap)
    bufs = []
    for _ in range(n_bufs):
        bufs.append([])
    b_i = 0
    for i in range(sum(b_cap)):
        b = data[i]
        while b_cap[b_i] <= len(bufs[b_i]):
            b_i = (b_i + 1) % n_bufs
        bufs[b_i].append(b)
        b_i = (b_i + 1) % n_bufs
    buf = ''
    for b in bufs:
        buf += ''.join(b)
    return buf


def parse_bits(bits, version):
    """
    Parses and decodes a TLV value from the given list of bits.
    Returns the parsed data and the remaining bits, if any.
    """
    enc, bits = bits_to_int(bits[:4]), bits[4:]
    if enc == 0:  # End of data.
        return '', []
    elif enc == 1:  # Number
        n_l = 10 if version < 10 else 12 if version < 27 else 14
        l, bits = bits_to_int(bits[:n_l]), bits[n_l:]
        buf = ''
        while l > 0:
            if l >= 3:
                num, bits = bits_to_int(bits[:10]), bits[10:]
            elif l >= 2:
                num, bits = bits_to_int(bits[:7]), bits[7:]
            else:
                num, bits = bits_to_int(bits[:3]), bits[3:]
            buf += str(num)
    elif enc == 2:  # Alphanumeric
        n_l = 9 if version < 10 else 11 if version < 27 else 13
        l, bits = bits_to_int(bits[:n_l]), bits[n_l:]
        buf = ''
        while l > 0:
            if l >= 2:
                num, bits = bits_to_int(bits[:11]), bits[11:]
                buf += ALPHANUM[num / 45]
                buf += ALPHANUM[num % 45]
                l -= 2
            else:
                num, bits = bits_to_int(bits[:6]), bits[6:]
                buf += ALPHANUM[num]
                l -= 1
        return buf, bits
    elif enc == 4:  # Bytes
        n_l = 8 if version < 10 else 16
        l, bits = bits_to_int(bits[:n_l]), bits[n_l:]
        return bits_to_bytes(bits[:l*8]), bits[l*8:]
    else:
        raise ValueError('Unsupported encoding: %d' % enc)


def remove_locator_patterns(data, mask):
    """
    Verifies and blanks out the three large locator patterns and dedicated
    whitespace surrounding them.
    """
    width = len(data)
    if not check_region(data, 0, 0, LOCATOR_BOX):
        raise ValueError('Top-left square missing')
    zero_region(mask, 0, 0, 9, 9)

    if not check_region(data, width-7, 0, LOCATOR_BOX):
        raise ValueError('Top-right square missing')
    zero_region(mask, width-8, 0, 8, 9)

    if not check_region(data, 0, width-7, LOCATOR_BOX):
        raise ValueError('Bottom-left square missing')
    zero_region(mask, 0, width-8, 9, 8)


def remove_alignment_patterns(mask, version):
    """Blanks out alignment patterns."""
    positions = ALIGNMENT_POSITIONS[version]
    for y in positions:
        for x in positions:
            # Do not try to remove patterns in locator pattern positions.
            if (x, y) not in [(6, 6), (6, positions[-1]), (positions[-1], 6)]:
                zero_region(mask, x-2, y-2, 5, 5)


def remove_timing_patterns(mask):
    """Blanks out tracking patterns."""
    width = len(mask)
    mask[6] = [0] * width
    for y in range(width):
        mask[y][6] = 0


def remove_version_info(mask):
    """Removes version data. Only for version 7 and greater."""
    width = len(mask)
    zero_region(mask, width-11, 0, 3, 6)
    zero_region(mask, 0, width-11, 5, 6)


def read_bits(qr_data, read_mask, mask):
    """Reads the data contained in a QR code as bits."""
    size = len(qr_data)
    mask_f = MASKS[mask]
    bits = []
    # Skip over vertical timing pattern
    for x in reversed(list(range(0, 6, 2)) + list(range(7, size, 2))):
        y_range = range(0, size)
        if (size - x)/2 % 2 != 0:
            y_range = reversed(y_range)
        for y in y_range:
            for i in reversed(range(2)):
                if read_mask[y][x+i]:
                    bits.append(qr_data[y][x+i] ^ mask_f(x+i, y))
    return bits
