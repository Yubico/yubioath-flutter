#ifndef EXPANDED_PAIR_H
#define EXPANDED_PAIR_H

/*
 * Copyright (C) 2010 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * 2019-07-17 translation from Java into C++
 */

/*
 * These authors would like to acknowledge the Spanish Ministry of Industry,
 * Tourism and Trade, for the support in the project TSI020301-2008-2
 * "PIRAmIDE: Personalizable Interactions with Resources on AmI-enabled
 * Mobile Dynamic Environments", led by Treelogic
 * ( http://www.treelogic.com/ ):
 *
 *   http://www.piramidepse.com/
 */

#include <zxing/oned/rss/FinderPattern.h>
#include <zxing/oned/rss/DataCharacter.h>
#include <zxing/common/Str.h>

namespace zxing {

namespace oned {

namespace rss {

class ExpandedPair
{

public:
    ExpandedPair(DataCharacter leftChar,
                 DataCharacter rightChar,
                 FinderPattern finderPattern);

    ExpandedPair(const ExpandedPair* other = nullptr);

    DataCharacter &getLeftChar();

    DataCharacter &getRightChar();

    FinderPattern &getFinderPattern();

    bool mustBeLast() const;

    String toString() const;

    bool equals(const ExpandedPair& other) const;

    int hashCode() const;

private:
    DataCharacter m_leftChar;
    DataCharacter m_rightChar;
    FinderPattern m_finderPattern;

};

}
}
}

#endif
