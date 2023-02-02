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

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'platform_util_method_channel.dart';

abstract class PlatformUtilPlatform extends PlatformInterface {
  /// Constructs a PlatformUtilPlatform.
  PlatformUtilPlatform() : super(token: _token);

  static final Object _token = Object();

  static PlatformUtilPlatform _instance = MethodChannelPlatformUtil();

  /// The default instance of [PlatformUtilPlatform] to use.
  ///
  /// Defaults to [MethodChannelPlatformUtil].
  static PlatformUtilPlatform get instance => _instance;

  static set instance(PlatformUtilPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool?> init() {
    throw UnimplementedError('init() has not been implemented.');
  }

  Future<Rect> getWindowRect() {
    throw UnimplementedError('getWindowRect() has not been implemented.');
  }

  Future<bool?> setWindowRect(Rect rect) {
    throw UnimplementedError('setWindowRect() has not been implemented.');
  }
}
