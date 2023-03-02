#include "include/window_manager_helper/window_manager_helper_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "window_manager_helper_plugin.h"

void WindowManagerHelperPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  window_manager_helper::WindowManagerHelperPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
