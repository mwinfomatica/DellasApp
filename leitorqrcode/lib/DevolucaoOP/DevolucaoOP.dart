import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Components/DashedRect.dart';
import 'package:leitorqrcode/DevolucaoOP/components/IniciarApuracao.dart';
import 'package:leitorqrcode/Models/APIModels/MovimentacaoMOdel.dart';
import 'package:leitorqrcode/Models/APIModels/OperacaoModel.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DevolucaoOP extends StatefulWidget {
  final String? titulo;
  final OperacaoModel? operacaoModel;

  const DevolucaoOP({
    Key? key,
    @required this.titulo,
    @required this.operacaoModel,
  }) : super(key: key);

  @override
  State<DevolucaoOP> createState() => _DevolucaoOPState();
}

class _DevolucaoOPState extends State<DevolucaoOP> {
  Barcode? result;
  bool reading = false;
  bool showCamera = false;
  bool hasAdress = false;
  bool prodReadSuccess = false;
  Random r = new Random();
  String? endRead = null;
  String? titleBtn = null;
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

            ProdutoModel? prodDB = await new ProdutoModel().getByIdLoteIdPedido(
                prodRead.idloteunico!.toUpperCase(),
                widget.operacaoModel!.id!.toUpperCase());

            if (prodDB != null) {
              if (isOK) {
                qtdeProdDialog.text = "";

                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(
                      "Informe a quantidade do produto scaneado",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    content: TextField(
                      controller: qtdeProdDialog,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor),
                          ),
                          labelText: 'Qtde'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          if (int.parse(prodDB.qtd!) ==
                              int.parse(qtdeProdDialog.text)) {
                            prodDB.qtd = qtdeProdDialog.text;
                            qtdeProdDialog.text = "";
                            saveMovimentacao(prodDB, prodRead);
                            Navigator.pop(context);
                          } else if (int.parse(prodDB.qtd!) <
                              int.parse(qtdeProdDialog.text)) {
                            Dialogs.showToast(context,
                                "A quantidade não pode ser maior que a informada na nota fiscal.");
                          } else {
                            ProdutoModel prodVirtual = new ProdutoModel(
                                id: new Uuid().v4().toUpperCase(),
                                cod: prodDB.cod,
                                idprodutoPedido: prodDB.idprodutoPedido,
                                idproduto: prodDB.idproduto,
                                desc: prodDB.desc,
                                end: prodDB.end,
                                idOperacao: prodDB.idOperacao,
                                idloteunico: prodDB.idloteunico,
                                infq: prodDB.infq,
                                sl: prodDB.sl,
                                lote: prodDB.lote,
                                nome: prodDB.nome,
                                qtd: qtdeProdDialog.text,
                                situacao: prodDB.situacao,
                                vali: prodDB.vali);

                            prodVirtual.isVirtual = '1';
                            prodVirtual.insert();
                            prodDB.qtd = (int.parse(prodDB.qtd!) -
                                    int.parse(qtdeProdDialog.text))
                                .toString();

                            if (int.parse(prodDB.qtd!) > 0) {
                              prodDB.update();
                            } else {
                              prodDB.delete(prodDB.id!);
                            }

                            listProd.add(prodVirtual);
                            saveMovimentacao(prodVirtual, prodRead,
                                idProdutoPai: prodDB.id);
                            Navigator.pop(context);
                          }
                        },
                        child: Text("Salvar"),
                      ),
                    ],
                    elevation: 24.0,
                  ),
                );
              }
            } else
              Dialogs.showToast(context, "Produto não encontrado");
          } else {
            //Habilita camera
            if (scanData.code!.isEmpty || scanData.code!.length > 20) {
              FlutterBeep.beep(false);
              Dialogs.showToast(context, "Código de barras inválido");
            } else {
              FlutterBeep.beep();

              setState(() {
                endRead = scanData.code;
                hasAdress = true;
              });
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
    prodDB.end = endRead!;
    prodDB.situacao = "3";
    await prodDB.update();
    MovimentacaoModel? moviDB = await new MovimentacaoModel()
        .getModelById(prodDB.id!, prodDB.idOperacao!);

    if (moviDB == null || prodDB.isVirtual == '1') {
      MovimentacaoModel movi = new MovimentacaoModel();
      movi.id = new Uuid().v4().toUpperCase();
      movi.operacao = widget.operacaoModel!.tipo;
      movi.idOperacao = widget.operacaoModel!.id;
      movi.codMovi =
          widget.operacaoModel!.nrdoc! + "_" + movi.operacao! + "_" + endRead!;
      movi.operador = idOperador;
      movi.endereco = endRead!;
      movi.idProduto = prodDB.idproduto!;
      movi.qtd = prodDB.qtd!;
      DateTime today = new DateTime.now();
      String dateSlug =
          "${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year.toString()} ${today.hour}:${today.minute}:${today.second}";
      movi.dataMovimentacao = dateSlug;
      await movi.insert();

      setState(() {
        ProdutoModel itemList = listProd.firstWhere(
            (element) => element.id!.toUpperCase() == prodDB.id!.toUpperCase());

        itemList.end = endRead!;
        itemList.situacao = "3";

        if (prodDB.isVirtual == '1') {
          ProdutoModel itemList1 =
              listProd.firstWhere((element) => element.id == idProdutoPai);
          itemList1.qtd =
              (int.parse(itemList1.qtd!) - int.parse(itemList.qtd!)).toString();
          if (int.parse(itemList1.qtd!) == 0) {
            listProd.remove(itemList1);
          }
        }
      });

      if (listProd.where((element) => element.situacao != "3").length == 0) {
        widget.operacaoModel!.situacao = "3";
        await widget.operacaoModel!.update();
        Dialogs.showToast(context, "Leitura concluída");
        setState(() {
          this.hasAdress = false;
          this.prodReadSuccess = true;
        });
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
    listProd = widget.operacaoModel!.prods!;
    var count = listProd.where((element) => element.situacao == "3").length;

    getIdUser();

    if (count == listProd.length) {
      Dialogs.showToast(context, "Leitura já realizada");
      // Navigator.pop(context);
      this.prodReadSuccess = true;
      this.hasAdress = false;
    }

    if (widget.operacaoModel!.tipo != null)
      widget.operacaoModel!.tipo = widget.operacaoModel!.tipo!.trim();
    else
      widget.operacaoModel!.tipo = "";

    if (widget.operacaoModel!.tipo == "10" ||
        widget.operacaoModel!.tipo == "40")
      titleBtn = "Iniciar Armazenamento";
    else if (widget.operacaoModel!.tipo == "21" ||
        widget.operacaoModel!.tipo == "31")
      titleBtn = "Iniciar Retirada";
    else if (widget.operacaoModel!.tipo == "41")
      titleBtn = "Iniciar Armazenamento";
    else if (widget.operacaoModel!.tipo == "20" ||
        widget.operacaoModel!.tipo == "30")
      titleBtn = "Iniciar Devolução";
    else if (widget.operacaoModel!.tipo == "90") titleBtn = "Iniciar Contagem";

    super.initState();
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
            title: Text(widget.titulo!),
          ),
          body: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              if (!prodReadSuccess)
                showCamera == false
                    ? BotaoIniciarApuracao(
                        titulo: titleBtn == null ? "" : titleBtn,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 7,
                    ),
                    Column(
                      children: [
                        Container(
                          child: endRead == null
                              ? Text(
                                  "Nenhum endereço lido",
                                  style: TextStyle(fontSize: 40),
                                )
                              : Text(
                                  endRead!,
                                  style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    )
                  ],
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
                    rows: List.generate(listProd.length, (index) {
                      return DataRow(
                        color: MaterialStateColor.resolveWith(
                          (states) =>
                              index % 2 == 0 ? Colors.white : Colors.grey[200]!,
                        ),
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
                              listProd[index].end != null
                                  ? listProd[index].end!
                                  : "",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              listProd[index].qtd!,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              listProd[index].nome!,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              listProd[index].sl!,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    })),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: 200,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          textStyle: const TextStyle(fontSize: 20)),
                      onPressed: () async {
                        List<ProdutoModel> notvirtual = listProd
                            .where((element) => element.isVirtual == '0')
                            .toList();

                        for (int i = 0; i < notvirtual.length; i++) {
                          await notvirtual[i].delete(notvirtual[i].id!);
                        }
                        widget.operacaoModel!.situacao = '3';
                        await widget.operacaoModel!.update();
                        Navigator.pop(context);
                      },
                      child: Text('Finalizar'),
                    ),
                  ),
                  if (hasAdress)
                    Container(
                      width: 200,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
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
                  // Container(
                  //   width: 200,
                  //   child: ElevatedButton(
                  //     style: ElevatedButton.styleFrom(
                  //       primary: primaryColor,
                  //       textStyle: const TextStyle(fontSize: 20),
                  //     ),
                  //     onPressed: () async {
                  //       await widget.operacaoModel.reset();
                  //       listProd = await ProdutoModel()
                  //           .getByIdOperacao(widget.operacaoModel.id);

                  //       setState(() {
                  //         endRead = null;
                  //         hasAdress = false;
                  //         prodReadSuccess = false;
                  //       });
                  //     },
                  //     child: Text('Refazer'),
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: BottomBar()),
    );
  }
}
