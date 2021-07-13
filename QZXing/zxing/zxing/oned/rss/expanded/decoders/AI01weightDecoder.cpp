#include "AI01weightDecoder.h"
#include <zxing/common/StringUtils.h>

namespace zxing {
namespace oned {
namespace rss {

AI01weightDecoder::AI01weightDecoder(Ref<BitArray> information)
    : AI01decoder(information)
{

}

void AI01weightDecoder::encodeCompressedWeight(String &buf, int currentPos, int weightSize)
{
    int originalWeightNumeric = getGeneralDecoder().extractNumericValueFromBitArray(currentPos, weightSize);
    addWeightCode(buf, originalWeightNumeric);

    int weightNumeric = checkWeight(originalWeightNumeric);

    int currentDivisor = 100000;
    for (int i = 0; i < 5; ++i) {
        if (weightNumeric / currentDivisor == 0) {
            buf.append('0');
        }
        currentDivisor /= 10;
    }
    buf.append(common::StringUtils::intToStr(weightNumeric));
}

}
}
}
