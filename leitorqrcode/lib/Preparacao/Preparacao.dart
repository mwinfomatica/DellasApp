import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Demo/ProdutoModelDemo.dart';
import 'package:leitorqrcode/DetalhesProdutos/DetalhesProduto.dart';

class ListaPreparacaosScreen extends StatefulWidget {
  @override
  _ListaPreparacaosScreenState createState() => _ListaPreparacaosScreenState();
}

class _ListaPreparacaosScreenState extends State<ListaPreparacaosScreen> {
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
          appBar: AppBar(
            backgroundColor: primaryColor,
            title: Text("Ordens de Produção"),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: 10,
            separatorBuilder: (BuildContext context, int index) => SizedBox(
                height: 15,
                child: Divider(),
              ),
            itemBuilder: (BuildContext context, int index) {
              return InkWell(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  height: 30,
                  child: Row(
                    children: [
                      Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('C0000${index + 1}'),
                      SizedBox(
                        height: 5,
                      ),
                      // Text(
                      //   armazenamento.descricao,
                      //   overflow: TextOverflow.ellipsis,
                      //   style: TextStyle(
                      //     color: Color.fromRGBO(132, 141, 149, 1),
                      //     fontSize: 12,
                      //   ),
                      // ),
                    ],
                  ),
                    ],
                  ),
                ),
                onTap: (
                ){
                    Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => DetalhesProduto(titulo:'C0000${index + 1}', listProd: listaProduto,),
                  ),
                );
                },
              );
            },
          ),
          bottomNavigationBar: BottomBar()),
    );
  }
}
