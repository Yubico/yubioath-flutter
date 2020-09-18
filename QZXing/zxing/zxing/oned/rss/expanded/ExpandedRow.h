#ifndef EXPANDED_ROW_H
#define EXPANDED_ROW_H

/*
 * Copyright (C) 2010 ZXing authors
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

#include "ExpandedPair.h"

#include <vector>

namespace zxing {

namespace oned {

namespace rss {

/**
 * One row of an RSS Expanded Stacked symbol, consisting of 1+ expanded pairs.
 */
class ExpandedRow
{

public:
    ExpandedRow(std::vector<ExpandedPair> pairs, int rowNumber, bool wasReversed);

    ExpandedRow(const ExpandedRow* other = nullptr);

    std::vector<ExpandedPair>& getPairs();

    int getRowNumber();

    bool isEquivalent(std::vector<ExpandedPair> otherPairs) const;

    String toString();

    /**
   * Two rows are equal if they contain the same pairs in the same order.
   */
    bool equals(const ExpandedRow& other) const;

private:
    std::vector<ExpandedPair> m_pairs;
    int m_rowNumber;
    /** Did this row of the image have to be reversed (mirrored) to recognize the pairs? */
    bool m_wasReversed;
};

}
}
}

#endif
