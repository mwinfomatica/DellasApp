import 'dart:convert';
import 'package:http/http.dart';
import 'package:leitorqrcode/Infrastructure/Http/WebClient.dart';
import 'package:leitorqrcode/Models/APIModels/EnderecoGrupo.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoEnderecoGrupoModel.dart';

class EnderecoGrupoService {
  Future<void> saveEnderecosGrupoDB() async {
    List<EnderecoGrupoModel> ends = await getEnderecosGrupoWS();
    if (ends != null) {
      await EnderecoGrupoModel().deleteAll();
      for (var i = 0; i < ends.length; i++) {
        EnderecoGrupoModel end = new EnderecoGrupoModel();
        end = ends[i];
        end.codendereco = end.codendereco!.trim();
        end.codgrupo = end.codgrupo!.trim();
        await end.insert();
      }
    }
  }

  Future<List<EnderecoGrupoModel>> getEnderecosGrupoWS() async {
    try {
      final Response response = await getClient(context: null).get(
        Uri.parse(baseUrl + "/ApiCliente/GetEnderecosGrupo"),
        headers: {
          'Content-type': 'application/json',
        },
      );

      RetornoEnderecoGrupoModel rtn =
          new RetornoEnderecoGrupoModel.fromJson(jsonDecode(response.body));

      if (rtn != null && rtn.error != true) {
        return rtn.endereco;
      } else
        return Future.value(null);
    } catch (ex) {
      print(ex);
      return Future.value(null);
    }
  }
}
