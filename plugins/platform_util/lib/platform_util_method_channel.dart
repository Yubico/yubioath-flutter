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

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'platform_util_platform_interface.dart';

/// An implementation of [PlatformUtilPlatform] that uses method channels.
class MethodChannelPlatformUtil extends PlatformUtilPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('platform_util');

  @override
  Future<bool?> init() async {
    return await methodChannel.invokeMethod<bool>('init', {});
  }

  @override
  Future<Rect> getWindowRect() async {
    final windowPosition =
        await methodChannel.invokeMethod('getWindowRect', {});
    return Rect.fromLTWH(
      windowPosition['left'] ?? 0.0,
      windowPosition['top'] ?? 0.0,
      windowPosition['width'] ?? 0.0,
      windowPosition['height'] ?? 0.0,
    );
  }

  @override
  Future<bool?> setWindowRect(Rect rect) async {
    final Map<String, dynamic> arguments = {
      'x': rect.left,
      'y': rect.top,
      'width': rect.width,
      'height': rect.height,
    }..removeWhere((key, value) => value == null);
    return await methodChannel.invokeMethod<bool>('setWindowRect', arguments);
  }
}
