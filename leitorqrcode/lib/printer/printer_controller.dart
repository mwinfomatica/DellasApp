import 'dart:convert';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoGetEmbalagemListModel.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
// import 'package:leitorqrcode/Services/NotasFiscaisService.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:leitorqrcode/printer/printer_helper.dart';
import 'package:posprinter_flutter/posprinter_flutter.dart';

class PrinterController {
  int nLinhaAtual = 0;
  int nMaxLinhas = 28;
  Future<bool> printQrCodeEmbalagem(
      {required List<EmbalagemPrinter> listemb,
      required BlueThermalPrinter bluetooth,
      required BuildContext context}) async {
    bool isConnected = await bluetooth.isConnected ?? false;

    bool retorno = false;

    int countPrint = 0;

    if (isConnected) {
      for (var i = 0; i < listemb.length; i++) {
        EmbalagemPrinter emb = listemb[i];
        String qrdata = json.encode(emb);

        ByteData data =
            await rootBundle.load("assets/img/logo_dellas_printer_1.png");
        Uint8List imageBytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

        await bluetooth.printImageBytes(imageBytes);

        //NÃO USAR WIDTH E HEIGTH ACIMA DE 250
        bluetooth.printQRcode(qrdata, 248, 248, PrinterHelper.escAlignCenter);

        //Quantidade de Linhas consumidas pelo QR e logo
        nLinhaAtual = 14;

        //Informações da Nota
        _printHeaderInfo(bluetooth: bluetooth, embalagem: emb);

        int restante = nMaxLinhas - nLinhaAtual;

        if (i > 0) {
          if (i % 2 > 0) {
            nMaxLinhas--;
          } else {
            nMaxLinhas++;
          }
        }

        _saltaEtiqueta(bluetooth, restante);

        nLinhaAtual = 0;
        nMaxLinhas -= 3;
        if (emb.listItens == null) {
          emb.listItens = [];
        }
        _printHeaderItens(bluetooth);
        //Itens da Embalagem
        _printItemProd(
            bluetooth: bluetooth, ListitemPedido: emb.listItens ?? []);

        countPrint++;

        if (countPrint == listemb.length) {
          retorno = true;
        }
      }
    } else {
      Dialogs.showToast(
        context,
        "Impressora não está conectada",
        bgColor: Color.fromARGB(255, 255, 174, 0),
        duration: const Duration(seconds: 5),
      );
    }

    return retorno;
  }

  _printLine(BlueThermalPrinter bluetooth) {
    bluetooth.printCustom("--------------------------------------------------",
        1, PrinterHelper.escAlignCenter);
    nLinhaAtual++;
  }

  Future<void> PrintHeaderItensTeste(
      {BuildContext? context,
      required String adressBT,
      required String cmdZPL}) async {
    ContextoServices context = ContextoServices();
    String? printerAdress = "";
    try {
      String? printerAdress = await context.getPrinter();
    } catch (e) {}

    final _posprint = PosprinterFlutter();

    String? rtn = await _posprint.getPlatformVersion();
    String? retorno = "";

    int tentativa = 0;

    try {
      if (printerAdress == null || printerAdress == "") {
        while (retorno != "Connected" && tentativa <= 3) {
          //"DC:0D:30:E0:43:C8"
          retorno = await _posprint.connectBluetoothPrinter(adressBT);
          tentativa++;
        }
        if (retorno == "Connected") {
          await context.savePrinter(adressBT);
        }
      } else {
        retorno = "Connected";
      }

      if (retorno == "Connected") {
        try {
          Map<String, dynamic> opt = {"direction": "I"};
          retorno = await _posprint.printText(cmdZPL, optionalParams: opt);
        } catch (e) {
          print(e);
        }
      }
    } catch (e) {
      print(e);
    }
  }

