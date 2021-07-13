#include "DataCharacter.h"
#include <zxing/common/StringUtils.h>

namespace zxing {
namespace oned {
namespace rss {

DataCharacter::DataCharacter(int value, int checksumPortion)
    : m_value(value), m_checksumPortion(checksumPortion)
{

}

DataCharacter::DataCharacter()
    : m_value(0), m_checksumPortion(0)
{

}

int DataCharacter::getValue() const
{
    return m_value;
}

int DataCharacter::getChecksumPortion() const
{
    return m_checksumPortion;
}

String DataCharacter::toString() const
{
    return String(common::StringUtils::intToStr(m_value) + '(' + common::StringUtils::intToStr(m_checksumPortion) + ')');
}

bool DataCharacter::equals(const DataCharacter &other) const
{
    return m_value == other.m_value && m_checksumPortion == other.m_checksumPortion;
}

int DataCharacter::hashCode() const
{
    return m_value & m_checksumPortion;
}

}
}
}
