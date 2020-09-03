#ifndef DATA_CHARACTER_H
#define DATA_CHARACTER_H

/*
 * Copyright 2009 ZXing authors
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
 * 2019-07-17 translation from Java into C++
 */

#include <zxing/common/Str.h>

namespace zxing {

namespace oned {

namespace rss {

/**
 * Encapsulates a since character value in an RSS barcode, including its checksum information.
 */
class DataCharacter
{

public:
    DataCharacter(int value, int checksumPortion);

    DataCharacter();

    int getValue() const;

    int getChecksumPortion() const;

    String toString() const;

    bool equals(const DataCharacter& other) const;

    int hashCode() const;

private:
    int m_value;
    int m_checksumPortion;

};

}
}
}

#endif
