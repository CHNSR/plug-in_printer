#include "flutter_printer01_plugin.h"

// winsock2.h included here after the guards defined in flutter_printer01_plugin.h
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <string>
#include <vector>
#include <thread>

#pragma comment(lib, "Ws2_32.lib")

namespace flutter_printer_01 {

// ---- State ----
static SOCKET g_socket = INVALID_SOCKET;
static bool g_wsa_init = false;

static bool InitWsa() {
  if (g_wsa_init) return true;
  WSADATA wsa_data;
  int result = WSAStartup(MAKEWORD(2, 2), &wsa_data);
  g_wsa_init = (result == 0);
  return g_wsa_init;
}

static bool IsConnected() {
  return g_socket != INVALID_SOCKET;
}

// static
void FlutterPrinter01Plugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "flutter_printer_01",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FlutterPrinter01Plugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

FlutterPrinter01Plugin::FlutterPrinter01Plugin() {}

FlutterPrinter01Plugin::~FlutterPrinter01Plugin() {
  if (g_socket != INVALID_SOCKET) {
    closesocket(g_socket);
    g_socket = INVALID_SOCKET;
  }
  if (g_wsa_init) {
    WSACleanup();
    g_wsa_init = false;
  }
}

void FlutterPrinter01Plugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

  const std::string &method = method_call.method_name();

  // ---- getPlatformVersion ----
  if (method == "getPlatformVersion") {
    std::ostringstream version_stream;
    version_stream << "Windows ";
    if (IsWindows10OrGreater()) version_stream << "10+";
    else if (IsWindows8OrGreater()) version_stream << "8";
    else if (IsWindows7OrGreater()) version_stream << "7";
    result->Success(flutter::EncodableValue(version_stream.str()));

  // ---- connect ----
  } else if (method == "connect") {
    const auto *args =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!args) { result->Success(flutter::EncodableValue(false)); return; }

    std::string address;
    int port = 9100;
    auto addr_it = args->find(flutter::EncodableValue("address"));
    auto port_it = args->find(flutter::EncodableValue("port"));
    if (addr_it != args->end())
      address = std::get<std::string>(addr_it->second);
    if (port_it != args->end())
      port = std::get<int>(port_it->second);

    // Close existing socket first
    if (g_socket != INVALID_SOCKET) {
      closesocket(g_socket);
      g_socket = INVALID_SOCKET;
    }

    if (!InitWsa()) { result->Success(flutter::EncodableValue(false)); return; }

    // Resolve address and connect on background thread
    auto shared_result = std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>(std::move(result));
    std::thread([address, port, shared_result]() {
      struct addrinfo hints = {}, *res = nullptr;
      hints.ai_family = AF_INET;
      hints.ai_socktype = SOCK_STREAM;
      hints.ai_protocol = IPPROTO_TCP;

      std::string port_str = std::to_string(port);
      int rc = getaddrinfo(address.c_str(), port_str.c_str(), &hints, &res);
      if (rc != 0 || res == nullptr) {
        shared_result->Success(flutter::EncodableValue(false));
        return;
      }

      SOCKET sock = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
      if (sock == INVALID_SOCKET) {
        freeaddrinfo(res);
        shared_result->Success(flutter::EncodableValue(false));
        return;
      }

      // Set connect timeout (3s)
      DWORD timeout_ms = 3000;
      setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, (char*)&timeout_ms, sizeof(timeout_ms));
      setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, (char*)&timeout_ms, sizeof(timeout_ms));

      int conn = connect(sock, res->ai_addr, (int)res->ai_addrlen);
      freeaddrinfo(res);

      if (conn == SOCKET_ERROR) {
        closesocket(sock);
        shared_result->Success(flutter::EncodableValue(false));
        return;
      }

      g_socket = sock;
      shared_result->Success(flutter::EncodableValue(true));
    }).detach();

  // ---- disconnect ----
  } else if (method == "disconnect") {
    if (g_socket != INVALID_SOCKET) {
      closesocket(g_socket);
      g_socket = INVALID_SOCKET;
    }
    result->Success(flutter::EncodableValue(true));

  // ---- getConnectionStatus ----
  } else if (method == "getConnectionStatus") {
    result->Success(flutter::EncodableValue(IsConnected()));

  // ---- getPrinterStatus ----
  } else if (method == "getPrinterStatus") {
    if (!IsConnected()) { result->Success(flutter::EncodableValue(-1)); return; }

    auto shared_result = std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>(std::move(result));
    std::thread([shared_result]() {
      char statusCmd[] = {0x10, 0x04, 0x01}; // DLE EOT 1
      int sent = send(g_socket, statusCmd, 3, 0);
      if (sent <= 0) {
        shared_result->Success(flutter::EncodableValue(-1));
        return;
      }

      // Read 1 byte response
      char buffer[1];
      int recv_len = recv(g_socket, buffer, 1, 0);
      if (recv_len > 0) {
        shared_result->Success(flutter::EncodableValue((int)buffer[0]));
      } else {
        shared_result->Success(flutter::EncodableValue(-1));
      }
    }).detach();

  // ---- printText ----
  } else if (method == "printText") {
    if (!IsConnected()) { result->Success(flutter::EncodableValue(false)); return; }

    const auto *args =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    std::string text;
    if (args) {
      auto it = args->find(flutter::EncodableValue("text"));
      if (it != args->end()) text = std::get<std::string>(it->second);
    }
    text += "\n";

    auto shared_result = std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>(std::move(result));
    std::thread([text, shared_result]() {
      int sent = send(g_socket, text.c_str(), (int)text.size(), 0);
      shared_result->Success(flutter::EncodableValue(sent != SOCKET_ERROR));
    }).detach();

  // ---- sendRawBytes ----
  } else if (method == "sendRawBytes") {
    if (!IsConnected()) { result->Success(flutter::EncodableValue(false)); return; }

    const auto *args =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    std::vector<uint8_t> bytes;
    if (args) {
      auto it = args->find(flutter::EncodableValue("bytes"));
      if (it != args->end()) {
        const auto *byte_list =
            std::get_if<std::vector<uint8_t>>(&it->second);
        if (byte_list) bytes = *byte_list;
      }
    }

    if (bytes.empty()) { result->Success(flutter::EncodableValue(false)); return; }

    auto shared_result = std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>(std::move(result));
    std::thread([bytes, shared_result]() {
      int sent = send(g_socket, reinterpret_cast<const char*>(bytes.data()), (int)bytes.size(), 0);
      shared_result->Success(flutter::EncodableValue(sent != SOCKET_ERROR));
    }).detach();

  // ---- getUsbDevices / usbConnect (not applicable on Windows - return stubs) ----
  } else if (method == "getUsbDevices") {
    result->Success(flutter::EncodableValue(flutter::EncodableList{}));

  } else if (method == "usbConnect") {
    result->Error("UNSUPPORTED", "USB connect is not supported on Windows", flutter::EncodableValue());

  } else {
    result->NotImplemented();
  }
}

}  // namespace flutter_printer_01
