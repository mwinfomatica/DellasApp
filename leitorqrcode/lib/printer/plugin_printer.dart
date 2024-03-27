import 'dart:async';

import 'package:flutter/services.dart';

class mwprinter {
  static const String namespace = 'net.printer.printdemo16/plugin';
  static const MethodChannel _channel = const MethodChannel(namespace);
  final StreamController<MethodCall> _methodStreamController =
      new StreamController.broadcast();

  mwprinter._() {
    _channel.setMethodCallHandler((MethodCall call) async {
      _methodStreamController.add(call);
    });
  }

  static mwprinter _instance = new mwprinter._();

  static mwprinter get instance => _instance;

 Future<dynamic> connect() =>
      _channel.invokeMethod('connectBT');

 Future<dynamic> printSample() =>
      _channel.invokeMethod('printSample');
}
