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

class RetornoGetDadosEmbalagemListModel {
  final bool error;
  final String message;
  final List<EmbalagemPrinter> data;

  RetornoGetDadosEmbalagemListModel({
    required this.error,
    required this.message,
    required this.data,
  });

  factory RetornoGetDadosEmbalagemListModel.fromJson(
      Map<String, dynamic> json) {
    return RetornoGetDadosEmbalagemListModel(
      error: json['error'],
      message: json['message'],
      data: List<EmbalagemPrinter>.from(
          json['data'].map((x) => EmbalagemPrinter.fromJson(x))),
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

class EmbalagemPrinter {
  late String id;
  late String Embalagem;

  String? carga;
  String? nomeCliente;
  String? nroNota;
  String? serie;
  String? seqEmbalagem;
  String? end;
  List<ItensEmbalagemPrinter>? listItens = [];

  EmbalagemPrinter({
    required this.id,
    required this.Embalagem,
    this.carga,
    this.end,
    this.nomeCliente,
    this.nroNota,
    this.seqEmbalagem,
  });

  EmbalagemPrinter.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    Embalagem = json['embalagem'] != null
        ? json['embalagem']
        : json['Embalagem'] != null
            ? json['Embalagem']
            : "-";
    carga = json['carga'] ?? " - ";
    nomeCliente = json['nomeCliente'] ?? " - ";
    nroNota = json['nroNota'] ?? " - ";
    seqEmbalagem = json['seqEmbalagem'] ?? " - ";
    end = json['end'] ?? " - ";
    serie = json['serie'] ?? " - ";

    if (json['listItens'] != null) {
      var list = json['listItens'];
      listItens = [];
      for (var i = 0; i < list.length; i++) {
        listItens!.add(new ItensEmbalagemPrinter.fromJson(list[i]));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = id;
    data['Embalagem'] = Embalagem;

    return data;
  }
}

class ItensEmbalagemPrinter {
  final String id;
  final String idProduto;
  final String codProd;
  final String nomeProd;
  final int? qtd;

  ItensEmbalagemPrinter({
    required this.id,
    required this.codProd,
    required this.nomeProd,
    required this.qtd,
    required this.idProduto,
  });

  factory ItensEmbalagemPrinter.fromJson(Map<String, dynamic> json) {
    return ItensEmbalagemPrinter(
      id: json['id'],
      codProd: json['codProd'],
      nomeProd: json['nomeProd'],
      qtd: json['qtd'],
      idProduto: json['idProduto'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codProd': codProd,
      'nomeProd': nomeProd,
      'qtd': qtd,
      'idProduto': idProduto,
    };
  }
}
