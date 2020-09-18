#include "AI01392xDecoder.h"
#include <zxing/common/StringUtils.h>

namespace zxing {
namespace oned {
namespace rss {

AI01392xDecoder::AI01392xDecoder(Ref<BitArray> information)
    : AI01decoder(information)
{

}

String AI01392xDecoder::parseInformation()
{
    if (getInformation()->getSize() < HEADER_SIZE + GTIN_SIZE) {
        throw NotFoundException();
    }

    String buf("");

    encodeCompressedGtin(buf, HEADER_SIZE);

    int lastAIdigit =
            getGeneralDecoder().extractNumericValueFromBitArray(HEADER_SIZE + GTIN_SIZE, LAST_DIGIT_SIZE);
    buf.append("(392");
    buf.append(common::StringUtils::intToStr(lastAIdigit));
    buf.append(')');

    String stub("");

    DecodedInformation decodedInformation =
            getGeneralDecoder().decodeGeneralPurposeField(HEADER_SIZE + GTIN_SIZE + LAST_DIGIT_SIZE, stub);
    buf.append(decodedInformation.getNewString().getText());

    return buf;
}

}
}
}
