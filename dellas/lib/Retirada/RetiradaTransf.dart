import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:dellas/Components/Bottom.dart';
import 'package:dellas/Components/Constants.dart';
import 'package:dellas/Components/DashedRect.dart';
import 'package:dellas/Models/APIModels/Endereco.dart';
import 'package:dellas/Models/APIModels/OperacaoModel.dart';
import 'package:dellas/Retirada/components/IniciarApuracao.dart';
import 'package:dellas/Models/APIModels/MovimentacaoMOdel.dart';
import 'package:dellas/Models/APIModels/ProdutoModel.dart';
import 'package:dellas/Shared/Dialog.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class RetiradaTransf extends StatefulWidget {
  final String titulo;
  final OperacaoModel operacaoModel;

  const RetiradaTransf({
    Key? key,
    required this.titulo,
    required this.operacaoModel,
  }) : super(key: key);

  @override
  State<RetiradaTransf> createState() => _RetiradaTransfState();
}

class _RetiradaTransfState extends State<RetiradaTransf> {
  late Barcode result;
  bool reading = false;
  bool showCamera = false;
  bool hasAdress = false;
  bool prodReadSuccess = false;
  Random r = new Random();
  String? endRead;
  String? titleBtn;
  String idOperador = "";
  final animateListKey = GlobalKey<AnimatedListState>();
  final qtdeProdDialog = TextEditingController();
  final GlobalKey qrAKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  List<ProdutoModel> listProd = [];

