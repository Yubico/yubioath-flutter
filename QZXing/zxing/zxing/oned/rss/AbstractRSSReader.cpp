#include "AbstractRSSReader.h"

#include <zxing/common/detector/MathUtils.h>

namespace zxing {
namespace oned {
namespace rss {

using zxing::common::detector::MathUtils;

AbstractRSSReader::AbstractRSSReader()
{
    m_decodeFinderCounters = std::vector<int>(4);
    m_dataCharacterCounters = std::vector<int>(8);
    m_oddRoundingErrors = std::vector<float>(4);
    m_evenRoundingErrors = std::vector<float>(4);
    m_oddCounts = std::vector<int>(m_dataCharacterCounters.size() / 2);
    m_evenCounts = std::vector<int>(m_dataCharacterCounters.size() / 2);
}

std::vector<int>& AbstractRSSReader::getDecodeFinderCounters()
{
    return m_decodeFinderCounters;
}

std::vector<int>& AbstractRSSReader::getDataCharacterCounters()
{
    return m_dataCharacterCounters;
}

std::vector<float>& AbstractRSSReader::getOddRoundingErrors()
{
    return m_oddRoundingErrors;
}

std::vector<float>& AbstractRSSReader::getEvenRoundingErrors()
{
    return m_evenRoundingErrors;
}

std::vector<int>& AbstractRSSReader::getOddCounts()
{
    return m_oddCounts;
}

std::vector<int>& AbstractRSSReader::getEvenCounts()
{
    return m_evenCounts;
}

int AbstractRSSReader::parseFinderValue(std::vector<int>& counters, std::vector<int const*> const& finderPatterns)
{
    for (size_t value = 0; value < finderPatterns.size(); value++) {
        if (patternMatchVariance(counters, finderPatterns[value], MAX_INDIVIDUAL_VARIANCE) <
                MAX_AVG_VARIANCE) {
            return static_cast<int>(value);
        }
    }
    throw NotFoundException();
}

int AbstractRSSReader::count(std::vector<int>& array)
{
    return MathUtils::sum(array);
}

void AbstractRSSReader::increment(std::vector<int>& array, std::vector<float>& errors)
{
    size_t index = 0;
    float biggestError = errors[0];
    for (size_t i = 1; i < array.size(); i++) {
        if (errors[i] > biggestError) {
            biggestError = errors[i];
            index = i;
        }
    }
    array[index]++;
}

void AbstractRSSReader::decrement(std::vector<int>& array, std::vector<float>& errors)
{
    size_t index = 0;
    float biggestError = errors[0];
    for (size_t i = 1; i < array.size(); i++) {
        if (errors[i] < biggestError) {
            biggestError = errors[i];
            index = i;
        }
    }
    array[index]--;
}

bool AbstractRSSReader::isFinderPattern(std::vector<int> &counters)
{
    int firstTwoSum = counters[0] + counters[1];
    int sum = firstTwoSum + counters[2] + counters[3];
    float ratio = static_cast<float>(firstTwoSum) / static_cast<float>(sum);
    if (ratio >= MIN_FINDER_PATTERN_RATIO && ratio <= MAX_FINDER_PATTERN_RATIO) {
        // passes ratio test in spec, but see if the counts are unreasonable
        int minCounter = 5555;
        int maxCounter = -5555;
        for (int counter : counters) {
            if (counter > maxCounter) {
                maxCounter = counter;
            }
            if (counter < minCounter) {
                minCounter = counter;
            }
        }
        return maxCounter < 10 * minCounter;
    }
    return false;
}

}
}
}
