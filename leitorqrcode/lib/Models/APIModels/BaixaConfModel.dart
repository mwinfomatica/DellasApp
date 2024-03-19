class BaixaConfModel {
  List<String>? idPedidos;
  List<String>? idEmbalagem;
  String? tipoBaixa;
  late String idUsuario;

  BaixaConfModel({this.idPedidos, this.idEmbalagem, this.tipoBaixa, required this.idUsuario});

  BaixaConfModel.fromJson(Map<String, dynamic> json) {
    idPedidos = json['idPedidos'];
    idEmbalagem = json['idEmbalagem'];
    tipoBaixa = json['tipoBaixa'];
    idUsuario = json['IdUsuario'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tipoBaixa'] = this.tipoBaixa;
    data['idPedidos'] = this.idPedidos;
    data['idEmbalagem'] = this.idEmbalagem;
    data['IdUsuario'] = this.idUsuario;
    return data;
  }
}
