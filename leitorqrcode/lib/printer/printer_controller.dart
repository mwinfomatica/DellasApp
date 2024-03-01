import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:leitorqrcode/printer/printer_helper.dart';

class PrinterController {
  var Currencyformat = NumberFormat("##0.00", "pt_BR");

  void _printHeaderCupom2(
      {required BlueThermalPrinter bluetooth,
      String? nomeproduto,
      String? valorTotal,
      String nomeuser = "",
      String estab = ""}) {
    DateTime data = DateTime.now();
    DateFormat datf = DateFormat('dd/MM/yyyy H:m');

    String date = datf.format(data);

    bluetooth.printCustom(estab, 4, PrinterHelper.escAlignCenter);
    bluetooth.printCustom(
        "--------------------------------", 0, PrinterHelper.escAlignRight);
    // bluetooth.printNewLine();

    bluetooth.printNewLine();
    bluetooth.printCustom(
      nomeproduto != null
          ? nomeproduto.length > 10
              ? nomeproduto
                  .substring(0, 10)
                  .replaceAll("ç", "c")
                  .replaceAll("ã", "a")
                  .replaceAll("õ", "o")
                  .replaceAll("á", "a")
                  .replaceAll("é", "e")
                  .replaceAll("í", "i")
                  .replaceAll("ó", "o")
                  .replaceAll("à", "a")
              : nomeproduto
                  .replaceAll("ç", "c")
                  .replaceAll("ã", "a")
                  .replaceAll("õ", "o")
                  .replaceAll("á", "a")
                  .replaceAll("é", "e")
                  .replaceAll("í", "i")
                  .replaceAll("ó", "o")
                  .replaceAll("à", "a")
          : "",
      4,
      PrinterHelper.escAlignCenter,
    );

    // bluetooth.printNewLine();

    bluetooth.printCustom(
      "R\$ " + Currencyformat.format(double.parse(valorTotal!)),
      3,
      PrinterHelper.escAlignCenter,
    );

    bluetooth.printCustom(
        "--------------------------------", 0, PrinterHelper.escAlignRight);

    bluetooth.printCustom(
      (date + " - " + nomeuser),
      PrinterHelper.sizeFontItensPedidos.bitLength,
      PrinterHelper.escAlignLeft,
    );
  }

  void _printHeaderCupom(
      {required BlueThermalPrinter bluetooth, String estab = ""}) {
    bluetooth.printCustom(estab, 4, PrinterHelper.escAlignCenter);
    bluetooth.printCustom(
        "--------------------------------", 0, PrinterHelper.escAlignRight);
    bluetooth.print4Column("Item", "Qtd", "VL", "Total", 0);

    // bluetooth.printLeftRight("Item        Qtd  ", "VL    Total", 0);
    bluetooth.printLeftRight("--------------------------------", " ", 0);
  }

