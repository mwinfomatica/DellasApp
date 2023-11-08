import 'dart:math';

import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Models/ProdutoModel.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../QrCoder.dart';

class PrepararArmazenamento extends StatefulWidget {
  final String titulo;
  final List<ProdutoModel> listProd;

  const PrepararArmazenamento(
      {Key key, @required this.titulo, @required this.listProd})
      : super(key: key);

  @override
  State<PrepararArmazenamento> createState() => _PrepararArmazenamentoState();
}

class _PrepararArmazenamentoState extends State<PrepararArmazenamento> {
  Barcode result;
  bool reading = false;
  Random r = new Random();
  final animateListKey = GlobalKey<AnimatedListState>();
  List<ProdutoModel> lista = [];

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    lista = widget.listProd;
    super.initState();
  }

  @override
  void reassemble() {
    super.reassemble();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: primaryColor,
            title: Text(widget.titulo),
          ),
          body: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                width: MediaQuery.of(context).size.width - 10,
                height: 80,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => QRCoder(
                          tipo: 1,
                        ),
                      ),
                    );
                  },
                  child: Text("Iniciar Armazenamento"),
                  style: ElevatedButton.styleFrom(
                    primary: primaryColor,
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                padding: EdgeInsets.all(10),
                color: Colors.grey[300],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 5,
                    ),
                    Column(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.23,
                          child: Text("Validade"),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.49,
                          child: Text("Produto"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 5,
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: lista.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      SizedBox(
                    height: 15,
                    child: Divider(),
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    return InkWell(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.23,
                                  child: Text(lista[index].validade),
                                ),
                              ],
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.70,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(lista[index].nome),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                    lista[index].descricao,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Color.fromRGBO(132, 141, 149, 1),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomBar()),
    );
  }
}
