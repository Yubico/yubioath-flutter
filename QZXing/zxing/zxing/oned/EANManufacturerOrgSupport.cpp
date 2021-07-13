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
*/

/*
 * Records EAN prefix to GS1 Member Organization, where the member organization
 * correlates strongly with a country. This is an imperfect means of identifying
 * a country of origin by EAN-13 barcode value. See
 * <a href="http://en.wikipedia.org/wiki/List_of_GS1_country_codes">
 * http://en.wikipedia.org/wiki/List_of_GS1_country_codes</a>.
 *
 * @author Sean Owen
 */

#include <zxing/oned/EANManufacturerOrgSupport.h>
#include <zxing/common/Str.h>

#include <cstdlib>

namespace zxing {
namespace oned {

struct Country {
    std::vector<int> range;
    std::string id;
};

static Country Countries[] {
    { {0,19},    "US/CA" },
    { {30,39},   "US" },
    { {60,139},  "US/CA" },
    { {300,379}, "FR" },
    { {380},     "BG" },
    { {383},     "SI" },
    { {385},     "HR" },
    { {387},     "BA" },
    { {400,440}, "DE" },
    { {450,459}, "JP" },
    { {460,469}, "RU" },
    { {471},     "TW" },
    { {474},     "EE" },
    { {475},     "LV" },
    { {476},     "AZ" },
    { {477},     "LT" },
    { {478},     "UZ" },
    { {479},     "LK" },
    { {480},     "PH" },
    { {481},     "BY" },
    { {482},     "UA" },
    { {484},     "MD" },
    { {485},     "AM" },
    { {486},     "GE" },
    { {487},     "KZ" },
    { {489},     "HK" },
    { {490,499}, "JP" },
    { {500,509}, "GB" },
    { {520},     "GR" },
    { {528},     "LB" },
    { {529},     "CY" },
    { {531},     "MK" },
    { {535},     "MT" },
    { {539},     "IE" },
    { {540,549}, "BE/LU" },
    { {560},     "PT" },
    { {569},     "IS" },
    { {570,579}, "DK" },
    { {590},     "PL" },
    { {594},     "RO" },
    { {599},     "HU" },
    { {600,601}, "ZA" },
    { {603},     "GH" },
    { {608},     "BH" },
    { {609},     "MU" },
    { {611},     "MA" },
    { {613},     "DZ" },
    { {616},     "KE" },
    { {618},     "CI" },
    { {619},     "TN" },
    { {621},     "SY" },
    { {622},     "EG" },
    { {624},     "LY" },
    { {625},     "JO" },
    { {626},     "IR" },
    { {627},     "KW" },
    { {628},     "SA" },
    { {629},     "AE" },
    { {640,649}, "FI" },
    { {690,695}, "CN" },
    { {700,709}, "NO" },
    { {729},     "IL" },
    { {730,739}, "SE" },
    { {740},     "GT" },
    { {741},     "SV" },
    { {742},     "HN" },
    { {743},     "NI" },
    { {744},     "CR" },
    { {745},     "PA" },
    { {746},     "DO" },
    { {750},     "MX" },
    { {754,755}, "CA" },
    { {759},     "VE" },
    { {760,769}, "CH" },
    { {770},     "CO" },
    { {773},     "UY" },
    { {775},     "PE" },
    { {777},     "BO" },
    { {779},     "AR" },
    { {780},     "CL" },
    { {784},     "PY" },
    { {785},     "PE" },
    { {786},     "EC" },
    { {789,790}, "BR" },
    { {800,839}, "IT" },
    { {840,849}, "ES" },
    { {850},     "CU" },
    { {858},     "SK" },
    { {859},     "CZ" },
    { {860},     "YU" },
    { {865},     "MN" },
    { {867},     "KP" },
    { {868,869}, "TR" },
    { {870,879}, "NL" },
    { {880},     "KR" },
    { {885},     "TH" },
    { {888},     "SG" },
    { {890},     "IN" },
    { {893},     "VN" },
    { {896},     "PK" },
    { {899},     "ID" },
    { {900,919}, "AT" },
    { {930,939}, "AU" },
    { {940,949}, "AZ" },
    { {955},     "MY" },
    { {958},     "MO" }
};

Ref<String> EANManufacturerOrgSupport::lookupCountryIdentifier(Ref<String>& productCode)
{
    int prefix = std::atoi(productCode->getText().substr(0, 3).c_str());
    int size = (sizeof(Countries) / sizeof(Countries[0]));
    for (int i = 0; i < size; i++) {
        std::vector<int> range = Countries[i].range;
        int start = range[0];
        if (prefix < start) {
            return Ref<String>();
        }
        int end = range.size() == 1 ? start : range[1];
        if (prefix <= end) {
            return Ref<String>(new String(Countries[i].id));
        }
    }
    return Ref<String>();
}

}
}
