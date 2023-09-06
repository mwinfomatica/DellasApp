import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:dellas/Armazenamento/components/ListItem.dart';
import 'package:dellas/Components/Bottom.dart';
import 'package:dellas/Components/Constants.dart';
import 'package:dellas/Components/DashedRect.dart';
import 'package:dellas/Demo/ProdutoModelDemo.dart';
import 'package:dellas/Models/ArmazenamentoModel.dart';
import 'package:dellas/Models/ProdutoModel.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class Armazenamento extends StatefulWidget {
  @override
  _ArmazenamentoState createState() => _ArmazenamentoState();
}

class _ArmazenamentoState extends State<Armazenamento> {
  Barcode? result;
  bool reading = false;
  Random r = new Random();
  QRViewController? controller;
  final GlobalKey qrAKey = GlobalKey(debugLabel: 'QR');
  final animateListKey = GlobalKey<AnimatedListState>();

  List<ArmazenamentoModel> lista = [];

  @override
  void dispose() {
    controller!.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      if (Platform.isAndroid) {
        controller!.pauseCamera();
      }
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: primaryColor,
            title: Text("Armazem 01 - Seção 2"),
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
                      margin: EdgeInsets.symmetric(vertical: (MediaQuery.of(context).size.height * 0.05),horizontal: 15),
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
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: AnimatedList(
                  key: animateListKey,
                  itemBuilder: (context, index, animation) {
                    return ListItem(
                      armazenamento: lista[index],
                      ontap: () {
                        _removeItem(index);
                      },
                      animation: animation,
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
    int a = r.nextInt(5);
    ProdutoModel produto = listaProduto[a];
    animateListKey.currentState!.insertItem(0);
    lista.insert(
      0,
      ArmazenamentoModel(
        codigo: produto.codigo,
        nome: produto.nome,
        descricao: produto.descricao,
        validade: produto.validade,
      ),
    );
  }

  void _removeItem(int index) {
    final item = lista.removeAt(index);

    animateListKey.currentState!.removeItem(
      index,
      (context, animation) => ListItem(
        armazenamento: item,
        animation: animation, ontap: ()=>{},
      ),
    );
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
