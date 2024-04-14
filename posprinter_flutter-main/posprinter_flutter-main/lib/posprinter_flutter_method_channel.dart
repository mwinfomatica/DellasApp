import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'posprinter_flutter_platform_interface.dart';

/// An implementation of [PosprinterFlutterPlatform] that uses method channels.
class MethodChannelPosprinterFlutter extends PosprinterFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('posprinter_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<String?> connectBluetoothPrinter(String address) async {
    final result = await methodChannel.invokeMethod<String>('connectBluetooth', {'address': address});
    return result;
  }

  @override
  Future<String?> printSample() async {
    final result = await methodChannel.invokeMethod<String>('printSample');
    return result;
  }

  @override
  Future<String?> printText(String text, Map<String, dynamic>? optionalParams) async {
    final result = await methodChannel.invokeMethod<String>('printText', {'text': text, 'optionalParams': optionalParams});
    return result;
  }

  @override
  Future<String?> printBarcode(String barcode, Map<String, dynamic>? optionalParams) async {
    final result = await methodChannel.invokeMethod<String>('printBarcode', {'barcode': barcode, 'optionalParams': optionalParams});
    return result;
  }

  @override
  Future<String?> printQR(String qrCode, Map<String, dynamic>? optionalParams) async {
    final result = await methodChannel.invokeMethod<String>('printQRCode', {'qrCode': qrCode, 'optionalParams': optionalParams});
    return result;
  }

  @override
  Future<String?> printBitmap(String path, Map<String, dynamic>? optionalParams) async {
    final result = await methodChannel.invokeMethod<String>('printBitmap', {'path': path, 'optionalParams': optionalParams});
    return result;
  }

  @override
  Future<String?> printBox(List<List<String>> table, Map<String, dynamic>? optionalParams) async {
    final result = await methodChannel.invokeMethod<String>('printBox', {'table': table, 'optionalParams': optionalParams});
    return result;
  }
}
