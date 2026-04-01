import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_printer_01/flutter_printer_01.dart';
import 'package:flutter_printer_01/flutter_printer_01_platform_interface.dart';
import 'package:flutter_printer_01/flutter_printer_01_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterPrinter01Platform
    with MockPlatformInterfaceMixin
    implements FlutterPrinter01Platform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterPrinter01Platform initialPlatform = FlutterPrinter01Platform.instance;

  test('$MethodChannelFlutterPrinter01 is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterPrinter01>());
  });

  test('getPlatformVersion', () async {
    FlutterPrinter01 flutterPrinter01Plugin = FlutterPrinter01();
    MockFlutterPrinter01Platform fakePlatform = MockFlutterPrinter01Platform();
    FlutterPrinter01Platform.instance = fakePlatform;

    expect(await flutterPrinter01Plugin.getPlatformVersion(), '42');
  });
}
