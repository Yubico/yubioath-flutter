#ifndef ZXING_BYTE_ARRAY_H
#define ZXING_BYTE_ARRAY_H
/*
* Copyright 2008 ZXing authors
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*      http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
* 2019-05-08 translation from Java into C++
*/

#include <vector>
#include <cstdint>
#include "Types.h"

namespace zxing {

/**
 * ByteArray is an extension of std::vector<unsigned char>.
 */
class ByteArray : public std::vector<zxing::byte>
{
public:
    ByteArray() {}
    ByteArray(std::initializer_list<zxing::byte> list) : std::vector<zxing::byte>(list) {}
    explicit ByteArray(int len) : std::vector<zxing::byte>(len, 0) {}
    int length() const { return static_cast<int>(size()); }
    const zxing::byte* bytePtr() const { return data(); }
    zxing::byte* bytePtr() { return data(); }
};

}

#endif
