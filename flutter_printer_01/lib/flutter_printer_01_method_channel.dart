import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_printer_01_platform_interface.dart';

/// An implementation of [FlutterPrinter01Platform] that uses method channels.
class MethodChannelFlutterPrinter01 extends FlutterPrinter01Platform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_printer_01');

  @override
  Future<bool> connectPrinter(String ip, int port) async {
    try {
      final bool? result = await methodChannel.invokeMethod(
        'connect',
        {'address': ip, 'port': port},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to connect printer: ${e.message}");
      return false;
    }
  }

  @override
  Future<bool> printText(String text) async {
    try {
      final bool? result = await methodChannel.invokeMethod(
        'printText',
        {'text': text},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to print text: ${e.message}");
      return false;
    }
  }

  @override
  Future<bool> disconnectPrinter() async {
    try {
      final bool? result = await methodChannel.invokeMethod('disconnect');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to disconnect printer: ${e.message}");
      return false;
    }
  }

  @override
  Future<bool> sendRawBytes(List<int> bytes) async {
    try {
      final bool? result = await methodChannel.invokeMethod(
        'sendRawBytes',
        {'bytes': Uint8List.fromList(bytes)},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to send raw bytes: ${e.message}");
      return false;
    }
  }

  @override
  Future<int> getPrinterStatus() async {
    try {
      final int? result = await methodChannel.invokeMethod('getPrinterStatus');
      return result ?? -1;
    } on PlatformException catch (e) {
      debugPrint("Failed to get printer status: ${e.message}");
      return -1;
    }
  }

  @override
  Future<bool> getConnectionStatus() async {
    try {
      final bool? result = await methodChannel.invokeMethod('getConnectionStatus');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to get connection status: ${e.message}");
      return false;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUsbDevices() async {
    try {
      final List<dynamic>? result = await methodChannel.invokeMethod('getUsbDevices');
      if (result == null) return [];
      return result.map((e) => Map<String, dynamic>.from(e)).toList();
    } on PlatformException catch (e) {
      debugPrint("Failed to get USB devices: ${e.message}");
      return [];
    }
  }

  @override
  Future<bool> usbConnect(int vendorId, int productId) async {
    try {
      final bool? result = await methodChannel.invokeMethod('usbConnect', {
        'vendorId': vendorId,
        'productId': productId,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to connect USB printer: ${e.message}");
      return false;
    }
  }

  @override
  Future<List<String>> scanNetworkPrinters({List<int> ports = const [9100]}) async {
    // We implement the actual scanning in Pure Dart inside the module class.
    // This is just a stub to satisfy the abstract interface if MethodChannel is called directly.
    return [];
  }
}
