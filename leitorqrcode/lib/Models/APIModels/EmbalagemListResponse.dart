class EmbalagemListResponse {
  bool error;
  String message;
  List<EmbalagemDados> data;

  EmbalagemListResponse({
    required this.error,
    required this.message,
    required this.data,
  });

  factory EmbalagemListResponse.fromJson(Map<String, dynamic> json) =>
      EmbalagemListResponse(
        error: json['error'],
        message: json['message'],
        data: List<EmbalagemDados>.from(
            json['data'].map((x) => EmbalagemDados.fromJson(x))),
      );
}

class EmbalagemDados {
  String idPedido;
  String sequencial;
  String idEmbalagem;
  String status;

  EmbalagemDados({
    required this.idPedido,
    required this.sequencial,
    required this.idEmbalagem,
    required this.status,
  });

  factory EmbalagemDados.fromJson(Map<String, dynamic> json) => EmbalagemDados(
        idPedido: json['idPedido'],
        sequencial: json['sequencial'],
        idEmbalagem: json['idEmbalagem'],
        status: json['status'],
      );
}
