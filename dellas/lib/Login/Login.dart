import 'package:dellas/Infrastructure/DataBase/DataBase.dart';
import 'package:flutter/material.dart';
import 'package:dellas/Components/Constants.dart';
import 'package:dellas/Home/Home.dart';
import 'package:dellas/Models/APIModels/Endereco.dart';
import 'package:dellas/Models/APIModels/LoginModel.dart';
import 'package:dellas/Models/APIModels/RetornoLoginModel.dart';
import 'package:dellas/Models/APIModels/UsuarioModel.dart';
import 'package:dellas/Services/AccountService.dart';
import 'package:dellas/Shared/Dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class LoginDemo extends StatefulWidget {
  @override
  _LoginDemoState createState() => _LoginDemoState();
}

class _LoginDemoState extends State<LoginDemo> {
  final controllerInputLogin = TextEditingController();
  final controllerInputPass = TextEditingController();
  bool isLoading = false;
  bool isLoadingLogin = false;
  bool isOk = false;

  Future<void> addUserLogged(UsuarioModel user) async {
    SharedPreferences userlogged = await SharedPreferences.getInstance();
    userlogged.setString('IdUser', user.codigo!);
  }

  Future<void> addEndereco(List<EnderecoModel> ends) async {
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      for (var end in ends) {
        await txn.insert(
          "endereco",
          end.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    setState(() {
      isOk = true;
    });
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    controllerInputLogin.dispose();
    controllerInputPass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingLogin) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Container(
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Sincronizando dados...",
                    style: TextStyle(
                        fontSize: 22.0,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 12.0,
                  ),
                  const CircularProgressIndicator(),
                ],
              )),
        ),
      );
    }
    return isOk
        ? Container()
        : Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: primaryColor,
              title: Text("Login"),
            ),
            body: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 70.0),
                        child: Center(
                          child: Container(
                              width: 200,
                              height: 150,
                              /*decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(50.0)),*/
                              child: Image.asset(
                                  'assets/img/ic_launcher-removebg.png')),
                        ),
                      ),
                      Padding(
                        //padding: const EdgeInsets.only(left:15.0,right: 15.0,top:0,bottom: 0),
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: TextField(
                          controller: controllerInputLogin,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: primaryColor)),
                              labelText: 'Login',
                              hintText: 'Entre com seu login'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 15.0, right: 15.0, top: 15, bottom: 0),
                        //padding: EdgeInsets.symmetric(horizontal: 15),
                        child: TextField(
                          controller: controllerInputPass,
                          obscureText: true,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: primaryColor)),
                              labelText: 'Senha',
                              hintText: 'Entre com sua senha'),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        height: 50,
                        width: 250,
                        decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(20)),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              primary: primaryColor,
                              textStyle: const TextStyle(fontSize: 20)),
                          onPressed: () async {
                            setState(() {
                              isLoading = true;
                            });

                            RetornoLoginModel? rtn = await _login(context);
                            setState(() {
                              isLoading = false;
                            });
                            if (rtn != null) {
                              setState(() {
                                isLoadingLogin = true;
                              });
                              await addUserLogged(rtn.usuarioModel);
                              await addEndereco(rtn.endereco);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      HomeScreen(),
                                ),
                              );
                              setState(() {
                                isLoadingLogin = false;
                              });
                            }
                          },
                          child: Text(
                            'Entrar',
                            style: TextStyle(color: Colors.white, fontSize: 25),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 130,
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Future<RetornoLoginModel?> _login(BuildContext context) async {
    AccountService accountService = new AccountService(context);
    LoginModel model = new LoginModel();
    model.login = controllerInputLogin.text;
    model.senha = controllerInputPass.text;

    if (model.login!.isNotEmpty && model.senha!.isNotEmpty) {
      RetornoLoginModel? rtn = new RetornoLoginModel();
      await accountService.login(model).then((value) => {
            rtn = value,
          });

      return rtn;
    } else {
      Dialogs.showToast(context, "Gentileza conferir os campos!");
      return null;
    }
  }
}
