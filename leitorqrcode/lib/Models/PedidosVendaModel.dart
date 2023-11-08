import 'package:leitorqrcode/Models/ProdutoModel.dart';

class PedidosVendaModel {
  String codigo;
  String nome;
  DateTime datavalidade;
  List<ProdutoModel> listProd;

  PedidosVendaModel(
      {this.codigo, this.nome, this.datavalidade, this.listProd});

  PedidosVendaModel.fromJson(Map<String, dynamic> json) {
    codigo = json['codigo'];
    nome = json['nome'];
    datavalidade = json['datavalidade'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['codigo'] = this.codigo;
    data['nome'] = this.nome;
    data['datavalidade'] = this.datavalidade;
    return data;
  }
}
