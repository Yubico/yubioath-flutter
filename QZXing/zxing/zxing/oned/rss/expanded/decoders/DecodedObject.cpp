#include "DecodedObject.h"

namespace zxing {
namespace oned {
namespace rss {

DecodedObject::DecodedObject(int newPosition)
    : m_newPosition(newPosition)
{

}

int DecodedObject::getNewPosition() const
{
    return m_newPosition;
}

}
}
}
