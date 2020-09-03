#include "AI01393xDecoder.h"

#include "DecodedInformation.h"
#include <zxing/FormatException.h>
#include <zxing/NotFoundException.h>
#include <zxing/common/StringUtils.h>

namespace zxing {
namespace oned {
namespace rss {

AI01393xDecoder::AI01393xDecoder(Ref<BitArray> information)
    : AI01decoder(information)
{

}

String AI01393xDecoder::parseInformation()
{
    if (getInformation()->getSize() < HEADER_SIZE + GTIN_SIZE) {
        throw NotFoundException();
    }

    String buf("");

    encodeCompressedGtin(buf, HEADER_SIZE);

    int lastAIdigit =
            getGeneralDecoder().extractNumericValueFromBitArray(HEADER_SIZE + GTIN_SIZE, LAST_DIGIT_SIZE);

    buf.append("(393");
    buf.append(common::StringUtils::intToStr(lastAIdigit));
    buf.append(')');

    int firstThreeDigits = getGeneralDecoder().extractNumericValueFromBitArray(
                HEADER_SIZE + GTIN_SIZE + LAST_DIGIT_SIZE, FIRST_THREE_DIGITS_SIZE);
    if (firstThreeDigits / 100 == 0) {
        buf.append('0');
    }
    if (firstThreeDigits / 10 == 0) {
        buf.append('0');
    }
    buf.append(common::StringUtils::intToStr(firstThreeDigits));

    String stub("");

    DecodedInformation generalInformation = getGeneralDecoder().decodeGeneralPurposeField(
                HEADER_SIZE + GTIN_SIZE + LAST_DIGIT_SIZE + FIRST_THREE_DIGITS_SIZE, stub);
    buf.append(generalInformation.getNewString().getText());

    return buf;
}

}
}
}
