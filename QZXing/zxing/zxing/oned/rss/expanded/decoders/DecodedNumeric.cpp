#include "DecodedNumeric.h"

namespace zxing {
namespace oned {
namespace rss {

DecodedNumeric::DecodedNumeric(int newPosition, int firstDigit, int secondDigit)
    : DecodedObject(newPosition)
{

    if (firstDigit < 0 || firstDigit > 10 || secondDigit < 0 || secondDigit > 10) {
        throw FormatException::getFormatInstance();
    }

    m_newPosition = newPosition;
    m_firstDigit  = firstDigit;
    m_secondDigit = secondDigit;
}

DecodedNumeric::DecodedNumeric(const DecodedNumeric *other)
    : DecodedObject (other == nullptr ? 0 : other->m_newPosition)
{
    m_newPosition = other == nullptr ? 0 : other->m_newPosition;
    m_firstDigit  = other == nullptr ? 0 : other->m_firstDigit;
    m_secondDigit = other == nullptr ? 0 : other->m_secondDigit;
}

int DecodedNumeric::getFirstDigit() const
{
    return m_firstDigit;
}

int DecodedNumeric::getSecondDigit() const
{
    return m_secondDigit;
}

int DecodedNumeric::getValue() const
{
    return m_firstDigit * 10 + m_secondDigit;
}

bool DecodedNumeric::isFirstDigitFNC1() const
{
    return m_firstDigit == FNC1;
}

bool DecodedNumeric::isSecondDigitFNC1() const
{
    return m_secondDigit == FNC1;
}

}
}
}
