#ifndef RSS14_READER_H
#define RSS14_READER_H

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

#include "AbstractRSSReader.h"
#include "Pair.h"
#include "RSSUtils.h"

#include <zxing/common/detector/MathUtils.h>
#include <vector>

namespace zxing {

namespace oned {

namespace rss {

/**
 * Decodes RSS-14, including truncated and stacked variants. See ISO/IEC 24724:2006.
 */
class RSS14Reader : public AbstractRSSReader
{

public:
    static const std::vector<int const*> FINDER_PATTERNS;

    RSS14Reader();

    Ref<Result> decodeRow(int rowNumber, Ref<BitArray> row, DecodeHints hints);

    static void addOrTally(std::vector<Pair> &possiblePairs, Pair &pair);

    void reset();

    Ref<Result> constructResult(Pair leftPair, Pair rightPair) const;

    static bool checkChecksum(Pair leftPair, Pair rightPair);

    Pair decodePair(Ref<BitArray> row, bool right, int rowNumber, DecodeHints hints);

    DataCharacter decodeDataCharacter(Ref<BitArray> row, FinderPattern pattern, bool outsideChar);

    std::vector<int> findFinderPattern(Ref<BitArray> row, bool rightFinderPattern);

    FinderPattern parseFoundFinderPattern(Ref<BitArray> row, int rowNumber, bool right, std::vector<int> startEnd);

    void adjustOddEvenCounts(bool outsideChar, int numModules);

private:
    std::vector<Pair> m_possibleLeftPairs;
    std::vector<Pair> m_possibleRightPairs;

};

}
}
}

#endif
