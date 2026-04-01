#ifndef FLUTTER_PLUGIN_FLUTTER_PRINTER01_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_PRINTER01_PLUGIN_H_

// Prevent windows.h from including the old winsock.h (v1).
// This MUST appear before any header that includes windows.h (including Flutter headers).
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef _WINSOCKAPI_
#define _WINSOCKAPI_
#endif

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace flutter_printer_01 {

class FlutterPrinter01Plugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterPrinter01Plugin();

  virtual ~FlutterPrinter01Plugin();

  // Disallow copy and assign.
  FlutterPrinter01Plugin(const FlutterPrinter01Plugin&) = delete;
  FlutterPrinter01Plugin& operator=(const FlutterPrinter01Plugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flutter_printer_01

#endif  // FLUTTER_PLUGIN_FLUTTER_PRINTER01_PLUGIN_H_
