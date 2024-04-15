import 'dart:convert';

import 'package:leitorqrcode/Models/APIModels/UsuarioModel.dart';
import 'package:leitorqrcode/Models/ContextoModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContextoServices {
  ContextoModel? contextoModel;

  Future<void> setEnderecoGrupo({bool? engerecoGrupo}) async {
    ContextoModel contextoModel = await getContexto();
    if (contextoModel != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      contextoModel.enderecoGrupo = engerecoGrupo!;
      final jsonModel = json.encode(contextoModel);
      prefs.setString('ContextoModel', jsonModel);
    }
  }

  Future<void> setDeviceSelected(
      {String? nameDevice, String? uuidDevice}) async {
    ContextoModel contextoModel = await getContexto();
    if (contextoModel != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      contextoModel.nameDevice = nameDevice!;
      contextoModel.uuidDevice = uuidDevice!;
      final jsonModel = json.encode(contextoModel);
      prefs.setString('ContextoModel', jsonModel);
    }
  }

  Future<void> setTipoLeitor({bool? leitorexterno}) async {
    ContextoModel contextoModel = await getContexto();
    if (contextoModel == null) {
      contextoModel = ContextoModel(leituraExterna: leitorexterno!);
    }

    contextoModel.leituraExterna = leitorexterno!;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (leitorexterno == true) {
      contextoModel.descLeituraExterna = "Dispositivo Habilitado";
    } else {
      contextoModel.descLeituraExterna = "Dispositivo Desabilitado";
    }
    final jsonModel = json.encode(contextoModel);
    prefs.setString('ContextoModel', jsonModel);
  }

  Future<ContextoModel> getContexto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey("ContextoModel")) {
        final response = prefs.getString("ContextoModel");
        final jsonModel = jsonDecode(response!);
        contextoModel = ContextoModel.fromJson(jsonModel);

        if (contextoModel!.leituraExterna == false) {
          contextoModel!.descLeituraExterna = "Dispositivo Desabilitado";
        } else {
          contextoModel!.descLeituraExterna = "Dispositivo Habilitado";
        }
      } else {
        contextoModel = ContextoModel(leituraExterna: false);
        contextoModel!.descLeituraExterna = "Dispositivo Desabilitado";
      }
    } catch (e) {
      contextoModel = ContextoModel(leituraExterna: false);
      contextoModel!.descLeituraExterna = "Dispositivo Desabilitado";
    }

    if (contextoModel!.enderecoGrupo == null) {
      contextoModel!.enderecoGrupo = false;
    }

    return contextoModel!;
  }

  Future<void> saveUserLogged(UsuarioModel user) async {
    SharedPreferences sharedPreference = await SharedPreferences.getInstance();
    sharedPreference.setString('IdUser', user.codigo!);
  }

   Future<void> savePrinter(String adress) async {
    SharedPreferences sharedPreference = await SharedPreferences.getInstance();
    sharedPreference.setString('printer', adress);
  }

  Future<String?> getPrinter() async {
    SharedPreferences sharedPreference = await SharedPreferences.getInstance();
    String? adress = sharedPreference.getString('printer')!;
    return adress;
  }

  Future<String> getIdUserLogged() async {
    SharedPreferences sharedPreference = await SharedPreferences.getInstance();
    String id = sharedPreference.getString('IdUser')!;
    return id;
  }

  Future<void> clearUserLogged() async {
    SharedPreferences sharedPreference = await SharedPreferences.getInstance();
    sharedPreference.setString('IdUser', '');
  }
}
