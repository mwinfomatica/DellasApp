import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_blue/flutter_blue.dart';

import 'package:flutter/material.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:leitorqrcode/Apuracao/components/IniciarApuracao.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Components/DashedRect.dart';
import 'package:leitorqrcode/Infrastructure/AtualizarDados/atualizaOp.dart';
import 'package:leitorqrcode/Models/APIModels/Endereco.dart';
import 'package:leitorqrcode/Models/APIModels/MovimentacaoMOdel.dart';
import 'package:leitorqrcode/Models/APIModels/OperacaoModel.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:leitorqrcode/Models/ContextoModel.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
import 'package:leitorqrcode/Services/ProdutosDBService.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:leitorqrcode/Transferencia/RetiradaItens/components/ListItem.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class Inventario extends StatefulWidget {
  @override
  _InventarioState createState() => _InventarioState();
}

class _InventarioState extends State<Inventario> {
  Barcode? result;
  bool reading = false;
  QRViewController? controller;
  final GlobalKey qrAKey = GlobalKey(debugLabel: 'QR');
  final animateListKey = GlobalKey<AnimatedListState>();
  final qtdeProdDialog = TextEditingController();
  String qtdModal = "1";
  List<ProdutoModel> listProd = [];
  String idOperador = "";
  String nroContagem = "01";
  String? endRead = null;
  bool hasAdress = false;
  OperacaoModel? op = null;
  bool showLeituraExterna = false;
  bool leituraExterna = false;
  String tipoLeituraExterna = "endereco";
  bool bluetoothDisconect = true;

  ContextoServices contextoServices = ContextoServices();
  ContextoModel contextoModel =
      ContextoModel(leituraExterna: false, descLeituraExterna: "");

  String textExterno = "";
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? device;
  BluetoothCharacteristic? cNotify4;
  StreamSubscription<List<int>>? sub4;
  Timer? temp;

  Future<void> getContexto() async {
    contextoModel = await contextoServices.getContexto();

    if (contextoModel == null) {
      contextoModel = ContextoModel(leituraExterna: false);
      contextoModel.descLeituraExterna = "Leitor Externo Desabilitado";
    } else {
      setState(() {
        leituraExterna =
            (contextoModel != null && contextoModel.leituraExterna == true);
      });

      flutterBlue.connectedDevices
          .asStream()
          .listen((List<BluetoothDevice> devices) {
        for (BluetoothDevice dev in devices) {
          if (dev.name == "EY-017P") {
            device = dev;
            scanner();
          }
        }
      });
      flutterBlue.scanResults.listen((List<ScanResult> results) {
        for (ScanResult result in results) {
          if (result.device.name == "EY-017P") {
            device = result.device;
            scanner();
          }
        }
      });

      flutterBlue.startScan();
    }
  }

