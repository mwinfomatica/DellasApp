import 'package:leitorqrcode/Infrastructure/DataBase/DataBase.dart';
import 'package:leitorqrcode/Models/APIModels/MovimentacaoMOdel.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:sqflite/sqflite.dart';

class OperacaoModel {
  String id;
  String tipo;
  String cnpj;
  String nrdoc;
  String situacao;
  List<ProdutoModel> prods;

  OperacaoModel(
      {this.id, this.tipo, this.cnpj, this.nrdoc, this.prods, this.situacao});

  OperacaoModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tipo = json['tipo'];
    cnpj = json['cnpj'];
    nrdoc = json['nrdoc'];
    situacao = json['situacao'];
    if (json['prods'] != null) {
      prods = <ProdutoModel>[];
      json['prods'].forEach((v) {
        prods.add(new ProdutoModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['tipo'] = this.tipo;
    data['cnpj'] = this.cnpj;
    data['nrdoc'] = this.nrdoc;
    data['situacao'] = this.situacao;
    if (this.prods != null) {
      data['prods'] = this.prods.map((v) => v.toJson()).toList();
    }
    return data;
  }

  Map<String, dynamic> toJsonDB() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['tipo'] = this.tipo;
    data['cnpj'] = this.cnpj;
    data['nrdoc'] = this.nrdoc;
    data['situacao'] = this.situacao;
    return data;
  }

  insert() async {
    Database db = await DatabaseHelper.instance.database;
    await db.insert(
      "operacao",
      toJsonDB(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  delete(String id) async {
    Database db = await DatabaseHelper.instance.database;
    await db.delete("operacao", where: "id = ?", whereArgs: [id]);
  }
  deleteAll() async {
    Database db = await DatabaseHelper.instance.database;
    await db.delete("operacao");
  }

  update() async {
    Database db = await DatabaseHelper.instance.database;
    await db.update(
      "operacao",
      toJsonDB(),
      where: 'id = ?',
      whereArgs: [this.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  reset() async {
    this.situacao = "1";
    List<ProdutoModel> prods = await ProdutoModel().getByIdOperacao(this.id);

    if (prods.where((element) => element.isVirtual == "1").length > 0) {
      int soma =
          prods.map((item) => int.parse(item.qtd)).reduce((a, b) => a + b);

      ProdutoModel notVirtual =
          prods.firstWhere((item) => item.isVirtual == "0");

      notVirtual.qtd = (int.parse(notVirtual.qtd) + soma).toString();
    }

    for (int i = 0; i < prods.length; i++) {
      if (prods[i].isVirtual == "1") {
        await prods[i].delete(prods[i].id);
      } else {
        prods[i].situacao = "1";
        await prods[i].update();
      }
    }

    await MovimentacaoModel().deleteByIdOperacao(this.id);

    Database db = await DatabaseHelper.instance.database;
    await db.update(
      "operacao",
      toJsonDB(),
      where: 'id = ?',
      whereArgs: [this.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  getById(String id) async {
    Database db = await DatabaseHelper.instance.database;
    return db.rawQuery("SELECT Id FROM operacao where id = " + id);
  }

  Future<OperacaoModel> getModelById(String id) async {
    List<String> columnsToSelect = ["id", "tipo", "cnpj", "nrdoc", "situacao"];

    Database db = await DatabaseHelper.instance.database;
    var data = await db.query("operacao",
        columns: columnsToSelect, where: 'id = ?', whereArgs: [id]);

    return data.isNotEmpty
        ? OperacaoModel.fromJson(data.first)
        : Future<Null>.value(null);
  }

  Future<OperacaoModel> getModelByNumDocTipo(String numdoc, String tipo) async {
    List<String> columnsToSelect = ["id", "tipo", "cnpj", "nrdoc", "situacao"];

    Database db = await DatabaseHelper.instance.database;
    var data = await db.query("operacao",
        columns: columnsToSelect,
        where: 'nrdoc = ? AND tipo = ?',
        whereArgs: [
          numdoc,
          tipo,
        ]);

    return data.isNotEmpty
        ? OperacaoModel.fromJson(data.first)
        : Future<Null>.value(null);
  }

  Future<List<OperacaoModel>> getListByStituacao() async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query("operacao",
        where: "situacao != ? or situacao is null", whereArgs: ["3"]);
    List<OperacaoModel> listop = [];

    if (result.isNotEmpty) {
      for (var i = 0; i < result.length; i++) {
        OperacaoModel op = OperacaoModel.fromJson(result[i]);
        listop.add(op);
      }
    }
    return listop;
  }

  Future<List<OperacaoModel>> getListFinalizado() async {
    Database db = await DatabaseHelper.instance.database;
    var result =
        await db.query("operacao", where: "situacao = ?", whereArgs: ["3"]);
    List<OperacaoModel> listop = [];

    if (result.isNotEmpty) {
      for (var i = 0; i < result.length; i++) {
        OperacaoModel op = OperacaoModel.fromJson(result[i]);
        listop.add(op);
      }
    }
    return listop;
  }

  Future<List<OperacaoModel>> getListByStituacaoSeparadoC() async {
    Database db = await DatabaseHelper.instance.database;
    var result =
        await db.query("operacao", where: "situacao == ?", whereArgs: ["3"]);
    List<OperacaoModel> listop = [];

    if (result.isNotEmpty) {
      for (var i = 0; i < result.length; i++) {
        OperacaoModel op = OperacaoModel.fromJson(result[i]);
        listop.add(op);
      }
    }
    return listop;
  }

  Future<OperacaoModel> getPendenteAramazenamento() async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query("operacao",
        where: "tipo = '41'");
    return result.isNotEmpty
        ? OperacaoModel.fromJson(result.first)
        : Future<Null>.value(null);
  }

  Future<OperacaoModel> getOpAramazenamento() async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query("operacao",
        where: "tipo = '40'");
    return result.isNotEmpty
        ? OperacaoModel.fromJson(result.first)
        : Future<Null>.value(null);
  }

  Future<OperacaoModel> getOpInventario() async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query("operacao",
        where: "tipo = '90'");
    return result.isNotEmpty
        ? OperacaoModel.fromJson(result.first)
        : Future<Null>.value(null);
  }

  Future<OperacaoModel> getOpAramazenamentoPendente() async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query("operacao",
        where: "tipo = '40'");
    return result.isNotEmpty
        ? OperacaoModel.fromJson(result.first)
        : Future<Null>.value(null);
  }
}
