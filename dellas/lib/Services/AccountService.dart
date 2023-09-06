import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:dellas/Infrastructure/Http/WebClient.dart';
import 'package:dellas/Models/APIModels/LoginModel.dart';
import 'package:dellas/Models/APIModels/RetornoLoginModel.dart';
import 'package:dellas/Shared/Dialog.dart';

class AccountService {
  final BuildContext context;

  AccountService(this.context);

  Future<RetornoLoginModel?> login(LoginModel loginModel) async {
    String wS = json.encode(loginModel);
    print(wS);

    try {
      final Response response = await getClient(context: context).post(
        Uri.parse(baseUrl + "/ApiCliente/Login"),
        headers: {
          'Content-type': 'application/json',
        },
        body: wS,
      );

      RetornoLoginModel rtn = new RetornoLoginModel();

      String? retorno = response.body;
      print(retorno);
      print(baseUrl + "/ApiCliente/Login");

      rtn = new RetornoLoginModel.fromJson(jsonDecode(retorno));

      if (rtn == null) {
        Dialogs.showToast(context,
            "Ocorreu um erro em nossos servidores, tente novamente mais tarde.");
        return null;
      } else if (rtn.error == null || !rtn.error) {
        // Dialogs.showToast(context, "Login concluído com sucesso");
        // UsuarioModel user = UsuarioModel.fromJson(rtn.data.user);
        return rtn;
      } else {
        Dialogs.showToast(context, rtn.message);
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
