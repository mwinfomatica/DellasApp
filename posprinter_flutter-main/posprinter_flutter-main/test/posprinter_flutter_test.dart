import 'package:flutter_test/flutter_test.dart';
import 'package:posprinter_flutter/posprinter_flutter.dart';
import 'package:posprinter_flutter/posprinter_flutter_platform_interface.dart';
import 'package:posprinter_flutter/posprinter_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPosprinterFlutterPlatform
    with MockPlatformInterfaceMixin
    implements PosprinterFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<String?> connectBluetoothPrinter(String address) {
    // TODO: implement connectBluetoothPrinter
    throw UnimplementedError();
  }

  @override
  Future<String?> printBarcode(String barcode, Map<String, dynamic>? optionalParams) {
    // TODO: implement printBarcode
    throw UnimplementedError();
  }

  @override
  Future<String?> printBitmap(String path, Map<String, dynamic>? optionalParams) {
    // TODO: implement printBitmap
    throw UnimplementedError();
  }

  @override
  Future<String?> printBox(List<List<String>> table, Map<String, dynamic>? optionalParams) {
    // TODO: implement printBox
    throw UnimplementedError();
  }

  @override
  Future<String?> printQR(String qrCode, Map<String, dynamic>? optionalParams) {
    // TODO: implement printQR
    throw UnimplementedError();
  }

  @override
  Future<String?> printSample() {
    // TODO: implement printSample
    throw UnimplementedError();
  }

  @override
  Future<String?> printText(String text, Map<String, dynamic>? optionalParams) {
    // TODO: implement printText
    throw UnimplementedError();
  }
}

void main() {
  final PosprinterFlutterPlatform initialPlatform = PosprinterFlutterPlatform.instance;

  test('$MethodChannelPosprinterFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPosprinterFlutter>());
  });

  test('getPlatformVersion', () async {
    PosprinterFlutter posprinterFlutterPlugin = PosprinterFlutter();
    MockPosprinterFlutterPlatform fakePlatform = MockPosprinterFlutterPlatform();
    PosprinterFlutterPlatform.instance = fakePlatform;

    expect(await posprinterFlutterPlugin.getPlatformVersion(), '42');
  });
}
