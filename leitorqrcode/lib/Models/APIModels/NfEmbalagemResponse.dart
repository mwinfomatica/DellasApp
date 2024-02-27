class NfeEmbalagemResponse {
  bool error;
  String message;
  List<NfeDados> data;

  NfeEmbalagemResponse({
    required this.error,
    required this.message,
    required this.data,
  });

  factory NfeEmbalagemResponse.fromJson(Map<String, dynamic> json) =>
      NfeEmbalagemResponse(
        error: json['error'],
        message: json['message'],
        data:
            List<NfeDados>.from(json['data'].map((x) => NfeDados.fromJson(x))),
      );
}

class NfeDados {
  String idPedido;
  String nrNfe;
  String serieNfe;
  String nomeCliente;

  NfeDados({
    required this.idPedido,
    required this.nrNfe,
    required this.serieNfe,
    required this.nomeCliente,
  });

  factory NfeDados.fromJson(Map<String, dynamic> json) => NfeDados(
        idPedido: json['idPedido'],
        nrNfe: json['nrNfe'],
        serieNfe: json['serieNfe'] ?? "",
        nomeCliente: json['nomeCliente'] ?? "",
      );
}
