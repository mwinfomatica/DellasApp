import 'dart:convert';
import 'package:http/http.dart';
import 'package:leitorqrcode/Infrastructure/Http/WebClient.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoDBModel.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoBase.dart';
import 'package:uuid/uuid.dart';

class ProdutosDBService {
  Future<void> updateProdutosDB() async {
    List<ProdutoDBModel> prods = await getProdutosWS();
    if (prods != null) {
      await ProdutoDBModel().deleteAll();
      for (var i = 0; i < prods.length; i++) {
        ProdutoDBModel end = new ProdutoDBModel();
        end = prods[i];
        end.cod = end.cod!.trim();
        await end.insert();
      }
    }
  }

  Future<List<ProdutoDBModel>> getProdutosWS() async {
    List<ProdutoDBModel> prods = [];
    try {
      final Response response = await getClient(context: null).get(
        Uri.parse(baseUrl + "/ApiCliente/GetProdutos"),
        headers: {
          'Content-type': 'application/json',
        },
      );

      RetornoBaseModel rtn =
          RetornoBaseModel.fromJson(jsonDecode(response.body));

      if (rtn != null && !rtn.error!) {
        // prods = prods.map((e) => ProdutoModel.fromJson(e.toJson())).toList();
        // print(prods);
        prods = (rtn.data as List)
            .map((item) => ProdutoDBModel.fromJson(item))
            .toList();
        return prods;
      } else
        return Future.value(null);
    } catch (ex) {
      print(ex);
      return Future.value(null);
    }
  }

  Future<ProdutoModel> getProdutoPedidoByBarCodigo(String codigo) async {
    try {
      ProdutoDBModel? produtoDBModel =
          await ProdutoDBModel().getByBar_coddum(codigo);

      if (produtoDBModel != null && produtoDBModel.cod!.isNotEmpty) {
        ProdutoModel produtoModel = ProdutoModel();
        produtoModel.id = new Uuid().v4().toUpperCase();
        produtoModel.idproduto = produtoDBModel.id;
        produtoModel.idprodutoPedido = null;
        produtoModel.cod = produtoDBModel.cod;
        produtoModel.nome = produtoDBModel.nome;
        produtoModel.desc = produtoDBModel.desc;
        produtoModel.vali = produtoDBModel.vali;
        produtoModel.qtd = null;
        produtoModel.end = null;
        produtoModel.lote = produtoDBModel.lote;
        produtoModel.sl = produtoDBModel.sl;
        // produtoModel.idOperacao = null;
        // produtoModel.situacao = null;
        produtoModel.idloteunico = produtoDBModel.loteunico;
        produtoModel.infq = null;
        produtoModel.infVali = produtoDBModel.infvali;
        produtoModel.barcode = produtoDBModel.barcode;
        produtoModel.coddum = produtoDBModel.coddum;
        produtoModel.isVirtual = null;
        return produtoModel;
      } else
        return Future.value(null);
    } catch (ex) {
      print(ex);
      return Future.value(null);
    }
  }

  Future<ProdutoModel> getProdutoPedidoByProduto(
      ProdutoModel produtoModel) async {
    try {
      ProdutoDBModel? produtoDBModel =
          await ProdutoDBModel().getByCodigo(produtoModel.cod!);

      if (produtoDBModel != null && produtoDBModel.cod!.isNotEmpty) {
        produtoModel.infVali = produtoDBModel.infvali;
        produtoModel.barcode = produtoDBModel.barcode;
        return produtoModel;
      } else
        return Future.value(null);
    } catch (ex) {
      print(ex);
      return Future.value(null);
    }
  }

  Future<bool> isLeituraQRCodeProduto(String code) async {
    try {
      ProdutoModel prodRead = ProdutoModel.fromJson(jsonDecode(code));
      if (prodRead != null && prodRead.cod!.isNotEmpty)
        return true;
      else
        return false;
    } catch (e) {
      return false;
    }
  }
}
