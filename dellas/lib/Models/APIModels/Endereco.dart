// EnderecoModel.dart

import 'package:dellas/Infrastructure/DataBase/DataBase.dart';
import 'package:sqflite/sqflite.dart';

class EnderecoModel {
  String? cod;

  EnderecoModel({this.cod});

  EnderecoModel.fromJson(Map<String, dynamic> json) {
    cod = json['cod'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['cod'] = this.cod;
    return data;
  }

  Future<void> insert() async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      "endereco",
      toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAll() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete("endereco");
  }

  Future<EnderecoModel?> getById(String id) async {
    final db = await DatabaseHelper.instance.database;
    var result = await db.query("endereco", where: "cod = ?", whereArgs: [id]);
    if (result.isNotEmpty) {
      return EnderecoModel.fromJson(result.first);
    } else {
      return null;
    }
  }
}
