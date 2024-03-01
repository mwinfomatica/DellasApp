import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Components/DashedRect.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoGetCreateEmbalagemModel.dart';
import 'package:leitorqrcode/Models/ContextoModel.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
import 'package:leitorqrcode/Services/ProdutosDBService.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:leitorqrcode/notaFiscal/components/IniciarMontagem.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

class MontarEmbalagem extends StatefulWidget {
  final RetornoGetCreateEmbalagemModel dadosCreateEmbalagem;
  const MontarEmbalagem({
    Key? key,
    required this.dadosCreateEmbalagem,
  }) : super(key: key);

  @override
  State<MontarEmbalagem> createState() => _MontarEmbalagemState();
}

class _MontarEmbalagemState extends State<MontarEmbalagem> {
  bool reading = false;
  bool prodReadSuccess = false;
  bool isManual = false;
  bool leituraExterna = false;

  int? selectedCardIndex;
  late QRViewController controller;
  bool showCamera = false;
  bool showLeituraExterna = false;
  String idOperador = "";
  String titleBtn = '';
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final animateListKey = GlobalKey<AnimatedListState>();
  String textExterno = "";
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  late BluetoothDevice device;
  late BluetoothCharacteristic cNotify3;
  late StreamSubscription<List<int>> sub3;
  bool isExternalDeviceEnabled = false;
  bool isCollectModeEnabled = false;
  bool isCameraEnabled = false;

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
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
    );
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
      _readCodes(texto);
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

      if (cNotify3 != null) {
        await sub3.cancel();
      }
      for (BluetoothService service in _services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.notify) {
            cNotify3 = characteristic;

            sub3 = cNotify3.value.listen(
              (value) {
                textExterno += String.fromCharCodes(value);
                if (textExterno != "") {
                  setTimer(textExterno);
                }
              },
            );
            await cNotify3.setNotifyValue(true);

            setState(() {});
          }
        }
      }
    } else {
      bluetoothDisconect = true;
      setState(() {});
    }
  }

  void _readCodes(String code) async {
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
          // ProdutoModel? prodDB = await new ProdutoModel().getByIdLoteIdPedido(
          //     prodRead.idloteunico!.toUpperCase(),
          //     widget.operacaoModel.id!.toUpperCase());

          List<ProdutoModel> lProdDB = [];
          // List<ProdutoModel> lProdDB = await ProdutoModel()
          //     .getByIdProdIdOperacao(prodRead.idloteunico!.toUpperCase(),
          //         widget.operacaoModel.id!.toUpperCase());

          FlutterBeep.beep(false);
          Dialogs.showToast(context,
              "Produto não foi localizado favor ir até as configurações e atualizá-los.",
              duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
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
    if (sub3 != null) {
      sub3.cancel();
      // device.disconnect();
    }
    controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    listProd = [];
    var count = listProd.where((element) => element.situacao == "3").length;
    getIdUser();
    getContexto();
    _loadPreferences();

    // if (count == listProd.length) {
    //   Dialogs.showToast(context, "Leitura já realizada");
    //   this.prodReadSuccess = true;
    // }

    titleBtn = "Iniciar Montagem";

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
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    late bool visible;
    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: primaryColor,
            automaticallyImplyLeading: false,
            title: ListTile(
              title: RichText(
                maxLines: 2,
                text: TextSpan(
                  text: "Montagem de Embalagem",
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
            scrollDirection: Axis.vertical,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                if (isCollectModeEnabled)
                  Offstage(
                    offstage: true,
                    child: VisibilityDetector(
                      onVisibilityChanged: (VisibilityInfo info) {
                        visible = info.visibleFraction > 0;
                      },
                      key: Key('visible-detector-key'),
                      child: BarcodeKeyboardListener(
                        bufferDuration: Duration(milliseconds: 50),
                        onBarcodeScanned: (barcode) async {
                          print(barcode);
                          _readCodes(barcode);
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
                              _readCodes(value);
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
                              ? BotaoIniciarMontagem(
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
                  height: 10,
                ),
                _buildButtons(width),
                SizedBox(
                  height: 10,
                ),
                Text(
                  'Itens da Nota Fiscal',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                Container(
                  width: width *
                      0.95, // Define a largura para 90% da largura da tela
                  child: _buildCustomTable(
                      width, widget.dadosCreateEmbalagem.data),
                ),
                SizedBox(
                  height: 20,
                ),
                Text(
                  'Itens da Embalagem',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                Container(
                  width: width *
                      0.95, // Define a largura para 90% da largura da tela
                  child: _buildItensEmbalagem(width),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomBar()),
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

  Widget _buildButtons(double width) {
    return Center(
      child: SizedBox(
        width: width * 0.9,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: width * 0.43,
                height: 60,
                decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.green),
                child: Center(
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Container(
                width: width * 0.43,
                height: 60,
                decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.green),
                child: Center(
                  child: Text(
                    'Finalizar',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTable(double width, List<DadosEmbalagem> dadosEmbalagem) {
    // Estilos de texto para os cabeçalhos e células
    TextStyle headerStyle = TextStyle(fontWeight: FontWeight.bold);
    TextStyle cellStyle = TextStyle();

    double cellHeight = 48.0;

    // Cria uma linha de cabeçalho com fundo cinza e texto em negrito
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
                      child: Center(
                          child: Text('Qtde Total', style: headerStyle))))),
          TableCell(
              child: Center(
                  child: SizedBox(
                      height: cellHeight,
                      child:
                          Center(child: Text('Qtd Emb', style: headerStyle))))),
          TableCell(
              child: Center(
                  child: SizedBox(
                      height: cellHeight,
                      child:
                          Center(child: Text('Produto', style: headerStyle))))),
        ],
      );
    }

    TableRow _buildRow(DadosEmbalagem embalagem, int index) {
      return TableRow(
        children: [
          TableCell(child: Center(child: Text('', style: cellStyle))),
          TableCell(
              child: Center(
                  child: Text('${embalagem.quantNota}', style: cellStyle))),
          TableCell(
              child: Center(
                  child: Text('${embalagem.quantEmbalado}', style: cellStyle))),
          TableCell(
              child:
                  Center(child: Text(embalagem.descProduto, style: cellStyle))),
        ],
      );
    }

    return Table(
      border: TableBorder.symmetric(
        inside: BorderSide(width: 1, color: Colors.black),
        outside: BorderSide(width: 1, color: Colors.black),
      ),
      columnWidths: {
        0: FlexColumnWidth(0.5),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(2),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _buildHeader(),
        ...dadosEmbalagem
            .asMap()
            .entries
            .map((entry) => _buildRow(entry.value, entry.key))
            .toList(),
      ],
    );
  }

  Widget _buildItensEmbalagem(double width) {
    // Estilos de texto para os cabeçalhos e células
    TextStyle headerStyle = TextStyle(fontWeight: FontWeight.bold);
    TextStyle cellStyle = TextStyle();

    double cellHeight = 48.0;

    // Cria uma linha de cabeçalho com fundo cinza e texto em negrito
    TableRow _buildHeader() {
      return TableRow(
        decoration: BoxDecoration(color: Colors.grey.shade400),
        children: [
          TableCell(
              child: Center(
                  child: SizedBox(
                      height: cellHeight,
                      child: Center(
                          child: Text('Qtde Emb.', style: headerStyle))))),
          TableCell(
              child: Center(
                  child: SizedBox(
                      height: cellHeight,
                      child:
                          Center(child: Text('Produto', style: headerStyle))))),
          TableCell(
              child: Center(
                  child: SizedBox(
                      height: cellHeight,
                      child: Center(child: Text('Ação', style: headerStyle))))),
        ],
      );
    }

    // Cria uma única linha de dados
    TableRow _buildRow(int index) {
      return TableRow(
        children: [
          TableCell(
              child: Center(child: Text('${index + 1}', style: cellStyle))),
          TableCell(child: Center(child: Text('Em Aberto', style: cellStyle))),
          TableCell(
            child: Center(
              child: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  // Ação quando o ícone é pressionado
                },
              ),
            ),
          ),
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
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _buildHeader(),
        ...List.generate(2, (index) => _buildRow(index)).toList(),
      ],
    );
  }
}
