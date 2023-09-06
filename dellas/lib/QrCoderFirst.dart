import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:dellas/Apuracao/Apuracao.dart';
import 'package:dellas/DevolucaoOP/DevolucaoOP.dart';
import 'package:dellas/Models/APIModels/OperacaoModel.dart';
import 'package:dellas/Models/APIModels/ProdutoModel.dart';
import 'package:dellas/Services/ProdutoService.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:dellas/Home/Home.dart';
import 'package:dellas/Shared/Dialog.dart';
import 'package:uuid/uuid.dart';

import 'Components/Constants.dart';

class QrCoderFirst extends StatefulWidget {
  final int? tipo;

  const QrCoderFirst({
    Key? key,
    this.tipo,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QrCoderFirstState();
}

class _QrCoderFirstState extends State<QrCoderFirst> {
  late Barcode result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  String textoCentral = "Posicione a câmera \n em frente ao código QR";
  String resultado = "";
  String titlePageOp = "";
  bool reading = false;

  @override
  void reassemble() {
    super.reassemble();
    if (!Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _buildQrView(context),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          Navigator.pop(context);
                        },
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          controller?.toggleFlash();
                          setState(() {});
                        },
                        child: FutureBuilder(
                          future: controller?.getFlashStatus(),
                          builder: (context, snapshot) {
                            if (snapshot.data != true) {
                              return Icon(
                                Icons.flash_off,
                                color: Colors.white,
                              );
                            } else {
                              return Icon(
                                Icons.flash_on,
                                color: Colors.white,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          "Leia o código QR",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width,
                margin: EdgeInsets.symmetric(horizontal: 25),
                decoration: BoxDecoration(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 30,
                  ),
                  child: Text(
                    textoCentral,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;

    return QRView(
      key: qrKey,
      overlay: QrScannerOverlayShape(
          borderColor: primaryColor,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onQRViewCreated: _onQRViewCreated,
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    setState(() {
      if (!Platform.isAndroid) {
        controller.pauseCamera();
      }
      controller.resumeCamera();
    });
    controller.scannedDataStream.listen((scanData) async {
      // if (widget.tipo == 1) {
      try {
        if (!reading) {
          reading = true;

          OperacaoModel opRead =
              OperacaoModel.fromJson(jsonDecode(scanData.code!));

          if (widget.tipo == 1) {
            OperacaoModel? opDB =
                await new OperacaoModel().getModelById(opRead.id);

            if (opDB == null || opDB.id == null) {
              opRead.prods = await _getProdutosInServer(opRead.id);

              if (opRead.prods != null) {
                await opRead.insert();

                for (int i = 0; i < opRead.prods!.length; i++) {
                  ProdutoModel? prodDB =
                      await new ProdutoModel().getById(opRead.prods![i].id);
                  if (prodDB == null || prodDB.id == null) {
                    opRead.prods![i].idOperacao = opRead.id;
                    await opRead.prods![i].insert();
                  } else {
                    opRead.prods![i] = prodDB;
                  }
                }
              } else
                opRead.prods = [];
            } else {
              opRead.prods = await ProdutoModel().getByIdOperacao(opRead.id);
              if (opRead.prods == null || opRead.prods!.length == 0) {
                opRead.prods = await _getProdutosInServer(opRead.id);
                for (int i = 0; i < opRead.prods!.length; i++) {
                  ProdutoModel? prodDB =
                      await new ProdutoModel().getById(opRead.prods![i].id);
                  if (prodDB == null || prodDB.id == null) {
                    opRead.prods![i].idOperacao = opRead.id;
                    await opRead.prods![i].insert();
                  } else {
                    opRead.prods![i] = prodDB;
                  }
                }
              }
            }

            getTitlePageOp(opRead.tipo);

            Navigator.pop(context);
            if (opRead.prods == null || opRead.prods!.length == 0) {
              FlutterBeep.beep(false);
              Dialogs.showToast(
                  context, "Nenhum produto encontrado para o pedido.",
                  duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => HomeScreen(),
                  ),
                  (route) => false);
            } else {
              FlutterBeep.beep();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => Apuracao(
                    titulo: titlePageOp +
                        (opRead.nrdoc != null ? "\n" + opRead.nrdoc : ""),
                    operacaoModel: opRead,
                  ),
                ),
              );
            }
          } else if (widget.tipo == 2) {
            OperacaoModel? opDB = await new OperacaoModel()
                .getModelByNumDocTipo(opRead.nrdoc, "20");

            if (opDB == null || opDB.id == null) {
              opRead.prods = await _getProdutosInServerDevolucao(opRead.id);

              if (opRead.prods != null && opRead.prods!.length > 0) {
                OperacaoModel opDev = OperacaoModel(
                  id: new Uuid().v4().toUpperCase(),
                  cnpj: "14633154000206",
                  nrdoc: opRead.nrdoc,
                  situacao: "1",
                  tipo: "20",
                );

                await opDev.insert();

                for (int i = 0; i < opRead.prods!.length; i++) {
                  ProdutoModel prod = ProdutoModel(
                    id: new Uuid().v4().toUpperCase(),
                    cod: opRead.prods![i].cod,
                    desc: opRead.prods![i].desc,
                    end: opRead.prods![i].end,
                    idloteunico: opRead.prods![i].idloteunico,
                    idOperacao: opDev.id,
                    idproduto: opRead.prods![i].idproduto,
                    idprodutoPedido: opRead.prods![i].idprodutoPedido,
                    infq: opRead.prods![i].infq,
                    lote: opRead.prods![i].lote,
                    nome: opRead.prods![i].nome,
                    qtd: opRead.prods![i].qtd,
                    situacao: "1",
                    sl: opRead.prods![i].sl,
                    vali: opRead.prods![i].vali,
                  );
                  prod.isVirtual = "0";

                  prod.insert();
                }

                getTitlePageOp("20");

                opDev.prods = await ProdutoModel().getByIdOperacao(opDev.id);
                await FlutterBeep.beep();

                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => DevolucaoOP(
                      titulo: titlePageOp +
                          (opDev.nrdoc != null ? "\n" + opDev.nrdoc : ""),
                      operacaoModel: opDev,
                    ),
                  ),
                );
              } else {
                await FlutterBeep.beep(false);
                Dialogs.showToast(
                    context, "Nenhum produto encontrado para o pedido.",
                    duration: Duration(seconds: 5),
                    bgColor: Colors.red.shade200);
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => HomeScreen(),
                    ),
                    (route) => false);
              }
            } else {
              getTitlePageOp("20");

              opDB.prods = await ProdutoModel().getByIdOperacao(opDB.id);

              await FlutterBeep.beep();

              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => DevolucaoOP(
                    titulo: titlePageOp +
                        (opDB.nrdoc != null ? "\n" + opDB.nrdoc : ""),
                    operacaoModel: opDB,
                  ),
                ),
              );
            }
          } else if (widget.tipo == 3) {
            OperacaoModel? opDB = await new OperacaoModel()
                .getModelByNumDocTipo(opRead.nrdoc, "22");

            if (opDB == null || opDB.id == null) {
              opRead.prods = await _getProdutosInServerDevolucao(opRead.id);

              if (opRead.prods != null && opRead.prods!.length > 0) {
                OperacaoModel opDev = OperacaoModel(
                  id: new Uuid().v4().toUpperCase(),
                  cnpj: "14633154000206",
                  nrdoc: opRead.nrdoc,
                  situacao: "1",
                  tipo: "22",
                );

                await opDev.insert();

                for (int i = 0; i < opRead.prods!.length; i++) {
                  ProdutoModel prod = ProdutoModel(
                    id: new Uuid().v4().toUpperCase(),
                    cod: opRead.prods![i].cod,
                    desc: opRead.prods![i].desc,
                    end: opRead.prods![i].end,
                    idloteunico: opRead.prods![i].idloteunico,
                    idOperacao: opDev.id,
                    idproduto: opRead.prods![i].idproduto,
                    idprodutoPedido: opRead.prods![i].idprodutoPedido,
                    infq: opRead.prods![i].infq,
                    lote: opRead.prods![i].lote,
                    nome: opRead.prods![i].nome,
                    qtd: opRead.prods![i].qtd,
                    situacao: "1",
                    sl: opRead.prods![i].sl,
                    vali: opRead.prods![i].vali,
                  );
                  prod.isVirtual = "0";

                  prod.insert();
                }

                getTitlePageOp("21");

                opDev.prods = await ProdutoModel().getByIdOperacao(opDev.id);
                await FlutterBeep.beep();

                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => DevolucaoOP(
                      titulo: titlePageOp +
                          (opDev.nrdoc != null ? "\n" + opDev.nrdoc : ""),
                      operacaoModel: opDev,
                    ),
                  ),
                );
              } else {
                await FlutterBeep.beep(false);
                Dialogs.showToast(
                    context, "Nenhum produto encontrado para o pedido.",
                    duration: Duration(seconds: 5),
                    bgColor: Colors.red.shade200);
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => HomeScreen(),
                    ),
                    (route) => false);
              }
            } else {
              getTitlePageOp("21");

              opDB.prods = await ProdutoModel().getByIdOperacao(opDB.id);

              await FlutterBeep.beep();

              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => DevolucaoOP(
                    titulo: titlePageOp +
                        (opDB.nrdoc != null ? "\n" + opDB.nrdoc : ""),
                    operacaoModel: opDB,
                  ),
                ),
              );
            }

            Timer(Duration(seconds: 2), () {
              reading = false;
            });
          }

          Timer(Duration(seconds: 2), () {
            reading = false;
          });
        }
      } catch (ex) {
        Timer(Duration(seconds: 2), () {
          reading = false;
        });
        FlutterBeep.beep(false);

        setState(() {
          textoCentral = "Código \"QR\" não reconhecido \n tente novamente";
        });
      }
      // }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void getTitlePageOp(String tipo) async {
    if (tipo == "10")
      titlePageOp = "Entrada de Mercadoria";
    else if (tipo == "21")
      titlePageOp = "Retirada para Produção";
    else if (tipo == "20")
      titlePageOp = "Devolução da Produção";
    else if (tipo == "31")
      titlePageOp = "Retirada para Venda";
    else if (tipo == "30")
      titlePageOp = "Devolução de Venda";
    else if (tipo == "41")
      titlePageOp = "Saída de Transferência";
    else if (tipo == "40")
      titlePageOp = "Entrada de Transferência";
    else if (tipo == "90") titlePageOp = "Contagem de  Inventário";
  }

  Future<List<ProdutoModel>?> _getProdutosInServer(String idOperacao) async {
    ProdutoService produtoService = new ProdutoService();

    if (idOperacao.isNotEmpty)
      return await produtoService.getProdutos(idOperacao);
    else
      return null;
  }

  Future<List<ProdutoModel>?> _getProdutosInServerDevolucao(
      String idOperacao) async {
    ProdutoService produtoService = new ProdutoService();

    if (idOperacao.isNotEmpty)
      return await produtoService.getProdutosDevolucao(idOperacao);
    else
      return null;
  }
}
