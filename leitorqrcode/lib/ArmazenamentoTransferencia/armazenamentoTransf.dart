import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'package:flutter/material.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:leitorqrcode/ArmazenamentoTransferencia/components/IniciarArmazenamentoTransf.dart';
import 'package:leitorqrcode/ArmazenamentoTransferencia/components/info_qtde_armz.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Components/DashedRect.dart';
import 'package:leitorqrcode/Infrastructure/AtualizarDados/atualizaOp.dart';
import 'package:leitorqrcode/Models/APIModels/Endereco.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:leitorqrcode/Models/ContextoModel.dart';
import 'package:leitorqrcode/Models/armprodModel.dart';
import 'package:leitorqrcode/Models/pendenteArmazModel.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
import 'package:leitorqrcode/Services/ProdutosDBService.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:leitorqrcode/Transferencia/Transferencias.dart';
import 'package:leitorqrcode/Transferencia/components/TransferenciaMenu.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ArmazenamentoTransf extends StatefulWidget {
  const ArmazenamentoTransf({
    Key? key,
    @required this.listPendente,
    this.listarm,
    this.end,
  }) : super(key: key);

  final List<pendenteArmazModel>? listPendente;
  final List<armprodModel>? listarm;
  final String? end;

  @override
  State<ArmazenamentoTransf> createState() => _ArmazenamentoTransfState();
}

class _ArmazenamentoTransfState extends State<ArmazenamentoTransf> {
  Barcode? result;
  bool readingArm = false;
  bool showCameraArm = false;
  bool showLeituraExternaArm = false;
  bool hasAdressArm = false;
  bool prodReadSuccessArm = false;
  bool isManual = false;
  bool leituraExternaArm = false;
  Random r = new Random();
  String endRead = '';
  String titleBtn = "Iniciar Armazenamento";
  String tipoLeituraExterna = "endereco";
  String idOperador = "";
  final animateListKey = GlobalKey<AnimatedListState>();
  final qtdeProdDialog = TextEditingController();
  final GlobalKey qrAKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  Timer? temp;
  bool bluetoothDisconect = true;

  ContextoServices contextoServices = ContextoServices();
  ContextoModel contextoModel =
      ContextoModel(leituraExterna: false, descLeituraExterna: "");

  List<armprodModel> armlist = [];

  Widget _buildQrView(BuildContext context) {
    return QRView(
      key: qrAKey,
      onQRViewCreated: _onQRViewCreatedarm,
    );
  }

  String textExterno = "";
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? device;
  BluetoothCharacteristic? cNotify;
  StreamSubscription<List<int>>? sub;
  bool isExternalDeviceEnabled = false;
  bool isCollectModeEnabled = false;
  bool isCameraEnabled = false;

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    bool collectMode = prefs.getBool('collectMode') ?? false;
    bool cameraEnabled = prefs.getBool('useCamera') ?? false;
    bool externalDeviceEnabled = prefs.getBool('leituraExterna') ?? false;