  scanner() async {
    if (device != null) {
      flutterBlue.stopScan();
      try {
        await device!.connect();
      } catch (e) {
        if (e == 'already_connected') {
          bluetoothDisconect = false;
          // throw e;
        } else {
          bluetoothDisconect = true;
        }
        setState(() {});
      } finally {
        // final mtu = await device.mtu.first;
        // await device.requestMtu(512);
      }

      device!.state.listen((BluetoothDeviceState event) {
        if (event == BluetoothDeviceState.disconnected) {
          bluetoothDisconect = true;
        }
        if (event == BluetoothDeviceState.connected) {
          bluetoothDisconect = false;
        }
        setState(() {});
      });

      List<BluetoothService> _services = await device!.discoverServices();

      if (cNotify4 != null) {
        sub4!.cancel();
      }
      for (BluetoothService service in _services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.notify) {
            cNotify4 = characteristic;

            sub4 = cNotify4!.value.listen(
              (value) {
                textExterno += String.fromCharCodes(value);
                if (textExterno != "") {
                  setTimer(textExterno);
                }
              },
            );
            await cNotify4!.setNotifyValue(true);

            setState(() {});
          }
        }
      }
    } else {
      bluetoothDisconect = true;
      setState(() {});
    }
  }

  setTimer(String texto) async {
    // if (temp != null) {
    //   temp.cancel();
    //   temp = null;
    // }

    // temp = Timer.periodic(Duration(seconds: 1), (timer) {
    await _readCodes(texto);
    // timer.cancel();
    // });
  }

  void initState() {
    getIdUser();
    createEditOP();
    getContexto();
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

      op!.prods = [];
      await op!.insert();
    } else {
      op!.situacao = "1";
      await op!.update();
      op!.prods = await ProdutoModel().getByIdOperacao(op!.id!);
      listProd = op!.prods!;

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
    if (sub4 != null) {
      sub4!.cancel();
      // device.disconnect();
    }

    controller?.dispose();
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
            title: ListTile(
              title: Text(
                "Inventário",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              trailing: Container(
                height: 35,
                width: 35,
                child: !leituraExterna
                    ? Container()
                    : bluetoothDisconect
                        ? Icon(
                            Icons.bluetooth_disabled,
                            color: Colors.red,
                          )
                        : Row(
                            children: [
                              Icon(
                                Icons.bluetooth_connected,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
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
              leituraExterna
                  ? showLeituraExterna == false
                      ? BotaoIniciarApuracao(
                          titulo: "Iniciar leitura externa",
                          onPressed: () {
                            if (bluetoothDisconect) {
                              Dialogs.showToast(context,
                                  "Leitor externo não conectado, favor verificar a conexão bluetooth com o dispositivo.",
                                  duration: Duration(seconds: 7),
                                  bgColor: Colors.red.shade200);
                            } else {
                              setState(() {
                                showLeituraExterna = true;
                              });
                            }
                          },
                        )
                      : Stack(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              color: !hasAdress
                                  ? Colors.grey[400]
                                  : Colors.yellow[400],
                              child: Center(
                                child: Text(
                                  !hasAdress
                                      ? "Aguardando leitura \n do Endereço"
                                      : "Aguardando leitura \n dos Produtos",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        )
                  : Stack(
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
                height: 1,
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
                          fontSize: 20,
                        ),
                      )
                    : Text(
                        endRead!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
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
            ],
          ),
          bottomSheet: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    primary: primaryColor,
                    textStyle: const TextStyle(fontSize: 20)),
                onPressed: () async {
                  op!.situacao = "3";
                  await op!.update();
                  await syncOp(context, false);
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

  Future<void> _addItem(ProdutoModel prod) async {
    ProdutoModel produto = listProd.firstWhere(
      (element) =>
          element.idproduto == prod.idproduto &&
          element.barcode == prod.barcode &&
          element.idloteunico == prod.idloteunico &&
          element.lote == prod.lote,
      orElse: () => null as ProdutoModel,
    );

    // if (prod.infq == "s") {
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
          autofocus: true,
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
    // } else {
    //   await geraMoviProd(produto, prod, prod.qtd ?? "1");
    // }
  }

  Future<void> geraMoviProd(
      ProdutoModel produto, ProdutoModel prod, String qtd) async {
    if (produto == null) {
      MovimentacaoModel movi = new MovimentacaoModel();
      movi.id = new Uuid().v4().toUpperCase();
      movi.operacao = op!.tipo;
      movi.idOperacao = op!.id;
      movi.codMovi = op!.nrdoc;
      movi.operador = idOperador;
      movi.endereco = endRead!;
      movi.idProduto = prod.idproduto!;
      movi.qtd = qtd;
      movi.nroContagem = nroContagem;
      DateTime today = new DateTime.now();
      String dateSlug =
          "${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year.toString()} ${today.hour}:${today.minute}:${today.second}";
      movi.dataMovimentacao = dateSlug;
      await movi.insert();

      animateListKey.currentState!.insertItem(0);
      prod.idproduto = prod.idproduto;
      prod.id = new Uuid().v4().toUpperCase();
      prod.idOperacao = op!.id;
      prod.qtd = qtd;
      listProd.add(prod);
      op!.prods!.add(prod);
      await prod.insert();
    } else {
      ProdutoModel prodsop = new ProdutoModel();
      List<MovimentacaoModel> listmovi = [];
      listmovi = await new MovimentacaoModel().getAllByoperacao(op!.id!);
      MovimentacaoModel movi = new MovimentacaoModel();

      movi = listmovi.firstWhere((element) => element.idOperacao == op!.id,
          orElse: () => null as MovimentacaoModel);
      if (movi != null) {
        movi.qtd = (int.parse(movi.qtd!) + int.parse(qtd)).toString();
        await movi.updatebyIdOP();

        prodsop = op!.prods!
            .firstWhere((element) => element.idproduto == produto.idproduto);

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
    ProdutoModel produto = listProd.firstWhere(
        (element) => produtoModel.id == element.id,
        orElse: () => null as ProdutoModel);

    if (int.parse(produtoModel.qtd!) == 1) {
      produtoModel.delete(produtoModel.id!);
      op!.prods!.removeWhere((element) => element.id == produto.id);
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
      movi.getAllByoperacao(op!.id!).then((value) => {
            movi = value[0],
            movi.qtd = (int.parse(produto.qtd!) - 1).toString(),
            movi.updatebyIdOP(),
            setState(() {
              produto.qtd = (int.parse(produto.qtd!) - 1).toString();
            }),
            produto.edit(produto),
            prodsop =
                op!.prods!.where((element) => element.id == produto.id).single,
            setState(() {
              prodsop.qtd = produto.qtd;
            })
          });
    }
  }

  Future<void> _readCodes(code) async {
    textExterno = "";
    if (temp != null) {
      temp!.cancel();
      temp = null;
    }
    try {
      if (!reading) {
        if (hasAdress) {
          reading = true;

          ProdutosDBService produtosDBService = ProdutosDBService();
          bool leituraQR = await produtosDBService.isLeituraQRCodeProduto(code);
          ProdutoModel prodjson = ProdutoModel();

          if (leituraQR) {
            prodjson = ProdutoModel.fromJson(jsonDecode(code));
            prodjson =
                await produtosDBService.getProdutoPedidoByProduto(prodjson);
          } else {
            prodjson = await produtosDBService
                .getProdutoPedidoByBarCodigo(code.trim());
          }

          // var prodjson = json.decode(code);
          // ProdutoModel prod = ProdutoModel.fromJson(prodjson);
          if (prodjson == null) {
            Dialogs.showToast(context, "Produto não encontrado.",
                duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
          } else {
            await _addItem(prodjson);
          }
        } else {
          reading = true;
          if (code.isEmpty || code.length > 20) {
            FlutterBeep.beep(false);
            Dialogs.showToast(context, "Código de barras inválido",
                duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
          } else {
            code = code.trim();

            EnderecoModel? end = await EnderecoModel().getById(code);
            if (end == null) {
              FlutterBeep.beep(false);
              Dialogs.showToast(context, "Endereço não existente.",
                  duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
            } else {
              FlutterBeep.beep();
              Dialogs.showToast(context, "Leitura realiza com sucesso.",
                  duration: Duration(seconds: 5),
                  bgColor: Colors.green.shade200);
              setState(() {
                endRead = code;
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
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      _readCodes(scanData.code);
    });
  }
}
