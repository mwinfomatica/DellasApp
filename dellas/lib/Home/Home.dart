import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dellas/Components/Bottom.dart';
import 'package:dellas/Components/Constants.dart';
import 'package:dellas/Components/GetTipoOperacao.dart';
import 'package:dellas/Home/components/Menu.dart';
import 'package:dellas/Login/Login.dart';
import 'package:dellas/Models/APIModels/Endereco.dart';
import 'package:dellas/Models/APIModels/OperacaoModel.dart';
import 'package:dellas/Models/APIModels/ProdutoDBModel.dart';
import 'package:dellas/Models/APIModels/ProdutoModel.dart';
import 'package:dellas/Services/ContextoServices.dart';
import 'package:dellas/SettingsApp/settings_page.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<OperacaoModel> listOperacao = [];

  void getListOP() async {
    listOperacao = await new OperacaoModel().getListByStituacaoSeparadoC();

    if (listOperacao.length == 0) {
      listOperacao = [];
    }
  }

  @override
  void initState() {
    getListOP();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: primaryColor,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return SafeArea(
      child: Scaffold(
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  child: Text(
                    'Controle de Estoque',
                    style: TextStyle(color: Colors.white, fontSize: 25),
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor,
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.input),
                  title: Text('Sair'),
                  onTap: () async {
                    await OperacaoModel().deleteAll();
                    await ProdutoModel().deleteAll();
                    await ProdutoDBModel().deleteAll();
                    await EnderecoModel().deleteAll();
                    ContextoServices contextoServices = ContextoServices();
                    await contextoServices.clearUserLogged();
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) => LoginDemo(),
                        ),
                        (route) => false);
                  },
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            child: Stack(
              children: [
                Column(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * 0.2,
                      color: primaryColor,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: ListTile(
                    title: Text.rich(
                      TextSpan(
                        text: "Controle de Estoque",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    trailing: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  SettingsPage()),
                        );
                      },
                      child: Icon(
                        Icons.settings,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                MenuHome(
                  topPadding: (MediaQuery.of(context).size.height * 0.2) - 50,
                ),
                // DraggableScrollableSheet(
                //   initialChildSize: 0.1,
                //   minChildSize: 0.1,
                //   maxChildSize: 0.8,
                //   builder: (BuildContext context,
                //       ScrollController scrollController) {
                //     return SingleChildScrollView(
                //         controller: scrollController,
                //         child: Container(
                //           height: MediaQuery.of(context).size.height * 0.75,
                //           decoration: BoxDecoration(
                //               color: Color.fromRGBO(238, 238, 238, 1),
                //               borderRadius: BorderRadius.only(
                //                 topLeft: Radius.circular(30),
                //                 topRight: Radius.circular(30),
                //               ),
                //               border: Border.all(color: primaryColor)),
                //           child: Column(
                //             mainAxisSize: MainAxisSize.max,
                //             children: [
                //               Padding(
                //                 padding: const EdgeInsets.all(15.0),
                //                 child: Text(
                //                   "Últimas Transações",
                //                   style: TextStyle(
                //                     fontWeight: FontWeight.w600,
                //                     fontSize: 25,
                //                   ),
                //                 ),
                //               ),
                //               Divider(
                //                 thickness: 1,
                //                 color: primaryColor,
                //               ),
                //               ...List.generate(
                //                 listOperacao.length,
                //                 (i) {
                //                   if (listOperacao != null) {
                //                     if (listOperacao.length > 0) {
                //                       return ListTile(
                //                         title: Text(
                //                             "N° Doc: " + listOperacao[i].nrdoc),
                //                         subtitle:
                //                             Text(getTipo(listOperacao[i].tipo)),
                //                       );
                //                     } else {
                //                       return null;
                //                     }
                //                   } else {
                //                     return null;
                //                   }
                //                 },
                //               ),
                //             ],
                //           ),
                //         ));
                //   },
                // ),
              ],
            ),
          ),
          bottomNavigationBar: BottomBar()),
    );
  }
}
