#include "AI01320xDecoder.h"

namespace zxing {
namespace oned {
namespace rss {

AI01320xDecoder::AI01320xDecoder(Ref<BitArray> information)
    : AI013x0xDecoder(information)
{

}

void AI01320xDecoder::addWeightCode(String &buf, int weight)
{
    if (weight < 10000) {
        buf.append("(3202)");
    } else {
        buf.append("(3203)");
    }
}

int AI01320xDecoder::checkWeight(int weight)
{
    if (weight < 10000) {
        return weight;
    }
    return weight - 10000;
}

}
}
}