  Widget _buildQrView(BuildContext context) {
    return QRView(
      key: qrAKey,
      onQRViewCreated: _onQRViewCreated,
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
      controller.resumeCamera();
    });
    controller.scannedDataStream.listen((scanData) async {
      try {
        if (!reading) {
          reading = true;

          //Atualizar produto & Criar movimentação
          if (hasAdress) {
            bool isOK = true;

            ProdutoModel prodRead =
                ProdutoModel.fromJson(jsonDecode(scanData.code!));

            FlutterBeep.beep();

            // ProdutoModel prodDB = await new ProdutoModel()
            //     .getByIdLoteIdPedidoEnd(prodRead.idloteunico.toUpperCase(),
            //         widget.operacaoModel.id.toUpperCase(), endRead);

            var prodExist = listProd.where((element) =>
                prodRead.id == element.idproduto && endRead == element.end);

            if (prodExist.length > 0) {
              if (isOK) {
                ProdutoModel? proddb = await ProdutoModel()
                    .getByIdLoteIdPedidoEnd(prodRead.idloteunico,
                        widget.operacaoModel.id, endRead!);
                ProdutoModel prod = prodExist.single;
                prod.qtd = prod.qtd == null ? "1" : prod.qtd;
                prod.qtd = (int.parse(prod.qtd) + 1).toString();
                prod.idOperacao = widget.operacaoModel.id;
                proddb!.qtd = prod.qtd;
                prod.edit(proddb);
                saveMovimentacao(prod, prodRead);
                setState(() {
                  if (prodExist.isNotEmpty) {
                    prodExist.single.qtd = prod.qtd;
                  }
                  var i = widget.operacaoModel.prods!.indexOf(listProd
                      .where((element) =>
                          prodRead.id == element.idproduto &&
                          endRead == element.end)
                      .single);
                  widget.operacaoModel.prods![i].qtd = prod.qtd;
                  listProd = widget.operacaoModel.prods!;
                });
              }
            } else {
              ProdutoModel prod = prodRead;
              prod.idOperacao = widget.operacaoModel.id.toUpperCase();
              prod.idproduto = prodRead.id;
              prod.isVirtual = "0";
              prod.id = new Uuid().v4().toUpperCase();
              prod.qtd = "1";
              prod.end = endRead!;
              prod.insert();
              saveMovimentacao(prod, prodRead);
              setState(() {
                widget.operacaoModel.prods!.add(prod);
                listProd = widget.operacaoModel.prods!;
              });
            }
          } else {
            //Habilita camera
            if (scanData.code!.isEmpty || scanData.code!.length > 20) {
              FlutterBeep.beep(false);
              Dialogs.showToast(context, "Código de barras inválido");
            } else {
              EnderecoModel? end =
                  await EnderecoModel().getById(scanData.code!);

              if (end == null) {
                FlutterBeep.beep(false);
                Dialogs.showToast(context, "Endereço não existente.");
              } else {
                FlutterBeep.beep();

                setState(() {
                  endRead = scanData.code!;
                  hasAdress = true;
                });
              }
            }
          }
          Timer(Duration(seconds: 2), () {
            reading = false;
          });
        }
      } catch (ex) {
        Timer(Duration(milliseconds: 500), () {
          reading = false;
        });
      }
    });
  }

  void saveMovimentacao(ProdutoModel prodDB, ProdutoModel prodRead,
      {String? idProdutoPai}) async {
    // prodDB.end = endRead;
    // prodDB.situacao = "3";
    // await prodDB.update();
    MovimentacaoModel? moviDB = await new MovimentacaoModel()
        .getModelById(prodDB.id, prodDB.idOperacao);

    if (moviDB == null || prodDB.isVirtual == '1') {
      MovimentacaoModel movi = new MovimentacaoModel();
      movi.id = new Uuid().v4().toUpperCase();
      movi.operacao = widget.operacaoModel.tipo;
      movi.idOperacao = widget.operacaoModel.id;
      movi.codMovi = widget.operacaoModel.nrdoc;
      movi.operador = idOperador;
      movi.endereco = endRead!;
      movi.idProduto = prodDB.idproduto;
      movi.qtd = "1";
      DateTime today = new DateTime.now();
      String dateSlug =
          "${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year.toString()} ${today.hour}:${today.minute}:${today.second}";
      movi.dataMovimentacao = dateSlug;
      await movi.insert();

      widget.operacaoModel.situacao = "1";
      await widget.operacaoModel.update();
      OperacaoModel? opRetirada = await OperacaoModel().getOpAramazenamento();
      if (opRetirada != null) {
        opRetirada.situacao = "1";
        opRetirada.update();
      }
    }
  }

  void getIdUser() async {
    SharedPreferences userlogged = await SharedPreferences.getInstance();
    this.idOperador = userlogged.getString('IdUser')!;
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    if (widget.operacaoModel.prods!.length > 0) {
      listProd = widget.operacaoModel.prods!;
      var count = listProd.where((element) => element.situacao == "3").length;
    }

    getIdUser();

    if (widget.operacaoModel.tipo != null)
      widget.operacaoModel.tipo = widget.operacaoModel.tipo.trim();
    else
      widget.operacaoModel.tipo = "";

    if (widget.operacaoModel.tipo == "10" || widget.operacaoModel.tipo == "40")
      titleBtn = "Iniciar Armazenamento";
    else if (widget.operacaoModel.tipo == "21" ||
        widget.operacaoModel.tipo == "31")
      titleBtn = "Iniciar Retirada";
    else if (widget.operacaoModel.tipo == "41")
      titleBtn = "Iniciar Saída Transferência";
    else if (widget.operacaoModel.tipo == "20" ||
        widget.operacaoModel.tipo == "30")
      titleBtn = "Iniciar Devolução";
    else if (widget.operacaoModel.tipo == "90") titleBtn = "Iniciar Contagem";

    super.initState();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      if (Platform.isAndroid) {
        controller?.pauseCamera();
      }
      controller?.resumeCamera();
    }
  }

  Color? strippedList(int index) {
    if (index % 2 == 0) {
      return Colors.white;
    } else {
      return Colors.grey[200];
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
              if (!prodReadSuccess)
                showCamera == false
                    ? BotaoIniciarApuracao(
                        titulo: titleBtn ?? "",
                        onPressed: () {
                          setState(() {
                            showCamera = true;
                          });
                        },
                      )
                    : Stack(
                        children: [
                          Container(
                            height: (MediaQuery.of(context).size.height * 0.20),
                            child: _buildQrView(context),
                            // child: Container(),
                          ),
                          Center(
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                vertical: !hasAdress
                                    ? (MediaQuery.of(context).size.height *
                                        0.05)
                                    : (MediaQuery.of(context).size.height *
                                        0.01),
                                horizontal: !hasAdress
                                    ? 25
                                    : (MediaQuery.of(context).size.width * 0.3),
                              ),
                              height: !hasAdress
                                  ? (MediaQuery.of(context).size.height * 0.10)
                                  : (MediaQuery.of(context).size.height * 0.17),
                              child: DashedRect(
                                color: primaryColor,
                                gap: !hasAdress ? 10 : 25,
                                strokeWidth: !hasAdress ? 2 : 5,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Center(
                                    child: Text(
                                      hasAdress
                                          ? "Leia o QRCode \n do produto"
                                          : "Realize a leitura do \n Endereço",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 25, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              SizedBox(
                height: 0,
              ),
              Container(
                padding: EdgeInsets.all(10),
                color: !hasAdress ? Colors.grey[300] : Colors.yellow[300],
                child: Container(
                  child: endRead == null
                      ? Text(
                          "Nenhum endereço lido",
                          style: TextStyle(fontSize: 40),
                        )
                      : Text(
                          endRead!,
                          style: TextStyle(
                              fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              SizedBox(
                height: 5,
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateColor.resolveWith(
                    (states) => Colors.grey,
                  ),
                  columnSpacing: 20,
                  columns: [
                    DataColumn(
                      label: Text(""),
                    ),
                    DataColumn(
                      label: Text(
                        "Endereço",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      numeric: true,
                      label: Text(
                        "Qtd",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Produto",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Sub Lote",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  rows: List.generate(
                    listProd.length,
                    (index) {
                      return DataRow(
                        color: MaterialStateProperty.resolveWith((states) {
                          return strippedList(index);
                        }),
                        cells: [
                          DataCell(
                            Icon(
                              Icons.check_box,
                              color: listProd[index].situacao == "3"
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                          DataCell(
                            Text(
                              listProd[index].end,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              listProd[index].qtd,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              listProd[index].nome,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              listProd[index].sl,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: 200,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          primary: primaryColor,
                          textStyle: const TextStyle(fontSize: 20)),
                      onPressed: () async {
                        Navigator.pop(context);
                      },
                      child: Text('Finalizar'),
                    ),
                  ),
                ],
              ),
              if (hasAdress)
                Container(
                  width: 200,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        primary: primaryColor,
                        textStyle: const TextStyle(fontSize: 20)),
                    onPressed: () {
                      setState(() {
                        endRead = null;
                        hasAdress = false;
                      });
                    },
                    child: Text('Alterar endereço'),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: BottomBar()),
    );
  }
}
