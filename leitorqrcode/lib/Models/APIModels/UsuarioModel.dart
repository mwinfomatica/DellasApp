class UsuarioModel {
  String? codigo;
  String? login;
  String? tipo;
  bool? validaGrupoxEndereco;

  UsuarioModel({this.codigo, this.login, this.tipo});

  UsuarioModel.fromJson(Map<String, dynamic> json) {
    codigo = json['codigo'];
    login = json['login'];
    tipo = json['tipo'];
    validaGrupoxEndereco = json['validaGrupoxEndereco'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['codigo'] = this.codigo;
    data['login'] = this.login;
    data['tipo'] = this.tipo;
    data['validaGrupoxEndereco'] = this.validaGrupoxEndereco;
    return data;
  }
}
