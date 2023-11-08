class ContextoModel {
  bool leituraExterna;
  String descLeituraExterna;
  String nameDevice;
  String uuidDevice;
  bool enderecoGrupo;

  ContextoModel(
      {this.leituraExterna,
      this.descLeituraExterna,
      this.nameDevice,
      this.uuidDevice,
      this.enderecoGrupo});

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
