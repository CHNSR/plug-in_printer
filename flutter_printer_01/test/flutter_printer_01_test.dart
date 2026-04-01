import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_printer_01/flutter_printer_01.dart';
import 'package:flutter_printer_01/flutter_printer_01_platform_interface.dart';
import 'package:flutter_printer_01/flutter_printer_01_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterPrinter01Platform
    with MockPlatformInterfaceMixin
    implements FlutterPrinter01Platform {
  // @override
  // Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool> connectPrinter(String ip, int port) => Future.value(true);

  @override
  Future<bool> printText(String text) => Future.value(true);

  @override
  Future<bool> disconnectPrinter() => Future.value(true);

  @override
  Future<bool> sendRawBytes(List<int> bytes) => Future.value(true);

  @override
  Future<bool> getConnectionStatus() => Future.value(true);

  @override
  Future<List<Map<String, dynamic>>> getUsbDevices() => Future.value([]);

  @override
  Future<bool> usbConnect(int vendorId, int productId) => Future.value(true);

  @override
  Future<List<String>> scanNetworkPrinters({List<int> ports = const [9100]}) => Future.value([]);

  @override
  Future<int> getPrinterStatus() => Future.value(-1);
}

void main() {
  final FlutterPrinter01Platform initialPlatform =
      FlutterPrinter01Platform.instance;

  test('$MethodChannelFlutterPrinter01 is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterPrinter01>());
  });

  test('getPlatformVersion', () async {
    FlutterPrinter01 flutterPrinter01Plugin = FlutterPrinter01();
    MockFlutterPrinter01Platform fakePlatform = MockFlutterPrinter01Platform();
    FlutterPrinter01Platform.instance = fakePlatform;
  });
}
