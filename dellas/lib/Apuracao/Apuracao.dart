import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:dellas/Apuracao/components/IniciarApuracao.dart';
import 'package:dellas/Components/Bottom.dart';
import 'package:dellas/Components/Constants.dart';
import 'package:dellas/Components/DashedRect.dart';
import 'package:dellas/Models/APIModels/Endereco.dart';
import 'package:dellas/Models/APIModels/MovimentacaoMOdel.dart';
import 'package:dellas/Models/APIModels/OperacaoModel.dart';
import 'package:dellas/Models/APIModels/ProdutoModel.dart';
import 'package:dellas/Shared/Dialog.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class Apuracao extends StatefulWidget {
  final String titulo;
  final OperacaoModel operacaoModel;

  const Apuracao({
    Key? key,
    required this.titulo,
    required this.operacaoModel,
  }) : super(key: key);

  @override
  State<Apuracao> createState() => _ApuracaoState();
}

class _ApuracaoState extends State<Apuracao> {
  late Barcode result;
  bool reading = false;
  bool showCamera = false;
  bool hasAdress = false;
  bool prodReadSuccess = false;
  Random r = new Random();
  String endRead = "";
  String titleBtn = "";
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

          if (hasAdress) {
            bool isOK = true;
            ProdutoModel? prodDB = new ProdutoModel();
            ProdutoModel prodRead = new ProdutoModel();

            //Valida se o que foi lido é um QRCode com um json ou um Barcode / DUMCode
            if (scanData.code!.contains('idproduto')) {
              prodRead = ProdutoModel.fromJson(jsonDecode(scanData.code!));

              FlutterBeep.beep();

              prodDB = await new ProdutoModel().getByIdLoteIdPedido(
                  prodRead.idloteunico.toUpperCase(),
                  widget.operacaoModel.id.toUpperCase());

              List<ProdutoModel> lProdDB = await ProdutoModel()
                  .getByIdProdIdOperacao(prodRead.idloteunico.toUpperCase(),
                      widget.operacaoModel.id.toUpperCase());
            } else {
              prodDB = await ProdutoModel().getByBar_DumCode(scanData.code!);

              if (prodDB == null) {
                FlutterBeep.beep(false);
                Dialogs.showToast(context,
                    "Produto não encontrado. Código de barras / DUM, não cadastrado");
              }
              FlutterBeep.beep();
            }

            List<ProdutoModel> lProdDB = await ProdutoModel()
                .getByIdProdIdOperacao(prodRead.idloteunico.toUpperCase(),
                    widget.operacaoModel.id.toUpperCase());

            if (lProdDB.length > 1) {
              var tqtd = 0;
              for (var i = 0; i < lProdDB.length; i++) {
                int qtdprod = 0;

                if (!lProdDB[i].qtd.isEmpty) {
                  qtdprod = int.parse(lProdDB[i].qtd);
                }

                tqtd = tqtd + qtdprod;
              }
            }

            if (prodDB != null) {
              var tqtd = int.parse(prodDB.qtd);

              if (widget.operacaoModel.tipo == '21' ||
                  widget.operacaoModel.tipo == '31') {
                if (prodDB.end != endRead) {
                  Dialogs.showToast(context,
                      "O produto deve ser retirado do endereço " + prodDB.end);

                  isOK = false;
                } else if (prodDB.lote != prodRead.lote ||
                    prodDB.vali != prodRead.vali) {
                  Dialogs.showToast(context,
                      "O produto deve ter a validade e lote informado na nota fiscal.");

                  isOK = false;
                }
              }

              if (isOK) {
                if (prodRead.infq == "s") {
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
                          onPressed: () async {
                            List<ProdutoModel> lProdDB = await ProdutoModel()
                                .getByIdProdIdOperacao(
                                    prodRead.idloteunico.toUpperCase(),
                                    widget.operacaoModel.id.toUpperCase());

                            if (lProdDB.length > 1) {
                              tqtd = 0;
                              for (var i = 0; i < lProdDB.length; i++) {
                                int qtdprod = 0;

                                if (!lProdDB[i].qtd.isEmpty) {
                                  qtdprod = int.parse(lProdDB[i].qtd);
                                }

                                tqtd = tqtd + qtdprod;
                              }
                            }

                            if (tqtd < int.parse(qtdeProdDialog.text)) {
                              Dialogs.showToast(context,
                                  "A quantidade não pode ser maior que a informada na nota fiscal.");
                            } else {
                              if (lProdDB.length > 1) {
                              } else {
                                if (prodDB == null) {
                                  Dialogs.showToast(
                                      context, "Produto não encontrado.");
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
                                  await prodVirtual.insert();
                                  prodDB.qtd = (int.parse(prodDB.qtd) -
                                          int.parse(qtdeProdDialog.text))
                                      .toString();

                                  if (int.parse(prodDB.qtd) > 0) {
                                    await prodDB.update();
                                  } else {
                                    await prodDB.delete(prodDB.id);
                                  }

                                  listProd.add(prodVirtual);
                                  saveMovimentacao(prodVirtual, prodRead,
                                      idProdutoPai: prodDB.id);
                                  Navigator.pop(context);
                                }
                              }
                            }
                          },
                          child: Text("Salvar"),
                        ),
                      ],
                      elevation: 24.0,
                    ),
                  );
                } else {
                  saveMovimentacao(prodDB, prodRead);
                }
              }
            } else
              Dialogs.showToast(context, "Produto não encontrado");
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
      {String idProdutoPai = ""}) async {
    prodDB.end = endRead;
    prodDB.situacao = "3";
    await prodDB.update();
    MovimentacaoModel? moviDB = await new MovimentacaoModel()
        .getModelById(prodDB.id, prodDB.idOperacao);

    if (moviDB == null || prodDB.isVirtual == '1') {
      MovimentacaoModel movi = new MovimentacaoModel();
      movi.id = new Uuid().v4().toUpperCase();
      movi.operacao = widget.operacaoModel.tipo;
      movi.idOperacao = widget.operacaoModel.id;
      movi.codMovi = widget.operacaoModel.nrdoc;
      movi.operador = idOperador;
      movi.endereco = endRead;
      movi.idProduto = prodDB.idproduto;
      movi.qtd = prodDB.qtd;
      DateTime today = new DateTime.now();
      String dateSlug =
          "${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year.toString()} ${today.hour}:${today.minute}:${today.second}";
      movi.dataMovimentacao = dateSlug;
      await movi.insert();

      setState(() {
        ProdutoModel itemList = listProd.firstWhere(
            (element) => element.id.toUpperCase() == prodDB.id.toUpperCase());

        itemList.end = endRead;
        itemList.situacao = "3";

        if (prodDB.isVirtual == '1') {
          ProdutoModel? itemList1 = listProd.firstWhere(
              (element) => element.id == idProdutoPai,
              orElse: () => new ProdutoModel());
          itemList1.qtd =
              (int.parse(itemList1.qtd) - int.parse(itemList.qtd)).toString();
          if (int.parse(itemList1.qtd) == 0) {
            listProd.remove(itemList1);
          }
        }
      });

      if (listProd.where((element) => element.situacao != "3").length == 0) {
        widget.operacaoModel.situacao = "3";
        await widget.operacaoModel.update();
        if (widget.operacaoModel.tipo == '40') {
          OperacaoModel? opRetirada =
              await OperacaoModel().getPendenteAramazenamento();
          opRetirada.situacao = "3";
          opRetirada.update();
        }

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
    controller!.dispose();
    super.dispose();
  }

  @override
  void initState() {
    listProd = widget.operacaoModel.prods!;
    var count = listProd.where((element) => element.situacao == "3").length;

    getIdUser();
    if (count == listProd.length) {
      Dialogs.showToast(context, "Leitura já realizada");
      this.prodReadSuccess = true;
      this.hasAdress = false;
    }

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
      titleBtn = "Iniciar Armazenamento";
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
            title: Text(widget.titulo),
          ),
          body: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
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
                              height:
                                  (MediaQuery.of(context).size.height * 0.20),
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
                                      : (MediaQuery.of(context).size.width *
                                          0.3),
                                ),
                                height: !hasAdress
                                    ? (MediaQuery.of(context).size.height *
                                        0.10)
                                    : (MediaQuery.of(context).size.height *
                                        0.17),
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
                    child: endRead == null || endRead == ""
                        ? Text(
                            "Nenhum endereço lido",
                            style: TextStyle(fontSize: 40),
                          )
                        : Text(
                            endRead,
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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
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
                            //   color: MaterialStateColor.resolveWith(
                            //     (states) => index % 2 == 0
                            //         ? Colors.white
                            //         : Colors.grey[200],
                            //   ),
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
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (prodReadSuccess)
                      Container(
                        width: 200,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                primary: primaryColor,
                                textStyle: const TextStyle(fontSize: 20)),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Finalizar')),
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
                              endRead = "";
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
          ),
          bottomNavigationBar: BottomBar()),
    );
  }
}