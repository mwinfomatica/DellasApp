import 'package:leitorqrcode/Infrastructure/DataBase/DataBase.dart';
import 'package:sqflite/sqflite.dart';

class retiradaprodModel {
  String? idRetirado;
  String? idProdRetirado;
  String? idtransfRetirado;
  String? endRetirado;
  String? qtdRetirado;
  String? validRetirado;
  String? loteRetirado;
  String? nomeProdRetirado;
  String? idoperadorRetirado;
  String? barcodeRetirado;

  retiradaprodModel(
      {this.idRetirado,
      this.idProdRetirado,
      this.nomeProdRetirado,
      this.idtransfRetirado,
      this.endRetirado,
      this.qtdRetirado,
      this.loteRetirado,
      this.validRetirado,
      this.idoperadorRetirado,
      this.barcodeRetirado});

  retiradaprodModel.fromJson(Map<String, dynamic> json) {
    idRetirado = json['idRetirado'] ?? "";
    idProdRetirado = json['idProdRetirado'] ?? "";
    nomeProdRetirado = json['nomeProdRetirado'] ?? "";
    idtransfRetirado = json['idtransfRetirado'] ?? "";
    endRetirado = json['endRetirado'] ?? "";
    qtdRetirado = json['qtdRetirado'] ?? "";
    loteRetirado = json['loteRetirado'] ?? "";
    validRetirado = json['validRetirado'] ?? "";
    idoperadorRetirado = json['idoperadorRetirado'] ?? "";
    barcodeRetirado = json['barcodeRetirado'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['idRetirado'] = this.idRetirado ?? "";
    data['idProdRetirado'] = this.idProdRetirado ?? "";
    data['nomeProdRetirado'] = this.nomeProdRetirado ?? "";
    data['idtransfRetirado'] = this.idtransfRetirado ?? "";
    data['endRetirado'] = this.endRetirado ?? "";
    data['qtdRetirado'] = this.qtdRetirado ?? "";
    data['validRetirado'] = this.validRetirado ?? "";
    data['loteRetirado'] = this.loteRetirado ?? "";
    data['idoperadorRetirado'] = this.idoperadorRetirado ?? "";
    data['barcodeRetirado'] = this.barcodeRetirado ?? "";
    return data;
  }

  Map<String, dynamic> toJsonUpdate() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['idProdRetirado'] = this.idProdRetirado ?? "";
    data['nomeProdRetirado'] = this.nomeProdRetirado ?? "";
    data['idtransfRetirado'] = this.idtransfRetirado ?? "";
    data['endRetirado'] = this.endRetirado ?? "";
    data['qtdRetirado'] = this.qtdRetirado ?? "";
    data['validRetirado'] = this.validRetirado ?? "";
    data['loteRetirado'] = this.loteRetirado ?? "";
    data['idoperadorRetirado'] = this.idoperadorRetirado ?? "";
    data['barcodeRetirado'] = this.barcodeRetirado ?? "";
    return data;
  }

  insert() async {
    Database db = await DatabaseHelper.instance.database;
    await db.insert(
      "retiradaprod",
      toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  update() async {
    Database db = await DatabaseHelper.instance.database;
    await db.update(
      "retiradaprod",
      toJsonUpdate(),
      where: 'idRetirado = ?',
      whereArgs: [this.idRetirado],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  delete(String idRetirado) async {
    Database db = await DatabaseHelper.instance.database;
    await db.delete("retiradaprod",
        where: "idRetirado = ?", whereArgs: [idRetirado]);
  }

  deleteAll() async {
    Database db = await DatabaseHelper.instance.database;
    await db.delete("retiradaprod");
  }

  Future<retiradaprodModel?> getByIdProdIdTransf(
      String idprod, String idtransfRetirado) async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query("retiradaprod",
        where: "idProdRetirado = ? AND idtransfRetirado = ?",
        whereArgs: [idprod, idtransfRetirado]);
    return result.isNotEmpty ? retiradaprodModel.fromJson(result.first) : null;
  }

  Future<retiradaprodModel?> getByIdProdIdTransfEnd(
      String idprod, String idtransfRetirado, String endRetirado) async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query("retiradaprod",
        where:
            "idProdRetirado = ? AND idtransfRetirado = ? AND endRetirado = ?",
        whereArgs: [idprod, idtransfRetirado, endRetirado]);
    return result.isNotEmpty ? retiradaprodModel.fromJson(result.first) : null;
  }

  Future<retiradaprodModel?> getByIdProd(String idprod) async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query("retiradaprod",
        where: "idProdRetirado = ?", whereArgs: [idprod]);
    return result.isNotEmpty ? retiradaprodModel.fromJson(result.first) : null;
  }

  Future<List<retiradaprodModel>> getListByTransf(String idtrnasf) async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query("retiradaprod",
        where: "idtransfRetirado = ?", whereArgs: [idtrnasf]);
    List<retiradaprodModel> listretirada = [];

    if (result.isNotEmpty) {
      for (var i = 0; i < result.length; i++) {
        retiradaprodModel retirada = retiradaprodModel.fromJson(result[i]);
        listretirada.add(retirada);
      }
    }
    return listretirada;
  }

  Future<List<retiradaprodModel>> getAll() async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query("retiradaprod");
    List<retiradaprodModel> listretirada = [];

    if (result.isNotEmpty) {
      for (var i = 0; i < result.length; i++) {
        retiradaprodModel retirada = retiradaprodModel.fromJson(result[i]);
        listretirada.add(retirada);
      }
      return listretirada;
    } else {
      return [];
    }
  }
}
