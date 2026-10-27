/*
 * Copyright (C) 2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

/// OTP keyboard character maps mirrored from the Android/ykman scancode tables.
enum OtpKeyboardLayouts {
    private static let encoded: [String: (String, String)] = [
        "MODHEX": ("62,63,64,65,66,67,68,69,6a,6b,6c,6e,72,74,75,76,42,43,44,45,46,47,48,49,4a,4b,4c,4e,52,54,55,56", "05060708090a0b0c0d0e0f111517181985868788898a8b8c8d8e8f9195979899"),
        "US": ("61,62,63,64,65,66,67,68,69,6a,6b,6c,6d,6e,6f,70,71,72,73,74,75,76,77,78,79,7a,41,42,43,44,45,46,47,48,49,4a,4b,4c,4d,4e,4f,50,51,52,53,54,55,56,57,58,59,5a,30,31,32,33,34,35,36,37,38,39,9,a,21,22,23,24,25,26,27,60,28,29,2a,2b,2c,2d,2e,2f,3a,3b,3c,3d,3e,3f,40,5b,5c,5d,5e,5f,7b,7d,7c,7e,20", "0405060708090a0b0c0d0e0f101112131415161718191a1b1c1d8485868788898a8b8c8d8e8f909192939495969798999a9b9c9d271e1f202122232425262b289eb4a0a1a2a43435a6a7a5ae362d3738b333b62eb7b89f2f3230a3adafb0b2b52c"),
        "UK": ("61,62,63,64,65,66,67,68,69,6a,6b,6c,6d,6e,6f,70,71,72,73,74,75,76,77,78,79,7a,41,42,43,44,45,46,47,48,49,4a,4b,4c,4d,4e,4f,50,51,52,53,54,55,56,57,58,59,5a,30,31,32,33,34,35,36,37,38,39,9,a,21,40,a3,24,25,26,27,60,28,29,2a,2b,2c,2d,2e,2f,3a,3b,3c,3d,3e,3f,22,5b,23,5d,5e,5f,7b,7d,7e,ac,20", "0405060708090a0b0c0d0e0f101112131415161718191a1b1c1d8485868788898a8b8c8d8e8f909192939495969798999a9b9c9d271e1f202122232425262b289eb4a0a1a2a43435a6a7a5ae362d3738b333b62eb7b89f2f3230a3adafb0b2b52c"),
        "DE": ("61,62,63,64,65,66,67,68,69,6a,6b,6c,6d,6e,6f,70,71,72,73,74,75,76,77,78,79,7a,41,42,43,44,45,46,47,48,49,4a,4b,4c,4d,4e,4f,50,51,52,53,54,55,56,57,58,59,5a,30,31,32,33,34,35,36,37,38,39,9,a,21,22,23,24,25,26,27,28,29,2a,2b,2c,2d,2e,2f,3a,3b,3c,3d,3e,3f,5e,5f,20,60,a7,b4,c4,d6,dc,df,e4,f6,fc", "0405060708090a0b0c0d0e0f101112131415161718191a1b1d1c8485868788898a8b8c8d8e8f909192939495969798999a9b9d9c271e1f202122232425262b289e9f32a1a2a3b2a5a6b030363837a4b7b664a7e4ad35b82cada02eb4b3af2d34332f"),
        "FR": ("61,62,63,64,65,66,67,68,69,6a,6b,6c,6d,6e,6f,70,71,72,73,74,75,76,77,78,79,7a,41,42,43,44,45,46,47,48,49,4a,4b,4c,4d,4e,4f,50,51,52,53,54,55,56,57,58,59,5a,30,31,32,33,34,35,36,37,38,39,9,a,20,21,22,24,25,26,27,28,29,2a,2b,2c,2d,2e,2f,3a,3b,3c,3d,5f,7f,a3,a7,b0,b2,b5,e0,e7,e8,e9,f9", "1405060708090a0b0c0d0e0f331112130415161718191d1b1c1a9485868788898a8b8c8d8e8fb39192938495969798999d9b9c9aa79e9fa0a1a2a3a4a5a62b282c382030b41e21222d31ae1023b6b73736642e252ab0b8ad35b12726241f34"),
        "IT": ("9,a,20,21,22,23,24,25,26,27,28,29,2a,2b,2c,2d,2e,2f,30,31,32,33,34,35,36,37,38,39,3a,3b,3c,3d,3e,3f,40,41,42,43,44,45,46,47,48,49,4a,4b,4c,4d,4e,4f,50,51,52,53,54,55,56,57,58,59,5a,5c,5e,5f,60,61,62,63,64,65,66,67,68,69,6a,6b,6c,6d,6e,6f,70,71,72,73,74,75,76,77,78,79,7a,7c,a3,a7,b0,e7,e8,e9,e0,ec,f2,f9", "2b282c9e9f32a1a2a32da5a65530363863a4271e1f20212223242526b7b664a7e4ad248485868788898a8b8c8d8e8f909192939495969798999a9b9c9d35aeb8ad0405060708090a0b0c0d0e0f101112131415161718191a1b1c1db5a0b2b4b32faf342e3331"),
        "BEPO": ("9,a,20,21,22,23,24,25,27,28,29,2a,2b,2c,2d,2e,2f,30,31,32,33,34,35,36,37,38,39,3a,3b,3d,3f,40,41,42,43,44,45,46,47,48,49,4a,4b,4c,4d,4e,4f,50,51,52,53,54,55,56,57,58,59,5a,60,61,62,63,64,65,66,67,68,69,6a,6b,6c,6d,6e,6f,70,71,72,73,74,75,76,77,78,79,7a,a0,ab,b0,bb,c0,c7,c8,c9,ca,e0,e7,e8,e9,ea", "aba82c9c1eb5352e11212227240a251926a79e9fa0a1a2a3a4a5a6998a2d912384948b8c89b8b6b787938592b4b39588908f8e8d9698b0869bafae04140b0c093836370713051234331508100f0e0d161830061b2fac1fad209db1979ae41d31171a64"),
        "NORMAN": ("61,62,63,64,65,66,67,68,69,6a,6b,6c,6d,6e,6f,70,71,72,73,74,75,76,77,78,79,7a,41,42,43,44,45,46,47,48,49,4a,4b,4c,4d,4e,4f,50,51,52,53,54,55,56,57,58,59,5a,30,31,32,33,34,35,36,37,38,39,9,a,21,22,23,24,25,26,27,60,28,29,2a,2b,2c,2d,2e,2f,3a,3b,3c,3d,3e,3f,40,5b,5c,5d,5e,5f,7b,7d,7c,7e,20", "0405060807150a330e1c1712100d0f11140c160918191a1b0b1d8485868887958ab38e9c9792908d8f91948c968998999a9b8b9d271e1f202122232425262b289eb4a0a1a2a43435a6a7a5ae362d3738b313b62eb7b89f2f3230a3adafb0b2b52c"),
    ]

    static var characters: [String: [String]] {
        Dictionary(
            uniqueKeysWithValues: encoded.keys.map {
                ($0, (try? alphabet(for: $0))?.map(String.init) ?? [])
            }
        )
    }

    static func alphabet(for name: String) throws -> [Character] {
        guard let (codePoints, _) = encoded[name] else {
            throw OtpError.message("Unsupported keyboard layout: \(name)")
        }
        return codePoints.split(separator: ",")
            .compactMap { UInt32($0, radix: 16) }
            .compactMap(UnicodeScalar.init)
            .map(Character.init)
    }

    static func scanCodes(for text: String, layout: String) throws -> Data {
        guard let (_, rawCodes) = encoded[layout] else {
            throw OtpError.message("Unsupported keyboard layout: \(layout)")
        }
        let alphabet = try alphabet(for: layout)
        let codes = stride(from: 0, to: rawCodes.count, by: 2).compactMap {
            let start = rawCodes.index(rawCodes.startIndex, offsetBy: $0)
            let end = rawCodes.index(start, offsetBy: 2)
            return UInt8(rawCodes[start..<end], radix: 16)
        }
        guard codes.count == alphabet.count else {
            throw OtpError.message("Invalid keyboard layout data")
        }
        let mapping = Dictionary(uniqueKeysWithValues: zip(alphabet, codes))
        let result = try text.map { character -> UInt8 in
            guard let code = mapping[character] else {
                throw OtpError.message("Unsupported character for keyboard layout: \(character)")
            }
            return code
        }
        guard result.count <= 38 else {
            throw OtpError.message("Static password cannot exceed 38 characters")
        }
        return Data(result)
    }
}
