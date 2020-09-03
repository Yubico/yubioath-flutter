#include "BitArrayBuilder.h"

namespace zxing {
namespace oned {
namespace rss {

Ref<BitArray> BitArrayBuilder::buildBitArray(std::vector<ExpandedPair> pairs)
{
    int charNumber = static_cast<int>(pairs.size() * 2) - 1;
    if (pairs[pairs.size() - 1].getRightChar().getValue() == 0) {
        charNumber -= 1;
    }

    int size = 12 * charNumber;

    Ref<BitArray> binary(new BitArray(int(size)));
    int accPos = 0;

    ExpandedPair firstPair = pairs[0];
    int firstValue = firstPair.getRightChar().getValue();
    for (int i = 11; i >= 0; --i) {
        if ((firstValue & (1 << i)) != 0) {
            binary->set(accPos);
        }
        accPos++;
    }

    for (size_t i = 1; i < pairs.size(); ++i) {
        ExpandedPair currentPair = pairs[i];

        int leftValue = currentPair.getLeftChar().getValue();
        for (int j = 11; j >= 0; --j) {
            if ((leftValue & (1 << j)) != 0) {
                binary->set(accPos);
            }
            accPos++;
        }

        if (currentPair.getRightChar().getValue() != 0) {
            int rightValue = currentPair.getRightChar().getValue();
            for (int j = 11; j >= 0; --j) {
                if ((rightValue & (1 << j)) != 0) {
                    binary->set(accPos);
                }
                accPos++;
            }
        }
    }
    return binary;
}

}
}
}
