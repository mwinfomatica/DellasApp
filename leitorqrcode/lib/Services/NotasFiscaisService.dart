import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:leitorqrcode/Infrastructure/Http/WebClient.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoGetEmbalagemListModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoNotasFiscaisModel.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';

class NotasFiscaisService {
  final BuildContext context;

  NotasFiscaisService(this.context);

  Future<RetornoNotasFiscaisModel?> getNotasFiscais(String idPedido) async {
    try {
      print('chegou');
      final Response response = await getClient(context: context).get(
        Uri.parse(baseUrl + "/ApiCliente/GetNfeEmbalagens?idPedido=$idPedido"),
        headers: {
          'Content-type': 'application/json',
        },
      );
      print(baseUrl + "/ApiCliente/GetNfeEmbalagens?idPedido=$idPedido");
      print(response.body);

      final respostaCarga =
          RetornoNotasFiscaisModel.fromJson(jsonDecode(response.body));

      if (respostaCarga.error) {
        Dialogs.showToast(context, respostaCarga.message, bgColor: Colors.red);
        return null;
      } else {
        return respostaCarga;
      }
    } catch (ex) {
      Dialogs.showToast(context,
          "Ocorreu um erro em nossos servidores, tente novamente mais tarde.");
      print(ex);
      return null;
    }
  }

  Future<RetornoGetEmbalagemListModel?> getEmbalagemList(
      String idPedido) async {
    try {
      print('chegou getEmbalagemList');
      final Response response = await getClient(context: context).get(
        Uri.parse(baseUrl + "/ApiCliente/GetEmbalagemList?idPedido=$idPedido"),
        headers: {
          'Content-type': 'application/json',
        },
      );

      print(response.body);

      final respostaCarga =
          RetornoGetEmbalagemListModel.fromJson(jsonDecode(response.body));

      if (respostaCarga.error) {
        Dialogs.showToast(context, respostaCarga.message, bgColor: Colors.red);
        return null;
      } else {
        return respostaCarga;
      }
    } catch (ex) {
      Dialogs.showToast(context,
          "Ocorreu um erro em nossos servidores, tente novamente mais tarde.");
      print(ex);
      return null;
    }
  }
}
