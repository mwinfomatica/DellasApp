import 'package:leitorqrcode/Models/APIModels/Endereco.dart';
import 'package:leitorqrcode/Models/APIModels/UsuarioModel.dart';

class RetornoLoginModel {
  RetornoLoginModel();

  bool? error;
  String? message;
  UsuarioModel usuarioModel = new UsuarioModel();
  List<EnderecoModel> endereco = [];

  RetornoLoginModel.fromJson(Map<String, dynamic> json) {
    error = json['cod'];
    message = json['message'];
    // var data = jsonDecode(json['data']);
    if (json['user'] != null) {
      usuarioModel = UsuarioModel.fromJson(json['user']);
    }
    // endereco = UsuarioModel.fromJson(data['user']);
    json['end'].forEach((v) {
      endereco.add(new EnderecoModel.fromJson(v));
    });
  }
  RetornoLoginModel.fromJsonNotUser(Map<String, dynamic> json) {
    error = json['cod'];
    message = json['message'];
    json['end'].forEach((v) {
      endereco.add(new EnderecoModel.fromJson(v));
    });
  }
}
