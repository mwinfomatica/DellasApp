import 'package:leitorqrcode/Models/armprodModel.dart';
import 'package:leitorqrcode/Models/retiradaprodModel.dart';

class TransferenciaModel {
  String? id;
  String? cnpj;
  String? iduser;
  List<retiradaprodModel>? ListRetirada = [];
  List<armprodModel>? ListArmz = [];

  TransferenciaModel(
      {this.ListArmz, this.ListRetirada, this.cnpj, this.id, this.iduser});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['cnpj'] = this.cnpj;
    data['iduser'] = this.iduser;
    if (this.ListRetirada != null) {
      data['ListRetirada'] = this.ListRetirada?.map((v) => v.toJson()).toList();
    }
    if (this.ListArmz != null) {
      data['ListArmz'] = this.ListArmz?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
