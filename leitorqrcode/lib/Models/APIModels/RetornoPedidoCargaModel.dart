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

  PedidoCarga({
    required this.idPedido,
    required this.nro,
    required this.serie,
    this.cliente,
    required this.chave,
  });

  factory PedidoCarga.fromJson(Map<String, dynamic> json) {
    return PedidoCarga(
      idPedido: json['idPedido'],
      nro: json['nro'],
      serie: json['serie'],
      cliente: json['cliente'],
      chave: json['chave'],
    );
  }
}
