import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Components/DashedRect.dart';
import 'package:leitorqrcode/Models/ProdutoModel.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class DetalhesProduto extends StatefulWidget {
  final String titulo;
  final List<ProdutoModel> listProd;

  const DetalhesProduto(
      {Key key, @required this.titulo, @required this.listProd})
      : super(key: key);

  @override
  State<DetalhesProduto> createState() => _DetalhesProdutoState();
}

class _DetalhesProdutoState extends State<DetalhesProduto> {
  Barcode result;
  bool reading = false;
  Random r = new Random();
  QRViewController controller;
  final GlobalKey qrAKey = GlobalKey(debugLabel: 'QR');
  final animateListKey = GlobalKey<AnimatedListState>();
  List<ProdutoModel> lista = [];

  @override
  void dispose() {
    controller?.dispose();
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
    if (controller != null) {
      if (Platform.isAndroid) {
        controller.pauseCamera();
      }
      controller.resumeCamera();
    }
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
              Stack(
                children: [
                  Container(
                    height: (MediaQuery.of(context).size.height * 0.20),
                    child: _buildQrView(context),
                  ),
                  Center(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                          vertical: (MediaQuery.of(context).size.height * 0.05),
                          horizontal: 15),
                      height: (MediaQuery.of(context).size.height * 0.10),
                      child: DashedRect(
                        color: primaryColor,
                        gap: 10,
                        strokeWidth: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                          child: Center(
                            child: Text(
                              "Posicione a câmera \n em frente ao código",
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                color: Colors.grey[300],
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 5,
                    ),
                    Column(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.17,
                          child: Text("Endereço"),
                        ),
                      ],
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
                                      MediaQuery.of(context).size.width * 0.15,
                                  child: Text(lista[index].endereco),
                                ),
                              ],
                            ),
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
                              width: MediaQuery.of(context).size.width * 0.49,
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
                            Icon(
                              Icons.check_box,
                              color: lista[index].checked
                                  ? Colors.green
                                  : Colors.grey,
                            )
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

  void _addItem() {
    for (var i = 0; i < lista.length; i++) {
      if (!lista[i].checked) {
        setState(() {
          lista[i].checked = true;
        });

        i = lista.length;
      }
    }

    // ProdutoModel produto = listaProduto[a];
    // animateListKey.currentState.insertItem(0);
    // lista.insert(
    //   0,
    //   ArmazenamentoModel(
    //     codigo: produto.codigo,
    //     nome: produto.nome,
    //     descricao: produto.descricao,
    //     validade: produto.validade,
    //   ),
    // );
  }

  Widget _buildQrView(BuildContext context) {
    return QRView(
      key: qrAKey,
      onQRViewCreated: _onQRViewCreated,
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      if (!reading) {
        reading = true;
        print("aqui");
        _addItem();
        Timer(Duration(seconds: 2), () {
          reading = false;
        });
      }
    });
  }
}
