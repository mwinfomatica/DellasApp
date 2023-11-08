class ProdutoModel {
  String codigo;
  String nome;
  String descricao;
  String validade;
  String endereco;
  bool checked;

  ProdutoModel(
      {this.codigo, this.nome, this.descricao, this.validade, this.endereco, this.checked = false});

  ProdutoModel.fromJson(Map<String, dynamic> json) {
    codigo = json['codigo'];
    nome = json['nome'];
    descricao = json['descricao'];
    validade = json['validade'];
    endereco = json['endereco'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['codigo'] = this.codigo;
    data['nome'] = this.nome;
    data['descricao'] = this.descricao;
    data['validade'] = this.validade;
    data['endereco'] = this.endereco;
    return data;
  }
}
