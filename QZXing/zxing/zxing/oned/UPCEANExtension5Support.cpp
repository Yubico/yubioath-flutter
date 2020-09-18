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

#include <zxing/oned/UPCEANExtension5Support.h>
#include <zxing/oned/UPCEANReader.h>
#include <zxing/oned/OneDResultPoint.h>
#include <zxing/common/BitArray.h>
#include <zxing/Result.h>
#include <zxing/NotFoundException.h>

#include <sstream>
#include <iomanip>
#include <cstdlib>

namespace zxing {
namespace oned {

static int extensionChecksum(const std::string& s)
{
    int length = static_cast<int>(s.length());
    int sum = 0;
    for (int i = length - 2; i >= 0; i -= 2) {
        sum += (int)s[i] - (int) '0';
    }
    sum *= 3;
    for (int i = length - 1; i >= 0; i -= 2) {
        sum += (int)s[i] - (int) '0';
    }
    sum *= 3;
    return sum % 10;
}

static int determineCheckDigit(int lgPatternFound)
{
    static const int CHECK_DIGIT_ENCODINGS[] = {
        0x18, 0x14, 0x12, 0x11, 0x0C, 0x06, 0x03, 0x0A, 0x09, 0x05
    };
    for (int d = 0; d < 10; d++) {
        if (lgPatternFound == CHECK_DIGIT_ENCODINGS[d]) {
            return d;
        }
    }
    return -1;
}

static int decodeMiddle(Ref<BitArray> row, int rowOffset_, std::string& resultString)
{
    std::vector<int> counters(4);
    counters[0] = 0;
    counters[1] = 0;
    counters[2] = 0;
    counters[3] = 0;

    int end = row->getSize();
    int rowOffset = rowOffset_;

    int lgPatternFound = 0;

    for (int x = 0; x < 5 && rowOffset < end; x++) {
        int bestMatch = UPCEANReader::decodeDigit(row, counters, rowOffset,
                                                  UPCEANReader::L_AND_G_PATTERNS);
        resultString += static_cast<char>('0' + bestMatch % 10);
        for (int counter : counters) {
            rowOffset += counter;
        }
        if (bestMatch >= 10) {
            lgPatternFound |= 1 << (4 - x);
        }
        if (x != 4) {
            // Read off separator if not last
            rowOffset = row->getNextSet(rowOffset);
            rowOffset = row->getNextUnset(rowOffset);
        }
    }

    if (resultString.length() != 5) {
        throw NotFoundException();
    }

    int checkDigit = determineCheckDigit(lgPatternFound);
    if (extensionChecksum(resultString) != checkDigit) {
        throw NotFoundException();
    }

    return rowOffset;
}

static std::string parseExtension5String(const std::string& raw)
{
    std::string currency;
    switch (raw.front()) {
    case '0':
        currency = "\xa3";
        break;
    case '5':
        currency = "$";
        break;
    case '9':
        // Reference: http://www.jollytech.com
        if (raw == "90000") {
            // No suggested retail price
            return std::string();
        }
        if (raw == "99991") {
            // Complementary
            return "0.00";
        }
        if (raw == "99990") {
            return "Used";
        }
        // Otherwise... unknown currency?
        currency = "";
        break;
    default:
        currency = "";
        break;
    }
    int rawAmount = std::atoi(raw.substr(1).c_str());
    std::stringstream buf;
    buf << currency << std::fixed << std::setprecision(2) << (float(rawAmount) / 100);
    return buf.str();
}

Ref<Result> UPCEANExtension5Support::decodeRow(int rowNumber, Ref<BitArray> row, int extStartRangeBegin, int extStartRangeEnd)
{
    std::string resultString;
    int range = decodeMiddle(row, extStartRangeEnd, resultString);

    ResultMetadata metadata;
    std::string value = parseExtension5String(resultString);
    if (!value.empty()) {
        metadata.put(ResultMetadata::SUGGESTED_PRICE, value);
    }

    ArrayRef< Ref<ResultPoint> > resultPoints(2);
    resultPoints[0] = Ref<OneDResultPoint>(new OneDResultPoint((extStartRangeBegin + extStartRangeEnd) / 2.0f,
                                           static_cast<float> (rowNumber)));
    resultPoints[1] = Ref<OneDResultPoint>(new OneDResultPoint(static_cast<float> (range),
                                           static_cast<float> (rowNumber)));

    return Ref<Result>(new Result(Ref<String>(new String(resultString)),
                                  ArrayRef<zxing::byte>(),
                                  resultPoints,
                                  BarcodeFormat::UPC_EAN_EXTENSION,
                                  "",
                                  metadata));
}

}
}
