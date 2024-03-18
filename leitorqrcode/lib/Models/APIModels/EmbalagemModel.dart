class EmbalagemModel {
  EmbalagemModel(
    this.idUsuario,
    this.idEmbalagem,
    this.idPedido,
    this.itens,
  );

  String? idUsuario;
  String? idPedido;
  String? idEmbalagem;
  List<ItensEmbalagem> itens = [];

  EmbalagemModel.fromJson(Map<String, dynamic> json) {
    idUsuario = json['idUsuario'];
    idPedido = json['idPedido'];
    idEmbalagem = json['idEmbalagem'];

    List<Map<String, dynamic>> list = json['itens'];

    for (var i = 0; i < list.length; i++) {
      itens.add(ItensEmbalagem.fromJson(list[i]));
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['idUsuario'] = this.idUsuario;
    data['idPedido'] = this.idPedido;
    data['idEmbalagem'] = this.idEmbalagem;
    data['itens'] = this.itens.map((v) => v.toJson()).toList();
    return data;
  }
}

class ItensEmbalagem {
  String? id;
  String? idProduto;
  String? idPedidoProduto;
  int? qtd;
  String? descProd;

  ItensEmbalagem(this.idPedidoProduto, this.idProduto, this.qtd, this.descProd);

  ItensEmbalagem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    descProd = json['descProd'];
    idProduto = json['idProduto'];
    idPedidoProduto = json['idPedidoProduto'];
    qtd = json['qtd'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['idProduto'] = this.idProduto;
    data['idPedidoProduto'] = this.idPedidoProduto;
    data['qtd'] = this.qtd;
    return data;
  }
}

class RetornoGetEditEmbalagemModel {
  bool error;
  String message;
  List<ItensEmbalagem> data;

  RetornoGetEditEmbalagemModel({
    required this.error,
    required this.message,
    required this.data,
  });

  factory RetornoGetEditEmbalagemModel.fromJson(Map<String, dynamic> json) =>
      RetornoGetEditEmbalagemModel(
        error: json["error"],
        message: json["message"],
        data: List<ItensEmbalagem>.from(
            json["data"].map((x) => ItensEmbalagem.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "error": error,
        "message": message,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}
