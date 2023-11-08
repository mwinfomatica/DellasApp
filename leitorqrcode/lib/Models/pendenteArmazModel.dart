import 'package:leitorqrcode/Infrastructure/DataBase/DataBase.dart';
import 'package:sqflite/sqflite.dart';

class pendenteArmazModel {
  String id;
  String idProd;
  String idtransf;
  String end;
  String qtd;
  String valid;
  String lote;
  String nomeProd;
  String idoperador;
  String situacao;
  String barcode;

  pendenteArmazModel(
      {this.id,
      this.idProd,
      this.nomeProd,
      this.idtransf,
      this.end,
      this.qtd,
      this.lote,
      this.valid,
      this.idoperador,
      this.situacao,
      this.barcode});

  pendenteArmazModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    idProd = json['idProd'];
    idtransf = json['idtransf'];
    end = json['end'];
    qtd = json['qtd'];
    lote = json['lote'];
    valid = json['valid'];
    idoperador = json['idoperador'];
    situacao = json['situacao'];
    nomeProd = json['nomeProd'];
    barcode = json['barcode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['idProd'] = this.idProd;
    data['idtransf'] = this.idtransf;
    data['end'] = this.end;
    data['qtd'] = this.qtd;
    data['valid'] = this.valid;
    data['lote'] = this.lote;
    data['idoperador'] = this.idoperador;
    data['nomeProd'] = this.nomeProd;
    data['situacao'] = this.situacao;
    data['barcode'] = this.barcode;
    return data;
  }

  Map<String, dynamic> toJsonUpdate() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['idProd'] = this.idProd;
    data['idtransf'] = this.idtransf;
    data['end'] = this.end;
    data['qtd'] = this.qtd;
    data['valid'] = this.valid;
    data['lote'] = this.lote;
    data['idoperador'] = this.idoperador;
    data['situacao'] = this.situacao;
    data['barcode'] = this.barcode;
    return data;
  }

  insert() async {
    Database db = await DatabaseHelper.instance.database;
    await db.insert(
      "pendenteArmaz",
      toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  update() async {
    Database db = await DatabaseHelper.instance.database;
    await db.update(
      "pendenteArmaz",
      toJsonUpdate(),
      where: 'id = ?',
      whereArgs: [this.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  delete(String id) async {
    Database db = await DatabaseHelper.instance.database;
    await db.delete("pendenteArmaz", where: "id = ?", whereArgs: [id]);
  }

  deleteByProd(String idprod, String idtrnasf) async {
    Database db = await DatabaseHelper.instance.database;
    await db.delete("pendenteArmaz",
        where: "idProd = ? AND idtransf = ? ", whereArgs: [idprod, idtrnasf]);
  }

  deleteAll() async {
    Database db = await DatabaseHelper.instance.database;
    await db.delete("pendenteArmaz");
  }

  Future<pendenteArmazModel> getByIdProdIdTransf(
      String idprod, String idtransf) async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query("pendenteArmaz",
        where: "idProd = ? AND idtransf = ?", whereArgs: [idprod, idtransf]);
    if (result != null) {
      return result.isNotEmpty
          ? pendenteArmazModel.fromJson(result.first)
          : Future<Null>.value(null);
    } else {
      return Future<Null>.value(null);
    }
  }

  Future<List<pendenteArmazModel>> getListByTransf(String idtrnasf) async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db
        .query("pendenteArmaz", where: "idtransf = ?", whereArgs: [idtrnasf]);
    List<pendenteArmazModel> listretirada = [];

    if (result.isNotEmpty) {
      for (var i = 0; i < result.length; i++) {
        pendenteArmazModel retirada = pendenteArmazModel.fromJson(result[i]);
        listretirada.add(retirada);
      }
    }
    return listretirada;
  }

  Future<List<pendenteArmazModel>> getAll() async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query("pendenteArmaz");
    List<pendenteArmazModel> listretirada = [];

    if (result.isNotEmpty) {
      for (var i = 0; i < result.length; i++) {
        pendenteArmazModel retirada = pendenteArmazModel.fromJson(result[i]);
        listretirada.add(retirada);
      }
    }
    return listretirada;
  }

  Future<List<pendenteArmazModel>> getAllpendente() async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query("pendenteArmaz", where: "situacao = '0'");
    List<pendenteArmazModel> listretirada = [];

    if (result.isNotEmpty) {
      for (var i = 0; i < result.length; i++) {
        pendenteArmazModel retirada = pendenteArmazModel.fromJson(result[i]);
        listretirada.add(retirada);
      }
    }
    return listretirada;
  }
}
