import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_printer_01_method_channel.dart';

abstract class FlutterPrinter01Platform extends PlatformInterface {
  FlutterPrinter01Platform() : super(token: _token);

  static final Object _token = Object();

  static FlutterPrinter01Platform _instance = MethodChannelFlutterPrinter01();

  static FlutterPrinter01Platform get instance => _instance;

  static set instance(FlutterPrinter01Platform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> connectPrinter(String ip, int port) {
    throw UnimplementedError('connectPrinter() has not been implemented.');
  }

  Future<bool> printText(String text) {
    throw UnimplementedError('printText() has not been implemented.');
  }

  Future<bool> disconnectPrinter() {
    throw UnimplementedError('disconnectPrinter() has not been implemented.');
  }

  Future<bool> sendRawBytes(List<int> bytes) {
    throw UnimplementedError('sendRawBytes() has not been implemented.');
  }

  Future<bool> getConnectionStatus() {
    throw UnimplementedError('getConnectionStatus() has not been implemented.');
  }

  Future<List<Map<String, dynamic>>> getUsbDevices() {
    throw UnimplementedError('getUsbDevices() has not been implemented.');
  }

  Future<bool> usbConnect(int vendorId, int productId) {
    throw UnimplementedError('usbConnect() has not been implemented.');
  }

  Future<int> getPrinterStatus() {
    throw UnimplementedError('getPrinterStatus() has not been implemented.');
  }

  Future<List<String>> scanNetworkPrinters({List<int> ports = const [9100]}) {
    throw UnimplementedError('scanNetworkPrinters() has not been implemented.');
  }
}
