import 'package:leitorqrcode/Infrastructure/DataBase/DataBase.dart';
import 'package:sqflite/sqflite.dart';

class armprodModel {
  String idArm;
  String idProdArm;
  String nomeProdArm;
  String barcodeArm;
  String idtransfArm;
  String endArm;
  String qtdArm;
  String validArm;
  String loteArm;

  armprodModel(
      {this.idArm,
      this.idProdArm,
      this.idtransfArm,
      this.endArm,
      this.qtdArm,
      this.loteArm,
      this.validArm,
      this.barcodeArm,
      this.nomeProdArm});

  armprodModel.fromJson(Map<String, dynamic> json) {
    idArm = json['idArm'] ?? "";
    idProdArm = json['idProdArm'] ?? "";
    idtransfArm = json['idtransfArm'] ?? "";
    endArm = json['endArm'] ?? "";
    qtdArm = json['qtdArm'] ?? "";
    loteArm = json['loteArm'] ?? "";
    validArm = json['validArm'] ?? "";
    nomeProdArm = json['nomeProdArm'] ?? "";
    barcodeArm = json['barcodeArm'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['idArm'] = this.idArm ?? "";
    data['idProdArm'] = this.idProdArm ?? "";
    data['idtransfArm'] = this.idtransfArm ?? "";
    data['endArm'] = this.endArm ?? "";
    data['qtdArm'] = this.qtdArm ?? "";
    data['validArm'] = this.validArm ?? "";
    data['loteArm'] = this.loteArm ?? "";
    data['nomeProdArm'] = this.nomeProdArm ?? "";
    data['barcodeArm'] = this.barcodeArm ?? "";

    return data;
  }

  Map<String, dynamic> toJsonUpdate() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['idProdArm'] = this.idProdArm ?? "";
    data['idtransfArm'] = this.idtransfArm ?? "";
    data['endArm'] = this.endArm ?? "";
    data['qtdArm'] = this.qtdArm ?? "";
    data['validArm'] = this.validArm ?? "";
    data['loteArm'] = this.loteArm ?? "";
    data['nomeProdArm'] = this.nomeProdArm ?? "";
    data['barcodeArm'] = this.barcodeArm ?? "";
    return data;
  }

  insert() async {
    Database db = await DatabaseHelper.instance.database;;
    await db.insert(
      "armprod",
      toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  update() async {
    Database db = await DatabaseHelper.instance.database;;
    await db.update(
      "armprod",
      toJsonUpdate(),
      where: 'idArm = ?',
      whereArgs: [this.idArm],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  delete(String idArm) async {
    Database db = await DatabaseHelper.instance.database;;
    await db.delete("armprod", where: "idArm = ?", whereArgs: [idArm]);
  }

  deleteAll() async {
    Database db = await DatabaseHelper.instance.database;;
    await db.delete("armprod");
  }

  Future<armprodModel> getByIdProdIdTransf(
      String idprod, String idtransfArm) async {
    Database db = await DatabaseHelper.instance.database;;
    var result = await db.query("armprod",
        where: "idProdArm = ? AND idtransfArm = ?",
        whereArgs: [idprod, idtransfArm]);
    return result.isNotEmpty
        ? armprodModel.fromJson(result.first)
        : Future<Null>.value(null);
  }

  Future<List<armprodModel>> getListByTransf(String idtrnasf) async {
    Database db = await DatabaseHelper.instance.database;;
    var result = await db
        .query("armprodArm", where: "idtransfArm = ?", whereArgs: [idtrnasf]);
    List<armprodModel> listArm = [];

    if (result.isNotEmpty) {
      for (var i = 0; i < result.length; i++) {
        armprodModel arm = armprodModel.fromJson(result[i]);
        listArm.add(arm);
      }
    }
    return listArm;
  }

  Future<List<armprodModel>> getAll() async {
    Database db = await DatabaseHelper.instance.database;;
    var result = await db.query("armprod");
    List<armprodModel> listArm = [];

    if (result.isNotEmpty) {
      for (var i = 0; i < result.length; i++) {
        armprodModel arm = armprodModel.fromJson(result[i]);
        listArm.add(arm);
      }
      return listArm;
    } else {
      return [];
    }
  }
}
