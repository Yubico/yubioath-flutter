#include "RSSUtils.h"

namespace zxing {
namespace oned {
namespace rss {

int RSSUtils::getRSSvalue(std::vector<int> widths, int maxWidth, bool noNarrow)
{
    int n = 0;
    for (int width : widths) {
        n += width;
    }
    int val = 0;
    int narrowMask = 0;
    int elements = widths.size();
    for (int bar = 0; bar < elements - 1; bar++) {
        int elmWidth;
        for (elmWidth = 1, narrowMask |= 1 << bar;
             elmWidth < widths[bar];
             elmWidth++, narrowMask &= ~(1 << bar)) {
            int subVal = combins(n - elmWidth - 1, elements - bar - 2);
            if (noNarrow && (narrowMask == 0) &&
                    (n - elmWidth - (elements - bar - 1) >= elements - bar - 1)) {
                subVal -= combins(n - elmWidth - (elements - bar),
                                  elements - bar - 2);
            }
            if (elements - bar - 1 > 1) {
                int lessVal = 0;
                for (int mxwElement = n - elmWidth - (elements - bar - 2);
                     mxwElement > maxWidth; mxwElement--) {
                    lessVal += combins(n - elmWidth - mxwElement - 1,
                                       elements - bar - 3);
                }
                subVal -= lessVal * (elements - 1 - bar);
            } else if (n - elmWidth > maxWidth) {
                subVal--;
            }
            val += subVal;
        }
        n -= elmWidth;
    }
    return val;
}

int RSSUtils::combins(int n, int r)
{
    int maxDenom;
    int minDenom;
    if (n - r > r) {
        minDenom = r;
        maxDenom = n - r;
    } else {
        minDenom = n - r;
        maxDenom = r;
    }
    int val = 1;
    int j = 1;
    for (int i = n; i > maxDenom; i--) {
        val *= i;
        if (j <= minDenom) {
            val /= j;
            j++;
        }
    }
    while (j <= minDenom) {
        val /= j;
        j++;
    }
    return val;
}

}
}
}
