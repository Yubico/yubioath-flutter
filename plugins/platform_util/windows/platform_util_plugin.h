#ifndef FLUTTER_PLUGIN_PLATFORM_UTIL_PLUGIN_H_
#define FLUTTER_PLUGIN_PLATFORM_UTIL_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace platform_util {

class PlatformUtilPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  explicit PlatformUtilPlugin(flutter::PluginRegistrarWindows* registrar);

  virtual ~PlatformUtilPlugin();

  // Disallow copy and assign.
  PlatformUtilPlugin(const PlatformUtilPlugin&) = delete;
  PlatformUtilPlugin& operator=(const PlatformUtilPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  flutter::PluginRegistrarWindows* registrar;
  HWND native_window;
};

}  // namespace platform_util

#endif  // FLUTTER_PLUGIN_PLATFORM_UTIL_PLUGIN_H_
