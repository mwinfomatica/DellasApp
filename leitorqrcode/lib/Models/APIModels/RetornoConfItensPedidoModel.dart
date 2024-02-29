class RetornoConfItensPedidoModel {
  final bool error;
  final String message;
  final PedidoCargaData data;

  RetornoConfItensPedidoModel({
    required this.error,
    required this.message,
    required this.data,
  });

  factory RetornoConfItensPedidoModel.fromJson(Map<String, dynamic> json) {
    return RetornoConfItensPedidoModel(
      error: json['error'],
      message: json['message'],
      data: PedidoCargaData.fromJson(json['data']),
    );
  }
}

class PedidoCargaData {
  final String nroNFE;
  final String serieNfe;
  final dynamic cliente;
  final String chaveNfe;
  final List<ItemConferenciaNfs> itensConferenciaNfs;
  final List<String> idsEmbalagens;

  PedidoCargaData({
    required this.nroNFE,
    required this.serieNfe,
    this.cliente,
    required this.chaveNfe,
    required this.itensConferenciaNfs,
    required this.idsEmbalagens,
  });

  factory PedidoCargaData.fromJson(Map<String, dynamic> json) {
    return PedidoCargaData(
      nroNFE: json['nroNFE'],
      serieNfe: json['serieNfe'],
      cliente: json['cliente'],
      chaveNfe: json['chaveNfe'],
      itensConferenciaNfs: (json['itensConferenciaNfs'] as List)
          .map((i) => ItemConferenciaNfs.fromJson(i))
          .toList(),
      idsEmbalagens: List<String>.from(json['idsEmbalagens']),
    );
  }
}

class ItemConferenciaNfs {
  final String idItem;
  final int qtde;
  final String codigo;
  final String descricao;

  ItemConferenciaNfs({
    required this.idItem,
    required this.qtde,
    required this.codigo,
    required this.descricao,
  });

  factory ItemConferenciaNfs.fromJson(Map<String, dynamic> json) {
    return ItemConferenciaNfs(
      idItem: json['idItem'],
      qtde: json['qtde'],
      codigo: json['codigo'],
      descricao: json['descricao'],
    );
  }
}
