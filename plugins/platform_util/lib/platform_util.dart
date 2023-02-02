/*
 * Copyright (C) 2023 Yubico.
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

import 'dart:ui';

import 'platform_util_platform_interface.dart';

class PlatformUtil {
  Future<bool?> init() async {
    return await PlatformUtilPlatform.instance.init();
  }

  Future<Rect> getWindowRect() async {
    return await PlatformUtilPlatform.instance.getWindowRect();
  }

  Future<bool?> setWindowRect(Rect rect) async {
    return await PlatformUtilPlatform.instance.setWindowRect(rect);
  }
}

final platformUtil = PlatformUtil();
