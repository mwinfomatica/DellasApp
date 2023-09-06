import 'package:dellas/Infrastructure/DataBase/DataBase.dart';
import 'package:sqflite/sqflite.dart';

class MovimentacaoModel {
  late String id;
  late String operacao;
  late String idOperacao;
  late String operador;
  late String endereco;
  late String idProduto;
  late String dataMovimentacao;
  late String codMovi;
  late String nroContagem;
  late String qtd;

  MovimentacaoModel({
    this.id = "",
    this.operacao = "",
    this.idOperacao = "",
    this.operador = "",
    this.endereco = "",
    this.idProduto = "",
    this.dataMovimentacao = "",
    this.codMovi = "",
    this.nroContagem = "",
    this.qtd = "",
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
      where: 'idOperacao = ?',
      whereArgs: [this.idOperacao],
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
    List<Map<String, Object?>> data = [];
    try {
      data = await db
          .query(
            'movimentacao',
          )
          .catchError(
            // ignore: invalid_return_type_for_catch_error
            (e) => {
              print(e),
            },
          );
      // columns: columnsToSelect,
      // where: 'idProduto = ? AND idOperacao = ?',
      // whereArgs: [idProduto, idOperacao]
    } catch (e) {
      print(e);
    }

    if (data != null && data.isNotEmpty) {
      return MovimentacaoModel.fromJson(data.first);
    } else {
      return Future<Null>.value(null);
    }
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

  deleteInventario(String idProduto, String idOperacao) async {
    Database db = await DatabaseHelper.instance.database;

    var result = await db.query("movimentacao",
        where: "idProduto = ? AND idOperacao = ?",
        whereArgs: [idProduto, idOperacao]);

    MovimentacaoModel? movi = result.single.values.single as MovimentacaoModel?;
    await db.delete("movimentacao", where: "id = ?", whereArgs: [movi!.id]);
  }
}
