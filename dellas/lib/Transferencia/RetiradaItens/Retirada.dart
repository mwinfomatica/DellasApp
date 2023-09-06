import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:dellas/Components/Bottom.dart';
import 'package:dellas/Components/DashedRect.dart';
import 'package:dellas/Home/Home.dart';
import 'package:dellas/Models/APIModels/OperacaoModel.dart';
import 'package:dellas/Models/APIModels/ProdutoModel.dart';
import 'package:dellas/Transferencia/RetiradaItens/components/ListItem.dart';
import 'package:dellas/Components/Constants.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:uuid/uuid.dart';

class Retirada extends StatefulWidget {
  @override
  _RetiradaState createState() => _RetiradaState();
}

class _RetiradaState extends State<Retirada> {
  late Barcode result;
  bool reading = false;
  Random r = new Random();
  late QRViewController controller;
  final GlobalKey qrAKey = GlobalKey(debugLabel: 'QR');
  final animateListKey = GlobalKey<AnimatedListState>();

  List<ProdutoModel> listProd = [];
  OperacaoModel op = new OperacaoModel();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    verifyOp();
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
            title: Text("Retirada"),
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
                        horizontal: 25,
                      ),
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
                              "Realize a leitura do \n QRcode do produto",
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
              Expanded(
                child: AnimatedList(
                  key: animateListKey,
                  itemBuilder: (context, index, animation) {
                    return ListItem(
                      produto: listProd[index],
                      ontap: () {
                        _removeItem(index);
                      },
                      animation: animation,
                    );
                  },
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    primary: primaryColor,
                    textStyle: const TextStyle(fontSize: 20)),
                onPressed: () {
                  op.situacao = "2";
                  op.update();
                  op.prods = listProd;
                  if (op.prods != null && op.prods!.length > 0)
                    Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => HomeScreen(),
                    ),
                  );
                },
                child: Text('Concluir Retirada'),
              )
            ],
          ),
          bottomNavigationBar: BottomBar()),
    );
  }

  void _addItem(ProdutoModel prod) {
    var prodExist = listProd.where((element) => prod.id == element.id);

    if (prodExist.length == 0) {
      prod.idOperacao = op.id.toUpperCase();
 prod.idproduto = prod.id;
      prod.id = new Uuid().v4().toUpperCase();
      prod.qtd = prod.qtd == null ? "1" : prod.qtd;
      listProd.add(prod);
      prod.insert();
      animateListKey.currentState!.insertItem(0);
    } else {
      ProdutoModel prod = prodExist.single;
      prod.idproduto = prod.id;
      prod.id = new Uuid().v4().toUpperCase();
      prod.qtd = prod.qtd == null ? "1" : prod.qtd;
      prod.qtd = (int.parse(prod.qtd) + 1).toString();
      prod.edit(prod);
    }
  }

  void _removeItem(int index) {
    final item = listProd.removeAt(index);
    item.delete(item.id);
    animateListKey.currentState!.removeItem(
      index,
      (context, animation) => ListItem(
        produto: item,
        animation: animation,
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
      try {
        if (!reading) {
          reading = true;
          var prodjson = json.decode(scanData.code!);
          ProdutoModel prod = ProdutoModel.fromJson(prodjson);
          _addItem(prod);
          FlutterBeep.beep();
          Timer(Duration(seconds: 2), () {
            reading = false;
          });
        }
      } catch (ex) {
        FlutterBeep.beep(false);
        Timer(Duration(seconds: 1), () {
          reading = false;
        });
      }
    });
  }

  verifyOp() async {
    op = await new OperacaoModel().getPendenteAramazenamento();
    if (op == null) {
      op = new OperacaoModel(
          id: new Uuid().v4().toUpperCase(),
          cnpj: '11.377.757/0001-15',
          tipo: '41',
          situacao: '1');
      op.insert();
    }
  }
}
