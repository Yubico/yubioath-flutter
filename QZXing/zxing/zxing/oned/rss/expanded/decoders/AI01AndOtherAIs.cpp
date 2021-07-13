#include "AI01AndOtherAIs.h"
#include <zxing/common/StringUtils.h>

namespace zxing {
namespace oned {
namespace rss {

AI01AndOtherAIs::AI01AndOtherAIs(Ref<BitArray> information)
    : AI01decoder(information)
{

}

String AI01AndOtherAIs::parseInformation()
{
    String buff("(01)");

    int initialGtinPosition = buff.length();
    int firstGtinDigit = getGeneralDecoder().extractNumericValueFromBitArray(HEADER_SIZE, 4);
    buff.append(common::StringUtils::intToStr(firstGtinDigit));

    encodeCompressedGtinWithoutAI(buff, HEADER_SIZE + 4, initialGtinPosition);

    return getGeneralDecoder().decodeAllCodes(buff, HEADER_SIZE + 44);
}

}
}
}
