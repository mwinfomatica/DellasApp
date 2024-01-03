import 'package:flutter/material.dart';
import 'package:leitorqrcode/Home/Home.dart';
import 'package:leitorqrcode/Login/Login.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';

import 'Components/Constants.dart';
import 'Infrastructure/DataBase/DataBase.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper.instance.database;
  runApp(MyApp());
}

Future<String> isLogged() async {
  ContextoServices contextoServices = ContextoServices();
  String codUser = await contextoServices.getIdUserLogged();
  return codUser;
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(
            textScaleFactor: 1,
          ),
          child: child!,
        );
      },
      title: 'Dellas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        backgroundColor: primaryColor,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: scalfolding,
      ),
      home: FutureBuilder(
        future: isLogged(),
        builder: (context, payload) {
          if (payload.connectionState == ConnectionState.done) {
            if (payload.data == null) {
              return LoginDemo();
            } else {
              return HomeScreen();
            }
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