  void printCupomComandaIndividual(
      {required String username,
      required BlueThermalPrinter bluetooth,
      required BuildContext context}) async {
    bluetooth.isConnected.then((isConnected) {
      if (isConnected!) {
        double vlrTotal = 0;
        // _printHeaderCupom2(
        //     bluetooth: bluetooth,
        //     nomeproduto: "",
        //     valorTotal: vlrTotal.toString(),
        //     nomeuser: username,
        //     estab: "");

        bluetooth.printImage('/assets/img/barcode.png');

        bluetooth.printCustom(
            "--------------------------------", 0, PrinterHelper.escAlignRight);
        bluetooth.printNewLine();
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

  // void printCupomPorMesa(
  //     {required BlueThermalPrinter bluetooth,
  //     required PedidoModel pedido,
  //     required List<ItensPedidoModel> listPedidos,
  //     required BuildContext context}) async {
  //   List<FormaPgtoPedido> forma =
  //       await AppFormaPgtoPedidoService().getbyPedido(pedido.codPedido!);
  //   String estab = await getNameEstab();

  //   bluetooth.isConnected.then((isConnected) {
  //     if (isConnected!) {
  //       _printHeaderCupom(bluetooth: bluetooth, estab: estab);

  //       for (var i = 0; i < listPedidos.length; i++) {
  //         ItensPedidoModel item = listPedidos[i];
  //         _printItemPedido(bluetooth: bluetooth, itemPedido: item);
  //       }

  //       bluetooth.printNewLine();
  //       double vlrTotal = pedido.valorTotal ?? 0;

  //       _printFooterCupom(
  //           bluetooth: bluetooth,
  //           vlrTotal: vlrTotal,
  //           qtdTotalItens: listPedidos.length,
  //           vlrTaxas: null);
  //       bluetooth.printNewLine();

  //       _printformaPgto(
  //           bluetooth: bluetooth, listforma: forma, totalpedido: vlrTotal);

  //       bluetooth.printNewLine();
  //     } else {
  //       Dialogs.showToast(
  //           context, "Impressora não está conectada", DialogType.info,
  //           duration: const Duration(seconds: 5));
  //     }
  //   });
  // }

  // Future<void> _printItemPedido({required BlueThermalPrinter bluetooth}) async {
  //   var namePedido = "";
  //   String name = namePedido[0]
  //       .replaceAll("ç", "c")
  //       .replaceAll("ã", "a")
  //       .replaceAll("õ", "o")
  //       .replaceAll("á", "a")
  //       .replaceAll("é", "e")
  //       .replaceAll("í", "i")
  //       .replaceAll("ó", "o")
  //       .replaceAll("à", "a");

  //   if (name.length > 6) {
  //     name = name
  //         .substring(0, 6)
  //         .replaceAll("ç", "c")
  //         .replaceAll("ã", "a")
  //         .replaceAll("õ", "o")
  //         .replaceAll("á", "a")
  //         .replaceAll("é", "e")
  //         .replaceAll("í", "i")
  //         .replaceAll("ó", "o")
  //         .replaceAll("à", "a");
  //   }

  //   var vlrunt = Currencyformat.format(itemPedido.valorUnitario!);
  //   var vlrtotal = Currencyformat.format(itemPedido.valorTotal!);
  //   var qtd = itemPedido.quantidade!.toStringAsFixed(3);

  //   // bluetooth.printLeftRight(
  //   //     name + " " + qtd + " ",
  //   //     vlrunt.padLeft(6, ".").substring(0, 6) +
  //   //         vlrtotal.padLeft(8, ".").substring(0, 8),
  //   //     0);
  //   bluetooth.print4Column(
  //     name,
  //     qtd,
  //     vlrunt,
  //     vlrtotal,
  //     0,
  //     format: PrinterHelper.formatItensPedidos,
  //   );
  // }

  // void _printformaPgto(
  //     {List<FormaPgtoPedido>? listforma,
  //     required BlueThermalPrinter bluetooth,
  //     double? totalpedido}) {
  //   double? valorDebito = 0;
  //   double? valorCredito = 0;
  //   double? valorDinheiro = 0;
  //   double? valorPix = 0;

  //   for (var cred in listforma!.where((e) {
  //     return e.formapgto != null &&
  //         e.formapgto ==
  //             (EnumFormaPgtoPedido.cartaoCredito.index + 1).toString();
  //   })) {
  //     valorCredito = valorCredito! + cred.valor!;
  //   }
  //   for (var deb in listforma.where((e) {
  //     return e.formapgto != null &&
  //         e.formapgto! ==
  //             (EnumFormaPgtoPedido.cartaoDebito.index + 1).toString();
  //   })) {
  //     valorDebito = valorDebito! + deb.valor!;
  //   }
  //   for (var din in listforma.where((e) {
  //     return e.formapgto != null &&
  //         e.formapgto! == (EnumFormaPgtoPedido.dinheiro.index + 1).toString();
  //   })) {
  //     valorDinheiro = valorDinheiro! + din.valor!;
  //   }
  //   for (var pix in listforma.where((e) {
  //     return e.formapgto != null &&
  //         e.formapgto! == (EnumFormaPgtoPedido.pix.index + 1).toString();
  //   })) {
  //     valorPix = valorPix! + pix.valor!;
  //   }

  //   if (valorPix != 0 ||
  //       valorCredito != 0 ||
  //       valorDebito != 0 ||
  //       valorDinheiro != 0) {
  //     bluetooth.printLeftRight(
  //         "Pagamentos", "...........", PrinterHelper.sizeFontItensPedidos);
  //     if (valorCredito != 0) {
  //       bluetooth.printLeftRight(
  //           "Credito",
  //           "R\$ " + Currencyformat.format(valorCredito),
  //           PrinterHelper.sizeFontItensPedidos);
  //     }
  //     if (valorDebito != 0) {
  //       bluetooth.printLeftRight(
  //           "Debito",
  //           "R\$ " + Currencyformat.format(valorDebito),
  //           PrinterHelper.sizeFontItensPedidos);
  //     }
  //     if (valorDinheiro != 0) {
  //       bluetooth.printLeftRight(
  //           "Dinheiro",
  //           "R\$ " + Currencyformat.format(valorDinheiro),
  //           PrinterHelper.sizeFontItensPedidos);
  //     }
  //     if (valorPix != 0) {
  //       bluetooth.printLeftRight(
  //           "PIX",
  //           "R\$ " + Currencyformat.format(valorPix),
  //           PrinterHelper.sizeFontItensPedidos);
  //     }
  //     double vlrtotal =
  //         (valorPix! + valorDinheiro! + valorDebito! + valorCredito!);

  //     bluetooth.printCustom(
  //         "--------------------------------", 0, PrinterHelper.escAlignRight);
  //     bluetooth.printLeftRight(
  //         "TOTAL Pgto:",
  //         "R\$ " + Currencyformat.format(vlrtotal),
  //         PrinterHelper.sizeFontItensPedidos);

  //     bluetooth.printCustom(
  //         "--------------------------------", 0, PrinterHelper.escAlignRight);

  //     bluetooth.printLeftRight(
  //         "Saldo:",
  //         "R\$ " + Currencyformat.format((totalpedido ?? 0) - vlrtotal),
  //         PrinterHelper.sizeFontItensPedidos);
  //   }

  //   bluetooth.printCustom(
  //       "--------------------------------", 0, PrinterHelper.escAlignRight);
  // }

  // void _printFooterCupom(
  //     {double? vlrTaxas,
  //     required BlueThermalPrinter bluetooth,
  //     required double vlrTotal,
  //     required int qtdTotalItens}) {
  //   bluetooth.printLeftRight(
  //     "Qtd total",
  //     qtdTotalItens.toString(),
  //     PrinterHelper.sizeFontItensPedidos,
  //   );

  //   if (vlrTaxas != null && !vlrTaxas.isNegative) {
  //     String? taxas = vlrTaxas.toString() + "%";
  //     bluetooth.printLeftRight("Vlr total taxas R\$",
  //         Currencyformat.format(taxas), PrinterHelper.sizeFontItensPedidos,
  //         charset: PrinterHelper.charsetDefault,
  //         format: PrinterHelper.formatItensPedidos);
  //   }

  //   bluetooth.printLeftRight(
  //     "Vlr total R\$",
  //     Currencyformat.format(vlrTotal),
  //     PrinterHelper.sizeFontItensPedidos,
  //   );

  //   bluetooth.printNewLine();
  // }

  // void printDataPrinterConected(
  //     {required BlueThermalPrinter bluetooth,
  //     required BuildContext context,
  //     required BluetoothDevice deviceConected}) async {
  //   bluetooth.isConnected.then((isConnected) {
  //     // print("------------------ ------------------- -------------------");
  //     // print("isConnected");
  //     // print(isConnected);
  //     if (isConnected!) {
  //       bluetooth.printCustom("Dados Impressora",
  //           PrinterHelper.boldWithLargeText, PrinterHelper.escAlignCenter);

  //       bluetooth.print4Column("nome", "", "", deviceConected.name!,
  //           PrinterHelper.sizeFontItensPedidos,
  //           charset: PrinterHelper.charsetDefault,
  //           format: PrinterHelper.formatItensPedidos);

  //       bluetooth.print4Column(
  //           "address",
  //           "",
  //           "",
  //           deviceConected.address.toString(),
  //           PrinterHelper.sizeFontItensPedidos,
  //           charset: PrinterHelper.charsetDefault,
  //           format: PrinterHelper.formatItensPedidos);

  //       bluetooth.print4Column("type", "", "", deviceConected.type.toString(),
  //           PrinterHelper.sizeFontItensPedidos,
  //           charset: PrinterHelper.charsetDefault,
  //           format: PrinterHelper.formatItensPedidos);

  //       // bluetooth.printNewLine();
  //       bluetooth.printNewLine();
  //       bluetooth.printNewLine();

  //       bluetooth.paperCut();
  //     } else {
  //       Dialogs.showToast(context, "Impressora não está conectada",
  //           duration: const Duration(seconds: 5));
  //     }
  //   });
  // }
}
