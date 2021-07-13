#include "Pair.h"

namespace zxing {
namespace oned {
namespace rss {

Pair::Pair(int value, int checksumPortion, FinderPattern finderPattern)
    : DataCharacter (value, checksumPortion), m_finderPattern(finderPattern)
{

}

Pair::Pair()
    : DataCharacter (0, 0), m_finderPattern(FinderPattern()), m_count(0)
{

}

FinderPattern& Pair::getFinderPattern()
{
    return m_finderPattern;
}

int Pair::getCount() const
{
    return m_count;
}

void Pair::incrementCount()
{
    m_count++;
}

bool Pair::isValid() const
{
    return m_finderPattern.isValid();
}

}
}
}
