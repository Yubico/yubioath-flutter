#include "include/platform_util/platform_util_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "platform_util_plugin.h"

void PlatformUtilPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  platform_util::PlatformUtilPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
