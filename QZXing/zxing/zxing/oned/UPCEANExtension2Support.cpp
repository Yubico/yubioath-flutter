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

#include <zxing/oned/UPCEANExtension2Support.h>
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

    for (int x = 0; x < 2 && rowOffset < end; x++) {
        int bestMatch = UPCEANReader::decodeDigit(row, counters, rowOffset,
                                                  UPCEANReader::L_AND_G_PATTERNS);
        resultString += static_cast<char>('0' + bestMatch % 10);
        for (int counter : counters) {
            rowOffset += counter;
        }
        if (bestMatch >= 10) {
            lgPatternFound |= 1 << (1 - x);
        }
        if (x != 1) {
            // Read off separator if not last
            rowOffset = row->getNextSet(rowOffset);
            rowOffset = row->getNextUnset(rowOffset);
        }
    }

    if (resultString.length() != 2) {
        throw NotFoundException();
    }

    if (std::atoi(resultString.c_str()) % 4 !=lgPatternFound) {
        throw NotFoundException();
    }

    return rowOffset;
}

Ref<Result> UPCEANExtension2Support::decodeRow(int rowNumber, Ref<BitArray> row, int extStartRangeBegin, int extStartRangeEnd)
{
    std::string resultString;
    int range = decodeMiddle(row, extStartRangeEnd, resultString);

    ResultMetadata metadata;
    metadata.put(ResultMetadata::ISSUE_NUMBER, std::atoi(resultString.c_str()));

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
