import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:leitorqrcode/Infrastructure/Http/WebClient.dart';
import 'package:leitorqrcode/Models/APIModels/MovimentacaoMOdel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoBase.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';

class MovimentacaoService {
  MovimentacaoService({BuildContext contexto}) {
    this.context = contexto;
  }

  BuildContext context;

  Future<bool> insertMovimentacoes(
      List<MovimentacaoModel> movimentacoes) async {
    String wS = json.encode(movimentacoes);

    try {
      final Response response = await getClient(context: context).post(
        Uri.parse(baseUrl + "/ApiCliente/InsertMovimentacoes"),
        headers: {
          'Content-type': 'application/json',
        },
        body: wS,
      );
      RetornoBaseModel rtn =
          RetornoBaseModel.fromJson(jsonDecode(response.body));

      if (rtn == null) {
        Dialogs.showToast(context,
            "Ocorreu um erro em nossos servidores, tente novamente mais tarde.");
        return Future<bool>.value(false);
      } else if (!rtn.error) {
        Dialogs.showToast(context, "Sincronização concluído com sucesso");
        return Future<bool>.value(true);
      } else {
        Dialogs.showToast(context, rtn.message);
        return Future<bool>.value(false);
      }
    } catch (ex) {
      Dialogs.showToast(context,
          "Ocorreu um erro em nossos servidores, tente novamente mais tarde.");
      print(ex);
      return Future<bool>.value(false);
    }
  }
}
