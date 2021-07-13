#ifndef FINDER_PATTERN_H
#define FINDER_PATTERN_H

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

#include <zxing/oned/OneDResultPoint.h>
#include <zxing/common/Array.h>

#include <vector>

namespace zxing {

namespace oned {

namespace rss {

/**
 * Encapsulates an RSS barcode finder pattern, including its start/end position and row.
 */
class FinderPattern
{

public:
    FinderPattern(int value, std::vector<int> startEnd, int start, int end, int rowNumber);

    FinderPattern(const FinderPattern* other = nullptr);

    int getValue() const;

    std::vector<int> &getStartEnd();

    ArrayRef<Ref<ResultPoint> > &getResultPoints();

    bool equals(const FinderPattern& other) const;

    int hashCode() const;

    bool isValid() const;

private:
    int m_value;
    std::vector<int> m_startEnd;
    ArrayRef< Ref<ResultPoint> > m_resultPoints;

};

}
}
}

#endif
