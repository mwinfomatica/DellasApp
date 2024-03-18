import 'dart:convert';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leitorqrcode/Models/APIModels/EmbalagemModel.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';

class PrinterController {
  void printQrCodeEmbalagem(
      {required EmbalagemModel emb,
      required BlueThermalPrinter bluetooth,
      required BuildContext context}) async {
    bluetooth.isConnected.then((isConnected) {
      if (isConnected!) {
        String qrdata = json.encode(emb);
        Uint8List bt = Uint8List(1);
        bluetooth.printImageBytes(bt);

        // bluetooth.printCustom(
        //     "--------------------------------", 0, PrinterHelper.escAlignRight);
        // bluetooth.printNewLine();
      } else {
        Dialogs.showToast(
          context,
          "Impressora não está conectada",
          bgColor: Color.fromARGB(255, 255, 174, 0),
          duration: const Duration(seconds: 5),
        );
      }
    });
  }
}
