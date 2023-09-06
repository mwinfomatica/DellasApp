import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:dellas/Components/Bottom.dart';
import 'package:dellas/Components/Constants.dart';
import 'package:dellas/Components/DashedRect.dart';
import 'package:dellas/Models/APIModels/Endereco.dart';
import 'package:dellas/Models/APIModels/MovimentacaoMOdel.dart';
import 'package:dellas/Models/APIModels/OperacaoModel.dart';
import 'package:dellas/Models/APIModels/ProdutoModel.dart';
import 'package:dellas/Shared/Dialog.dart';
import 'package:dellas/Transferencia/RetiradaItens/components/ListItem.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class Inventario extends StatefulWidget {
  @override
  _InventarioState createState() => _InventarioState();
}

class _InventarioState extends State<Inventario> {
  late Barcode result;
  bool reading = false;
  QRViewController? controller;
  final GlobalKey qrAKey = GlobalKey(debugLabel: 'QR');
  final animateListKey = GlobalKey<AnimatedListState>();
  final qtdeProdDialog = TextEditingController();
  String qtdModal = "1";
  List<ProdutoModel> listProd = [];
  String idOperador = "";
  String nroContagem = "01";
  String? endRead;
  bool hasAdress = false;
  OperacaoModel op = OperacaoModel();

  void initState() {
    getIdUser();
    createEditOP();

    super.initState();
  }

