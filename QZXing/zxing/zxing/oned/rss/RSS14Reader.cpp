#include "RSS14Reader.h"
#include <zxing/common/StringUtils.h>

namespace zxing {
namespace oned {
namespace rss {

using ::zxing::common::detector::MathUtils;

static const std::vector<int> OUTSIDE_EVEN_TOTAL_SUBSET = {1,10,34,70,126};
static const std::vector<int> INSIDE_ODD_TOTAL_SUBSET = {4,20,48,81};
static const std::vector<int> OUTSIDE_GSUM = {0,161,961,2015,2715};
static const std::vector<int> INSIDE_GSUM = {0,336,1036,1516};
static const std::vector<int> OUTSIDE_ODD_WIDEST = {8,6,4,3,1};
static const std::vector<int> INSIDE_ODD_WIDEST = {2,4,6,8};

const int FINDER_PATTERNS_[][4] = {
    {3,8,2,1},
    {3,5,5,1},
    {3,3,7,1},
    {3,1,9,1},
    {2,7,4,1},
    {2,5,6,1},
    {2,3,8,1},
    {1,5,7,1},
    {1,3,9,1}
};

#define VECTOR_INIT(v) v, v + sizeof(v)/sizeof(v[0])

const std::vector<int const*>
RSS14Reader::FINDER_PATTERNS (VECTOR_INIT(FINDER_PATTERNS_));

RSS14Reader::RSS14Reader()
    : m_possibleLeftPairs({}),
      m_possibleRightPairs({})
{

}

Ref<Result> RSS14Reader::decodeRow(int rowNumber, Ref<BitArray> row, DecodeHints hints)
{
    Pair leftPair = decodePair(row, false, rowNumber, hints);
    addOrTally(m_possibleLeftPairs, leftPair);
    row->reverse();

    Pair rightPair = decodePair(row, true, rowNumber, hints);
    addOrTally(m_possibleRightPairs, rightPair);
    row->reverse();

    for (Pair &left : m_possibleLeftPairs) {
        if (left.getCount() > 1) {
            for (Pair &right : m_possibleRightPairs) {
                if (right.getCount() > 1 && checkChecksum(left, right)) {
                    return constructResult(left, right);
                }
            }
        }
    }

    throw NotFoundException();
}

void RSS14Reader::addOrTally(std::vector<Pair>& possiblePairs, Pair& pair)
{
    if (!pair.isValid()) {
        return;
    }

    bool found = false;
    for (Pair& other : possiblePairs) {
        if (other.getValue() == pair.getValue()) {
            other.incrementCount();
            found = true;
            break;
        }
    }

    if (!found) {
        possiblePairs.push_back(pair);
    }
}

void RSS14Reader::reset()
{
    m_possibleLeftPairs.clear();
    m_possibleRightPairs.clear();
}

Ref<Result> RSS14Reader::constructResult(Pair leftPair, Pair rightPair) const
{
    long long symbolValue = 4537077LL * leftPair.getValue() + rightPair.getValue();
    String text(common::StringUtils::intToStr(symbolValue));

    String buffer(14);
    for (int i = 13 - text.length(); i > 0; i--) {
        buffer.append('0');
    }
    buffer.append(text.getText());

    int checkDigit = 0;
    for (int i = 0; i < 13; i++) {
        int digit = buffer.charAt(i) - '0';
        checkDigit += ((i & 0x01) == 0) ? (3 * digit) : digit;
    }
    checkDigit = 10 - (checkDigit % 10);
    if (checkDigit == 10) {
        checkDigit = 0;
    }
    buffer.append(common::StringUtils::intToStr(checkDigit));

    ArrayRef< Ref<ResultPoint> > leftPoints = leftPair.getFinderPattern().getResultPoints();
    ArrayRef< Ref<ResultPoint> > rightPoints = rightPair.getFinderPattern().getResultPoints();

    ArrayRef< Ref<ResultPoint> > resultPoints(4);
    resultPoints[0] = leftPoints[0];
    resultPoints[1] = leftPoints[1];
    resultPoints[2] = rightPoints[0];
    resultPoints[3] = rightPoints[1];

    return Ref<Result>(new Result(
                           Ref<String>(new String(buffer)),
                           nullptr,
                           resultPoints,
                           BarcodeFormat::RSS_14));
}

Pair RSS14Reader::decodePair(Ref<BitArray> row, bool right, int rowNumber, DecodeHints hints)
{
    try {
        std::vector<int> startEnd = findFinderPattern(row, right);
        if (startEnd.empty()) {
            return Pair();
        }
        FinderPattern pattern = parseFoundFinderPattern(row, rowNumber, right, startEnd);

        Ref<ResultPointCallback> resultPointCallback = hints.getResultPointCallback();

        if (resultPointCallback != nullptr) {
            startEnd = pattern.getStartEnd();
            float center = (startEnd[0] + startEnd[1] - 1) / 2.0f;
            if (right) {
                // row is actually reversed
                center = row->getSize() - 1 - center;
            }
            resultPointCallback->foundPossibleResultPoint(ResultPoint(center, static_cast<float>(rowNumber)));
        }

        DataCharacter outside = decodeDataCharacter(row, pattern, true);
        DataCharacter inside = decodeDataCharacter(row, pattern, false);
        return Pair(1597 * outside.getValue() + inside.getValue(),
                    outside.getChecksumPortion() + 4 * inside.getChecksumPortion(),
                    pattern);

    } catch (NotFoundException const& /*e*/) {
        return Pair();
    }
}

DataCharacter RSS14Reader::decodeDataCharacter(Ref<BitArray> row, FinderPattern pattern, bool outsideChar)
{

    std::vector<int>& counters = getDataCharacterCounters();
    for (size_t x = 0; x < counters.size(); x++) {
        counters[x] = 0;
    }

    if (outsideChar) {
        recordPatternInReverse(row, pattern.getStartEnd()[0], counters);
    } else {
        recordPattern(row, pattern.getStartEnd()[1], counters);
        // reverse it
        for (size_t i = 0, j = counters.size() - 1; i < j; i++, j--) {
            int temp = counters[i];
            counters[i] = counters[j];
            counters[j] = temp;
        }
    }

    int numModules = outsideChar ? 16 : 15;
    float elementWidth = MathUtils::sum(counters) / static_cast<float>(numModules);

    std::vector<int>& oddCounts = getOddCounts();
    std::vector<int>& evenCounts = getEvenCounts();
    std::vector<float>& oddRoundingErrors = getOddRoundingErrors();
    std::vector<float>& evenRoundingErrors = getEvenRoundingErrors();

    for (size_t i = 0; i < counters.size(); i++) {
        float value = counters[i] / elementWidth;
        int count = static_cast<int>(value + 0.5f); // Round
        if (count < 1) {
            count = 1;
        } else if (count > 8) {
            count = 8;
        }
        size_t offset = i / 2;
        if ((i & 0x01) == 0) {
            oddCounts[offset] = count;
            oddRoundingErrors[offset] = value - count;
        } else {
            evenCounts[offset] = count;
            evenRoundingErrors[offset] = value - count;
        }
    }

    adjustOddEvenCounts(outsideChar, numModules);

    int oddSum = 0;
    int oddChecksumPortion = 0;
    for (size_t i = oddCounts.size() - 1; i-- > 0; ) {
        oddChecksumPortion *= 9;
        oddChecksumPortion += oddCounts[i];
        oddSum += oddCounts[i];
    }
    int evenChecksumPortion = 0;
    int evenSum = 0;
    for (size_t i = evenCounts.size() - 1; i-- > 0; ) {
        evenChecksumPortion *= 9;
        evenChecksumPortion += evenCounts[i];
        evenSum += evenCounts[i];
    }
    int checksumPortion = oddChecksumPortion + 3 * evenChecksumPortion;

    if (outsideChar) {
        if ((oddSum & 0x01) != 0 || oddSum > 12 || oddSum < 4) {
            throw NotFoundException();
        }
        size_t group = static_cast<size_t>((12 - oddSum) / 2);
        int oddWidest = OUTSIDE_ODD_WIDEST[group];
        int evenWidest = 9 - oddWidest;
        int vOdd = RSSUtils::getRSSvalue(oddCounts, oddWidest, false);
        int vEven = RSSUtils::getRSSvalue(evenCounts, evenWidest, true);
        int tEven = OUTSIDE_EVEN_TOTAL_SUBSET[group];
        int gSum = OUTSIDE_GSUM[group];
        return DataCharacter(vOdd * tEven + vEven + gSum, checksumPortion);
    } else {
        if ((evenSum & 0x01) != 0 || evenSum > 10 || evenSum < 4) {
            throw NotFoundException();
        }
        size_t group = static_cast<size_t>((10 - evenSum) / 2);
        int oddWidest = INSIDE_ODD_WIDEST[group];
        int evenWidest = 9 - oddWidest;
        int vOdd = RSSUtils::getRSSvalue(oddCounts, oddWidest, true);
        int vEven = RSSUtils::getRSSvalue(evenCounts, evenWidest, false);
        int tOdd = INSIDE_ODD_TOTAL_SUBSET[group];
        int gSum = INSIDE_GSUM[group];
        return DataCharacter(vEven * tOdd + vOdd + gSum, checksumPortion);
    }

}

std::vector<int> RSS14Reader::findFinderPattern(Ref<BitArray> row, bool rightFinderPattern)
{
    std::vector<int>& counters = getDecodeFinderCounters();
    counters[0] = 0;
    counters[1] = 0;
    counters[2] = 0;
    counters[3] = 0;

    int width = row->getSize();
    bool isWhite = false;
    int rowOffset = 0;
    while (rowOffset < width) {
        isWhite = !row->get(rowOffset);
        if (rightFinderPattern == isWhite) {
            // Will encounter white first when searching for right finder pattern
            break;
        }
        rowOffset++;
    }

    size_t counterPosition = 0;
    int patternStart = rowOffset;
    for (int x = rowOffset; x < width; x++) {
        if (row->get(x) != isWhite) {
            counters[counterPosition]++;
        } else {
            if (counterPosition == 3) {
                if (isFinderPattern(counters)) {
                    return std::vector<int>{patternStart, x};
                }
                patternStart += counters[0] + counters[1];
                counters[0] = counters[2];
                counters[1] = counters[3];
                counters[2] = 0;
                counters[3] = 0;
                counterPosition--;
            } else {
                counterPosition++;
            }
            counters[counterPosition] = 1;
            isWhite = !isWhite;
        }
    }
    return std::vector<int>();

}

FinderPattern RSS14Reader::parseFoundFinderPattern(Ref<BitArray> row, int rowNumber, bool right, std::vector<int> startEnd)
{
    // Actually we found elements 2-5
    bool firstIsBlack = row->get(startEnd[0]);
    int firstElementStart = startEnd[0] - 1;
    // Locate element 1
    while (firstElementStart >= 0 && firstIsBlack != row->get(firstElementStart)) {
        firstElementStart--;
    }
    firstElementStart++;
    int firstCounter = startEnd[0] - firstElementStart;

    // Make 'counters' hold 1-4
    std::vector<int>& counters = getDecodeFinderCounters();
    std::vector<int> _counters = counters;
    for (size_t i = 1; i < counters.size(); i++) {
        counters[i] = _counters[i - 1];
    }

    counters[0] = firstCounter;
    int value = parseFinderValue(counters, FINDER_PATTERNS);
    int start = firstElementStart;
    int end = startEnd[1];
    if (right) {
        // row is actually reversed
        start = row->getSize() - 1 - start;
        end = row->getSize() - 1 - end;
    }
    return new FinderPattern(value, {firstElementStart, startEnd[1]}, start, end, rowNumber);
}

void RSS14Reader::adjustOddEvenCounts(bool outsideChar, int numModules)
{
    int oddSum = MathUtils::sum(getOddCounts());
    int evenSum = MathUtils::sum(getEvenCounts());

    bool incrementOdd = false;
    bool decrementOdd = false;
    bool incrementEven = false;
    bool decrementEven = false;

    if (outsideChar) {
        if (oddSum > 12) {
            decrementOdd = true;
        } else if (oddSum < 4) {
            incrementOdd = true;
        }
        if (evenSum > 12) {
            decrementEven = true;
        } else if (evenSum < 4) {
            incrementEven = true;
        }
    } else {
        if (oddSum > 11) {
            decrementOdd = true;
        } else if (oddSum < 5) {
            incrementOdd = true;
        }
        if (evenSum > 10) {
            decrementEven = true;
        } else if (evenSum < 4) {
            incrementEven = true;
        }
    }

    int mismatch = oddSum + evenSum - numModules;
    bool oddParityBad = (oddSum & 0x01) == (outsideChar ? 1 : 0);
    bool evenParityBad = (evenSum & 0x01) == 1;
    /*if (mismatch == 2) {
      if (!(oddParityBad && evenParityBad)) {
        throw ReaderException.getInstance();
      }
      decrementOdd = true;
      decrementEven = true;
    } else if (mismatch == -2) {
      if (!(oddParityBad && evenParityBad)) {
        throw ReaderException.getInstance();
      }
      incrementOdd = true;
      incrementEven = true;
    } else */
    switch (mismatch) {
    case 1:
        if (oddParityBad) {
            if (evenParityBad) {
                throw NotFoundException();
            }
            decrementOdd = true;
        } else {
            if (!evenParityBad) {
                throw NotFoundException();
            }
            decrementEven = true;
        }
        break;
    case -1:
        if (oddParityBad) {
            if (evenParityBad) {
                throw NotFoundException();
            }
            incrementOdd = true;
        } else {
            if (!evenParityBad) {
                throw NotFoundException();
            }
            incrementEven = true;
        }
        break;
    case 0:
        if (oddParityBad) {
            if (!evenParityBad) {
                throw NotFoundException();
            }
            // Both bad
            if (oddSum < evenSum) {
                incrementOdd = true;
                decrementEven = true;
            } else {
                decrementOdd = true;
                incrementEven = true;
            }
        } else {
            if (evenParityBad) {
                throw NotFoundException();
            }
            // Nothing to do!
        }
        break;
    default:
        throw NotFoundException();
    }

    if (incrementOdd) {
        if (decrementOdd) {
            throw NotFoundException();
        }
        increment(getOddCounts(), getOddRoundingErrors());
    }
    if (decrementOdd) {
        decrement(getOddCounts(), getOddRoundingErrors());
    }
    if (incrementEven) {
        if (decrementEven) {
            throw NotFoundException();
        }
        increment(getEvenCounts(), getOddRoundingErrors());
    }
    if (decrementEven) {
        decrement(getEvenCounts(), getEvenRoundingErrors());
    }
}

bool RSS14Reader::checkChecksum(Pair leftPair, Pair rightPair)
{
    //int leftFPValue = leftPair.getFinderPattern().getValue();
    //int rightFPValue = rightPair.getFinderPattern().getValue();
    //if ((leftFPValue == 0 && rightFPValue == 8) ||
    //    (leftFPValue == 8 && rightFPValue == 0)) {
    //}
    int checkValue = (leftPair.getChecksumPortion() + 16 * rightPair.getChecksumPortion()) % 79;
    int targetCheckValue =
            9 * leftPair.getFinderPattern().getValue() + rightPair.getFinderPattern().getValue();
    if (targetCheckValue > 72) {
        targetCheckValue--;
    }
    if (targetCheckValue > 8) {
        targetCheckValue--;
    }
    return checkValue == targetCheckValue;
}

}
}
}
