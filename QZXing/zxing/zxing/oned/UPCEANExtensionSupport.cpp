/*
* Copyright 2008 ZXing authors
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
* 2019-05-08 translation from Java into C++
*/

#include <zxing/oned/UPCEANExtensionSupport.h>
#include <zxing/oned/UPCEANExtension5Support.h>
#include <zxing/oned/UPCEANExtension2Support.h>
#include <zxing/oned/UPCEANReader.h>
#include <zxing/Result.h>
#include <zxing/common/BitArray.h>
#include <zxing/NotFoundException.h>

namespace zxing {
namespace oned {

static const std::vector<int> EXTENSION_START_PATTERN = { 1, 1, 2 };

Ref<Result> UPCEANExtensionSupport::decodeRow(int rowNumber, Ref<BitArray> row, int rowOffset)
{
    UPCEANReader::Range extStartRange = UPCEANReader::findGuardPattern(row, rowOffset, false, EXTENSION_START_PATTERN);

    try {
        return UPCEANExtension5Support::decodeRow(rowNumber, row, extStartRange[0], extStartRange[1]);
    } catch (NotFoundException const& /*nfe*/) {
        return UPCEANExtension2Support::decodeRow(rowNumber, row, extStartRange[0], extStartRange[1]);
    }
}

} // oned
} // zxing