  void createEditOP() async {
    op = await OperacaoModel().getOpInventario();

    if (op == null) {
      op = new OperacaoModel(
        id: new Uuid().v4().toUpperCase(),
        cnpj: '11.377.757/0001-15',
        nrdoc: new Uuid().v4().toUpperCase(),
        situacao: "1",
        tipo: "90",
      );

      op.prods = [];
      await op.insert();
    } else {
      op.situacao = "1";
      await op.update();
      op.prods = await ProdutoModel().getByIdOperacao(op.id);
      listProd = op.prods!;

      for (int i = 0; i < listProd.length; i++) {
        animateListKey.currentState!.insertItem(i);
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
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      if (!Platform.isAndroid) {
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
            title: Text("Inventário"),
          ),
          body: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: (MediaQuery.of(context).size.height * 0.05),
                child: Text(
                  "Nro Contagem",
                  style: TextStyle(),
                ),
              ),
              Container(
                height: (MediaQuery.of(context).size.height * 0.05),
                width: (MediaQuery.of(context).size.width * 0.2),
                child: Padding(
                    padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                    child: DropdownButton<String>(
                      value: nroContagem,
                      icon: const Icon(Icons.arrow_downward),
                      iconSize: 20,
                      elevation: 16,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                      ),
                      underline: Container(
                        height: 1,
                        color: Colors.transparent,
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          nroContagem = newValue!;
                        });
                      },
                      items: <String>[
                        '01',
                        '02',
                        '03',
                        '04',
                        '05',
                        '06',
                        '07',
                        '08',
                        '09',
                        '10'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    )),
              ),
              Stack(
                children: [
                  Container(
                    height: (MediaQuery.of(context).size.height * 0.20),
                    child: _buildQrView(context),
                  ),
                  Center(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        vertical: !hasAdress
                            ? (MediaQuery.of(context).size.height * 0.05)
                            : (MediaQuery.of(context).size.height * 0.01),
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
                              style:
                                  TextStyle(fontSize: 25, color: Colors.white),
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
                width: MediaQuery.of(context).size.width,
                color: !hasAdress ? Colors.grey[300] : Colors.yellow[300],
                child: endRead == null
                    ? Text(
                        "Nenhum endereço lido",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 40,
                        ),
                      )
                    : Text(
                        endRead!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 40, fontWeight: FontWeight.bold),
                      ),
              ),
              Expanded(
                child: AnimatedList(
                  key: animateListKey,
                  itemBuilder: (context, index, animation) {
                    return ListItem(
                      produto: listProd[index],
                      ontap: () {
                        _removeItem(listProd[index], index);
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
                onPressed: () async {
                  op.situacao = "3";
                  await op.update();
                  Navigator.pop(context);
                },
                child: Text('Finalizar'),
              ),
              if (hasAdress)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: primaryColor,
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                  onPressed: () {
                    setState(() {
                      endRead = null;
                      hasAdress = false;
                    });
                  },
                  child: Text('Alterar endereço'),
                ),
            ],
          ),
          bottomNavigationBar: BottomBar()),
    );
  }

  Widget _buildQrView(BuildContext context) {
    return QRView(
      key: qrAKey,
      onQRViewCreated: _onQRViewCreated,
    );
  }

  void _addItem(ProdutoModel prod) async {
    ProdutoModel? produto = listProd.firstWhere(
        (element) => element.idproduto == prod.id,
        orElse: () => ProdutoModel());

    if (prod.infq == "s") {
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
                geraMoviProd(produto, prod, qtdeProdDialog.text);
                Navigator.pop(context);
              },
              child: Text("Salvar"),
            ),
          ],
          elevation: 24.0,
        ),
      );
    } else {
      geraMoviProd(produto, prod, "1");
    }
  }

  void geraMoviProd(ProdutoModel produto, ProdutoModel prod, String qtd) async {
    if (produto == null) {
      MovimentacaoModel movi = new MovimentacaoModel();
      movi.id = new Uuid().v4().toUpperCase();
      movi.operacao = op.tipo;
      movi.idOperacao = op.id;
      movi.codMovi = op.nrdoc;
      movi.operador = idOperador;
      movi.endereco = endRead!;
      movi.idProduto = prod.id;
      movi.qtd = qtd;
      movi.nroContagem = nroContagem;
      DateTime today = new DateTime.now();
      String dateSlug =
          "${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year.toString()} ${today.hour}:${today.minute}:${today.second}";
      movi.dataMovimentacao = dateSlug;
      await movi.insert();

      animateListKey.currentState!.insertItem(0);
      prod.idproduto = prod.id;
      prod.id = new Uuid().v4().toUpperCase();
      prod.idOperacao = op.id;
      prod.qtd = qtd;
      listProd.add(prod);
      op.prods!.add(prod);
      await prod.insert();
    } else {
      ProdutoModel prodsop = new ProdutoModel();
      List<MovimentacaoModel> Listmovi = [];
      Listmovi = await new MovimentacaoModel().getAllByoperacao(op.id);
      MovimentacaoModel movi = new MovimentacaoModel();

      movi = Listmovi.firstWhere((element) => element.idOperacao == op.id,
          orElse: null);
      if (movi != null) {
        movi.qtd = (int.parse(movi.qtd) + int.parse(qtd)).toString();
        await movi.updatebyIdOP();

        prodsop = op.prods!
            .where((element) => element.idproduto == produto.idproduto)
            .single;

        setState(() {
          prod.qtd = prod.qtd == null ? "1" : prod.qtd;
          produto.qtd = movi.qtd;
          prodsop.qtd = movi.qtd;
          produto.edit(produto);
        });
      } else {
        return;
      }
    }
  }

  void _removeItem(ProdutoModel produtoModel, index) async {
    ProdutoModel? produto = listProd.firstWhere(
        (element) => produtoModel.id == element.id,
        orElse: () => ProdutoModel());

    if (int.parse(produtoModel.qtd) == 1) {
      produtoModel.delete(produtoModel.id);
      op.prods!.removeWhere((element) => element.id == produto.id);
      animateListKey.currentState!.removeItem(
        index,
        (context, animation) => ListItem(
          produto: produto,
          animation: animation,
        ),
      );
    } else {
      ProdutoModel prodsop = new ProdutoModel();
      MovimentacaoModel movi = new MovimentacaoModel();
      movi.getAllByoperacao(op.id).then((value) => {
            movi = value[0],
            movi.qtd = (int.parse(produto.qtd) - 1).toString(),
            movi.updatebyIdOP(),
            setState(() {
              produto.qtd = (int.parse(produto.qtd) - 1).toString();
            }),
            produto.edit(produto),
            prodsop =
                op.prods!.where((element) => element.id == produto.id).single,
            setState(() {
              prodsop.qtd = produto.qtd;
            })
          });
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
      controller.resumeCamera();
    });
    controller.scannedDataStream.listen((scanData) async {
      try {
        if (!reading) {
          if (hasAdress) {
            reading = true;
            var prodjson = json.decode(scanData.code!);
            ProdutoModel prod = ProdutoModel.fromJson(prodjson);
            _addItem(prod);
          } else {
            reading = true;
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
                  endRead = scanData.code;
                  hasAdress = true;
                });
              }
            }
          }

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
}
