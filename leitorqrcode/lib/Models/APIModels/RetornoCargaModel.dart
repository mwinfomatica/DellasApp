class RetornoCargaModel {
  final bool error;
  final String message;
  final List<Pedido>? data;

  RetornoCargaModel({required this.error, required this.message, this.data});

  factory RetornoCargaModel.fromJson(Map<String, dynamic> json) {
    List<Pedido>? data;
    if (json['data'] != null) {
      data = List<Pedido>.from(json['data'].map((x) => Pedido.fromJson(x)));
    }
    return RetornoCargaModel(
      error: json['error'],
      message: json['message'],
      data: data,
    );
  }
}

class Pedido {
  final String idPedido;
  final String carga;

  Pedido({required this.idPedido, required this.carga});

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      idPedido: json['idPedido'],
      carga: json['carga'],
    );
  }
}
