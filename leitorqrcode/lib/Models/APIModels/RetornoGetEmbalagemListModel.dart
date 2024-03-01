class RetornoGetEmbalagemListModel {
  final bool error;
  final String message;
  final List<EmbalagemData> data;

  RetornoGetEmbalagemListModel({
    required this.error,
    required this.message,
    required this.data,
  });

  factory RetornoGetEmbalagemListModel.fromJson(Map<String, dynamic> json) {
    return RetornoGetEmbalagemListModel(
      error: json['error'],
      message: json['message'],
      data: List<EmbalagemData>.from(
          json['data'].map((x) => EmbalagemData.fromJson(x))),
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

class EmbalagemData {
  final String idPedido;
  final String sequencial;
  final String idEmbalagem;
  final String status;

  EmbalagemData({
    required this.idPedido,
    required this.sequencial,
    required this.idEmbalagem,
    required this.status,
  });

  factory EmbalagemData.fromJson(Map<String, dynamic> json) {
    return EmbalagemData(
      idPedido: json['idPedido'],
      sequencial: json['sequencial'],
      idEmbalagem: json['idEmbalagem'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idPedido': idPedido,
      'sequencial': sequencial,
      'idEmbalagem': idEmbalagem,
      'status': status,
    };
  }
}
