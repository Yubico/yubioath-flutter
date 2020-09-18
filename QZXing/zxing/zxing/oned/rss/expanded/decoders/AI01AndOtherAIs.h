#ifndef AI01_AND_OTHER_AIS_H
#define AI01_AND_OTHER_AIS_H
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

#include "AI01decoder.h"

#include <zxing/FormatException.h>
#include <zxing/NotFoundException.h>
#include <zxing/common/BitArray.h>
#include <zxing/common/Str.h>

namespace zxing {

namespace oned {

namespace rss {

class AI01AndOtherAIs : public AI01decoder
{

    static const int HEADER_SIZE = 1 + 1 + 2;   //first bit encodes the linkage flag,
                                                //the second one is the encodation method, and the other two are for the variable length
public:
    AI01AndOtherAIs(Ref<BitArray> information);

    virtual String parseInformation() override;
};

}
}
}

#endif
