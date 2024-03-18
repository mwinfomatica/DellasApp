class BaixaConfModel {
  List<String>? idPedidos;
  List<String>? idEmbalagem;
  String? tipoBaixa;

  BaixaConfModel({idPedidos, idEmbalagem, tipoBaixa});

  BaixaConfModel.fromJson(Map<String, dynamic> json) {
    idPedidos = json['idPedidos'];
    idEmbalagem = json['idEmbalagem'];
    tipoBaixa = json['tipoBaixa'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tipoBaixa'] = this.tipoBaixa;
    data['idPedidos'] = this.idPedidos;
    data['idEmbalagem'] = this.idEmbalagem;
    return data;
  }
}
