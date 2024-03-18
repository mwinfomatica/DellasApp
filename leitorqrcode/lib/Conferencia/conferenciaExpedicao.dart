import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Components/DashedRect.dart';
import 'package:leitorqrcode/Conferencia/components/button_conferencia.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoConfItensPedidoModel.dart';
import 'package:leitorqrcode/Models/ContextoModel.dart';
import 'package:leitorqrcode/Services/CargasService.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
import 'package:leitorqrcode/Services/ProdutosDBService.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ConferenciaExpedicaoScreen extends StatefulWidget {
  final RetornoConfItensPedidoModel retorno;
  const ConferenciaExpedicaoScreen({
    Key? key,
    required this.retorno,
  }) : super(key: key);

  @override
  State<ConferenciaExpedicaoScreen> createState() =>
      _ConferenciaExpedicaoScreenState();
}

class _ConferenciaExpedicaoScreenState
    extends State<ConferenciaExpedicaoScreen> {
  int? selectedCardIndex;
  late QRViewController controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  bool reading = false;
  bool prodReadSuccess = false;
  bool isManual = false;
  bool leituraExterna = false;

  bool showCamera = false;
  bool showLeituraExterna = false;
  String idOperador = "";
  String titleBtn = '';
  final GlobalKey qrKeyM = GlobalKey(debugLabel: 'QR');
  final animateListKey = GlobalKey<AnimatedListState>();
  String textExterno = "";
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  late BluetoothDevice device;
  late BluetoothCharacteristic cNotify6;
  late StreamSubscription<List<int>> sub6;
  bool isExternalDeviceEnabled = false;
  bool isCollectModeEnabled = false;
  bool isCameraEnabled = false;

  final qtdeProdDialog = TextEditingController();

  List<ProdutoModel> listProd = [];
  bool bluetoothDisconect = true;
  Timer? temp;

  ContextoServices contextoServices = ContextoServices();
  ContextoModel contextoModel =
      ContextoModel(leituraExterna: false, descLeituraExterna: "");

  void getIdUser() async {
    SharedPreferences userlogged = await SharedPreferences.getInstance();
    this.idOperador = userlogged.getString('IdUser')!;
  }

  Widget _buildQrView(BuildContext context) {
    return QRView(
      key: qrKeyM,
      onQRViewCreated: _onQRViewCreated,
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      // if (widget.tipo == 1) {
      // _readCodes(scanData.code!);

      // }
    });
  }

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
      titleBtn =
          isCollectModeEnabled ? "Aguardando leitura do leitor" : titleBtn;
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
        leituraExterna =
            (contextoModel != null && contextoModel.leituraExterna == true);
      });

      flutterBlue.connectedDevices
          .asStream()
          .listen((List<BluetoothDevice> devices) {
        for (BluetoothDevice dev in devices) {
          if (contextoModel.uuidDevice!.isNotEmpty &&
              dev.id.id == contextoModel.uuidDevice) {
            device = dev;
            scanner();
          }
        }
      });
      flutterBlue.scanResults.listen((List<ScanResult> results) {
        for (ScanResult result in results) {
          if (contextoModel.uuidDevice!.isNotEmpty &&
              result.device.id.id == contextoModel.uuidDevice) {
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

    temp = Timer.periodic(Duration(milliseconds: 500), (timer) {
      _readCodesConf(texto);
      timer.cancel();
    });
  }

  scanner() async {
    if (device != null) {
      await flutterBlue.stopScan();
      try {
        await device.connect();
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

      device.state.listen((BluetoothDeviceState event) {
        if (event == BluetoothDeviceState.disconnected) {
          bluetoothDisconect = true;
        }
        if (event == BluetoothDeviceState.connected) {
          bluetoothDisconect = false;
        }
        setState(() {});
      });

      List<BluetoothService> _services = await device.discoverServices();

      if (cNotify6 != null) {
        await sub6.cancel();
      }
      for (BluetoothService service in _services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.notify) {
            cNotify6 = characteristic;

            sub6 = cNotify6.value.listen(
              (value) {
                textExterno += String.fromCharCodes(value);
                if (textExterno != "") {
                  setTimer(textExterno);
                }
              },
            );
            await cNotify6.setNotifyValue(true);

            setState(() {});
          }
        }
      }
    } else {
      bluetoothDisconect = true;
      setState(() {});
    }
  }

  void _readCodesConf(String code) async {
    textExterno = "";
    if (temp != null) {
      temp!.cancel();
      temp = null;
    }

    try {
      if (!reading) {
        reading = true;
        bool showDialogQtd = false;
        //Atualizar produto & Criar movimentação
        bool isOK = true;

        ProdutosDBService produtosDBService = ProdutosDBService();
        bool leituraQR = await produtosDBService.isLeituraQRCodeProduto(code);
        ProdutoModel prodRead = ProdutoModel();

        if (leituraQR) {
          prodRead = ProdutoModel.fromJson(jsonDecode(code));
          prodRead =
              await produtosDBService.getProdutoPedidoByProduto(prodRead);
        } else {
          prodRead =
              await produtosDBService.getProdutoPedidoByBarCodigo(code.trim());
        }

        if (prodRead != null && prodRead.cod!.isNotEmpty) {
          FlutterBeep.beep();
          bool qtdOk = false;

          if (prodRead.infq == "s") {
            qtdeProdDialog.text = "";
            showDialogQtd = true;
            showDialog(
              context: context,
              barrierDismissible: false,
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
                    child: const Text('Cancelar'),
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                  ),
                  TextButton(
                    child: Text("Salvar"),
                    onPressed: () async {
                      // qtdOk = validaQtd(prodRead, qtdeProdDialog.text);
                      Navigator.pop(context);
                    },
                  ),
                ],
                elevation: 24.0,
              ),
            );
          } else {
            // qtdOk = validaQtd(
            //     prodRead,
            //     prodRead.qtd != null &&
            //             prodRead.qtd != "" &&
            //             prodRead.qtd != "0"
            //         ? prodRead.qtd!
            //         : "1");
          }

          if (qtdOk) {
            // addEmbalagem(
            //     prodRead,
            //     int.parse(prodRead.qtd != null &&
            //             prodRead.qtd != "" &&
            //             prodRead.qtd != "0"
            //         ? prodRead.qtd!
            //         : "1"));
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
      FlutterBeep.beep(false);
      Dialogs.showToast(context,
          "Código não reconhecido \n favor realizar a leitura novamente",
          duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
    }
  }

  @override
  void dispose() {
    if (sub6 != null) {
      sub6.cancel();
      // device.disconnect();
    }
    controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    listProd = [];
    getIdUser();
    getContexto();
    _loadPreferences();

    titleBtn = "Iniciar Conferência";

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    late bool visible;
    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            automaticallyImplyLeading: false,
            backgroundColor: primaryColor,
            title: ListTile(
              title: RichText(
                maxLines: 2,
                text: TextSpan(
                  text: "Conferência",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
              trailing: !leituraExterna
                  ? Container(
                      height: 1,
                      width: 1,
                    )
                  : Container(
                      height: 35,
                      width: 35,
                      child: bluetoothDisconect
                          ? isCollectModeEnabled
                              ? Icon(
                                  Icons.qr_code_scanner,
                                  color: Colors.blue,
                                )
                              : Icon(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isCollectModeEnabled)
                  Offstage(
                    offstage: true,
                    child: VisibilityDetector(
                      onVisibilityChanged: (VisibilityInfo info) {
                        visible = info.visibleFraction > 0;
                      },
                      key: Key(
                        'visible-detector-key-M',
                      ),
                      child: BarcodeKeyboardListener(
                        bufferDuration: Duration(milliseconds: 50),
                        onBarcodeScanned: (barcode) async {
                          print(barcode);
                          _readCodesConf(barcode);
                        },
                        child: Text(""),
                      ),
                    ),
                  ),
                if (!prodReadSuccess)
                  isManual
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            autofocus: true,
                            onSubmitted: (value) async {
                              _readCodesConf(value);
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
                          ? showLeituraExterna == false
                              ? Stack(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(10),
                                      color: Colors.yellow[400],
                                      child: Center(
                                        child: Text(
                                          "Aguardando leitura",
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
                                      color: Colors.yellow[400],
                                      child: Center(
                                        child: Text(
                                          "Aguardando leitura",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                          : showCamera == false
                              ? ButtonConference(
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
                                          (MediaQuery.of(context).size.height *
                                              0.20),
                                      child: _buildQrView(context),
                                      // child: Container(),
                                    ),
                                    Center(
                                      child: Container(
                                        margin: EdgeInsets.symmetric(
                                          vertical: (MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.01),
                                          horizontal: (MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.3),
                                        ),
                                        height: (MediaQuery.of(context)
                                                .size
                                                .height *
                                            0.17),
                                        child: DashedRect(
                                          color: primaryColor,
                                          gap: 25,
                                          strokeWidth: 5,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            child: Center(
                                              child: Text(
                                                "Leia o QRCode \n do produto",
                                                textAlign: TextAlign.center,
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
                  height: 5,
                ),
                _buildHeaderNF(height),
                SizedBox(
                  height: 10,
                ),
                Container(
                  width: width * 0.9,
                  child: _buildCustomTable(width),
                ),
                SizedBox(
                  height: 40,
                ),
                ButtonConference(
                  titulo: 'Finalizar',
                  onPressed: () async {},
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomBar()),
    );
  }

  Widget _buildHeaderNF(double height) {
    return Stack(
      children: [
        Container(
          height: height * 0.09,
          color: Colors.yellow.shade300,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Nota: ${widget.retorno.data.nroNFE}/${widget.retorno.data.serieNfe.isEmpty ? 'SN' : widget.retorno.data.serieNfe}',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(
                        width: 8.0,
                      ),
                      Text(
                        '- <${widget.retorno.data.cliente ?? 'Cliente não identificado'}>',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ChaveNFe: ${widget.retorno.data.chaveNfe.isEmpty ? 'Sem número' : widget.retorno.data.chaveNfe.isEmpty}',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ]),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTable(double width) {
    TextStyle headerStyle = TextStyle(fontWeight: FontWeight.bold);
    TextStyle cellStyle = TextStyle();

    double cellHeight = 48.0;

    TableRow _buildHeader() {
      return TableRow(
        decoration: BoxDecoration(color: Colors.grey.shade400),
        children: [
          TableCell(
              child: Center(
                  child: SizedBox(
                      height: cellHeight,
                      child: Center(child: Text('', style: headerStyle))))),
          TableCell(
              child: Center(
                  child: SizedBox(
                      height: cellHeight,
                      child: Center(child: Text('', style: headerStyle))))),
          TableCell(
              child: Center(
                  child: SizedBox(
                      height: cellHeight,
                      child:
                          Center(child: Text('Qtde NF', style: headerStyle))))),
          TableCell(
              child: Center(
                  child: SizedBox(
                      height: cellHeight,
                      child: Center(
                          child: Text('Qtd Conf', style: headerStyle))))),
          TableCell(
              child: Center(
                  child: SizedBox(
                      height: cellHeight,
                      child:
                          Center(child: Text('Produto', style: headerStyle))))),
        ],
      );
    }

    // Cria uma única linha de dados
    TableRow _buildRow(ItemConferenciaNfs item) {
      return TableRow(
        children: [
          TableCell(child: Center(child: Text('', style: cellStyle))),
          TableCell(
            child: Center(
              child: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {},
              ),
            ),
          ),
          TableCell(
              child: Center(child: Text('${item.qtde}', style: cellStyle))),
          TableCell(child: Center(child: Text('0', style: cellStyle))),
          TableCell(
              child:
                  Center(child: Text('${item.descricao}', style: cellStyle))),
        ],
      );
    }

    // Cria a tabela completa com todas as linhas
    return Table(
      border: TableBorder.symmetric(
        inside: BorderSide(width: 1, color: Colors.black),
        outside: BorderSide(width: 1, color: Colors.black),
      ),
      columnWidths: {
        0: FlexColumnWidth(0.4),
        1: FlexColumnWidth(0.5),
        2: FlexColumnWidth(0.4),
        3: FlexColumnWidth(0.4),
        4: FlexColumnWidth(2),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _buildHeader(),
        ...widget.retorno.data.itensConferenciaNfs
            .map((item) => _buildRow(item))
            .toList(),
      ],
    );
  }

  Future<void> forcarConferencia() async {
    print('entrou aqui');
    CargasServices cargasServices = CargasServices(context);

    // RetornoConfBaixaModel? respostaForcarCarga =
    //     await cargasServices.baixaPedido(
    //         widget.retorno.data.idsEmbalagens, cargasSelecionadas, true);

    // if (respostaForcarCarga != null && !respostaForcarCarga.error) {
    // } else {
    //   Dialogs.showToast(context, "Erro forçar Conferência",
    //       duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
    // }
  }
}
