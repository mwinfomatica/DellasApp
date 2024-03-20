class ConfItensEmbalagem {
  late String? idProduto;
  late String idEmbalagem;
  late int? qtde;
  late String? idPedidoProduto;

  ConfItensEmbalagem({this.idProduto, required this.idEmbalagem, this.qtde,  this.idPedidoProduto});

  ConfItensEmbalagem.fromJson(Map<String, dynamic> json) {
    idProduto = json['idProduto'];
    idEmbalagem = json['idEmbalagem'];
    qtde = json['qtde'];
    idPedidoProduto = json['idPedidoProduto'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['qtde'] = this.qtde;
    data['idProduto'] = this.idProduto;
    data['idEmbalagem'] = this.idEmbalagem;
    data['idPedidoProduto'] = this.idPedidoProduto;
    return data;
  }
}

class RetornoGetConfItensEmbalagemModel {
  final bool error;
  final String message;
  final List<ConfItensEmbalagem> data;

  RetornoGetConfItensEmbalagemModel({
    required this.error,
    required this.message,
    required this.data,
  });

  factory RetornoGetConfItensEmbalagemModel.fromJson(
      Map<String, dynamic> json) {
    return RetornoGetConfItensEmbalagemModel(
      error: json['error'],
      message: json['message'],
      data: List<ConfItensEmbalagem>.from(
          json['data'].map((x) => ConfItensEmbalagem.fromJson(x))),
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
