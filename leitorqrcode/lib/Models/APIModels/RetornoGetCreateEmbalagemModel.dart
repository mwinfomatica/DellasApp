class RetornoGetCreateEmbalagemModel {
  bool error;
  String message;
  List<DadosEmbalagem> data;

  RetornoGetCreateEmbalagemModel({
    required this.error,
    required this.message,
    required this.data,
  });

  factory RetornoGetCreateEmbalagemModel.fromJson(Map<String, dynamic> json) =>
      RetornoGetCreateEmbalagemModel(
        error: json["error"],
        message: json["message"],
        data: List<DadosEmbalagem>.from(
            json["data"].map((x) => DadosEmbalagem.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "error": error,
        "message": message,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}

class DadosEmbalagem {
  String descProduto;
  String idProduto;
  String idPedidoProduto;
  int quantNota;
  int quantEmbalado;

  DadosEmbalagem({
    required this.descProduto,
    required this.idProduto,
    required this.idPedidoProduto,
    required this.quantNota,
    required this.quantEmbalado,
  });

  factory DadosEmbalagem.fromJson(Map<String, dynamic> json) => DadosEmbalagem(
        descProduto: json["descProduto"],
        idProduto: json["idProduto"],
        idPedidoProduto: json["idPedidoProduto"],
        quantNota: json["quantNota"],
        quantEmbalado: json["quantEmbalado"],
      );

  Map<String, dynamic> toJson() => {
        "descProduto": descProduto,
        "idProduto": idProduto,
        "idPedidoProduto": idPedidoProduto,
        "quantNota": quantNota,
        "quantEmbalado": quantEmbalado,
      };
}
