import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http_interceptor/http/http.dart';
import 'package:dellas/Infrastructure/Http/Interceptador/Interceptador.dart';

Client getClient({BuildContext? context}) {
  return InterceptedClient.build(
    interceptors: [Interceptador(context: context)],
    requestTimeout: Duration(seconds: 30),
  );
}

final Client client = InterceptedClient.build(
  interceptors: [Interceptador()],
  requestTimeout: Duration(seconds: 30),
);

const String baseUrl = 'http://3.224.148.218/Dellas';
//const String baseUrl = 'http://192.168.15.72/ControleMovimentacao';

String? getMessage(int statusCode) {
  if (_statusCodeResponses.containsKey(statusCode)) {
    return _statusCodeResponses[statusCode];
  }
  return 'Erro ao finalizar sua solicitação, gentileza entrar em contato com o suporte.';
}

final Map<int, String> _statusCodeResponses = {
  400: 'there was an error submitting transaction',
  401: 'authentication failed',
  409: 'transaction already exists'
};
