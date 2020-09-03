#include "Counted.h"

namespace zxing {

Counted::Counted() :
    count_(0)
{
}

Counted::~Counted()
{
}

Counted *Counted::retain()
{
    count_++;
    return this;
}

void Counted::release()
{
    count_--;
    if (count_ == 0) {
      count_ = 0xDEADF001;
      delete this;
    }
}

size_t Counted::count() const
{
    return count_;
}



}
