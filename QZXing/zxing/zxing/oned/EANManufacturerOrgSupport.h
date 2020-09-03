#ifndef ZXING_EAN_MANUFACTURER_ORG_SUPPORT_H
#define ZXING_EAN_MANUFACTURER_ORG_SUPPORT_H
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

#include <zxing/common/Counted.h>

#include <iostream>
#include <vector>

namespace zxing {

class String;

namespace oned {

class EANManufacturerOrgSupport
{
public:
    static Ref<String> lookupCountryIdentifier(Ref<String> &productCode);
};

}
}

#endif
