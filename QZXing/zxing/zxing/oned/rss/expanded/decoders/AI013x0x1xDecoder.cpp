#include "AI013x0x1xDecoder.h"
#include <zxing/common/StringUtils.h>

namespace zxing {
namespace oned {
namespace rss {

AI013x0x1xDecoder::AI013x0x1xDecoder(Ref<BitArray> information, String firstAIdigits, String dateCode)
    : AI01weightDecoder(information), m_dateCode(dateCode), m_firstAIdigits(firstAIdigits)
{

}

String AI013x0x1xDecoder::parseInformation()
{
    if (getInformation()->getSize() != HEADER_SIZE + GTIN_SIZE + WEIGHT_SIZE + DATE_SIZE) {
        throw NotFoundException();
    }

    String buf("");

    encodeCompressedGtin(buf, HEADER_SIZE);
    encodeCompressedWeight(buf, HEADER_SIZE + GTIN_SIZE, WEIGHT_SIZE);
    encodeCompressedDate(buf, HEADER_SIZE + GTIN_SIZE + WEIGHT_SIZE);

    return buf;
}

void AI013x0x1xDecoder::encodeCompressedDate(String &buf, int currentPos)
{
    int numericDate = getGeneralDecoder().extractNumericValueFromBitArray(currentPos, DATE_SIZE);
    if (numericDate == 38400) {
        return;
    }

    buf.append('(');
    buf.append(m_dateCode.getText());
    buf.append(')');

    int day   = numericDate % 32;
    numericDate /= 32;
    int month = numericDate % 12 + 1;
    numericDate /= 12;
    int year  = numericDate;

    if (year / 10 == 0) {
        buf.append('0');
    }
    buf.append(common::StringUtils::intToStr(year));
    if (month / 10 == 0) {
        buf.append('0');
    }
    buf.append(common::StringUtils::intToStr(month));
    if (day / 10 == 0) {
        buf.append('0');
    }
    buf.append(common::StringUtils::intToStr(day));
}

void AI013x0x1xDecoder::addWeightCode(String &buf, int weight)
{
    buf.append('(');
    buf.append(m_firstAIdigits.getText());
    buf.append(common::StringUtils::intToStr(weight / 100000));
    buf.append(')');
}

int AI013x0x1xDecoder::checkWeight(int weight)
{
    return weight % 100000;
}

}
}
}
