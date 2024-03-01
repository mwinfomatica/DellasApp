class RetornoPedidoCargaModel {
  final bool error;
  final String message;
  final List<PedidoCarga>? data;

  RetornoPedidoCargaModel({
    required this.error,
    required this.message,
    this.data,
  });

  factory RetornoPedidoCargaModel.fromJson(Map<String, dynamic> json) {
    return RetornoPedidoCargaModel(
      error: json['error'],
      message: json['message'],
      data: json['data'] != null
          ? List<PedidoCarga>.from(
              json['data'].map((x) => PedidoCarga.fromJson(x)))
          : null,
    );
  }
}

class PedidoCarga {
  final String idPedido;
  final String nro;
  final String serie;
  final String? cliente;
  final String chave;
  // final String idGrupo;

  PedidoCarga({
    required this.idPedido,
    required this.nro,
    required this.serie,
    this.cliente,
    required this.chave,
    // required this.idGrupo,
  });

  factory PedidoCarga.fromJson(Map<String, dynamic> json) {
    return PedidoCarga(
      idPedido: json['idPedido'],
      nro: json['nro'],
      serie: json['serie'],
      cliente: json['cliente'],
      chave: json['chave'],
      // idGrupo:  json['idGrupo']
    );
  }
}

class ListarConfNf {
  String? idUser;
  List<String> Cargas = [];

  ListarConfNf(this.Cargas, this.idUser);

  ListarConfNf.fromJson(Map<String, dynamic> json) {
    idUser = json['id'];
    Cargas = json['operacao'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['IdUser'] = this.idUser;
    data['Cargas'] = this.Cargas;
    return data;
  }
}
