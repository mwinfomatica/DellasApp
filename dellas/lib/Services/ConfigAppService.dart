import 'dart:convert';
import 'package:http/http.dart';
import 'package:dellas/Infrastructure/Http/WebClient.dart';
import 'package:dellas/Models/APIModels/Endereco.dart';
import 'package:dellas/Models/APIModels/RetornoLoginModel.dart';

class ConfigAppService {
  Future<void> saveEnderecosDB() async {
    List<EnderecoModel>? ends = await getEnderecosWS();
    if (ends != null) {
      await EnderecoModel().deleteAll();
      for (var i = 0; i < ends.length; i++) {
        EnderecoModel end = new EnderecoModel();
        end = ends[i];
        end.cod = end.cod!.trim();
        await end.insert();
      }
    }
  }

  Future<List<EnderecoModel>?> getEnderecosWS() async {
    try {
      final Response response = await client.get(
      Uri.parse(baseUrl + "/ApiCliente/GetEnderecos"),
        headers: {
          'Content-type': 'application/json',
        },
      );

      RetornoLoginModel rtn =
          new RetornoLoginModel.fromJson(jsonDecode(response.body));

      if (rtn != null && rtn.error != true) {
        return rtn.endereco;
      } else
        return Future<Null>.value(null);
    } catch (ex) {
      print(ex);
      return Future<Null>.value(null);
    }
  }
}
