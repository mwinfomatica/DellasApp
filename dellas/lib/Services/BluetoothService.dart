import 'package:flutter_blue/flutter_blue.dart';

class BluetoothService {
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> devicesList = <BluetoothDevice>[];
}
