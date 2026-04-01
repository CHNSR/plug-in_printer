import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_printer_01_platform_interface.dart';

/// An implementation of [FlutterPrinter01Platform] that uses method channels.
class MethodChannelFlutterPrinter01 extends FlutterPrinter01Platform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_printer_01');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
