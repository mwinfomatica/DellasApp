import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_blue/flutter_blue.dart';

import 'package:flutter/material.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:leitorqrcode/Apuracao/Apuracao.dart';
import 'package:leitorqrcode/Components/QR_LeituraExterna.dart';
import 'package:leitorqrcode/DevolucaoOP/DevolucaoOP.dart';
import 'package:leitorqrcode/Models/APIModels/OperacaoModel.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:leitorqrcode/Models/ContextoModel.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
import 'package:leitorqrcode/Services/ProdutoService.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:leitorqrcode/Home/Home.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:uuid/uuid.dart';
import 'package:f_logs/f_logs.dart' as logging;

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
  ContextoServices contextoServices = ContextoServices();
  ContextoModel contextoModel = ContextoModel(
    leituraExterna: false,
  );
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  String textoCentral = "Posicione a câmera \n em frente ao código QR";
  String resultado = "";
  String titlePageOp = "";
  bool reading = false;

  TextEditingController inputController = TextEditingController();
  FocusNode inputFocusNode = FocusNode();
  AnimationController? animationController;
  bool progress = false;
  bool bluetoothDisconect = true;

  String textExterno = "";
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? device;
  BluetoothCharacteristic? cNotify2;
  StreamSubscription<List<int>>? sub2;
  Timer? temp;

  Future<void> getContexto() async {
    contextoModel = await contextoServices.getContexto();

    // logging.FLog.logThis(
    //   text: "Dispositivos selecionado UUID ${contextoModel.uuidDevice}",
    //   type: logging.LogLevel.SEVERE,
    //   dataLogType: logging.DataLogType.DEVICE.toString(),
    // );

    if (contextoModel == null) {
      contextoModel = ContextoModel(leituraExterna: false);
      contextoModel.descLeituraExterna = "Leitor Externo Desabilitado";
    } else {
      flutterBlue.connectedDevices
          .asStream()
          .listen((List<BluetoothDevice> devices) {
        // logging.FLog.logThis(
        //   text: "Dispositivos conectados - Quantidade: ${devices.length}",
        //   type: logging.LogLevel.SEVERE,
        //   dataLogType: logging.DataLogType.DEVICE.toString(),
        // );

        for (BluetoothDevice dev in devices) {
          // logging.FLog.logThis(
          //   text: "Dispositivo Conectado ${dev.name} - UUID ${dev.id.id}",
          //   type: logging.LogLevel.SEVERE,
          //   dataLogType: logging.DataLogType.DEVICE.toString(),
          // );

          if (contextoModel.uuidDevice!.isNotEmpty &&
              dev.id.id.trim() == contextoModel.uuidDevice!.trim()) {
            device = dev;
            scanner();
          }
        }
      });

      flutterBlue.scanResults.listen((List<ScanResult> results) {
        // logging.FLog.logThis(
        //   text: "Dispositivos disponiveis - Quantidade: ${results.length}",
        //   type: logging.LogLevel.SEVERE,
        //   dataLogType: logging.DataLogType.DEVICE.toString(),
        // );

        for (ScanResult result in results) {
          // logging.FLog.logThis(
          //   text:
          //       "Dispositivo disponiveis ${result.device.name} - UUID ${result.device.id.id}",
          //   type: logging.LogLevel.SEVERE,
          //   dataLogType: logging.DataLogType.DEVICE.toString(),
          // );

          if (contextoModel.uuidDevice!.isNotEmpty &&
              result.device.id.id.trim() == contextoModel.uuidDevice!.trim()) {
            device = result.device;
            scanner();
          }
        }
      });

      flutterBlue.startScan();
    }
  }

  setTimer(String texto) {
    if (temp != null) {
      temp!.cancel();
      temp = null;
    }

    temp = Timer.periodic(Duration(seconds: 1), (timer) {
      _readCodes(texto);
      timer.cancel();
    });
  }

  scanner() async {
    if (device != null) {
      await flutterBlue.stopScan();
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

      if (cNotify2 != null) {
        sub2!.cancel();
      }

      for (BluetoothService service in _services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.notify) {
            cNotify2 = characteristic;

            sub2 = cNotify2!.value.listen(
              (value) {
                textExterno += String.fromCharCodes(value);
                if (textExterno != "") {
                  setTimer(textExterno);
                }
              },
            );
            await cNotify2!.setNotifyValue(true);

            setState(() {});
          }
        }
      }
    } else {
      bluetoothDisconect = true;
      setState(() {});
    }
  }

  void _readCodes(String scanData) async {
    textExterno = "";
    if (temp != null) {
      temp!.cancel();
      temp = null;
    }

    try {
      if (!reading) {
        setState(() {
          progress = true;
        });

        reading = true;

        OperacaoModel opRead = OperacaoModel.fromJson(jsonDecode(scanData));

        if (widget.tipo == 1) {
          OperacaoModel? opDB =
              await new OperacaoModel().getModelById(opRead.id!);

          if (opDB == null || opDB.id == null) {
            opRead.prods = await _getProdutosInServer(opRead.id!);

            if (opRead.prods != null) {
              await opRead.insert();

              for (int i = 0; i < opRead.prods!.length; i++) {
                ProdutoModel? prodDB =
                    await new ProdutoModel().getById(opRead.prods![i].id!);
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
            opRead.prods = await ProdutoModel().getByIdOperacao(opRead.id!);
            if (opRead.prods == null || opRead.prods!.length == 0) {
              opRead.prods = await _getProdutosInServer(opRead.id!);
              for (int i = 0; i < opRead.prods!.length; i++) {
                ProdutoModel? prodDB =
                    await new ProdutoModel().getById(opRead.prods![i].id!);
                if (prodDB == null || prodDB.id == null) {
                  opRead.prods![i].idOperacao = opRead.id;
                  await opRead.prods![i].insert();
                } else {
                  opRead.prods![i] = prodDB;
                }
              }
            }
          }

          getTitlePageOp(opRead.tipo!);

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
                      (opRead.nrdoc != null ? "\n" + opRead.nrdoc! : ""),
                  operacaoModel: opRead,
                ),
              ),
            );
          }
        } else if (widget.tipo == 2) {
          OperacaoModel? opDB = await new OperacaoModel()
              .getModelByNumDocTipo(opRead.nrdoc!, "20");

          if (opDB == null || opDB.id == null) {
            opRead.prods = await _getProdutosInServerDevolucao(opRead.id!);

            if (opRead.prods != null && opRead.prods!.length > 0) {
              OperacaoModel opDev = OperacaoModel(
                id: new Uuid().v4().toUpperCase(),
                cnpj: "03316661000119",
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

              opDev.prods = await ProdutoModel().getByIdOperacao(opDev.id!);
              await FlutterBeep.beep();

              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => DevolucaoOP(
                    titulo: titlePageOp +
                        (opDev.nrdoc != null ? "\n" + opDev.nrdoc! : ""),
                    operacaoModel: opDev,
                  ),
                ),
              );
            } else {
              await FlutterBeep.beep(false);
              Dialogs.showToast(
                  context, "Nenhum produto encontrado para o pedido.",
                  duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => HomeScreen(),
                  ),
                  (route) => false);
            }
          } else {
            getTitlePageOp("20");

            opDB.prods = await ProdutoModel().getByIdOperacao(opDB.id!);

            await FlutterBeep.beep();

            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => DevolucaoOP(
                  titulo: titlePageOp +
                      (opDB.nrdoc != null ? "\n" + opDB.nrdoc! : ""),
                  operacaoModel: opDB,
                ),
              ),
            );
          }
        } else if (widget.tipo == 3) {
          OperacaoModel? opDB = await new OperacaoModel()
              .getModelByNumDocTipo(opRead.nrdoc!, "22");

          if (opDB == null || opDB.id == null) {
            opRead.prods = await _getProdutosInServerDevolucao(opRead.id!);

            if (opRead.prods != null && opRead.prods!.length > 0) {
              OperacaoModel opDev = OperacaoModel(
                id: new Uuid().v4().toUpperCase(),
                cnpj: "03316661000119",
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

              opDev.prods = await ProdutoModel().getByIdOperacao(opDev.id!);
              await FlutterBeep.beep();

              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => DevolucaoOP(
                    titulo: titlePageOp +
                        (opDev.nrdoc != null ? "\n" + opDev.nrdoc! : ""),
                    operacaoModel: opDev,
                  ),
                ),
              );
            } else {
              await FlutterBeep.beep(false);
              Dialogs.showToast(
                  context, "Nenhum produto encontrado para o pedido.",
                  duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => HomeScreen(),
                  ),
                  (route) => false);
            }
          } else {
            getTitlePageOp("21");

            opDB.prods = await ProdutoModel().getByIdOperacao(opDB.id!);

            await FlutterBeep.beep();

            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => DevolucaoOP(
                  titulo: titlePageOp +
                      (opDB.nrdoc != null ? "\n" + opDB.nrdoc! : ""),
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

        setState(() {
          progress = false;
        });
      }
    } catch (ex) {
      Timer(Duration(seconds: 2), () {
        reading = false;
        inputFocusNode.requestFocus();
        inputController.clear();
      });
      FlutterBeep.beep(false);

      setState(() {
        progress = false;
        textoCentral = "Código \"QR\" não reconhecido \n tente novamente";
      });
      Dialogs.showToast(context, "Código não reconhecido \n tente novamente",
          duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
    }
  }

  @override
  void dispose() {
    if (sub2 != null) {
      sub2!.cancel();
      // device.disconnect();
    }
    controller!.dispose();
    super.dispose();
  }

  @override
  void initState() {
    getContexto();

    super.initState();
  }

  @override
  void reassemble() {
    if (!Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
    super.reassemble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: contextoModel != null && !contextoModel.leituraExterna!
            ? Stack(
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
                                if (controller != null)
                                  controller!.toggleFlash();

                                setState(() {});
                              },
                              child: FutureBuilder(
                                // future: controller != null ? controller.getFlashStatus() : false,
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
              )
            : QRLeituraExterna(
                progress: progress,
                bluetoothDisconect: bluetoothDisconect,
                bluetoothName: device != null ? device!.name : "",
                device: device,
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
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      // if (widget.tipo == 1) {
      _readCodes(scanData.code!);

      // }
    });
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
    else if (tipo == "72")
      titlePageOp = "Retirada de Carga";
    else if (tipo == "30")
      titlePageOp = "Devolução de Venda";
    else if (tipo == "41")
      titlePageOp = "Saída de Transferência";
    else if (tipo == "40")
      titlePageOp = "Entrada de Transferência";
    else if (tipo == "90") titlePageOp = "Contagem de Inventário";
  }

  Future<List<ProdutoModel>> _getProdutosInServer(String idOperacao) async {
    ProdutoService produtoService = new ProdutoService();

    if (idOperacao.isNotEmpty)
      return await produtoService.getProdutos(idOperacao);
    else
      return Future.value(<ProdutoModel>[]);
  }

  Future<List<ProdutoModel>> _getProdutosInServerDevolucao(
      String idOperacao) async {
    ProdutoService produtoService = new ProdutoService();

    if (idOperacao.isNotEmpty)
      return await produtoService.getProdutosDevolucao(idOperacao);
    else
      return Future.value(<ProdutoModel>[]);
  }
}
