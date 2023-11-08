import 'package:leitorqrcode/Infrastructure/DataBase/DataBase.dart';
import 'package:sqflite/sqflite.dart';

class EnderecoModel {
  String cod;

  EnderecoModel({this.cod});

  EnderecoModel.fromJson(Map<String, dynamic> json) {
    cod = json['cod'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['cod'] = this.cod;
    return data;
  }

  insert() async {
    Database db = await DatabaseHelper.instance.database;;
    await db.insert(
      "endereco",
      toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  deleteAll() async {
    Database db = await DatabaseHelper.instance.database;;
    await db.delete("endereco");
  }

  Future<EnderecoModel> getById(String id) async {
    Database db = await DatabaseHelper.instance.database;;
    var result = await db.query("endereco", where: "cod = ?", whereArgs: [id]);
    return result.isNotEmpty
        ? EnderecoModel.fromJson(result.first)
        : Future<Null>.value(null);
  }

  EnderecoModel.fromJsonList(List<Map<String, dynamic>> jsonList) {
    for (int i = 0; i < jsonList.length; i++) {
      cod = jsonList[i]['endereco'];
    }
  }

  Future<List<EnderecoModel>> get() async {
    Database db = await DatabaseHelper.instance.database;;
    var result = await db.query("endereco");
    List<EnderecoModel> list = [];

    if (result.isNotEmpty) {
      for (var i = 0; i < result.length; i++) {
        EnderecoModel op = EnderecoModel.fromJson(result[i]);
        list.add(op);
      }
      return list;
    } else {
      return [];
    }
  }
}
