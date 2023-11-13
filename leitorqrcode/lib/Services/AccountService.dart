import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:leitorqrcode/Infrastructure/Http/WebClient.dart';
import 'package:leitorqrcode/Models/APIModels/LoginModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoLoginModel.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';

class AccountService {
  final BuildContext context;

  AccountService(this.context);

  Future<RetornoLoginModel> login(LoginModel loginModel) async {
    String wS = json.encode(loginModel);

    try {
      final Response response = await getClient(context: context).post(
        Uri.parse(baseUrl + "/ApiCliente/Login"),
        headers: {
          'Content-type': 'application/json',
        },
        body: wS,
      );

      RetornoLoginModel rtn =
          new RetornoLoginModel.fromJson(jsonDecode(response.body));

      if (rtn == null) {
        Dialogs.showToast(context,
            "Ocorreu um erro em nossos servidores, tente novamente mais tarde.");
        return Future.value(null);
      } else if (rtn.error == null) {
        // Dialogs.showToast(context, "Login concluído com sucesso");
        // UsuarioModel user = UsuarioModel.fromJson(rtn.data.user);
        return rtn;
      } else {
        Dialogs.showToast(context, rtn.message!);
        return Future.value(null);
      }
    } catch (ex) {
      Dialogs.showToast(context,
          "Ocorreu um erro em nossos servidores, tente novamente mais tarde.");
      print(ex);
      return Future.value(null);
    }
  }
}
