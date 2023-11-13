import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Demo/PedidosModelDemo.dart';
import 'package:leitorqrcode/Demo/ProdutoModelDemo.dart';
import 'package:leitorqrcode/DetalhesProdutos/DetalhesProduto.dart';

class PedidosVendas extends StatefulWidget {
  @override
  _PedidosVendasState createState() => _PedidosVendasState();
}

class _PedidosVendasState extends State<PedidosVendas> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: primaryColor,
            title: Text("Pedidos Venda"),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: listaPedidos.length,
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listaPedidos[index].nome! +
                                  " V" +
                                  listaPedidos[index].codigo!.padLeft(4, "0"),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              listaPedidos[index]
                                      .datavalidade!
                                      .day
                                      .toString()
                                      .padLeft(2, "0") +
                                  "/" +
                                  listaPedidos[index]
                                      .datavalidade!
                                      .month
                                      .toString()
                                      .padLeft(2, "0") +
                                  "/" +
                                  listaPedidos[index]
                                      .datavalidade!
                                      .year
                                      .toString(),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color.fromRGBO(132, 141, 149, 1),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Align(
                      //   alignment: Alignment.centerRight,
                      //   child: Text(
                      //     ,
                      //     style: TextStyle(
                      //       color: Colors.black,
                      //       fontSize: 24,
                      //     ),
                      //   ),
                      // ),
                      SizedBox(
                        height: 5,
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => DetalhesProduto(
                          titulo: listaPedidos[index].nome! +
                              " V" +
                              listaPedidos[index].codigo!.padLeft(4, "0"),
                          listProd: listaProduto),
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
