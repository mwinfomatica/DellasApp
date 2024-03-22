import 'dart:convert';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoGetEmbalagemListModel.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:leitorqrcode/printer/printer_helper.dart';

class PrinterController {
  Future<void> printQrCodeEmbalagem(
      {required List<EmbalagemPrinter> listemb,
      required BlueThermalPrinter bluetooth,
      required BuildContext context}) async {
    bool isConnected = await bluetooth.isConnected ?? false;

    if (isConnected) {
      for (var i = 0; i < listemb.length; i++) {
        EmbalagemPrinter emb = listemb[i];
        String qrdata = json.encode(emb);

        ByteData data =
            await rootBundle.load("assets/img/logo_dellas_printer_1.png");
        Uint8List imageBytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

        await bluetooth.printImageBytes(imageBytes);

        bluetooth.printCustom(
            "--------------------------------------------------",
            3,
            PrinterHelper.escAlignCenter);

        //NÃO USAR WIDTH E HEIGTH ACIMA DE 250
        bluetooth.printQRcode(qrdata, 250, 250, PrinterHelper.escAlignCenter);

        //Informações da Nota
        _printHeaderInfo(bluetooth: bluetooth, embalagem: emb);

        // bluetooth.printNewLine();

        bluetooth.printNewLine();

        if (emb.listItens == null) {
          emb.listItens = [];
        }
        bluetooth.printCustom(
            "--------------------------------------------------",
            3,
            PrinterHelper.escAlignCenter);
        _printItemProd(
            bluetooth: bluetooth, ListitemPedido: emb.listItens ?? []);

        bluetooth.printNewLine();
        bluetooth.printNewLine();
      }
    } else {
      Dialogs.showToast(
        context,
        "Impressora não está conectada",
        bgColor: Color.fromARGB(255, 255, 174, 0),
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> PrintHeaderItensTeste(
      {required BlueThermalPrinter bluetooth}) async {
    bool isConnected = await bluetooth.isConnected ?? false;

    if (isConnected) {
      bluetooth.printCustom(
          "--------------------------------------------------",
          3,
          PrinterHelper.escAlignCenter);

      String cod = "WA9-MULTI 11/16";
      String desc = "PNEU-BRIG 235/55R19 101V  DUELER H/P SPORT EXT MOE";
      String qtd = "9999".padRight(4, '+');
      List<String> listDesc = [];
      List<String> listCod = [];

      desc = cod + " - " + desc;

      if (desc.length > 50) {
        int len = desc.length;
        for (var i = 0; i < len; i += 50) {
          listDesc.add(
              desc.substring(i, i + 50 < desc.length ? i + 50 : desc.length));
        }
      }

      for (var i = 0; i < 3; i++) {
        for (var i = 0; i < listDesc.length; i++) {
          bluetooth.printCustom(listDesc[i], 1, PrinterHelper.escAlignLeft);
        }

        bluetooth.printCustom(("Qtd: " + qtd), 1, PrinterHelper.escAlignRight);
        bluetooth.printCustom(
            "--------------------------------------------------",
            3,
            PrinterHelper.escAlignCenter);
      }
      bluetooth.printNewLine();
      bluetooth.printNewLine();
    }
  }

  void _printHeaderInfo(
      {required BlueThermalPrinter bluetooth,
      required EmbalagemPrinter embalagem}) {
    bluetooth.printCustom("--------------------------------------------------",
        3, PrinterHelper.escAlignCenter);
    bluetooth.printCustom(
        ("Carga: " + (embalagem.carga ?? "-")), 1, PrinterHelper.escAlignLeft);
    bluetooth.printCustom(
        ("Nota Fiscal: " +
            (embalagem.nroNota ?? "-") +
            " / " +
            (embalagem.serie ?? "-")),
        1,
        PrinterHelper.escAlignLeft);
    bluetooth.printCustom(("Cliente: " + (embalagem.nomeCliente ?? "-")), 1,
        PrinterHelper.escAlignLeft);
    bluetooth.printCustom(("Embalagem: " + (embalagem.seqEmbalagem ?? "-")), 1,
        PrinterHelper.escAlignLeft);
    bluetooth.printCustom(
        ("End: " + (embalagem.end ?? "-")), 1, PrinterHelper.escAlignLeft);
  }

  void _printHeaderItens({required BlueThermalPrinter bluetooth}) {
    bluetooth.printCustom("--------------------------------------------------",
        3, PrinterHelper.escAlignCenter);
    bluetooth.print3Column("Cod.", "Desc. Prod.", "Qtd", 10);
  }

  Future<void> _printItemProd(
      {required BlueThermalPrinter bluetooth,
      required List<ItensEmbalagemPrinter> ListitemPedido}) async {
    for (var i = 0; i < ListitemPedido.length; i++) {
      List<String> listDesc = [];
      String nameProd = ListitemPedido[i].nomeProd ?? "-";
      String name = nameProd
          .replaceAll("ç", "c")
          .replaceAll("ã", "a")
          .replaceAll("õ", "o")
          .replaceAll("á", "a")
          .replaceAll("é", "e")
          .replaceAll("í", "i")
          .replaceAll("ó", "o")
          .replaceAll("à", "a");

      String codProd = ListitemPedido[i].codProd ?? "-";
      String cod = codProd
          .replaceAll("ç", "c")
          .replaceAll("ã", "a")
          .replaceAll("õ", "o")
          .replaceAll("á", "a")
          .replaceAll("é", "e")
          .replaceAll("í", "i")
          .replaceAll("ó", "o")
          .replaceAll("à", "a");

      name = cod + " - " + name;

      int len = name.length;
      for (var i = 0; i < len; i += 50) {
        listDesc.add(
            name.substring(i, i + 50 < name.length ? i + 50 : name.length));
      }

      for (var i = 0; i < ListitemPedido.length; i++) {
        for (var i = 0; i < listDesc.length; i++) {
          bluetooth.printCustom(listDesc[i], 1, PrinterHelper.escAlignLeft);
        }

        bluetooth.printCustom(
            ("Qtd: " +
                (ListitemPedido[i].qtd! != null
                    ? ListitemPedido[i].qtd!.toString()
                    : "0")),
            1,
            PrinterHelper.escAlignRight);
        bluetooth.printCustom(
            "--------------------------------------------------",
            3,
            PrinterHelper.escAlignCenter);
      }
      bluetooth.printNewLine();
      bluetooth.printNewLine();
    }
  }
}