    setState(() {
      isCollectModeEnabled = collectMode;
      isCameraEnabled = cameraEnabled;
      isExternalDeviceEnabled = externalDeviceEnabled;
      // Atualiza o título do botão com base no modo coletor
      titleBtn = isCollectModeEnabled
          ? "Aguardando leitura do leitor"
          : "Iniciar Armazenamento";
    });
    print('o modo coletor é $isCollectModeEnabled');
  }

  Future<void> getContexto() async {
    contextoModel = await contextoServices.getContexto();

    if (contextoModel == null) {
      contextoModel = ContextoModel(leituraExterna: false);
      contextoModel.descLeituraExterna = "Leitor Externo Desabilitado";
    } else {
      setState(() {
        contextoModel.enderecoGrupo = true;
        leituraExternaArm =
            (contextoModel != null && contextoModel.leituraExterna == true);
      });

      List<BluetoothDevice> conectados = await flutterBlue.connectedDevices;
      if (conectados != null && conectados.length > 0) {
        device = conectados.firstWhere(
          (BluetoothDevice dev) => dev.id.id == contextoModel.uuidDevice,
          orElse: () => null as BluetoothDevice,
        );
      }
      if (device != null) {
        scannerArm();
      } else {
        flutterBlue.scanResults.listen((List<ScanResult> results) {
          for (ScanResult result in results) {
            if (contextoModel.uuidDevice!.isNotEmpty &&
                result.device.id.id == contextoModel.uuidDevice) {
              device = result.device;
              scannerArm();
            }
          }
        });

        flutterBlue.startScan();
      }
    }
  }

  scannerArm() async {
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

      if (cNotify != null) {
        sub!.cancel();
      }
      for (BluetoothService service in _services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.notify) {
            cNotify = characteristic;

            sub = cNotify!.value.listen(
              (value) {
                textExterno += String.fromCharCodes(value);
                if (textExterno != "") {
                  setTimerAr(textExterno);
                }
              },
            );
            await cNotify!.setNotifyValue(true);

            setState(() {});
          }
        }
      }
    } else {
      bluetoothDisconect = true;
      setState(() {});
    }
  }

  setTimerAr(String texto) async {
    // if (temp != null) {
    //   temp.cancel();
    //   temp = null;
    // }

    // temp = Timer.periodic(Duration(seconds: 1), (timer) async {
    await _readCodesArm(texto);
    // timer.cancel();
    // });
  }

  void _onQRViewCreatedarm(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      await _readCodesArm(scanData.code!);
    });
  }

  Future<void> _readCodesArm(String code) async {
    textExterno = "";
    try {
      if (!readingArm) {
        readingArm = true;
        bool showDialogQtd = false;

        //Atualizar produto & Criar movimentação
        if (hasAdressArm) {
          bool isOK = true;

          ProdutosDBService produtosDBService = ProdutosDBService();
          bool leituraQR = await produtosDBService.isLeituraQRCodeProduto(code);
          ProdutoModel prodRead = ProdutoModel();

          if (leituraQR) {
            prodRead = ProdutoModel.fromJson(jsonDecode(code));
            prodRead =
                await produtosDBService.getProdutoPedidoByProduto(prodRead);
          } else {
            prodRead = await produtosDBService
                .getProdutoPedidoByBarCodigo(code.trim());
          }

          if (prodRead != null) {
            if (isOK) {
              if (prodRead.infq == "s") {
                qtdeProdDialog.text = "";
                // showDialogQtd = true;
                // showDialog(
                //   context: context,
                //   barrierDismissible: false,
                //   builder: (_) => AlertDialog(
                //     title: Text(
                //       "Informe a quantidade do produto scaneado",
                //       style: TextStyle(fontWeight: FontWeight.w500),
                //     ),
                //     content: TextField(
                //       controller: qtdeProdDialog,
                //       keyboardType: TextInputType.number,
                //       autofocus: true,
                //       decoration: InputDecoration(
                //           border: OutlineInputBorder(),
                //           focusedBorder: OutlineInputBorder(
                //             borderSide: BorderSide(color: primaryColor),
                //           ),
                //           labelText: 'Qtde'),
                //     ),
                //     actions: [
                //       TextButton(
                //         child: const Text('Cancelar'),
                //         onPressed: () async {
                //           Navigator.pop(context);
                //         },
                //       ),
                //       TextButton(
                //         child: Text("Salvar"),
                //         onPressed: () async {
                //           await saveArmz(
                //               prodRead,
                //               (prodRead.qtd != null &&
                //                       prodRead.qtd != "" &&
                //                       prodRead.qtd != "0"
                //                   ? prodRead.qtd!
                //                   : "1"));
                //           Navigator.pop(context);
                //         },
                //       ),
                //     ],
                //     elevation: 24.0,
                //   ),
                // );

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => infoQtdArmz(
                      listPendente: widget.listPendente,
                      listarm: armlist,
                      endRead: endRead,
                      idOperador: idOperador,
                      prodRead: prodRead,
                      qtdeProdDialog: qtdeProdDialog,
                    ),
                  ),
                  (route) => false,
                );

                return;
              } else {
                await saveArmz(
                    prodRead,
                    (prodRead.qtd != null &&
                            prodRead.qtd != "" &&
                            prodRead.qtd != "0"
                        ? prodRead.qtd!
                        : "1"));
              }
            }
          } else
            Dialogs.showToast(context, "Produto não encontrado",
                duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
        } else {
          //Habilita camera
          if (code.isEmpty || code.length > 20) {
            FlutterBeep.beep(false);
            Dialogs.showToast(context, "Código de barras inválido",
                duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
          } else {
            code = code.trim();
            EnderecoModel? end = await EnderecoModel().getById(code);

            if (end == null) {
              FlutterBeep.beep(false);
              Dialogs.showToast(context,
                  "Endereço não localizado, verifique a atualização na tela de configurações.",
                  duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
            } else {
              FlutterBeep.beep();

              setState(() {
                endRead = code;
                hasAdressArm = true;
              });
            }
          }
        }
        Timer(Duration(seconds: 1), () {
          readingArm = false;
        });
      }
    } catch (ex) {
      Timer(Duration(seconds: 1), () {
        readingArm = false;
      });
      FlutterBeep.beep(false);
      Dialogs.showToast(context,
          "Código não reconhecido \n favor realizar a leitura novamente",
          duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
    }
  }

  Future<void> saveArmz(ProdutoModel prod, String qtde) async {
    armprodModel arm = armprodModel();

    pendenteArmazModel item = widget.listPendente!.firstWhere(
        (element) =>
            element.idProd == prod.idproduto &&
            element.idtransf == widget.listPendente![0].idtransf &&
            element.lote == prod.lote &&
            element.valid == (prod.vali ?? "") &&
            element.situacao == "0",
        orElse: () => null as pendenteArmazModel);
    int qt = 0;
    if (item != null) {
      qt = int.parse(item.qtd!) - int.parse(qtde);
      if (qt > 0) {
        item.qtd = qt.toString();
      }
    } else {
      FlutterBeep.beep(false);
      Dialogs.showToast(context,
          "Produto não listado para Armazenamento. \n Armazenamento deste produto já concluído.",
          duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
      return;
    }

    setState(() {});
    if (armlist.isNotEmpty) {
      arm = armlist.firstWhere(
          (e) =>
              e.idProdArm == prod.idproduto &&
              e.endArm == endRead &&
              e.loteArm == prod.lote &&
              e.validArm == (prod.vali ?? ""),
          orElse: () => null as armprodModel);
    }
    if (arm == null || arm.idProdArm == null) {
      arm = new armprodModel(
          idArm: new Uuid().v4().toUpperCase(),
          endArm: endRead,
          idProdArm: prod.idproduto!,
          idtransfArm: widget.listPendente![0].idtransf,
          loteArm: prod.lote!,
          nomeProdArm: prod.nome!,
          qtdArm: qtde,
          validArm: prod.vali ?? "",
          barcodeArm: prod.barcode!);

      await arm.insert();
      armlist.add(arm);
    } else {
      arm.qtdArm = (int.parse(arm.qtdArm!) + int.parse(qtde)).toString();
      await arm.update();
    }

    if (qt == 0) {
      widget.listPendente!.removeWhere((e) => e.id == item.id);
      await item.delete(item.id!);
    }

    setState(() {});

    var Gitem = widget.listPendente!.where((element) =>
        element.idProd == prod.idproduto &&
        element.idtransf == arm.idtransfArm &&
        element.end == endRead &&
        element.lote == arm.loteArm &&
        element.valid == (arm.validArm ?? "") &&
        element.situacao == "1");

    if (Gitem.isEmpty) {
      pendenteArmazModel pendenteOk = new pendenteArmazModel(
          id: new Uuid().v4().toUpperCase(),
          barcode: prod.barcode!,
          end: endRead,
          idProd: prod.idproduto!,
          idoperador: idOperador,
          idtransf: arm.idtransfArm,
          situacao: "1",
          valid: prod.vali ?? "",
          lote: prod.lote!,
          nomeProd: prod.nome!,
          qtd: qtde);
      widget.listPendente!.add(pendenteOk);
    } else {
      pendenteArmazModel itemOk = Gitem.first;
      itemOk.qtd = (int.parse(itemOk.qtd!) + int.parse(qtde)).toString();
    }

    if (widget.listPendente!.where((e) => e.situacao == "0").length == 0) {
      Dialogs.showToast(context, "Leitura concluída",
          duration: Duration(seconds: 5), bgColor: Colors.green.shade200);
      setState(() {
        this.hasAdressArm = false;
        this.prodReadSuccessArm = true;
      });
    }

    setState(() {});
  }

  void getIdUser() async {
    SharedPreferences userlogged = await SharedPreferences.getInstance();
    this.idOperador = userlogged.getString('IdUser')!;
  }

  @override
  void dispose() {
    if (sub != null) {
      sub!.cancel();
      //device.disconnect();
    }
    controller?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    getIdUser();
    getContexto();
    _loadPreferences(); // Carrega as preferências para o estado do widget

    if (widget.end != null && widget.end != "") {
      endRead = widget.end!;
      hasAdressArm = true;
    }

    armlist = widget.listarm!;

    var count =
        widget.listPendente!.where((element) => element.situacao == "1").length;
    if (count == widget.listPendente!.length) {
      Dialogs.showToast(context, "Leitura já realizada");
      this.prodReadSuccessArm = true;
      this.hasAdressArm = false;
    }

    setState(() {});
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
    late bool visible;

    return SafeArea(
      child: PopScope(
        canPop: false,
        onPopInvoked: (isPop) {
          if (!isPop) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => MenuTransferencia(),
              ),
              (route) => false,
            );
          }
        },
        child: Scaffold(
            appBar: AppBar(
              backgroundColor: primaryColor,
              title: ListTile(
                title: RichText(
                  maxLines: 2,
                  text: TextSpan(
                    text: "40 - Aramazenamento Transferência",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                trailing: !leituraExternaArm
                    ? Container(
                        height: 1,
                        width: 1,
                      )
                    : Container(
                        height: 35,
                        width: 35,
                        child: bluetoothDisconect
                            ? Icon(
                                Icons.bluetooth_disabled,
                                color: Colors.red,
                              )
                            : Icon(
                                Icons.bluetooth_connected,
                                color: Colors.blue,
                              ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
              ),
            ),
            body: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (isCollectModeEnabled)
                    Offstage(
                      offstage: true,
                      child: BarcodeKeyboardListener(
                        bufferDuration: Duration(milliseconds: 50),
                        onBarcodeScanned: (barcode) async {
                          print(barcode);
                          await _readCodesArm(barcode);
                        },
                        child: TextField(
                          autofocus: true,
                          keyboardType: TextInputType.none,
                        ),
                      ),
                    ),
                  if (!prodReadSuccessArm)
                    isManual
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              autofocus: true,
                              onSubmitted: (value) async {
                                await _readCodesArm(value);
                                setState(() {
                                  isManual = false;
                                });
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Digite o código',
                              ),
                            ),
                          )
                        : isCollectModeEnabled
                            ? showLeituraExternaArm == false
                                ? Stack(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(10),
                                        color: !hasAdressArm
                                            ? Colors.grey[400]
                                            : Colors.yellow[400],
                                        child: Center(
                                          child: Text(
                                            !hasAdressArm
                                                ? "Aguardando leitura do Endereço"
                                                : "Aguardando leitura dos Produtos",
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
                                        padding: EdgeInsets.all(10),
                                        color: !hasAdressArm
                                            ? Colors.grey[400]
                                            : Colors.yellow[400],
                                        child: Center(
                                          child: Text(
                                            !hasAdressArm
                                                ? "Aguardando leitura do Endereço"
                                                : "Aguardando leitura dos Produtos",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                            : leituraExternaArm
                                ? showLeituraExternaArm == false
                                    ? BotaoIniciarArmazenamentoTransf(
                                        titulo:
                                            titleBtn == null ? "" : titleBtn,
                                        onPressed: () {
                                          if (bluetoothDisconect) {
                                            Dialogs.showToast(context,
                                                "Leitor externo não conectado, favor verificar a conexão bluetooth com o dispositivo.",
                                                duration: Duration(seconds: 7),
                                                bgColor: Colors.red.shade200);
                                          } else {
                                            setState(() {
                                              showLeituraExternaArm = true;
                                            });
                                          }
                                        },
                                      )
                                    : Stack(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(10),
                                            color: !hasAdressArm
                                                ? Colors.grey[400]
                                                : Colors.yellow[400],
                                            child: Center(
                                              child: Text(
                                                !hasAdressArm
                                                    ? "Aguardando leitura do Endereço"
                                                    : "Aguardando leitura dos Produtos",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(fontSize: 18),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                : showCameraArm == false
                                    ? BotaoIniciarArmazenamentoTransf(
                                        titulo:
                                            titleBtn == null ? "" : titleBtn,
                                        onPressed: () {
                                          setState(() {
                                            showCameraArm = true;
                                          });
                                        },
                                      )
                                    : Stack(
                                        children: [
                                          Container(
                                            height: (MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.20),
                                            child: _buildQrView(context),
                                            // child: Container(),
                                          ),
                                          Center(
                                            child: Container(
                                              margin: EdgeInsets.symmetric(
                                                vertical: !hasAdressArm
                                                    ? (MediaQuery.of(context)
                                                            .size
                                                            .height *
                                                        0.05)
                                                    : (MediaQuery.of(context)
                                                            .size
                                                            .height *
                                                        0.01),
                                                horizontal: !hasAdressArm
                                                    ? 25
                                                    : (MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.3),
                                              ),
                                              height: !hasAdressArm
                                                  ? (MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      0.10)
                                                  : (MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      0.17),
                                              child: DashedRect(
                                                color: primaryColor,
                                                gap: !hasAdressArm ? 10 : 25,
                                                strokeWidth:
                                                    !hasAdressArm ? 2 : 5,
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    vertical: 10,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      hasAdressArm
                                                          ? "Leia o QRCode \n do produto"
                                                          : "Realize a leitura do \n Endereço",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                          fontSize: 25,
                                                          color: Colors.white),
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
                  prodReadSuccessArm
                      ? Container(
                          width: MediaQuery.of(context).size.width,
                          color: Colors.yellow[300],
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "Leitura concluída",
                              style: TextStyle(
                                  fontSize: 25, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : Container(
                          padding: EdgeInsets.all(10),
                          color: !hasAdressArm
                              ? Colors.grey[300]
                              : Colors.yellow[300],
                          child: Container(
                            width: MediaQuery.of(context).size.width - 10,
                            child: endRead == null
                                ? Text(
                                    "Nenhum endereço lido",
                                    style: TextStyle(fontSize: 25),
                                    textAlign: TextAlign.center,
                                  )
                                : Text(
                                    endRead,
                                    style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                        ),
                  SizedBox(
                    height: 3,
                  ),
                  Column(
                    children: [
                      Text(
                        "Produtos Pendentes Armazenamento",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            headingRowColor: MaterialStateColor.resolveWith(
                              (states) => Colors.grey,
                            ),
                            border: TableBorder.all(
                              color: Colors.black,
                            ),
                            headingRowHeight: 40,
                            dataRowHeight: 25,
                            columnSpacing: 5,
                            horizontalMargin: 10,
                            columns: [
                              DataColumn(
                                label: Text(""),
                              ),
                              DataColumn(
                                label: Text(
                                  "Endereço",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                numeric: true,
                                label: Text(
                                  "Qtd",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Produto",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Sub Lote",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            rows: List.generate(
                              widget.listPendente!
                                  .where((e) => e.situacao == "0")
                                  .length,
                              (index) {
                                return DataRow(
                                  color: MaterialStateColor.resolveWith(
                                    (states) => index % 2 == 0
                                        ? Colors.white
                                        : Colors.grey[200]!,
                                  ),
                                  cells: [
                                    DataCell(
                                      Icon(
                                        Icons.check_box,
                                        color: widget.listPendente![index]
                                                    .situacao ==
                                                "1"
                                            ? Colors.green
                                            : Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        widget.listPendente![index].end != null
                                            ? widget.listPendente![index].end!
                                            : "",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        widget.listPendente![index].qtd == null
                                            ? ""
                                            : widget.listPendente![index].qtd!,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        widget.listPendente![index].nomeProd ==
                                                null
                                            ? ""
                                            : widget
                                                .listPendente![index].nomeProd!,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        widget.listPendente![index].lote == null
                                            ? ""
                                            : widget.listPendente![index].lote!,
                                        style: TextStyle(
                                          fontSize: 15,
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
                      SizedBox(
                        height: 10,
                      ),
                      Divider(
                        color: Colors.black,
                      ),
                      Text(
                        "Produtos Armazenados",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            headingRowColor: MaterialStateColor.resolveWith(
                              (states) => Colors.grey,
                            ),
                            border: TableBorder.all(
                              color: Colors.black,
                            ),
                            headingRowHeight: 40,
                            dataRowHeight: 25,
                            columnSpacing: 5,
                            horizontalMargin: 10,
                            columns: [
                              DataColumn(
                                label: Text(""),
                              ),
                              DataColumn(
                                label: Text(
                                  "Endereço",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                numeric: true,
                                label: Text(
                                  "Qtd",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Produto",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Sub Lote",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            rows: List.generate(
                              armlist.length,
                              (index) {
                                return DataRow(
                                  color: MaterialStateColor.resolveWith(
                                    (states) => index % 2 == 0
                                        ? Colors.white
                                        : Colors.grey[200]!,
                                  ),
                                  cells: [
                                    DataCell(
                                      Icon(
                                        Icons.check_box,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        armlist[index].endArm != null
                                            ? armlist[index].endArm!
                                            : "",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        armlist[index].qtdArm == null
                                            ? ""
                                            : armlist[index].qtdArm!,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        armlist[index].nomeProdArm == null
                                            ? ""
                                            : armlist[index].nomeProdArm!,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        armlist[index].loteArm == null
                                            ? ""
                                            : armlist[index].loteArm!,
                                        style: TextStyle(
                                          fontSize: 15,
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
                    ],
                  ),
                ],
              ),
            ),
            bottomSheet: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (prodReadSuccessArm)
                  Container(
                    width: MediaQuery.of(context).size.width * 0.3,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          primary: primaryColor,
                          textStyle: const TextStyle(fontSize: 15)),
                      onPressed: () async {
                        await syncOp(context, true);
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  TransferenciasScreen(),
                            ),
                            (route) => false);
                      },
                      child: Text(
                        'Finalizar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                if (hasAdressArm)
                  Container(
                    width: 150,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          primary: primaryColor,
                          textStyle: const TextStyle(fontSize: 15)),
                      onPressed: () {
                        setState(() {
                          endRead = '';
                          hasAdressArm = false;
                        });
                      },
                      child: Text(
                        'Alterar endereço',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            bottomNavigationBar: BottomBar()),
      ),
    );
  }
}
