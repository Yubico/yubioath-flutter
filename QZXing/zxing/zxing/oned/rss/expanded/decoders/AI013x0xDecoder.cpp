#include "AI013x0xDecoder.h"

namespace zxing {
namespace oned {
namespace rss {

AI013x0xDecoder::AI013x0xDecoder(Ref<BitArray> information)
    : AI01weightDecoder(information)
{

}

String AI013x0xDecoder::parseInformation()
{
    if (getInformation()->getSize() != HEADER_SIZE + GTIN_SIZE + WEIGHT_SIZE) {
        throw NotFoundException();
    }

    String buf("");

    encodeCompressedGtin(buf, HEADER_SIZE);
    encodeCompressedWeight(buf, HEADER_SIZE + GTIN_SIZE, WEIGHT_SIZE);

    return buf;
}

}
}
}
