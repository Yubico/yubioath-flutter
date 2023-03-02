#ifndef FLUTTER_PLUGIN_WINDOW_MANAGER_HELPER_PLUGIN_H_
#define FLUTTER_PLUGIN_WINDOW_MANAGER_HELPER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace window_manager_helper {

class WindowManagerHelperPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  explicit WindowManagerHelperPlugin(flutter::PluginRegistrarWindows* registrar);

  virtual ~WindowManagerHelperPlugin();

  // Disallow copy and assign.
  WindowManagerHelperPlugin(const WindowManagerHelperPlugin&) = delete;
  WindowManagerHelperPlugin& operator=(const WindowManagerHelperPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  flutter::PluginRegistrarWindows* registrar;
  HWND native_window;
};

}  // namespace window_manager_helper

#endif  // FLUTTER_PLUGIN_WINDOW_MANAGER_HELPER_PLUGIN_H_
