import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'posprinter_flutter_method_channel.dart';

abstract class PosprinterFlutterPlatform extends PlatformInterface {
  /// Constructs a PosprinterFlutterPlatform.
  PosprinterFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static PosprinterFlutterPlatform _instance = MethodChannelPosprinterFlutter();

  /// The default instance of [PosprinterFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelPosprinterFlutter].
  static PosprinterFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PosprinterFlutterPlatform] when
  /// they register themselves.
  static set instance(PosprinterFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> connectBluetoothPrinter(String address) {
    throw UnimplementedError('connectBluetoothPrinter() has not been implemented.');
  }

  Future<String?> printSample() {
    throw UnimplementedError('printSample() has not been implemented.');
  }

  Future<String?> printText(String text, Map<String, dynamic>? optionalParams) {
    throw UnimplementedError('printText() has not been implemented.');
  }

  Future<String?> printBarcode(String barcode, Map<String, dynamic>? optionalParams) {
    throw UnimplementedError('printBarcode() has not been implemented.');
  }

  Future<String?> printQR(String qrCode, Map<String, dynamic>? optionalParams) {
    throw UnimplementedError('printQRCode() has not been implemented.');
  }

  Future<String?> printBitmap(String path, Map<String, dynamic>? optionalParams) {
    throw UnimplementedError('printBitmap() has not been implemented.');
  }

  Future<String?> printBox(List<List<String>> table, Map<String, dynamic>? optionalParams) {
    throw UnimplementedError('printBox() has not been implemented.');
  }
}
