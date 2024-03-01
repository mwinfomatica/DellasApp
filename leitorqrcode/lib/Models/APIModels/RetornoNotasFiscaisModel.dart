class RetornoNotasFiscaisModel {
  bool error;
  String message;
  List<Pedido> data;

  RetornoNotasFiscaisModel({
    required this.error,
    required this.message,
    required this.data,
  });

  factory RetornoNotasFiscaisModel.fromJson(Map<String, dynamic> json) {
    return RetornoNotasFiscaisModel(
      error: json['error'],
      message: json['message'],
      data: List<Pedido>.from(json['data'].map((x) => Pedido.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'message': message,
      'data': List<dynamic>.from(data.map((x) => x.toJson())),
    };
  }
}

class Pedido {
  String idPedido;
  String nrNfe;
  String serieNfe;
  String nomeCliente;

  Pedido({
    required this.idPedido,
    required this.nrNfe,
    required this.serieNfe,
    required this.nomeCliente,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      idPedido: json['idPedido'],
      nrNfe: json['nrNfe'],
      serieNfe: json['serieNfe'] ??
          '', // Assume-se que pode ser nulo e atribuído uma string vazia por padrão
      nomeCliente: json['nomeCliente'] ??
          '', // Assume-se que pode ser nulo e atribuído uma string vazia por padrão
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idPedido': idPedido,
      'nrNfe': nrNfe,
      'serieNfe': serieNfe,
      'nomeCliente': nomeCliente,
    };
  }
}
