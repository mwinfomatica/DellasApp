class RetornoConfItensEmbalagemModel {
  final bool error;
  final String message;
  final List<DadosEmbalagem> data;

  RetornoConfItensEmbalagemModel({
    required this.error,
    required this.message,
    required this.data,
  });

  factory RetornoConfItensEmbalagemModel.fromJson(Map<String, dynamic> json) {
    return RetornoConfItensEmbalagemModel(
      error: json['error'],
      message: json['message'],
      data: List<DadosEmbalagem>.from(
          json['data'].map((item) => DadosEmbalagem.fromJson(item))),
    );
  }
}

class DadosEmbalagem {
  final String idEmbalagem;
  final String idPedidoProduto;
  final String idProduto;
  final int qtde;

  DadosEmbalagem({
    required this.idEmbalagem,
    required this.idPedidoProduto,
    required this.idProduto,
    required this.qtde,
  });

  factory DadosEmbalagem.fromJson(Map<String, dynamic> json) {
    return DadosEmbalagem(
      idEmbalagem: json['idEmbalagem'],
      idPedidoProduto: json['idPedidoProduto'],
      idProduto: json['idProduto'],
      qtde: json['qtde'],
    );
  }
}
