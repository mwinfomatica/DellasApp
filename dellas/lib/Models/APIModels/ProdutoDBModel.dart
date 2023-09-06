import 'package:dellas/Infrastructure/DataBase/DataBase.dart';
import 'package:sqflite/sqflite.dart';

class ProdutoDBModel {
  String? id;
  String? cod;
  String? nome;
  String? desc;
  String? vali;
  String? lote;
  String? loteunico;
  String? impressao;
  String? sl;
  String? nrserie;
  String? grupo;
  String? barcode;
  String? infvali;

  ProdutoDBModel(
      {this.id,
      this.cod,
      this.nome,
      this.desc,
      this.vali,
      this.lote,
      this.loteunico,
      this.impressao,
      this.sl,
      this.nrserie,
      this.grupo,
      this.barcode,
      this.infvali});

  ProdutoDBModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    cod = json['cod'];
    nome = json['nome'];
    desc = json['desc'];
    vali = json['vali'];
    lote = json['lote'];
    loteunico = json['loteunico'];
    impressao = json['impressao'];
    sl = json['sl'];
    nrserie = json['nrserie'];
    grupo = json['grupo'];
    barcode = json['barcode'];
    infvali = json['infvali'];
  }

  ProdutoDBModel.fromJsonList(List<Map<String, dynamic>> jsonList) {
    for (int i = 0; i < jsonList.length; i++) {
      id = jsonList[i]['id'];
      cod = jsonList[i]['cod'];
      nome = jsonList[i]['nome'];
      desc = jsonList[i]['desc'];
      vali = jsonList[i]['vali'];
      lote = jsonList[i]['lote'];
      loteunico = jsonList[i]['loteunico'];
      impressao = jsonList[i]['impressao'];
      sl = jsonList[i]['sl'];
      nrserie = jsonList[i]['nrserie'];
      grupo = jsonList[i]['grupo'];
      barcode = jsonList[i]['barcode'];
      infvali = jsonList[i]['infvali'];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['cod'] = this.cod;
    data['nome'] = this.nome;
    data['desc'] = this.desc;
    data['vali'] = this.vali;
    data['lote'] = this.lote;
    data['loteunico'] = this.loteunico;
    data['impressao'] = this.impressao;
    data['sl'] = this.sl;
    data['nrserie'] = this.nrserie;
    data['grupo'] = this.grupo;
    data['barcode'] = this.barcode;
    data['infvali'] = this.infvali;
    return data;
  }

  deleteAll() async {
    Database db = await DatabaseHelper.instance.database;

    await db.delete("produtodb");
  }

  insert() async {
    Database db = await DatabaseHelper.instance.database;

    await db.insert(
      "produtodb",
      toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ProdutoDBModel?> getById(String id) async {
    Database db = await DatabaseHelper.instance.database;

    var result = await db.query("produtodb", where: "id = ?", whereArgs: [id]);

    if (result.isNotEmpty) {
      return ProdutoDBModel.fromJson(result.first);
    } else {
      return null;
    }
  }

  Future<ProdutoDBModel?> getByCodigo(String cod) async {
    Database db = await DatabaseHelper.instance.database;

    var result =
        await db.query("produtodb", where: "cod = ?", whereArgs: [cod]);
    if (result.isNotEmpty) {
      return ProdutoDBModel.fromJson(result.first);
    } else {
      return null;
    }
  }

  Future<ProdutoDBModel?> getByBarCodigo(String barcode) async {
    Database db = await DatabaseHelper.instance.database;

    var result =
        await db.query("produtodb", where: "barcode = ?", whereArgs: [barcode]);
    if (result.isNotEmpty) {
      return ProdutoDBModel.fromJson(result.first);
    } else {
      return null;
    }
  }

  Future<List<ProdutoDBModel>> getAll() async {
    Database db = await DatabaseHelper.instance.database;

    var result = await db.query("produtodb");
    List<ProdutoDBModel> listop = [];

    if (result.isNotEmpty) {
      for (var i = 0; i < result.length; i++) {
        ProdutoDBModel op = ProdutoDBModel.fromJson(result[i]);
        listop.add(op);
      }
    }
    return listop;
  }
}
