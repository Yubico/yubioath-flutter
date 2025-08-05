/*
 * Copyright (C) 2025 Yubico.
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

@file:Suppress("SpellCheckingInspection")

package com.yubico.authenticator.piv.utils

import com.yubico.authenticator.piv.data.hexStringToByteArray

object KeyMaterialTestData {
    object Rsa2048 {
        val PKCS12 = PKCS12_HEX.hexStringToByteArray()
        private const val PKCS12_HEX = "30820a1f020103308209d506092a864886f70d010701a08209c60482" +
                "09c2308209be3082042a06092a864886f70d010706a082041b308204170201003082041006092a8" +
                "64886f70d010701305f06092a864886f70d01050d3052303106092a864886f70d01050c30240410" +
                "73f69e2f73ce9cb317c38d10f0a0ef9602020800300c06082a864886f70d02090500301d0609608" +
                "64801650304012a041071b70f02b82756927b3b24e76f172835808203a0d8fcb1767999456491e9" +
                "779326c480afa903ca884394d3a665e718c5ddc48ec86941809ea3eea9bad66c2f67fbcf10fdeb1" +
                "c2adeb78b8322246f513095897c80fbac7a96125e37c69050b0af08f63599b0fdb549f08fa408c6" +
                "bf9b9843d640c8adbea7b0bd8678a75d02eaf3835ab232d50591f4a24087233c25db269fb250583" +
                "a7dec9044bb202e72d48711c02d8da107e1320e84e7ae802985bbda92801ee8324fa319507210f2" +
                "d67472a68c783b382ab9b7f4d0883c4be3bafc86dd58dcce6423fe8277e278ddaa6b47721118dc4" +
                "7b701bb3a50df9b277e8266d3953eb94f82b69bb34c22c001a817ae83066649f84f2868339f889f" +
                "7c71395a907eb5b3faa679cc5792760c60e6a1fdb59773685b4118db49708ecc9d615bcea97527c" +
                "b988921eadc1ea3fa0d371d63e0f132cf79f27382e0383bfecd6ede4b536850ef14bba5366ceb18" +
                "9a71fbeaffa1b18f26630ecb00410401e59756e7a90d4eba6b120a28da7c67789495ab964251fdd" +
                "1ce2e5f2c9207c467abdc1cca095b73e2a9065512d235176c52a48294f37456f11849ba16f4b99d" +
                "8e408b34f076f73017ee718001bebc8203408e945ba5055a36eb7c407678e4ee60997a189443637" +
                "08044807b1eee34bb03e4bda0a6887db73327f02e2c2ccc8f413573ee026debe659f45a494d8124" +
                "ab6ac7739b4174c2ae5095a478888a6e343f0738ab8889c4d682b5edad5a00dcf300882b973c5d4" +
                "08c0421a7b4fbe2d0487f7603a83ff123b5546abed33837bcbca755441549ddfd8698542cd69460" +
                "7e147ed03100c938a9de79e43120d4999d2b4ddf7480e64c5d1f979d8242186143ba0ad0cb9cc83" +
                "e920da8891d44c2f02c0e3558be51b95ba911a62cf35aac015178beb2e73969227970dae6ab30d5" +
                "d2dbfa22b751aff3679c836bfb69b2a9a2c31690f586326137edbb081b63b17dc2c9793d10c5248" +
                "d7aa2aaac1c075f3d22c53c178dd010e710d657be22932268ce48b803b629b51c02dd96f0111a2d" +
                "a5380e765f625be8ed42d3ef93cda0bda00bce579d8d7035e9d3283ac964c0495e972baa74f362c" +
                "69532ada2d9bd579f730dfe7a2b75c2cf3f2e47c55416b9533f5ac4870e1e63d2cd81c24bfddf64" +
                "f29b1f8f2224895a8bf2262a17681ec8a57f9034436d2124d3f69b790b0cbf9c822e1a97a87d5ce" +
                "70cdaa8b948b40da4560f451d99f4c4e21f13680dd0102539b8f9695fcfaca691bc6d6abcdb1d96" +
                "0de81b8a2055eaf9d15e3e355d2705b4eb770370bb9c4d019b37c32e72a46ddba979faa464fe0f0" +
                "26137dabd9778aff3223082058c06092a864886f70d010701a082057d0482057930820575308205" +
                "71060b2a864886f70d010c0a0102a082053930820535305f06092a864886f70d01050d305230310" +
                "6092a864886f70d01050c30240410f16373ea59850909c6ad2eaa94d1ad7e02020800300c06082a" +
                "864886f70d02090500301d060960864801650304012a0410b3f9462876bfee8df58eb03cae1eaab" +
                "c048204d024bea64756cf9aad643d3b3a41cbdf2096bfd1c5e74caa177fc02e0397956e55c866eb" +
                "a13b9a626ce6dc2a889075fb708a322abcb9c824dc4802e1d63d93cc51463770ac7e0d1078029ba" +
                "19be6f7f4bcacba22264da8cf1db41d5db7d6bcb80543487e894c03f2b412a009310dcd99ff9e20" +
                "18aa8b7441ee5df280492226b3e831b162de09e650009b58053a4a5d36c67fbd5b64c1481310f97" +
                "b17717c1bd75c81c927b99e0ca98c6c355c8f7d09565ced64fdb843c52d57c6e0cb5a84413c088d" +
                "1968d2696a6a0cb8375c445b700178c3b05fb1e1d11522ccb546714375bbaff717257f77245f434" +
                "24cc400227c576de6adb98a4865232ab4e12aac7e200ac1a16383cd24899794e4c2a37f73d6a4bc" +
                "7115d6ddffe7569f43ec15f3be0f07a2b69f54d9fd277cf1c055960d6e593276324d4ebcb9ef5f4" +
                "a0d92ba8e9eb4d6fb3f7a5979e096804fb6d9cbc420c93d213f66cb69591194e9f1f39b90382ee6" +
                "88cd080c8f5a327b8d40ab2541a69cd1cdb009165510be6757c11f14cf5f950e9e8098a3e600027" +
                "2f2b942afd7aa12723153971fe3a6325e495bfcb967c357c20fab3467f381d1038d2856d07e9bb5" +
                "90cc8b7de885f00edddd99a1fb152f9f953798d5385fd9d67c27d10773b5d2ac6cfbf13f0053092" +
                "1f27b54d969dfd76866ec26907512da97a35773db0049dae054c3fe9111638e74bdf0837b476b6c" +
                "2249849c854f72c3368d4b7d14d8c30c99e9370a1db5d3a78949a32af50d961b20b695d02aa6129" +
                "2a3c52aceb06c7f6b507fb06c397f45ffcf52f8a61b3ce5a4e79afcc5328d51c5300304f39ab9fc" +
                "f74a4a94f519c06bdf775678b12a760f86aa22cbb7a4e3f64d9d104354df79dadc7b42956cdfc7a" +
                "d27655a28ed980af67bca992f627ea91fbb4bd111e55ff04dd53c713f5cb21fbc4cdacb22e04812" +
                "f99ffc8273dbdec9efbdf61048e1dfaba5e9bbff63c2c8ec290fb5eb3aa3a3c2859b15eedcaa865" +
                "ed6f4040e64bdb23672fccee9dda445de2bad21f3c1b6d7b704aa376ca6d5813bca1b881f4cbf05" +
                "c99f6f7cceff2f76c17ca4a9e4524929cf41d9cf00ca74d3cce95dbe1e59fc95363a66dd8b7823f" +
                "99df5e9b496ef92b2071d25a73bdee4763921f28888b0244712e0d361c6268eb5c0c554099d7a13" +
                "a3ee03fc5713faca4154ab3f3ca7373a532c4c9418028e7938ec7871c732aa2d82f5a9c9998f1d5" +
                "8ae1dd795dd044c9b6fb1e3916e8bbd691f861a3ff4b2d107369769b3ddc95acfcca6e49c27f259" +
                "fbc647630b9fcd76b220795b73e7d78dd3384f277e6d7628d406c0ead207c499d51b693d3798330" +
                "0eef095cc3c8f8a9224dab140444f0f0d6faff4430292d5df055fe035b12eadd2334fc09ec70d25" +
                "1f6f745456eceb79cac132e6c3ede2537ba096a9fb7c564c81ab853de4659faf356f6c87e12bf50" +
                "e744b91661e3b53597bb3ea1726ae30371b5a235c4500b4093824eadd4f3fc086a1b2c6629538d7" +
                "327139882fa1cc96b0a0f396f28eb5a35948c214a88ce4a0f36affaeff22227e1e8bedb60d4f2b6" +
                "83b5937976cc9fa7f4001459bd20f28535d273d2aef3aead49ce63e6b3d9ca7cd8d999d0fb1b4d0" +
                "1098600b3181920ceea85992e3611b5b678373d136877fd41770f78f5e2be87ca57f95c721a2627" +
                "beb6f66107c1987cfeca35e03f25d75a50daccb08bafeeaf36a5493ca56604302db7ff6779b5c9d" +
                "7ff12815f2b361349a66214d3125302306092a864886f70d01091531160414565cc72e1bc0f781d" +
                "06b5ba3995fb9c5ffbc938030413031300d0609608648016503040201050004202373b26c9670ca" +
                "ecbf3336cba8dbbe443a88df401116515174d0d9949397667504089387718df8bb7e4a02020800"

        val PEM = PEM_STRING.toByteArray(Charsets.UTF_8)
        private const val PEM_STRING = "-----BEGIN CERTIFICATE-----\n" +
                "MIIDOTCCAiGgAwIBAgIUND9T2D3cevsQ947Le2H3WLiMl/kwDQYJKoZIhvcNAQEL" +
                "BQAwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUxITAfBgNVBAoM" +
                "GEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDAeFw0yNTA4MDEwNTUyMjJaFw0yNjA4" +
                "MDEwNTUyMjJaMEUxCzAJBgNVBAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEw" +
                "HwYDVQQKDBhJbnRlcm5ldCBXaWRnaXRzIFB0eSBMdGQwggEiMA0GCSqGSIb3DQEB" +
                "AQUAA4IBDwAwggEKAoIBAQDMZo6f9skXTORKN2RVHKXmbQIBFHXLvAXrGTcNkSSt" +
                "FUaRv+qDk850cSEdGh5/+TLNrJPTRVKQxo9u28OKo0tYFGHwcCUi9SdhpBic56Pz" +
                "kZW9QIfQ3BlJ2ThRnnYNEfyubo/3WBEWZOlaOJXXjZpwqLNBDAZCcUstlnOhowZQ" +
                "dGKdh9AJmzT5ubHtdrkmY5u1fsaklSEi69QXOOatDI5YkJIiGn9lwJ9Mlphaomsp" +
                "8YoKVpC/xupbHcH7B06Exk0CSUjpLv/pNV/AbLOWnKNW3Vqqq5coJWTWVbW1c9sL" +
                "PjQjbetq6BMhZylOo4/dKpT2IFrxpieZNZ8inh1KDe4nAgMBAAGjITAfMB0GA1Ud" +
                "DgQWBBTp7OcBdGgktyt+Oww556RxY6WWHTANBgkqhkiG9w0BAQsFAAOCAQEAs+6Z" +
                "v859tzA5eJQ0nRojFkXizk4tjbopYTA4t1p+812oPJMmvTUJ+zZ4LnOdako8a9XR" +
                "pY6xeGEnzt2wMhL7iF5ZVIC9eXAz5F2FrkmhIUHjdoqabv4vqav6+tPddlatkWUy" +
                "BQtNJh7R80T57/xVQjOfDLqLos8lrnuxQh+yJHZpC8ydCk+TE7gjOVkRPG99ZbNz" +
                "P99KdC9t9Qy1HTHwYUKljB5svB+AvMnTX6ww/T8xnepEUU0bU4CjAmAcPdm/9A3C" +
                "gA8ySq22RZBe+IuwTs8ppA2vK4StWbvi/yyIJOR0v9QkrzYIsT+1sJQjVSvw4iFJ" +
                "4uNDLtfSA6hINdEpGw==" +
                "-----END CERTIFICATE-----" +
                "-----BEGIN PRIVATE KEY-----" +
                "MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDMZo6f9skXTORK" +
                "N2RVHKXmbQIBFHXLvAXrGTcNkSStFUaRv+qDk850cSEdGh5/+TLNrJPTRVKQxo9u" +
                "28OKo0tYFGHwcCUi9SdhpBic56PzkZW9QIfQ3BlJ2ThRnnYNEfyubo/3WBEWZOla" +
                "OJXXjZpwqLNBDAZCcUstlnOhowZQdGKdh9AJmzT5ubHtdrkmY5u1fsaklSEi69QX" +
                "OOatDI5YkJIiGn9lwJ9Mlphaomsp8YoKVpC/xupbHcH7B06Exk0CSUjpLv/pNV/A" +
                "bLOWnKNW3Vqqq5coJWTWVbW1c9sLPjQjbetq6BMhZylOo4/dKpT2IFrxpieZNZ8i" +
                "nh1KDe4nAgMBAAECggEAXOUrYuYNBGrswhIkpk3r1Cqso4MB+kMMyYlfLOpPKd6m" +
                "gO0hDwWo6eDUdN5/CBhgj3skf/tch/HGFFMKrsKCJpi03kqJhja23Dhw+zaHm9YJ" +
                "oMZoM3MkhxyS7P1Al7YaCciz420B7xSTvW5EI3/2tcbmGOT3H1FQInrjOI3X+83p" +
                "FoS93sBnGfDHGMQxUPsHoSw5HfhYGCUFw9yFshOSv55SxKmQEoDFoqzGJYsLe/FI" +
                "RdUmM82miiAMr00X6u+zRffvtfjUIhQ5xLofUB6XetFjmRvLudK9OzY4LvzMImpX" +
                "Ga2jLE+d9JubX2pVXV34Ry4qM7KFaTFvEbpj0ygd4QKBgQDx+3OAUPWOKOhvndnx" +
                "zGGueya11qqinyvy+qqC1ppattfSFxdJT+9UF+zyRDDmhNd4Qa80tNaSL61fmiJ9" +
                "/f4SRBt0bH8RztQ4/UwhTYjaA4nsdsvAUsUc6dRygrsOWuaXNZ0+JZ30IbDcG7LV" +
                "iN7BFhEpZtEF6bIGOtp/71rWUQKBgQDYPcco9DLx6BokypPddM21DLkvlMXe4qmP" +
                "ICEVXpH+7z9RUsBnuGrz5zXTNVT7lOk2yubo//+u9GInGKNcvnI6DuI0u99dVuSw" +
                "haymuN0gSRT1fbxejPxQFuZce44zuRitLou6xhPpG1KiibEGLGvjyHz9j7VP7cS6" +
                "N8dq3x9G9wKBgESkvwQUc0QLiLw4/B1ijAcx+i41IhyVqKL5xqrs88Zt/dUkJb/v" +
                "RAYH73heLb0GzBTaFTiPYBsCGV14XPZ+ubc2yM8DBBzqHju4ZwM/emXWAScqH+yD" +
                "zlTAZDrDqQqOcMFOPTfm9eLON9yIovd+JyqA9wdWmk7iF1U7FsaaAJuxAoGBAMKW" +
                "/US2U63qnrQi8+LiPEbDV1Yg+9qxf8IDOKJBQwH1i7YD0I7FnsEze/U/VeU7QI6F" +
                "Ejv0OsLWugjSnBdWbfYe9KJduggFrK/I6u/xBVQLT+gGKN+w4VC0+sGYkgOrejBF" +
                "5YnCu6IWa0tGut2CVehZv1hx3Mg7f7/PeA2NEVlLAoGBAIA56s+GyLlSU9rU1IxZ" +
                "xD9UBWlak0qhauMXSsqSD3Pj5RxslsDUP7CY0Y+GtsFHDvu3/54OKomaA2JaoxQG" +
                "cKc05nARq3GzNS4F/hOt5izd3laddb8YOeO0+mDJrLFLzjtgN4kuvI7fTSfxHJrw" +
                "RZu52GdpFyD2dU1YCR6BsfJ/" +
                "-----END PRIVATE KEY-----"

        val DER_CERT = DER_CERT_HEX.hexStringToByteArray()
        private const val DER_CERT_HEX = "3082033930820221a0030201020214343f53d83ddc7afb10f78ecb" +
                "7b61f758b88c97f9300d06092a864886f70d01010b05003045310b3009060355040613024155311" +
                "3301106035504080c0a536f6d652d53746174653121301f060355040a0c18496e7465726e657420" +
                "5769646769747320507479204c7464301e170d3235303830313035353232325a170d32363038303" +
                "13035353232325a3045310b30090603550406130241553113301106035504080c0a536f6d652d53" +
                "746174653121301f060355040a0c18496e7465726e6574205769646769747320507479204c74643" +
                "0820122300d06092a864886f70d01010105000382010f003082010a0282010100cc668e9ff6c917" +
                "4ce44a3764551ca5e66d02011475cbbc05eb19370d9124ad154691bfea8393ce7471211d1a1e7ff" +
                "932cdac93d3455290c68f6edbc38aa34b581461f0702522f52761a4189ce7a3f39195bd4087d0dc" +
                "1949d938519e760d11fcae6e8ff758111664e95a3895d78d9a70a8b3410c0642714b2d9673a1a30" +
                "65074629d87d0099b34f9b9b1ed76b926639bb57ec6a4952122ebd41738e6ad0c8e589092221a7f" +
                "65c09f4c96985aa26b29f18a0a5690bfc6ea5b1dc1fb074e84c64d024948e92effe9355fc06cb39" +
                "69ca356dd5aaaab97282564d655b5b573db0b3e34236deb6ae8132167294ea38fdd2a94f6205af1" +
                "a62799359f229e1d4a0dee270203010001a321301f301d0603551d0e04160414e9ece701746824b" +
                "72b7e3b0c39e7a47163a5961d300d06092a864886f70d01010b05000382010100b3ee99bfce7db7" +
                "30397894349d1a231645e2ce4e2d8dba29613038b75a7ef35da83c9326bd3509fb36782e739d6a4" +
                "a3c6bd5d1a58eb1786127ceddb03212fb885e595480bd797033e45d85ae49a12141e3768a9a6efe" +
                "2fa9abfafad3dd7656ad916532050b4d261ed1f344f9effc5542339f0cba8ba2cf25ae7bb1421fb" +
                "22476690bcc9d0a4f9313b8233959113c6f7d65b3733fdf4a742f6df50cb51d31f06142a58c1e6c" +
                "bc1f80bcc9d35fac30fd3f319dea44514d1b5380a302601c3dd9bff40dc2800f324aadb645905ef" +
                "88bb04ecf29a40daf2b84ad59bbe2ff2c8824e474bfd424af3608b13fb5b09423552bf0e22149e2" +
                "e3432ed7d203a84835d1291b"

        val DER_KEY = DER_KEY_HEX.hexStringToByteArray()
        private const val DER_KEY_HEX = "308204be020100300d06092a864886f70d0101010500048204a8308" +
                "204a40201000282010100cc668e9ff6c9174ce44a3764551ca5e66d02011475cbbc05eb19370d91" +
                "24ad154691bfea8393ce7471211d1a1e7ff932cdac93d3455290c68f6edbc38aa34b581461f0702" +
                "522f52761a4189ce7a3f39195bd4087d0dc1949d938519e760d11fcae6e8ff758111664e95a3895" +
                "d78d9a70a8b3410c0642714b2d9673a1a3065074629d87d0099b34f9b9b1ed76b926639bb57ec6a" +
                "4952122ebd41738e6ad0c8e589092221a7f65c09f4c96985aa26b29f18a0a5690bfc6ea5b1dc1fb" +
                "074e84c64d024948e92effe9355fc06cb3969ca356dd5aaaab97282564d655b5b573db0b3e34236" +
                "deb6ae8132167294ea38fdd2a94f6205af1a62799359f229e1d4a0dee270203010001028201005c" +
                "e52b62e60d046aecc21224a64debd42aaca38301fa430cc9895f2cea4f29dea680ed210f05a8e9e" +
                "0d474de7f0818608f7b247ffb5c87f1c614530aaec2822698b4de4a898636b6dc3870fb36879bd6" +
                "09a0c668337324871c92ecfd4097b61a09c8b3e36d01ef1493bd6e44237ff6b5c6e618e4f71f515" +
                "0227ae3388dd7fbcde91684bddec06719f0c718c43150fb07a12c391df858182505c3dc85b21392" +
                "bf9e52c4a9901280c5a2acc6258b0b7bf14845d52633cda68a200caf4d17eaefb345f7efb5f8d42" +
                "21439c4ba1f501e977ad163991bcbb9d2bd3b36382efccc226a5719ada32c4f9df49b9b5f6a555d" +
                "5df8472e2a33b28569316f11ba63d3281de102818100f1fb738050f58e28e86f9dd9f1cc61ae7b2" +
                "6b5d6aaa29f2bf2faaa82d69a5ab6d7d21717494fef5417ecf24430e684d77841af34b4d6922fad" +
                "5f9a227dfdfe12441b746c7f11ced438fd4c214d88da0389ec76cbc052c51ce9d47282bb0e5ae69" +
                "7359d3e259df421b0dc1bb2d588dec116112966d105e9b2063ada7fef5ad65102818100d83dc728" +
                "f432f1e81a24ca93dd74cdb50cb92f94c5dee2a98f2021155e91feef3f5152c067b86af3e735d33" +
                "554fb94e936cae6e8ffffaef4622718a35cbe723a0ee234bbdf5d56e4b085aca6b8dd204914f57d" +
                "bc5e8cfc5016e65c7b8e33b918ad2e8bbac613e91b52a289b1062c6be3c87cfd8fb54fedc4ba37c" +
                "76adf1f46f702818044a4bf041473440b88bc38fc1d628c0731fa2e35221c95a8a2f9c6aaecf3c6" +
                "6dfdd52425bfef440607ef785e2dbd06cc14da15388f601b02195d785cf67eb9b736c8cf03041ce" +
                "a1e3bb867033f7a65d601272a1fec83ce54c0643ac3a90a8e70c14e3d37e6f5e2ce37dc88a2f77e" +
                "272a80f707569a4ee217553b16c69a009bb102818100c296fd44b653adea9eb422f3e2e23c46c35" +
                "75620fbdab17fc20338a2414301f58bb603d08ec59ec1337bf53f55e53b408e85123bf43ac2d6ba" +
                "08d29c17566df61ef4a25dba0805acafc8eaeff105540b4fe80628dfb0e150b4fac1989203ab7a3" +
                "045e589c2bba2166b4b46badd8255e859bf5871dcc83b7fbfcf780d8d11594b028181008039eacf" +
                "86c8b95253dad4d48c59c43f5405695a934aa16ae3174aca920f73e3e51c6c96c0d43fb098d18f8" +
                "6b6c1470efbb7ff9e0e2a899a03625aa3140670a734e67011ab71b3352e05fe13ade62cddde569d" +
                "75bf1839e3b4fa60c9acb14bce3b6037892ebc8edf4d27f11c9af0459bb9d867691720f6754d580" +
                "91e81b1f27f"
    }
}
