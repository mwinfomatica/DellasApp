import 'package:leitorqrcode/Infrastructure/DataBase/DataBase.dart';
import 'package:sqflite/sqflite.dart';

class MovimentacaoModel {
  String? id;
  String? operacao;
  String? idOperacao;
  String? operador;
  String? endereco;
  String? idProduto;
  String? dataMovimentacao;
  String? codMovi;
  String? nroContagem;
  String? qtd;

  MovimentacaoModel({
    this.id,
    this.operacao,
    this.idOperacao,
    this.operador,
    this.endereco,
    this.idProduto,
    this.dataMovimentacao,
    this.codMovi,
    this.nroContagem,
    this.qtd,
  });

  MovimentacaoModel.fromJson(Map<String, dynamic> json) {
    operacao = json['id'];
    operacao = json['operacao'];
    idOperacao = json['idOperacao'];
    operador = json['operador'];
    endereco = json['endereco'];
    idProduto = json['idProduto'];
    dataMovimentacao = json['dataMovimentacao'];
    codMovi = json['codMovi'];
    nroContagem = json['nroContagem'];
    qtd = json['qtd'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['operacao'] = this.operacao;
    data['idOperacao'] = this.idOperacao;
    data['operador'] = this.operador;
    data['endereco'] = this.endereco;
    data['idProduto'] = this.idProduto;
    data['dataMovimentacao'] = this.dataMovimentacao;
    data['codMovi'] = this.codMovi;
    data['nroContagem'] = this.nroContagem;
    data['qtd'] = this.qtd;
    return data;
  }

  insert() async {
    Database db = await DatabaseHelper.instance.database;
    await db.insert(
      "movimentacao",
      toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  updatebyIdOP() async {
    Database db = await DatabaseHelper.instance.database;
    await db.update(
      "movimentacao",
      toJson(),
      where: 'id = ?',
      whereArgs: [this.id],
    );
  }

  updatebyId() async {
    Database db = await DatabaseHelper.instance.database;
    await db.update(
      "movimentacao",
      toJson(),
      where: 'idOperacao = ?',
      whereArgs: [this.idOperacao],
    );
  }

  updatebyIdOpProdEnd() async {
    Database db = await DatabaseHelper.instance.database;
    await db.update(
      "movimentacao",
      toJson(),
      where: 'idOperacao = ? AND idProduto = ? AND endereco = ?',
      whereArgs: [this.idOperacao, this.idProduto, this.endereco],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<MovimentacaoModel?> getModelById(
      String idProduto, String idOperacao) async {
    List<String> columnsToSelect = [
      "id",
      "operacao",
      "idOperacao",
      "operador",
      "endereco",
      "idProduto",
      "dataMovimentacao",
      "codMovi",
      "nroContagem"
    ];

    Database db = await DatabaseHelper.instance.database;
    var data = await db.query("movimentacao",
        columns: columnsToSelect,
        where: 'idProduto = ? AND idOperacao = ?',
        whereArgs: [idProduto, idOperacao]);

    return data.isNotEmpty ? MovimentacaoModel.fromJson(data.first) : null;
  }

  Future<MovimentacaoModel?> getModelByIdProdEnd(
      String idProduto, String idOperacao, String end) async {
    List<String> columnsToSelect = [
      "id",
      "operacao",
      "idOperacao",
      "operador",
      "endereco",
      "idProduto",
      "dataMovimentacao",
      "codMovi",
      "nroContagem"
    ];

    Database db = await DatabaseHelper.instance.database;
    var data = await db.query("movimentacao",
        columns: columnsToSelect,
        where: 'idProduto = ? AND idOperacao = ? AND endereco = ?',
        whereArgs: [idProduto, idOperacao, end]);

    return data.isNotEmpty ? MovimentacaoModel.fromJson(data.first) : null;
  }

  Future<List<MovimentacaoModel>> getAll() async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query("movimentacao");
    List<MovimentacaoModel> listop = [];

    if (result.isNotEmpty) {
      for (var i = 0; i < result.length; i++) {
        MovimentacaoModel op = MovimentacaoModel.fromJson(result[i]);
        listop.add(op);
      }
      return listop;
    } else {
      return [];
    }
  }

  Future<List<MovimentacaoModel>> getAllByoperacao(String idOperacao) async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query("movimentacao",
        where: "idOperacao = ?", whereArgs: [idOperacao]);

    List<MovimentacaoModel> listop = [];

    if (result.isNotEmpty) {
      for (var i = 0; i < result.length; i++) {
        MovimentacaoModel op = MovimentacaoModel.fromJson(result[i]);
        listop.add(op);
      }
      return listop;
    } else {
      return [];
    }
  }

  Future<List<MovimentacaoModel>> getListTrans() async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query("movimentacao");
    List<MovimentacaoModel> listop = [];

    if (result.isNotEmpty) {
      for (var i = 0; i < result.length; i++) {
        MovimentacaoModel op = MovimentacaoModel.fromJson(result[i]);
        listop.add(op);
      }
      return listop;
    } else {
      return [];
    }
  }

  deleteAll() async {
    Database db = await DatabaseHelper.instance.database;
    await db.delete("movimentacao");
  }

  deleteByIdOperacao(String idOperacao) async {
    Database db = await DatabaseHelper.instance.database;
    await db.delete("movimentacao",
        where: "idOperacao = ?", whereArgs: [idOperacao]);
  }

  deleteByIdOperacaoIdProd(String idOperacao, String idProd) async {
    Database db = await DatabaseHelper.instance.database;
    await db.delete("movimentacao",
        where: "idOperacao = ? AND idProduto = ?",
        whereArgs: [idOperacao, idProd]);
  }

  deleteById(String id) async {
    Database db = await DatabaseHelper.instance.database;
    await db.delete("movimentacao", where: "id = ? ", whereArgs: [id]);
  }

  deleteInventario(String idProduto, String idOperacao) async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query("movimentacao",
        where: "idProduto = ? AND idOperacao = ?",
        whereArgs: [idProduto, idOperacao]);

    if (result.isNotEmpty) {
      MovimentacaoModel movi = MovimentacaoModel.fromJson(result.single);
      await db.delete("movimentacao", where: "id = ?", whereArgs: [movi.id]);
    } else {
      // Tratar o caso em que a consulta não retorna nenhum resultado
      print('Nenhum registro encontrado para ser deletado.');
    }
  }
}
