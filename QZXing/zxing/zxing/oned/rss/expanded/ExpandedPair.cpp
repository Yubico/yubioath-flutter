#include "ExpandedPair.h"
#include <zxing/common/StringUtils.h>

namespace zxing {
namespace oned {
namespace rss {

ExpandedPair::ExpandedPair(DataCharacter leftChar, DataCharacter rightChar, FinderPattern finderPattern)
    : m_leftChar(leftChar),
      m_rightChar(rightChar),
      m_finderPattern(finderPattern)
{

}

ExpandedPair::ExpandedPair(const ExpandedPair *other)
{
    m_leftChar = other != nullptr ? other->m_leftChar : DataCharacter();
    m_rightChar = other != nullptr ? other->m_rightChar : DataCharacter();
    m_finderPattern = other != nullptr ? other->m_finderPattern : nullptr;
}

DataCharacter& ExpandedPair::getLeftChar()
{
    return m_leftChar;
}

DataCharacter& ExpandedPair::getRightChar()
{
    return m_rightChar;
}

FinderPattern& ExpandedPair::getFinderPattern()
{
    return m_finderPattern;
}

bool ExpandedPair::mustBeLast() const
{
    return m_rightChar.getValue() == 0;
}

String ExpandedPair::toString() const
{
    return String(String("[ ").getText() + m_leftChar.toString().getText() + String(" , ").getText() +
                  m_rightChar.toString().getText() + " : " +
                  (m_finderPattern.getValue() != 0 ? "null" : common::StringUtils::intToStr(m_finderPattern.getValue())) + " ]");
}

bool ExpandedPair::equals(const ExpandedPair &other) const
{
    return m_leftChar.equals(other.m_leftChar) &&
            m_rightChar.equals(other.m_rightChar) &&
            m_finderPattern.equals(other.m_finderPattern);
}


int ExpandedPair::hashCode() const
{
    return m_leftChar.hashCode() & m_rightChar.hashCode() & m_finderPattern.hashCode();
}

}
}
}
