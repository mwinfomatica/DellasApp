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

        //NÃO USAR WIDTH E HEIGTH ACIMA DE 250
        bluetooth.printQRcode(qrdata, 250, 250, PrinterHelper.escAlignCenter);
        
        //Informações da Nota
        _printHeaderInfo(bluetooth: bluetooth, embalagem: emb);

        bluetooth.printNewLine();

        //Cabeçalho dos Itens
        _printHeaderItens(bluetooth: bluetooth);

        bluetooth.printNewLine();

        if (emb.listItens == null) {
          emb.listItens = [];
        }
        for (var i = 0; i < emb.listItens!.length; i++) {
          _printItemProd(bluetooth: bluetooth, itemPedido: emb.listItens![i]);
          bluetooth.printNewLine();
          bluetooth.printNewLine();
        }
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

  void _printHeaderInfo(
      {required BlueThermalPrinter bluetooth,
      required EmbalagemPrinter embalagem}) {
    bluetooth.printCustom(
        "--------------------------------------------------",
        3,
        PrinterHelper.escAlignCenter);
    bluetooth.printCustom(
        ("Carga: " + (embalagem.carga ?? "-")), 1, PrinterHelper.escAlignLeft);
    bluetooth.printCustom(
        ("Nota Fiscal: " +
            (embalagem.nroNota ?? "-") +
            " / " +
            (embalagem.serie ?? "-")),
        1,
        PrinterHelper.escAlignLeft);
    bluetooth.printCustom(("Clinete: " + (embalagem.nomeCliente ?? "-")), 1,
        PrinterHelper.escAlignLeft);
    bluetooth.printCustom(("Embalagem: " + (embalagem.seqEmbalagem ?? "-")), 1,
        PrinterHelper.escAlignLeft);
    bluetooth.printCustom(
        ("End: " + (embalagem.end ?? "-")), 1, PrinterHelper.escAlignLeft);
  }

  void _printHeaderItens({required BlueThermalPrinter bluetooth}) {
    bluetooth.printCustom(
        "--------------------------------------------------",
        3,
        PrinterHelper.escAlignCenter);
    bluetooth.print3Column("Cod.", "Desc. Prod.", "Qtd", 10);
  }

  Future<void> _printItemProd(
      {required BlueThermalPrinter bluetooth,
      required ItensEmbalagemPrinter itemPedido}) async {
    String nameProd = itemPedido.nomeProd ?? "-";
    String name = nameProd
        .replaceAll("ç", "c")
        .replaceAll("ã", "a")
        .replaceAll("õ", "o")
        .replaceAll("á", "a")
        .replaceAll("é", "e")
        .replaceAll("í", "i")
        .replaceAll("ó", "o")
        .replaceAll("à", "a");

    String codProd = itemPedido.codProd ?? "-";
    String cod = codProd
        .replaceAll("ç", "c")
        .replaceAll("ã", "a")
        .replaceAll("õ", "o")
        .replaceAll("á", "a")
        .replaceAll("é", "e")
        .replaceAll("í", "i")
        .replaceAll("ó", "o")
        .replaceAll("à", "a");

    bluetooth.print3Column(
      cod,
      (name),
      itemPedido.qtd != null ? itemPedido.qtd!.toString() : "0",
      1,
    );
  }
}
