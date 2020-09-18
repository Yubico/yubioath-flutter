#include "AI01decoder.h"
#include <zxing/common/StringUtils.h>

namespace zxing {
namespace oned {
namespace rss {

AI01decoder::AI01decoder(Ref<BitArray> information)
    : AbstractExpandedDecoder(information)
{

}

void AI01decoder::encodeCompressedGtin(String &buf, int currentPos)
{
    buf.append("(01)");
    int initialPosition = buf.length();
    buf.append('9');

    encodeCompressedGtinWithoutAI(buf, currentPos, initialPosition);
}

void AI01decoder::encodeCompressedGtinWithoutAI(String &buf, int currentPos, int initialBufferPosition)
{
    for (int i = 0; i < 4; ++i) {
        int currentBlock = getGeneralDecoder().extractNumericValueFromBitArray(currentPos + 10 * i, 10);
        if (currentBlock / 100 == 0) {
            buf.append("0");
        }
        if (currentBlock / 10 == 0) {
            buf.append("0");
        }
        buf.append(common::StringUtils::intToStr(currentBlock));
    }

    appendCheckDigit(buf, initialBufferPosition);
}

void AI01decoder::appendCheckDigit(String &buf, int currentPos)
{
    int checkDigit = 0;
    for (int i = 0; i < 13; i++) {
        int digit = buf.charAt(i + currentPos) - '0';
        checkDigit += (i & 0x01) == 0 ? 3 * digit : digit;
    }

    checkDigit = 10 - (checkDigit % 10);
    if (checkDigit == 10) {
        checkDigit = 0;
    }

    buf.append(common::StringUtils::intToStr(checkDigit));
}


}
}
}
