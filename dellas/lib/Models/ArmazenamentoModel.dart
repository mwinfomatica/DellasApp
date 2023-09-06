class ArmazenamentoModel {
 late String codigo;
 late String nome;
 late String descricao;
 late int quantidade;
 late String validade;

  ArmazenamentoModel(
      {this.codigo = "",
      this.nome = "",
      this.descricao = "",
      this.quantidade = 0,
      this.validade = ""});

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
