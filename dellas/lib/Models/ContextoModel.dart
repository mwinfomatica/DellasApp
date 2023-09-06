class ContextoModel {
  bool leituraExterna = false;
  String descLeituraExterna = "";
  String nameDevice = "";
  String uuidDevice = "";
  bool enderecoGrupo = false;

  ContextoModel(
      { this.leituraExterna = false,
       this.descLeituraExterna = "",
       this.nameDevice= "",
       this.uuidDevice= "",
       this.enderecoGrupo = false});

  ContextoModel.fromJson(Map<String, dynamic> json) {
    leituraExterna = json['leituraExterna'];
    descLeituraExterna = json['descLeituraExterna'];
    nameDevice = json['nameDevice'];
    uuidDevice = json['uuidDevice'];
    enderecoGrupo = json['enderecoGrupo'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['leituraExterna'] = this.leituraExterna;
    data['descLeituraExterna'] = this.descLeituraExterna;
    data['nameDevice'] = this.nameDevice;
    data['uuidDevice'] = this.uuidDevice;
    data['enderecoGrupo'] = this.enderecoGrupo;
    return data;
  }
}
