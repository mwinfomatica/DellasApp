class ArmazenamentoModel {
  String? codigo;
  String? nome;
  String? descricao;
  int? quantidade;
  String? validade;

  ArmazenamentoModel(
      {this.codigo, this.nome, this.descricao, this.quantidade, this.validade});

  ArmazenamentoModel.fromJson(Map<String, dynamic> json) {
    codigo = json['codigo'];
    nome = json['nome'];
    descricao = json['descricao'];
    quantidade = json['quantidade'];
    validade = json['validade'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['codigo'] = this.codigo;
    data['nome'] = this.nome;
    data['descricao'] = this.descricao;
    data['quantidade'] = this.quantidade;
    data['validade'] = this.validade;
    return data;
  }
}
