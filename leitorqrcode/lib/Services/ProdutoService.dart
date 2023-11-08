import 'dart:convert';

import 'package:http/http.dart';
import 'package:leitorqrcode/Infrastructure/Http/WebClient.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoBase.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoLoginModel.dart';
import 'package:leitorqrcode/Models/APIModels/SearchProdutosModel.dart';

class ProdutoService {
  Future<List<ProdutoModel>> getProdutos(String idOperacao) async {
    SearchProdutosModel search = new SearchProdutosModel();
    search.codOp = idOperacao;
    String wS = json.encode(search);
    List<ProdutoModel> prods = [];
    try {
      final Response response = await getClient(context: null).post(
        Uri.parse(baseUrl + "/ApiCliente/GetProdutosOpApp"),
        headers: {
          'Content-type': 'application/json',
        },
        body: wS,
      );

      RetornoBaseModel rtn =
          RetornoBaseModel.fromJson(jsonDecode(response.body));

      if (rtn != null && !rtn.error) {
        // prods = prods.map((e) => ProdutoModel.fromJson(e.toJson())).toList();
        // print(prods);
        prods = (rtn.data as List)
            .map((item) => ProdutoModel.fromJson(item))
            .toList();
        return prods;
      } else
        return Future<Null>.value(null);
    } catch (ex) {
      print(ex);
      return Future<Null>.value(null);
    }
  }

  Future<List<ProdutoModel>> getProdutosDevolucao(String idOperacao) async {
    SearchProdutosModel search = new SearchProdutosModel();
    search.codOp = idOperacao;
    String wS = json.encode(search);
    List<ProdutoModel> prods = [];
    try {
      final Response response = await getClient(context: null).post(
        Uri.parse(baseUrl + "/ApiCliente/GetProdutosOpAppdev"),
        headers: {
          'Content-type': 'application/json',
        },
        body: wS,
      );

      RetornoBaseModel rtn =
          RetornoBaseModel.fromJson(jsonDecode(response.body));

      if (rtn != null && !rtn.error) {
        // prods = prods.map((e) => ProdutoModel.fromJson(e.toJson())).toList();
        // print(prods);
        prods = (rtn.data as List)
            .map((item) => ProdutoModel.fromJson(item))
            .toList();
        return prods;
      } else
        return Future<Null>.value(null);
    } catch (ex) {
      print(ex);
      return Future<Null>.value(null);
    }
  }

  Future<RetornoLoginModel> getEndereco() async {
    try {
      final Response response = await getClient(context: null).post(
        Uri.parse(baseUrl + "/ApiCliente/GetEnderecos"),
        headers: {
          'Content-type': 'application/json',
        },
      );
      RetornoLoginModel rtn =
          RetornoLoginModel.fromJsonNotUser(jsonDecode(response.body));
      return rtn;
    } catch (ex) {
      print(ex);
      return Future<RetornoLoginModel>.value(null);
    }
  }
}