  void _printHeaderInfo(
      {required BlueThermalPrinter bluetooth,
      required EmbalagemPrinter embalagem}) {
    List<String> desc1 = [];

    String info1 = ("Carga: " + (embalagem.carga ?? "-")) +
        " / " +
        "Nota Fiscal: " +
        (embalagem.nroNota ?? "-") +
        " / " +
        (embalagem.serie ?? "S/ Serie") +
        " / " +
        ("Embalagem: " + (embalagem.seqEmbalagem ?? "-"));

    String info2 = ("Cliente: " +
        (embalagem.nomeCliente ?? "-") +
        " End: " +
        (embalagem.end ?? "-"));

    int len1 = info1.length + info2.length;

    int qtdlinhas = (len1 / 50).toInt();
    int modlinha = (len1 % 50).toInt();

    qtdlinhas += modlinha > 0 && modlinha < 50 ? 1 : 0;

    for (var e = 0; e < info1.length; e += 50) {
      desc1.add(
          info1.substring(e, e + 50 < info1.length ? e + 50 : info1.length));
    }

    for (var e = 0; e < info2.length; e += 50) {
      desc1.add(
          info2.substring(e, e + 50 < info2.length ? e + 50 : info2.length));
    }

    for (var a = 0; a < desc1.length; a++) {
      if (qtdlinhas > nMaxLinhas) {
        _saltaEtiqueta(bluetooth, 3);
        nLinhaAtual = 1;
      } else {
        bluetooth.printCustom(desc1[a], 1, PrinterHelper.escAlignLeft);
        nLinhaAtual++;
      }
    }
  }

  void _printHeaderItens(BlueThermalPrinter bluetooth) {
    bluetooth.printCustom(
        "ITENS DA EMBALAGEM", 1, PrinterHelper.escAlignCenter);
    _printLine(bluetooth);
    nLinhaAtual++;
  }

  Future<void> _printItemProd(
      {required BlueThermalPrinter bluetooth,
      required List<ItensEmbalagemPrinter> ListitemPedido}) async {
    List<String> listDesc = [];

    for (var i = 0; i < ListitemPedido.length; i++) {
      String nameProd = ListitemPedido[i].nomeProd;
      String name = nameProd
          .replaceAll("ç", "c")
          .replaceAll("ã", "a")
          .replaceAll("õ", "o")
          .replaceAll("á", "a")
          .replaceAll("é", "e")
          .replaceAll("í", "i")
          .replaceAll("ó", "o")
          .replaceAll("à", "a");

      String codProd = ListitemPedido[i].codProd;
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
      // listDesc.add("--------------------------------------------------");
      for (var e = 0; e < len; e += 50) {
        listDesc.add(
            name.substring(e, e + 50 < name.length ? e + 50 : name.length));
      }
      listDesc.add("Quantidade: " + ListitemPedido[i].qtd!.toString());
      listDesc.add("--------------------------------------------------");
    }

    //Imprime os Itens da Embalagem
    for (var a = 0; a < listDesc.length; a++) {
      if (nMaxLinhas < nLinhaAtual) {
        _saltaEtiqueta(bluetooth, 2);
        nLinhaAtual = 1;
        _printHeaderItens(bluetooth);
      }
      nLinhaAtual++;

      bluetooth.printCustom(listDesc[a], 1, PrinterHelper.escAlignLeft);
    }

    nMaxLinhas += 3;
    _saltaEtiqueta(bluetooth,
        (nMaxLinhas - nLinhaAtual).isNegative ? 0 : (nMaxLinhas - nLinhaAtual));
  }

  _saltaEtiqueta(BlueThermalPrinter bluetooth, int Restante) {
    for (var i = 0; i <= Restante; i++) {
      bluetooth.printNewLine();
    }
    nLinhaAtual = 0;
  }

  Future<bool> PrintZPL(
      {BuildContext? context,
      required PosprinterFlutter posprint,
      required String cmdZPL}) async {

    try {
      Map<String, dynamic> opt = {"direction": "I"};
      await posprint.printText(cmdZPL, optionalParams: opt);

      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
