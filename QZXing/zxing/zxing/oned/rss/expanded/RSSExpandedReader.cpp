#include "RSSExpandedReader.h"

namespace zxing {
namespace oned {
namespace rss {

using ::zxing::common::detector::MathUtils;

static const std::vector<int> SYMBOL_WIDEST = {7, 5, 4, 3, 1};
static const std::vector<int> EVEN_TOTAL_SUBSET = {4, 20, 52, 104, 204};
static const std::vector<int> GSUM = {0, 348, 1388, 2948, 3988};

const int FINDER_PATTERNS_[][4] = {
    {1,8,4,1}, // A
    {3,6,4,1}, // B
    {3,4,6,1}, // C
    {3,2,8,1}, // D
    {2,6,5,1}, // E
    {2,2,9,1}  // F
};

#define VECTOR_INIT(v) v, v + sizeof(v)/sizeof(v[0])

const std::vector<int const*>
RSSExpandedReader::FINDER_PATTERNS (VECTOR_INIT(FINDER_PATTERNS_));

static const std::vector<std::vector<int>> WEIGHTS = {
    {  1,   3,   9,  27,  81,  32,  96,  77},
    { 20,  60, 180, 118, 143,   7,  21,  63},
    {189, 145,  13,  39, 117, 140, 209, 205},
    {193, 157,  49, 147,  19,  57, 171,  91},
    { 62, 186, 136, 197, 169,  85,  44, 132},
    {185, 133, 188, 142,   4,  12,  36, 108},
    {113, 128, 173,  97,  80,  29,  87,  50},
    {150,  28,  84,  41, 123, 158,  52, 156},
    { 46, 138, 203, 187, 139, 206, 196, 166},
    { 76,  17,  51, 153,  37, 111, 122, 155},
    { 43, 129, 176, 106, 107, 110, 119, 146},
    { 16,  48, 144,  10,  30,  90,  59, 177},
    {109, 116, 137, 200, 178, 112, 125, 164},
    { 70, 210, 208, 202, 184, 130, 179, 115},
    {134, 191, 151,  31,  93,  68, 204, 190},
    {148,  22,  66, 198, 172,   94, 71,   2},
    {  6,  18,  54, 162,  64,  192,154,  40},
    {120, 149,  25,  75,  14,   42,126, 167},
    { 79,  26,  78,  23,  69,  207,199, 175},
    {103,  98,  83,  38, 114, 131, 182, 124},
    {161,  61, 183, 127, 170,  88,  53, 159},
    { 55, 165,  73,   8,  24,  72,   5,  15},
    { 45, 135, 194, 160,  58, 174, 100,  89}
};

static const int FINDER_PAT_A = 0;
static const int FINDER_PAT_B = 1;
static const int FINDER_PAT_C = 2;
static const int FINDER_PAT_D = 3;
static const int FINDER_PAT_E = 4;
static const int FINDER_PAT_F = 5;

static std::vector<std::vector<int>> FINDER_PATTERN_SEQUENCES = {
    { FINDER_PAT_A, FINDER_PAT_A },
    { FINDER_PAT_A, FINDER_PAT_B, FINDER_PAT_B },
    { FINDER_PAT_A, FINDER_PAT_C, FINDER_PAT_B, FINDER_PAT_D },
    { FINDER_PAT_A, FINDER_PAT_E, FINDER_PAT_B, FINDER_PAT_D, FINDER_PAT_C },
    { FINDER_PAT_A, FINDER_PAT_E, FINDER_PAT_B, FINDER_PAT_D, FINDER_PAT_D, FINDER_PAT_F },
    { FINDER_PAT_A, FINDER_PAT_E, FINDER_PAT_B, FINDER_PAT_D, FINDER_PAT_E, FINDER_PAT_F, FINDER_PAT_F },
    { FINDER_PAT_A, FINDER_PAT_A, FINDER_PAT_B, FINDER_PAT_B, FINDER_PAT_C, FINDER_PAT_C, FINDER_PAT_D, FINDER_PAT_D },
    { FINDER_PAT_A, FINDER_PAT_A, FINDER_PAT_B, FINDER_PAT_B, FINDER_PAT_C, FINDER_PAT_C, FINDER_PAT_D, FINDER_PAT_E, FINDER_PAT_E },
    { FINDER_PAT_A, FINDER_PAT_A, FINDER_PAT_B, FINDER_PAT_B, FINDER_PAT_C, FINDER_PAT_C, FINDER_PAT_D, FINDER_PAT_E, FINDER_PAT_F, FINDER_PAT_F },
    { FINDER_PAT_A, FINDER_PAT_A, FINDER_PAT_B, FINDER_PAT_B, FINDER_PAT_C, FINDER_PAT_D, FINDER_PAT_D, FINDER_PAT_E, FINDER_PAT_E, FINDER_PAT_F, FINDER_PAT_F },
};

static const int MAX_PAIRS = 11;

RSSExpandedReader::RSSExpandedReader()
    : m_pairs(std::vector<ExpandedPair>(MAX_PAIRS)), m_rows(std::vector<ExpandedRow>()),
      m_startEnd(std::vector<int>(2)), m_startFromEven(false)
{

}

Ref<Result> RSSExpandedReader::decodeRow(int rowNumber, Ref<BitArray> row, DecodeHints /*hints*/)
{
    // Rows can start with even pattern in case in prev rows there where odd number of patters.
    // So lets try twice
    m_pairs.clear();
    m_startFromEven = false;
    try {
        return constructResult(decodeRow2pairs(rowNumber, row));
    } catch (NotFoundException const& /*e*/) {
        // OK
    }

    m_pairs.clear();
    m_startFromEven = true;
    return constructResult(decodeRow2pairs(rowNumber, row));
}

void RSSExpandedReader::reset()
{
    m_pairs.clear();
    m_rows.clear();
}

std::vector<ExpandedPair> RSSExpandedReader::decodeRow2pairs(int rowNumber, Ref<BitArray> row)
{
    bool done = false;
    while (!done) {
        try {
            m_pairs.push_back(retrieveNextPair(row, m_pairs, rowNumber));
        } catch (NotFoundException const& nfe) {
            if (m_pairs.size() == 0) {
                throw nfe;
            }
            // exit this loop when retrieveNextPair() fails and throws
            done = true;
        }
    }

    // TODO: verify sequence of finder patterns as in checkPairSequence()
    if (checkChecksum()) {
        return m_pairs;
    }

    bool tryStackedDecode = !(m_rows.size() == 0);
    storeRow(rowNumber, false); // TODO: deal with reversed rows
    if (tryStackedDecode) {
        // When the image is 180-rotated, then rows are sorted in wrong direction.
        // Try twice with both the directions.
        std::vector<ExpandedPair> ps = checkRows(false);
        if (ps.size() != 0) {
            return ps;
        }
        ps = checkRows(true);
        if (ps.size() != 0) {
            return ps;
        }
    }

    throw NotFoundException();
}

std::vector<ExpandedPair> RSSExpandedReader::checkRows(bool reverse)
{
    // Limit number of rows we are checking
    // We use recursive algorithm with pure complexity and don't want it to take forever
    // Stacked barcode can have up to 11 rows, so 25 seems reasonable enough
    if (m_rows.size() > 25) {
        m_rows.clear();  // We will never have a chance to get result, so clear it
        return {};
    }

    m_pairs.clear();
    if (reverse) {
        std::reverse(m_rows.begin(), m_rows.end());
    }

    std::vector<ExpandedPair> ps;
    try {
        ps = checkRows({}, 0);
    } catch (NotFoundException const& /*e*/) {
        // OK
    }

    if (reverse) {
        std::reverse(m_rows.begin(), m_rows.end());
    }

    return ps;
}

std::vector<ExpandedPair> RSSExpandedReader::checkRows(std::vector<ExpandedRow> collectedRows, int currentRow)
{
    for (size_t i = static_cast<size_t>(currentRow); i < m_rows.size(); i++) {
        ExpandedRow row = m_rows[i];
        m_pairs.clear();
        for (ExpandedRow collectedRow : collectedRows) {

            std::vector<ExpandedPair> collectedRowPairs = collectedRow.getPairs();
            m_pairs.insert(m_pairs.end(), collectedRowPairs.begin(),
                           collectedRowPairs.end());
        }
        std::vector<ExpandedPair> rowPairs = row.getPairs();
        m_pairs.insert(m_pairs.end(), rowPairs.begin(),
                       rowPairs.end());

        if (isValidSequence(m_pairs)) {
            if (checkChecksum()) {
                return m_pairs;
            }

            std::vector<ExpandedRow> rs(collectedRows);
            rs.push_back(row);
            try {
                // Recursion: try to add more rows
                return checkRows(rs, static_cast<int>(i + 1));
            } catch (NotFoundException const& /*e*/) {
                // We failed, try the next candidate
            }
        }
    }

    throw NotFoundException();
}

bool RSSExpandedReader::isValidSequence(std::vector<ExpandedPair> pairs)
{
    for (std::vector<int> sequence : FINDER_PATTERN_SEQUENCES) {
        if (pairs.size() <= sequence.size()) {
            bool stop = true;
            for (size_t j = 0; j < pairs.size(); j++) {
                if (pairs[j].getFinderPattern().getValue() != sequence[j]) {
                    stop = false;
                    break;
                }
            }
            if (stop) {
                return true;
            }
        }

    }

    return false;
}

void RSSExpandedReader::storeRow(int rowNumber, bool wasReversed)
{
    // Discard if duplicate above or below; otherwise insert in order by row number.
    size_t insertPos = 0;
    bool prevIsSame = false;
    bool nextIsSame = false;
    while (insertPos < m_rows.size()) {
        ExpandedRow erow = m_rows[insertPos];
        if (erow.getRowNumber() > rowNumber) {
            nextIsSame = erow.isEquivalent(m_pairs);
            break;
        }
        prevIsSame = erow.isEquivalent(m_pairs);
        insertPos++;
    }
    if (nextIsSame || prevIsSame) {
        return;
    }

    // When the row was partially decoded (e.g. 2 pairs found instead of 3),
    // it will prevent us from detecting the barcode.
    // Try to merge partial rows

    // Check whether the row is part of an already detected row
    if (isPartialRow(m_pairs, m_rows)) {
        return;
    }

    m_rows.insert(m_rows.begin() + insertPos, ExpandedRow(m_pairs, rowNumber, wasReversed));

    removePartialRows();
}

void RSSExpandedReader::removePartialRows()
{

    for (size_t i = 0; i < m_rows.size(); i++) {
        if (m_rows[i].getPairs().size() != m_pairs.size()) {
            bool allFound = true;
            for (ExpandedPair &p : m_rows[i].getPairs()) {
                bool found = false;
                for (ExpandedPair &pp : m_pairs) {
                    if (p.equals(pp))
                    {
                        found = true;
                        break;
                    }
                }
                if (!found)
                {
                    allFound = false;
                    break;
                }
            }
            if (allFound) {
                // 'pairs' contains all the pairs from the row 'r'
                m_rows.erase(m_rows.begin() + i--);
            }
        }
    }
}

bool RSSExpandedReader::isPartialRow(std::vector<ExpandedPair>& pairs, std::vector<ExpandedRow>& rows)
{
    for (ExpandedRow r : rows) {
        bool allFound = true;
        for (ExpandedPair &p : pairs) {
            bool found = false;
            for (ExpandedPair &pp : r.getPairs()) {
                if (p.equals(pp)) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                allFound = false;
                break;
            }
        }
        if (allFound) {
            // the row 'r' contain all the pairs from 'pairs'
            return true;
        }
    }
    return false;
}

std::vector<ExpandedRow> RSSExpandedReader::getRows() const
{
    return m_rows;
}

Ref<Result> RSSExpandedReader::constructResult(std::vector<ExpandedPair> pairs)
{
    Ref<BitArray> binary = BitArrayBuilder::buildBitArray(pairs);

    AbstractExpandedDecoder* decoder = AbstractExpandedDecoder::createDecoder(binary);
    String resultingString = decoder->parseInformation();

    ArrayRef< Ref<ResultPoint> > firstPoints = pairs[0].getFinderPattern().getResultPoints();
    ArrayRef< Ref<ResultPoint> > lastPoints  = pairs[pairs.size() - 1].getFinderPattern().getResultPoints();

    ArrayRef< Ref<ResultPoint> > resultPoints(4);
    resultPoints[0] = firstPoints[0];
    resultPoints[1] = firstPoints[1];
    resultPoints[2] = lastPoints[0];
    resultPoints[3] = lastPoints[1];

    return Ref<Result>(new Result(
                           Ref<String>(new String(resultingString)),
                           nullptr,
                           resultPoints,
                           BarcodeFormat::RSS_EXPANDED
                           ));
}

bool RSSExpandedReader::checkChecksum()
{
    ExpandedPair firstPair = m_pairs[0];
    DataCharacter checkCharacter = firstPair.getLeftChar();
    DataCharacter firstCharacter = firstPair.getRightChar();

    if (firstCharacter.getChecksumPortion() == 0) {
        return false;
    }

    int checksum = firstCharacter.getChecksumPortion();
    int s = 2;

    for (size_t i = 1; i < m_pairs.size(); ++i) {
        ExpandedPair currentPair = m_pairs[i];
        checksum += currentPair.getLeftChar().getChecksumPortion();
        s++;
        DataCharacter currentRightChar = currentPair.getRightChar();
        if (currentRightChar.getValue() != 0) {
            checksum += currentRightChar.getChecksumPortion();
            s++;
        }
    }

    checksum %= 211;

    int checkCharacterValue = 211 * (s - 4) + checksum;

    return checkCharacterValue == checkCharacter.getValue();
}

int RSSExpandedReader::getNextSecondBar(Ref<BitArray> row, int initialPos)
{
    int currentPos;
    if (row->get(initialPos)) {
        currentPos = row->getNextUnset(initialPos);
        currentPos = row->getNextSet(currentPos);
    } else {
        currentPos = row->getNextSet(initialPos);
        currentPos = row->getNextUnset(currentPos);
    }
    return currentPos;
}

ExpandedPair RSSExpandedReader::retrieveNextPair(Ref<BitArray> row, std::vector<ExpandedPair>& previousPairs, int rowNumber)
{
    bool isOddPattern  = previousPairs.size() % 2 == 0;
    if (m_startFromEven) {
        isOddPattern = !isOddPattern;
    }

    FinderPattern pattern;

    bool keepFinding = true;
    int forcedOffset = -1;
    do {
        findNextPair(row, previousPairs, forcedOffset);
        pattern = parseFoundFinderPattern(row, rowNumber, isOddPattern);
        if (!pattern.isValid()) {
            forcedOffset = getNextSecondBar(row, m_startEnd[0]);
        } else {
            keepFinding = false;
        }
    } while (keepFinding);

    // When stacked symbol is split over multiple rows, there's no way to guess if this pair can be last or not.
    // bool mayBeLast = checkPairSequence(previousPairs, pattern);

    DataCharacter leftChar  = decodeDataCharacter(row, pattern, isOddPattern, true);

    if (!(previousPairs.size() == 0) && previousPairs[previousPairs.size() - 1].mustBeLast()) {
        throw NotFoundException();
    }

    DataCharacter rightChar;
    try {
        rightChar = decodeDataCharacter(row, pattern, isOddPattern, false);
    } catch (NotFoundException const& /*e*/) {
        //rightChar = nullptr;
    }
    return ExpandedPair(leftChar, rightChar, pattern);
}

void RSSExpandedReader::findNextPair(Ref<BitArray> row, std::vector<ExpandedPair> previousPairs, int forcedOffset)
{
    std::vector<int>& counters = getDecodeFinderCounters();
    counters[0] = 0;
    counters[1] = 0;
    counters[2] = 0;
    counters[3] = 0;

    int width = row->getSize();

    int rowOffset;
    if (forcedOffset >= 0) {
        rowOffset = forcedOffset;
    } else if (previousPairs.size() == 0) {
        rowOffset = 0;
    } else {
        ExpandedPair lastPair = previousPairs[previousPairs.size() - 1];
        rowOffset = lastPair.getFinderPattern().getStartEnd()[1];
    }
    bool searchingEvenPair = previousPairs.size() % 2 != 0;
    if (m_startFromEven) {
        searchingEvenPair = !searchingEvenPair;
    }

    bool isWhite = false;
    while (rowOffset < width) {
        isWhite = !row->get(rowOffset);
        if (!isWhite) {
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
                if (searchingEvenPair) {
                    std::reverse(counters.begin(), counters.end());
                }

                if (isFinderPattern(counters)) {
                    m_startEnd[0] = patternStart;
                    m_startEnd[1] = x;
                    return;
                }

                if (searchingEvenPair) {
                    std::reverse(counters.begin(), counters.end());
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
    throw NotFoundException();
}

FinderPattern RSSExpandedReader::parseFoundFinderPattern(Ref<BitArray> row, int rowNumber, bool oddPattern)
{
    // Actually we found elements 2-5.
    int firstCounter;
    int start;
    int end;

    if (oddPattern) {
        // If pattern number is odd, we need to locate element 1 *before* the current block.

        int firstElementStart = m_startEnd[0] - 1;
        // Locate element 1
        while (firstElementStart >= 0 && !row->get(firstElementStart)) {
            firstElementStart--;
        }

        firstElementStart++;
        firstCounter = m_startEnd[0] - firstElementStart;
        start = firstElementStart;
        end = m_startEnd[1];

    } else {
        // If pattern number is even, the pattern is reversed, so we need to locate element 1 *after* the current block.

        start = m_startEnd[0];

        end = row->getNextUnset(m_startEnd[1] + 1);
        firstCounter = end - m_startEnd[1];
    }

    // Make 'counters' hold 1-4
    std::vector<int>& counters = getDecodeFinderCounters();

    std::vector<int> _counters = counters;
    for (size_t i = 1; i < counters.size(); i++) {
        counters[i] = _counters[i - 1];
    }

    counters[0] = firstCounter;
    int value;
    try {
        value = parseFinderValue(counters, FINDER_PATTERNS);
    } catch (NotFoundException const& /*e*/) {
        return FinderPattern();
    }
    return FinderPattern(value, {start, end}, start, end, rowNumber);
}

DataCharacter RSSExpandedReader::decodeDataCharacter(Ref<BitArray> row, FinderPattern pattern, bool isOddPattern, bool leftChar)
{
    std::vector<int>& counters = getDataCharacterCounters();
    for (size_t x = 0; x < counters.size(); x++) {
        counters[x] = 0;
    }

    if (leftChar) {
        recordPatternInReverse(row, pattern.getStartEnd()[0], counters);
    } else {
        recordPattern(row, pattern.getStartEnd()[1], counters);
        // reverse it
        for (size_t i = 0, j = counters.size() - 1; i < j; i++, j--) {
            int temp = counters[i];
            counters[i] = counters[j];
            counters[j] = temp;
        }
    } //counters[] has the pixels of the module

    int numModules = 17; //left and right data characters have all the same length
    float elementWidth = MathUtils::sum(counters) / static_cast<float>(numModules);

    // Sanity check: element width for pattern and the character should match
    float expectedElementWidth = (pattern.getStartEnd()[1] - pattern.getStartEnd()[0]) / 15.0f;
    if (std::abs(elementWidth - expectedElementWidth) / expectedElementWidth > 0.3f) {
        throw NotFoundException();
    }

    std::vector<int>& oddCounts(getOddCounts());
    std::vector<int>& evenCounts(getEvenCounts());
    std::vector<float>& oddRoundingErrors(getOddRoundingErrors());
    std::vector<float>& evenRoundingErrors(getEvenRoundingErrors());

    for (size_t i = 0; i < counters.size(); i++) {
        float value = 1.0f * counters[i] / elementWidth;
        int count = static_cast<int>(value + 0.5f); // Round
        if (count < 1) {
            if (value < 0.3f) {
                throw NotFoundException();
            }
            count = 1;
        } else if (count > 8) {
            if (value > 8.7f) {
                throw NotFoundException();
            }
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

    adjustOddEvenCounts(numModules);

    size_t weightRowNumber = static_cast<size_t>(4 * pattern.getValue() + (isOddPattern ? 0 : 2) + (leftChar ? 0 : 1) - 1);

    int oddSum = 0;
    int oddChecksumPortion = 0;
    for (int i = oddCounts.size() - 1; i >= 0; i--) {
        if (isNotA1left(pattern, isOddPattern, leftChar)) {
            int weight = WEIGHTS[weightRowNumber][2 * i];
            oddChecksumPortion += oddCounts[i] * weight;
        }
        oddSum += oddCounts[i];
    }
    int evenChecksumPortion = 0;
    for (int i = evenCounts.size() - 1; i >= 0; i--) {
        if (isNotA1left(pattern, isOddPattern, leftChar)) {
            int weight = WEIGHTS[weightRowNumber][2 * i + 1];
            evenChecksumPortion += evenCounts[i] * weight;
        }
    }
    int checksumPortion = oddChecksumPortion + evenChecksumPortion;

    if ((oddSum & 0x01) != 0 || oddSum > 13 || oddSum < 4) {
        throw NotFoundException();
    }

    size_t group = static_cast<size_t>((13 - oddSum) / 2);
    int oddWidest = SYMBOL_WIDEST[group];
    int evenWidest = 9 - oddWidest;
    int vOdd = RSSUtils::getRSSvalue(oddCounts, oddWidest, true);
    int vEven = RSSUtils::getRSSvalue(evenCounts, evenWidest, false);
    int tEven = EVEN_TOTAL_SUBSET[group];
    int gSum = GSUM[group];
    int value = vOdd * tEven + vEven + gSum;

    return DataCharacter(value, checksumPortion);
}

bool RSSExpandedReader::isNotA1left(FinderPattern pattern, bool isOddPattern, bool leftChar) {
    // A1: pattern.getValue is 0 (A), and it's an oddPattern, and it is a left char
    return !(pattern.getValue() == 0 && isOddPattern && leftChar);
}

void RSSExpandedReader::adjustOddEvenCounts(int numModules){

    int oddSum = MathUtils::sum(getOddCounts());
    int evenSum = MathUtils::sum(getEvenCounts());

    bool incrementOdd = false;
    bool decrementOdd = false;

    if (oddSum > 13) {
        decrementOdd = true;
    } else if (oddSum < 4) {
        incrementOdd = true;
    }
    bool incrementEven = false;
    bool decrementEven = false;
    if (evenSum > 13) {
        decrementEven = true;
    } else if (evenSum < 4) {
        incrementEven = true;
    }

    int mismatch = oddSum + evenSum - numModules;
    bool oddParityBad = (oddSum & 0x01) == 1;
    bool evenParityBad = (evenSum & 0x01) == 0;
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
        std::vector<int>& oddCounts(getOddCounts());
        std::vector<float>& oddRoundingErrors(getOddRoundingErrors());
        increment(oddCounts, oddRoundingErrors);
    }
    if (decrementOdd) {
        std::vector<int>& oddCounts(getOddCounts());
        std::vector<float>& oddRoundingErrors(getOddRoundingErrors());
        decrement(oddCounts, oddRoundingErrors);
    }
    if (incrementEven) {
        if (decrementEven) {
            throw NotFoundException();
        }
        std::vector<int>& evenCounts(getEvenCounts());
        std::vector<float>& oddRoundingErrors(getOddRoundingErrors());
        increment(evenCounts, oddRoundingErrors);
    }
    if (decrementEven) {
        std::vector<int>& evenCounts(getEvenCounts());
        std::vector<float>& evenRoundingErrors(getEvenRoundingErrors());
        decrement(evenCounts, evenRoundingErrors);
    }
}


}
}
}
