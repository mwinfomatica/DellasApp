import 'package:flutter/material.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';

class Interceptador implements InterceptorContract {
  final BuildContext context;
  final GlobalKey keyloader = new GlobalKey<State>();
  
  Interceptador({this.context});
  
  @override
  Future<RequestData> interceptRequest({RequestData data}) async {
     if (context != null && keyloader != null)
      Dialogs.showLoadingDialog(context, keyloader);

    return data;
  }

  @override
  Future<ResponseData> interceptResponse({ResponseData data}) async {
     if (context != null && keyloader != null)
      Navigator.of(keyloader.currentContext, rootNavigator: true).pop();

    return data;
  }
}
