#ifndef ABSTRACT_RSS_READER_H
#define ABSTRACT_RSS_READER_H

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

#include <zxing/NotFoundException.h>
#include <zxing/common/detector/MathUtils.h>
#include <zxing/oned/OneDReader.h>

#include <vector>

namespace zxing {

namespace oned {

namespace rss {

/**
 * Superclass of {@link OneDReader} implementations that read barcodes in the RSS family
 * of formats.
 */
class AbstractRSSReader : public OneDReader
{

    static constexpr int MAX_AVG_VARIANCE = int(PATTERN_MATCH_RESULT_SCALE_FACTOR * 0.2f);
    static constexpr int MAX_INDIVIDUAL_VARIANCE = int(PATTERN_MATCH_RESULT_SCALE_FACTOR * 0.45f);

    static constexpr float MIN_FINDER_PATTERN_RATIO = 9.5f / 12.0f;
    static constexpr float MAX_FINDER_PATTERN_RATIO = 12.5f / 14.0f;

protected:
    AbstractRSSReader();

    std::vector<int> &getDecodeFinderCounters();

    std::vector<int> &getDataCharacterCounters();

    std::vector<float> &getOddRoundingErrors();

    std::vector<float> &getEvenRoundingErrors();

    std::vector<int> &getOddCounts();

    std::vector<int> &getEvenCounts();

    static int parseFinderValue(std::vector<int>& counters,
                                 const std::vector<const int *> &finderPatterns);

    /**
   * @param array values to sum
   * @return sum of values
   * @deprecated call {@link MathUtils#sum(int[])}
   */
    static int count(std::vector<int> &array);

    static void increment(std::vector<int> &array,  std::vector<float> &errors);

    static void decrement(std::vector<int> &array, std::vector<float>& errors);

    static bool isFinderPattern(std::vector<int>& counters);

private:
    std::vector<int> m_decodeFinderCounters;
    std::vector<int> m_dataCharacterCounters;
    std::vector<float> m_oddRoundingErrors;
    std::vector<float> m_evenRoundingErrors;
    std::vector<int> m_oddCounts;
    std::vector<int> m_evenCounts;

};

}
}
}

#endif
