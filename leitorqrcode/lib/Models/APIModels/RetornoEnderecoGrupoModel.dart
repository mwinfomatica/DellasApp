import 'package:leitorqrcode/Models/APIModels/EnderecoGrupo.dart';

class RetornoEnderecoGrupoModel {
  RetornoEnderecoGrupoModel();

  bool? error;
  String? message;
  List<EnderecoGrupoModel> endereco = [];

  RetornoEnderecoGrupoModel.fromJson(Map<String, dynamic> json) {
    error = json['cod'];
    message = json['message'];
    json['end'].forEach((v) {
      endereco.add(new EnderecoGrupoModel.fromJson(v));
    });
  }
  RetornoEnderecoGrupoModel.fromJsonNotUser(Map<String, dynamic> json) {
    error = json['cod'];
    message = json['message'];
    json['end'].forEach((v) {
      endereco.add(new EnderecoGrupoModel.fromJson(v));
    });
  }
}
