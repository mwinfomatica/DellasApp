import 'posprinter_flutter_platform_interface.dart';

class PosprinterFlutter {
  Future<String?> getPlatformVersion() {
    return PosprinterFlutterPlatform.instance.getPlatformVersion();
  }

  Future<String?> connectBluetoothPrinter(String address) {
    return PosprinterFlutterPlatform.instance.connectBluetoothPrinter(address);
  }

  Future<String?> printSample() {
    return PosprinterFlutterPlatform.instance.printSample();
  }

  /// Neste código, os seguintes campos estão disponíveis nos parâmetros
  /// opcionais (optionalParams):
  ///
  /// paperWidth: int
  /// paperHeight: int
  /// direction: String
  /// positionX: int
  /// positionY: int
  /// font: String
  /// fontSize: int
  /// lineSpacing: int
  ///
  /// Estes campos são utilizados para configurar o envio de dados para uma
  /// impressora ZPL.

  Future<String?> printText(String text, {Map<String, dynamic>? optionalParams}) {
    return PosprinterFlutterPlatform.instance.printText(text, optionalParams);
  }

  /// Neste código, os seguintes campos estão disponíveis nos parâmetros
  /// opcionais (optionalParams):
  ///
  /// paperWidth: int
  /// paperHeight: int
  /// direction: String
  /// positionX: int
  /// positionY: int
  /// barcodeWidth: int
  /// barcodeHeight: int
  ///
  /// Estes campos são utilizados para configurar o envio de dados para uma
  /// impressora ZPL, incluindo a impressão de códigos de barras.

  Future<String?> printBarcode(String barcode, {Map<String, dynamic>? optionalParams}) {
    return PosprinterFlutterPlatform.instance.printBarcode(barcode, optionalParams);
  }

  /// Neste código, os seguintes campos estão disponíveis nos parâmetros
  /// opcionais (optionalParams):
  ///
  /// paperWidth: int
  /// paperHeight: int
  /// direction: String
  /// positionX: int
  /// positionY: int
  ///
  /// Estes campos são utilizados para configurar o envio de dados para uma
  /// impressora ZPL, incluindo a impressão de códigos QR.

  Future<String?> printQR(String qrCode, {Map<String, dynamic>? optionalParams}) {
    return PosprinterFlutterPlatform.instance.printQR(qrCode, optionalParams);
  }

  /// Not implemented yet.

  Future<String?> printBitmap(String path, {Map<String, dynamic>? optionalParams}) {
    return PosprinterFlutterPlatform.instance.printBitmap(path, optionalParams);
  }

  /// Neste código, os seguintes campos estão disponíveis nos parâmetros
  /// opcionais (optionalParams):
  ///
  /// paperWidth: int
  /// paperHeight: int
  /// direction: String
  /// positionX: int
  /// positionY: int
  /// width: int
  /// height: int
  /// borderWidth: int
  ///
  /// Estes campos são utilizados para configurar o envio de dados para uma
  /// impressora ZPL, incluindo a impressão de caixas retangulares com bordas.

  Future<String?> printBox(List<List<String>> table, {Map<String, dynamic>? optionalParams}) {
    return PosprinterFlutterPlatform.instance.printBox(table, optionalParams);
  }
}
