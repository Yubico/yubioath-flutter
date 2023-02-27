//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <desktop_drop/desktop_drop_plugin.h>
#include <local_notifier/local_notifier_plugin.h>
#include <platform_util/platform_util_plugin_c_api.h>
#include <screen_retriever/screen_retriever_plugin.h>
#include <tray_manager/tray_manager_plugin.h>
#include <url_launcher_windows/url_launcher_windows.h>
#include <window_manager/window_manager_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  DesktopDropPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("DesktopDropPlugin"));
  LocalNotifierPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("LocalNotifierPlugin"));
  PlatformUtilPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PlatformUtilPluginCApi"));
  ScreenRetrieverPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ScreenRetrieverPlugin"));
  TrayManagerPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("TrayManagerPlugin"));
  UrlLauncherWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherWindows"));
  WindowManagerPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("WindowManagerPlugin"));
}
