import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:leitorqrcode/Infrastructure/Http/WebClient.dart';
import 'package:leitorqrcode/Models/APIModels/ConfItensEmbalagem.dart';
import 'package:leitorqrcode/Models/APIModels/EmbalagemModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoBase.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoGetCreateEmbalagemModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoGetEmbalagemListModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoNotasFiscaisModel.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotasFiscaisService {
  final BuildContext context;

  NotasFiscaisService(this.context);

  Future<String> _getIdUser() async {
    SharedPreferences userlogged = await SharedPreferences.getInstance();
    return userlogged.getString('IdUser')!;
  }

  Future<RetornoNotasFiscaisModel?> getNotasFiscais(String idPedido) async {
    try {
      final Response response = await getClient(context: context).get(
        Uri.parse(baseUrl + "/ApiCliente/GetNfeEmbalagens?idPedido=$idPedido"),
        headers: {
          'Content-type': 'application/json',
        },
      );

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
      final Response response = await getClient(context: context).get(
        Uri.parse(baseUrl + "/ApiCliente/GetEmbalagemList?idPedido=$idPedido"),
        headers: {
          'Content-type': 'application/json',
        },
      );

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

  Future<RetornoGetCreateEmbalagemModel?> getCreateEmbalagem(
      String idPedido) async {
    try {
      String idUser = await _getIdUser();
      final Response response = await getClient(context: context).get(
        Uri.parse(baseUrl +
            "/ApiCliente/GetCreateEmbalagem?idPedido=$idPedido&idUsuario=$idUser"),
        headers: {
          'Content-type': 'application/json',
        },
      );

      final respostaCarga =
          RetornoGetCreateEmbalagemModel.fromJson(jsonDecode(response.body));

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

  Future<RetornoBaseModel?> finalizarEmbalagem(
      EmbalagemModel embalagemModel) async {
    String wS = json.encode(embalagemModel);
    try {
      final Response response = await getClient(context: context).post(
        Uri.parse(baseUrl + "/ApiCliente/FinalizarEmbalagem"),
        headers: {
          'Content-type': 'application/json',
        },
        body: wS,
      );

      RetornoBaseModel? rtn =
          RetornoBaseModel.fromJson(jsonDecode(response.body));

      if (rtn != null) {
        return rtn;
      } else
        return Future.value(null);
    } catch (ex) {
      return RetornoBaseModel(
          error: true,
          message: "Um erro inesperado ocorreu ao Finalizar a embalagem.");
    }
  }

  Future<RetornoGetEditEmbalagemModel?> getItensEmbalagem(
      String idEmbalagem) async {
    try {
      String idUser = await _getIdUser();
      final Response response = await getClient(context: context).get(
        Uri.parse(baseUrl +
            "/ApiCliente/GetEditEmbalagem?IdEmbalagem=$idEmbalagem&IdUsuario=$idUser"),
        headers: {
          'Content-type': 'application/json',
        },
      );

      RetornoGetEditEmbalagemModel respostaCarga =
          RetornoGetEditEmbalagemModel.fromJson(jsonDecode(response.body));

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

  Future<RetornoGetDetailsEmbalagemModel?> getDetailsItensEmbalagem(
      String idEmbalagem) async {
    try {
      String idUser = await _getIdUser();
      final Response response = await getClient(context: context).get(
        Uri.parse(baseUrl +
            "/ApiCliente/GetDetailsEmbalagem?IdEmbalagem=$idEmbalagem&IdUsuario=$idUser"),
        headers: {
          'Content-type': 'application/json',
        },
      );

      RetornoGetDetailsEmbalagemModel rtnEmbalagem =
          RetornoGetDetailsEmbalagemModel.fromJson(jsonDecode(response.body));

      if (rtnEmbalagem.error) {
        Dialogs.showToast(context, rtnEmbalagem.message, bgColor: Colors.red);
        return null;
      } else {
        return rtnEmbalagem;
      }
    } catch (ex) {
      Dialogs.showToast(context,
          "Ocorreu um erro em nossos servidores, tente novamente mais tarde.");
      print(ex);
      return null;
    }
  }

  Future<RetornoBaseModel?> DeleteEmbalagem(String IdEmbalagem) async {
    try {
      String idUser = await _getIdUser();
      final Response response = await getClient(context: context)
          .post(Uri.parse(baseUrl + "/ApiCliente/DeleteEmbalagem"),
              headers: {
                'Content-type': 'application/json',
              },
              body: jsonEncode({
                "IdEmbalagem": IdEmbalagem,
                "IdUsuario": idUser,
              }));

      RetornoBaseModel? rtn =
          RetornoBaseModel.fromJson(jsonDecode(response.body));

      if (rtn != null) {
        return rtn;
      } else
        return Future.value(null);
    } catch (ex) {
      print(ex);
      return RetornoBaseModel(
          error: true,
          message: "Um erro inesperado ocorreu ao Finalizar a embalagem.");
    }
  }

  Future<RetornoGetDadosEmbalagemListModel?> getDadosPrinterEmbalagem(
      List<String> idEmbalagem) async {
    try {
      Uri uri = Uri(
        scheme: 'http',
        host: '3.224.148.218',
        path: '/Dellas/ApiCliente/GetDadosPrinterEmbalagem/',
        queryParameters: {
          'model': idEmbalagem.join(","),
        },
      );

      final Response response = await getClient(context: context).get(
        uri,
        headers: {
          'Content-type': 'application/json',
        },
      );

      RetornoGetDadosEmbalagemListModel respostaCarga =
          RetornoGetDadosEmbalagemListModel.fromJson(jsonDecode(response.body));

      if (respostaCarga.error) {
        Dialogs.showToast(context, respostaCarga.message, bgColor: Colors.red);
        return null;
      } else {
        if (respostaCarga.data == null || respostaCarga.data.length == 0) {
          Dialogs.showToast(context, "Não há Etiquetas para ser impressa.",
              bgColor: Colors.orange[400], duration: Duration(seconds: 2));

          return null;
        }
        return respostaCarga;
      }
    } catch (ex) {
      Dialogs.showToast(context,
          "Ocorreu um erro em nossos servidores, tente novamente mais tarde.");
      print(ex);
      return null;
    }
  }

  Future<RetornoGetConfItensEmbalagemModel?> getConfItensEmbalagem(
      String idEmbalagem) async {
    try {
      String idUser = await _getIdUser();
      final Response response = await getClient(context: context).get(
        Uri.parse(baseUrl +
            "/ApiCliente/ConfItensEmbalagem?IdEmbalagem=$idEmbalagem"),
        headers: {
          'Content-type': 'application/json',
        },
      );

      RetornoGetConfItensEmbalagemModel respostaCarga =
          RetornoGetConfItensEmbalagemModel.fromJson(jsonDecode(response.body));

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
