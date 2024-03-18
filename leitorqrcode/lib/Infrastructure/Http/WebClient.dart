import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http_interceptor/http_interceptor.dart';

import 'Interceptador/Interceptador.dart';

Client getClient({BuildContext? context}) {
  return InterceptedClient.build(
    interceptors: [Interceptador(context: context)],
    requestTimeout: const Duration(seconds: 30),
  );
}

//const String baseUrl = 'http://3.224.148.218/DellasHomolog';
 const String baseUrl = 'http://3.224.148.218/Dellas';
//const String baseUrl = 'http://192.168.1.11/Dellas';

String getMessage(int statusCode) {
  if (_statusCodeResponses.containsKey(statusCode)) {
    return _statusCodeResponses[statusCode]!;
  }
  return 'Erro ao finalizar sua solicitação, gentileza entrar em contato com o suporte.';
}

final Map<int, String> _statusCodeResponses = {
  400: 'Ocorreu um erro ao realizar a solicitação',
  401: 'Sem permissão para realizar a solicitação',
  409: 'transaction already exists'
};
