class SearchProdutosModel {
  String? codOp;

  SearchProdutosModel({this.codOp});

  SearchProdutosModel.fromJson(Map<String, dynamic> json) {
    codOp = json['codOp'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['codOp'] = this.codOp;
    return data;
  }
}
