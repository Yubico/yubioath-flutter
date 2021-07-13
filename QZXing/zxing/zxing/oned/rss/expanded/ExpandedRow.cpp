#include "ExpandedRow.h"

namespace zxing {
namespace oned {
namespace rss {

ExpandedRow::ExpandedRow(std::vector<ExpandedPair> pairs, int rowNumber, bool wasReversed)
    : m_pairs(pairs),
      m_rowNumber(rowNumber),
      m_wasReversed(wasReversed)
{

}

ExpandedRow::ExpandedRow(const ExpandedRow *other)
{
    m_pairs = other != nullptr ? other->m_pairs : std::vector<ExpandedPair>();
    m_rowNumber = other != nullptr ? other->m_rowNumber : 0;
    m_wasReversed = other != nullptr ? other->m_wasReversed : false;
}

std::vector<ExpandedPair> &ExpandedRow::getPairs()
{
    return m_pairs;
}

int ExpandedRow::getRowNumber()
{
    return m_rowNumber;
}

bool ExpandedRow::isEquivalent(std::vector<ExpandedPair> otherPairs) const
{
    if (m_pairs.size() != otherPairs.size()) {
        return false;
    }

    for (size_t i = 0; i < m_pairs.size(); i++) {
        if (!m_pairs[i].equals(otherPairs[i])) {
            return false;
        }
    }

    return true;
}

String ExpandedRow::toString()
{
    String result("{ ");
    for (const ExpandedPair &i : m_pairs) {
        result.append(i.toString().getText());
    }
    result.append(" }");
    return result;
}

bool ExpandedRow::equals(const ExpandedRow &other) const
{
    return isEquivalent(other.m_pairs) && m_wasReversed == other.m_wasReversed;
}

}
}
}
