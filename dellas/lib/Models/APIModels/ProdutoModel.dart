import 'package:dellas/Infrastructure/DataBase/DataBase.dart';
import 'package:sqflite/sqflite.dart';

class ProdutoModel {
  late String id;
  late String idproduto;
  late String idprodutoPedido;
  late String cod;
  late String nome;
  late String desc;
  late String vali;
  late String qtd;
  late String end;
  late String lote;
  late String sl;
  late String idOperacao;
  late String situacao;
  late String idloteunico;
  late String infq;
  late String isVirtual;

  ProdutoModel(
      {this.id = "",
      this.idproduto = "",
      this.idprodutoPedido = "",
      this.cod = "",
      this.nome = "",
      this.desc = "",
      this.vali = "",
      this.qtd = "",
      this.end = "",
      this.lote = "",
      this.sl = "",
      this.idOperacao = "",
      this.situacao = "",
      this.idloteunico = "",
      this.infq = "",
      this.isVirtual = '0'});

  ProdutoModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? "";
    idproduto = json['idproduto'] ?? "";
    idprodutoPedido = json['idprodutoPedido'] ?? "";
    cod = json['cod'] ?? "";
    nome = json['nome'] ?? "";
    desc = json['desc'] ?? "";
    vali = json['vali'] ?? "";
    qtd = json['qtd'] ?? "";
    end = json['end'] ?? "";
    lote = json['lote'] ?? "";
    sl = json['sl'] ?? "";
    idOperacao = json['idOperacao'] ?? "";
    situacao = json['situacao'] ?? "";
    idloteunico = json['idloteunico'] ?? "";
    infq = json['infq'] ?? "";
    isVirtual = json['isVirtual'] ?? "";
  }

  ProdutoModel.fromJsonList(List<Map<String, dynamic>> jsonList) {
    for (int i = 0; i < jsonList.length; i++) {
      id = jsonList[i]['id'] ?? "";
      idproduto = jsonList[i]['idproduto'] ?? "";
      idprodutoPedido = jsonList[i]['idprodutoPedido'] ?? "";
      cod = jsonList[i]['cod'] ?? "";
      nome = jsonList[i]['nome'] ?? "";
      desc = jsonList[i]['desc'] ?? "";
      vali = jsonList[i]['vali'] ?? "";
      qtd = jsonList[i]['qtd'] ?? "";
      end = jsonList[i]['end'] ?? "";
      lote = jsonList[i]['lote'] ?? "";
      sl = jsonList[i]['sl'] ?? "";
      idOperacao = jsonList[i]['idOperacao'] ?? "";
      situacao = jsonList[i]['situacao'] ?? "";
      idloteunico = jsonList[i]['idloteunico'] ?? "";
      infq = jsonList[i]['infq'] ?? "";
      isVirtual = jsonList[i]['isVirtual'] ?? "";
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['idproduto'] = this.idproduto;
    data['idprodutoPedido'] = this.idprodutoPedido;
    data['cod'] = this.cod;
    data['nome'] = this.nome;
    data['desc'] = this.desc;
    data['vali'] = this.vali;
    data['qtd'] = this.qtd;
    data['end'] = this.end;
    data['lote'] = this.lote;
    data['sl'] = this.sl;
    data['idOperacao'] = this.idOperacao;
    data['situacao'] = this.situacao;
    data['idloteunico'] = this.idloteunico;
    data['infq'] = this.infq;
    data['isVirtual'] = this.isVirtual;
    return data;
  }

  Map<String, dynamic> toJsonUpdate() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    // data['id'] = this.id;
    // data['cod'] = this.cod;
    // data['nome'] = this.nome;
    // data['desc'] = this.desc;
    // data['vali'] = this.vali;
    data['qtd'] = this.qtd;
    data['end'] = this.end;
    data['lote'] = this.lote;
    data['idOperacao'] = this.idOperacao;
    data['situacao'] = this.situacao;
    data['idloteunico'] = this.idloteunico;
    data['infq'] = this.infq;
    // data['isVirtual'] = this.isVirtual;
    return data;
  }

  insert() async {
    Database db = await DatabaseHelper.instance.database;

    await db.insert(
      "produtos",
      toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  update() async {
    Database db = await DatabaseHelper.instance.database;

    await db.update(
      "produtos",
      toJsonUpdate(),
      where: 'id = ?',
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: [this.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  delete(String id) async {
    Database db = await DatabaseHelper.instance.database;

    await db.delete("produtos", where: "id = ?", whereArgs: [id]);
  }

  deleteAll() async {
    Database db = await DatabaseHelper.instance.database;

    await db.delete("produtos");
  }

  deleteByIdOperacao(String id) async {
    Database db = await DatabaseHelper.instance.database;

    await db.delete("produtos", where: "idOperacao = ?", whereArgs: [id]);
  }

  edit(ProdutoModel prod) async {
    Database db = await DatabaseHelper.instance.database;

    await db.update("produtos", prod.toJson(),
        where: "id = ?", whereArgs: [prod.id]);
  }

  Future<ProdutoModel?> getById(String id) async {
    Database db = await DatabaseHelper.instance.database;

    var result = await db.query("produtos", where: "id = ?", whereArgs: [id]);
    if (result.isNotEmpty) {
      return ProdutoModel.fromJson(result.first);
    } else {
      return null;
    }
  }

  Future<ProdutoModel?> getByIdLote(String id) async {
    Database db = await DatabaseHelper.instance.database;

    var result = await db.query("produtos",
        where: "idloteunico = ? and (isVirtual = '0' OR isVirtual is null)",
        whereArgs: [id]);
    if (result.isNotEmpty) {
      return ProdutoModel.fromJson(result.first);
    } else {
      return null;
    }
  }

  Future<ProdutoModel?> getByIdLoteIdPedido(
      String id, String idOperacao) async {
    Database db = await DatabaseHelper.instance.database;

    var result = await db.query("produtos",
        where:
            "idloteunico = ? and idOperacao = ? and (isVirtual = '0' OR isVirtual is null) ",
        whereArgs: [id, idOperacao]);
    if (result.isNotEmpty) {
      return ProdutoModel.fromJson(result.first);
    } else {
      return null;
    }
  }

  Future<ProdutoModel?> getByIdLoteIdPedidoSituacao(
      String id, String idOperacao) async {
    Database db = await DatabaseHelper.instance.database;

    var result = await db.query("produtos",
        where:
            "idloteunico = ? and idOperacao = ? and (isVirtual = '0' OR isVirtual is null) and situacao != 3 ",
        whereArgs: [id, idOperacao]);
    if (result.isNotEmpty) {
      return ProdutoModel.fromJson(result.first);
    } else {
      return null;
    }
  }

  Future<ProdutoModel?> getByIdLoteIdPedidoEnd(
      String id, String idOperacao, String end) async {
    Database db = await DatabaseHelper.instance.database;

    var result = await db.query("produtos",
        where:
            "idloteunico = ? and idOperacao = ? and (isVirtual = '0' OR isVirtual is null) and end = ? ",
        whereArgs: [id, idOperacao, end]);
    if (result.isNotEmpty) {
      return ProdutoModel.fromJson(result.first);
    } else {
      return null;
    }
  }

  Future<List<ProdutoModel>> getBySemEnd() async {
    Database db = await DatabaseHelper.instance.database;

    var result = await db.query("produtos", where: "end IS NULL");
    List<ProdutoModel> listop = [];

    if (result.isNotEmpty) {
      for (var i = 0; i < result.length; i++) {
        ProdutoModel op = ProdutoModel.fromJson(result[i]);
        listop.add(op);
      }
      return listop;
    } else {
      return [];
    }
  }

  Future<List<ProdutoModel>> getByIdOperacao(String id) async {
    Database db = await DatabaseHelper.instance.database;

    var result =
        await db.query("produtos", where: "idOperacao = ?", whereArgs: [id]);
    List<ProdutoModel> listop = [];

    if (result.isNotEmpty) {
      for (var i = 0; i < result.length; i++) {
        ProdutoModel op = ProdutoModel.fromJson(result[i]);
        listop.add(op);
      }
    }
    return listop;
  }

  Future<List<ProdutoModel>> getByIdProdIdOperacao(
      String id, String idOp) async {
    Database db = await DatabaseHelper.instance.database;

    var result = await db.query("produtos",
        where:
            "idloteunico = ? AND idOperacao = ? AND (isVirtual = '0' OR isVirtual is null)",
        whereArgs: [id, idOp]);
    List<ProdutoModel> listop = [];

    if (result.isNotEmpty) {
      for (var i = 0; i < result.length; i++) {
        ProdutoModel op = ProdutoModel.fromJson(result[i]);
        listop.add(op);
      }
    }
    return listop;
  }

  Future<ProdutoModel?> getByBar_DumCode(String barcode) async {
    Database db = await DatabaseHelper.instance.database;

    var result = await db.query("produtos",
        where:
            "(barcode = ? OR dumcode = ?) and (isVirtual = '0' OR isVirtual is null)",
        whereArgs: [barcode, barcode]);
    if (result.isNotEmpty) {
      return ProdutoModel.fromJson(result.first);
    } else {
      return null;
    }
  }
}
