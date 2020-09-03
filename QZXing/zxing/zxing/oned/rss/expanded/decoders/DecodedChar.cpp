#include "DecodedChar.h"

namespace zxing {
namespace oned {
namespace rss {

DecodedChar::DecodedChar(int newPosition, char value)
    : DecodedObject (newPosition), m_value(value)
{

}

char DecodedChar::getValue() const
{
    return m_value;
}

bool DecodedChar::isFNC1() const
{
    return m_value == FNC1;
}

}
}
}
