import 'package:leitorqrcode/Infrastructure/DataBase/DataBase.dart';
import 'package:sqflite/sqflite.dart';

class EnderecoGrupoModel {
  String? codendereco;
  String? codgrupo;

  EnderecoGrupoModel({this.codendereco, this.codgrupo});

  EnderecoGrupoModel.fromJson(Map<String, dynamic> json) {
    codendereco = json['codendereco'];
    codgrupo = json['codgrupo'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['codendereco'] = this.codendereco;
    data['codgrupo'] = this.codgrupo;
    return data;
  }

  insert() async {
    Database db = await DatabaseHelper.instance.database;
    await db.insert(
      "enderecogrupo",
      toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  deleteAll() async {
    Database db = await DatabaseHelper.instance.database;
    await db.delete("enderecogrupo");
  }

  Future<EnderecoGrupoModel?> getByGroupAndCod(
      String codendereco, codgrupo) async {
    Database db = await DatabaseHelper.instance.database;

    var result = await db.query("endereco",
        where: "codendereco = ? AND codgrupo = ?",
        whereArgs: [codendereco, codgrupo]);

    return result.isNotEmpty ? EnderecoGrupoModel.fromJson(result.first) : null;
  }
}
