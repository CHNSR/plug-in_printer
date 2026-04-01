import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_printer_01_method_channel.dart';

abstract class FlutterPrinter01Platform extends PlatformInterface {
  /// Constructs a FlutterPrinter01Platform.
  FlutterPrinter01Platform() : super(token: _token);

  static final Object _token = Object();

  static FlutterPrinter01Platform _instance = MethodChannelFlutterPrinter01();

  /// The default instance of [FlutterPrinter01Platform] to use.
  ///
  /// Defaults to [MethodChannelFlutterPrinter01].
  static FlutterPrinter01Platform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterPrinter01Platform] when
  /// they register themselves.
  static set instance(FlutterPrinter01Platform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
