#include "AI013103decoder.h"

namespace zxing {
namespace oned {
namespace rss {

AI013103decoder::AI013103decoder(Ref<BitArray> information)
    : AI013x0xDecoder(information)
{

}

void AI013103decoder::addWeightCode(String &buf, int /*weight*/)
{
    buf.append("(3103)");
}

int AI013103decoder::checkWeight(int weight)
{
    return weight;
}

}
}
}
