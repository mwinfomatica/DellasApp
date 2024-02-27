import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:leitorqrcode/Infrastructure/Http/WebClient.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoCargaModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoPedidoCargaModel.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';

class CargasServices {
  final BuildContext context;

  CargasServices(this.context);

  Future<RetornoCargaModel?> getCargas() async {
    try {
      final Response response = await getClient(context: context).get(
        Uri.parse(baseUrl + "/ApiCliente/ConfListaCarga"),
        headers: {
          'Content-type': 'application/json',
        },
      );
      print(baseUrl + "/ApiCliente/ConfListaCarga");
      print(response.body);

      final respostaCarga =
          RetornoCargaModel.fromJson(jsonDecode(response.body));

      if (respostaCarga.error) {
        Dialogs.showToast(context, respostaCarga.message);
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

  Future<RetornoPedidoCargaModel?> getPedidosDeCarga(
      String idUser, List<String> cargas) async {
    try {
      String cargasQueryString = cargas.join(',');
      String url =
          '$baseUrl/ApiCliente/ConfListaPedidoCarga?IdUser=$idUser&Cargas=$cargasQueryString';

      var response = await getClient(context: context).get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print(url); // Para depuração
      print(response.body);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return RetornoPedidoCargaModel.fromJson(responseData);
      } else {
        Dialogs.showToast(
            context, "Erro na chamada HTTP: ${response.statusCode}");
        return null;
      }
    } catch (ex) {
      Dialogs.showToast(context,
          "Ocorreu um erro em nossos servidores, tente novamente mais tarde.");
      print(ex);
      return null;
    }
  }
}
