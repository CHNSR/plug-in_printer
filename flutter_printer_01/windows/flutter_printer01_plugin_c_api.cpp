#include "include/flutter_printer_01/flutter_printer01_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_printer01_plugin.h"

void FlutterPrinter01PluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_printer_01::FlutterPrinter01Plugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
