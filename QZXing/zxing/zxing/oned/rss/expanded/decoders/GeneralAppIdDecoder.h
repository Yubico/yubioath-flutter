#ifndef GENERAL_APP_ID_DECODER_H
#define GENERAL_APP_ID_DECODER_H
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

#include <zxing/common/Counted.h>
#include <zxing/common/BitArray.h>
#include <zxing/common/Str.h>
#include <zxing/IllegalStateException.h>
#include "CurrentParsingState.h"
#include "DecodedInformation.h"
#include "DecodedNumeric.h"
#include "FieldParser.h"
#include "BlockParsedResult.h"
#include "DecodedChar.h"

// VC++
namespace zxing {

namespace oned {

namespace rss {

class GeneralAppIdDecoder
{

public:
    GeneralAppIdDecoder(Ref<BitArray> information);

    String decodeAllCodes(String &buff, int initialPosition);

    bool isStillNumeric(int pos) const;

    DecodedNumeric *decodeNumeric(int pos);

    int extractNumericValueFromBitArray(int pos, int bits);

    static int extractNumericValueFromBitArray(Ref<BitArray> information, int pos, int bits);

    DecodedInformation decodeGeneralPurposeField(int pos, String &remaining);

    DecodedInformation parseBlocks();

    BlockParsedResult *parseNumericBlock();

    BlockParsedResult *parseIsoIec646Block();

    BlockParsedResult *parseAlphaBlock();

    bool isStillIsoIec646(int pos);

    DecodedChar decodeIsoIec646(int pos);

    bool isStillAlpha(int pos);

    DecodedChar decodeAlphanumeric(int pos);

    bool isAlphaTo646ToAlphaLatch(int pos);

    bool isAlphaOr646ToNumericLatch(int pos);

    bool isNumericToAlphaNumericLatch(int pos);

private:
    Ref<BitArray> m_information;
    CurrentParsingState m_current;
    String m_buffer;

};
}
}
}

#endif
