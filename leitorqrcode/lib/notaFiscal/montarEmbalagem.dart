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
import 'package:leitorqrcode/Models/APIModels/EmbalagemModel.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoBase.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoGetCreateEmbalagemModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoGetEmbalagemListModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoNotasFiscaisModel.dart';
import 'package:leitorqrcode/Models/ContextoModel.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
import 'package:leitorqrcode/Services/NotasFiscaisService.dart';
import 'package:leitorqrcode/Services/ProdutosDBService.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:leitorqrcode/notaFiscal/components/IniciarMontagem.dart';
import 'package:leitorqrcode/notaFiscal/selecionarEmbalagem.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

class MontarEmbalagem extends StatefulWidget {
  final RetornoGetCreateEmbalagemModel dadosCreateEmbalagem;
  final String idPedido;
  final String? idEmbalagem;
  final Pedido pedido;
  final String IdPedidoRetiradaCarga;
  const MontarEmbalagem({
    Key? key,
    required this.dadosCreateEmbalagem,
    required this.idPedido,
    this.idEmbalagem,
    required this.pedido,
    required this.IdPedidoRetiradaCarga,
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
  final GlobalKey qrKeyM = GlobalKey(debugLabel: 'QR');
  final animateListKey = GlobalKey<AnimatedListState>();
  String textExterno = "";
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  late BluetoothDevice device;
  late BluetoothCharacteristic cNotify5;
  late StreamSubscription<List<int>> sub5;
  bool isExternalDeviceEnabled = false;
  bool isCollectModeEnabled = false;
  bool isCameraEnabled = false;

  final qtdeProdDialog = TextEditingController();

  RetornoGetEmbalagemListModel? dadosNotaFiscal;
  List<ProdutoModel> listProd = [];
  bool bluetoothDisconect = true;
  Timer? temp;

  List<ItensEmbalagem> list = [];

  ContextoServices contextoServices = ContextoServices();
  ContextoModel contextoModel =
      ContextoModel(leituraExterna: false, descLeituraExterna: "");

  _getItens() async {
    NotasFiscaisService notaservice = NotasFiscaisService(context);
    RetornoGetEditEmbalagemModel? rtnItens =
        await notaservice.getItensEmbalagem(widget.idEmbalagem!);

    if (rtnItens != null) {
      if (!rtnItens.error) {
        list = rtnItens.data;
        setState(() {});
      }
    }
  }

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
      _readCodesM(texto);
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

      if (cNotify5 != null) {
        await sub5.cancel();
      }
      for (BluetoothService service in _services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.notify) {
            cNotify5 = characteristic;

            sub5 = cNotify5.value.listen(
              (value) {
                textExterno += String.fromCharCodes(value);
                if (textExterno != "") {
                  setTimer(textExterno);
                }
              },
            );
            await cNotify5.setNotifyValue(true);

            setState(() {});
          }
        }
      }
    } else {
      bluetoothDisconect = true;
      setState(() {});
    }
  }

  void _readCodesM(String code) async {
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
                      qtdOk = validaQtd(prodRead, qtdeProdDialog.text);
                      Navigator.pop(context);
                    },
                  ),
                ],
                elevation: 24.0,
              ),
            );
          } else {
            qtdOk = validaQtd(
                prodRead,
                prodRead.qtd != null &&
                        prodRead.qtd != "" &&
                        prodRead.qtd != "0"
                    ? prodRead.qtd!
                    : "1");
          }

          if (qtdOk) {
            addEmbalagem(
                prodRead,
                int.parse(prodRead.qtd != null &&
                        prodRead.qtd != "" &&
                        prodRead.qtd != "0"
                    ? prodRead.qtd!
                    : "1"));
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
    if (sub5 != null) {
      sub5.cancel();
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
    _getItens();

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
                      key: Key(
                        'visible-detector-key-M',
                      ),
                      child: BarcodeKeyboardListener(
                        bufferDuration: Duration(milliseconds: 50),
                        onBarcodeScanned: (barcode) async {
                          print(barcode);
                          _readCodesM(barcode);
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
                              _readCodesM(value);
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
                tableItensNotafiscal(),
                SizedBox(
                  height: 20,
                ),
                Text(
                  'Itens da Embalagem',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                tableItensEmbalagem(),
              ],
            ),
          ),
          bottomNavigationBar: BottomBar()),
    );
  }

  Widget tableItensEmbalagem() {
    return SingleChildScrollView(
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
          headingRowHeight: 20,
          dataRowHeight: 25,
          columnSpacing: 10,
          horizontalMargin: 10,
          columns: [
            DataColumn(
              numeric: true,
              label: Text(
                "Qtd",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                "Produto",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                "",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          rows: List.generate(
            list.length,
            (index) {
              return DataRow(
                color: MaterialStateColor.resolveWith(
                  (states) => index % 2 == 0 ? Colors.white : Colors.grey[200]!,
                ),
                cells: [
                  DataCell(
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        list[index].qtd!.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      list[index].descProd == null &&
                              list[index].descProd == null
                          ? ""
                          : list[index].descProd == null &&
                                  list[index].descProd != null
                              ? list[index].descProd!
                              : list[index].descProd != null &&
                                      list[index].descProd == null
                                  ? list[index].descProd!
                                  : list[index].descProd!.trim(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      "",
                      style: TextStyle(
                        fontSize: 14,
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
    );
  }

  Widget tableItensNotafiscal() {
    return SingleChildScrollView(
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
          headingRowHeight: 20,
          dataRowHeight: 25,
          columnSpacing: 10,
          horizontalMargin: 10,
          columns: [
            DataColumn(
              label: Text(
                "",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              numeric: true,
              label: Text(
                "Qtd Total",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                "Qtd Emb.",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                "Produto",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          rows: List.generate(
            widget.dadosCreateEmbalagem.data.length,
            (index) {
              return DataRow(
                color: MaterialStateColor.resolveWith(
                  (states) => index % 2 == 0 ? Colors.white : Colors.grey[200]!,
                ),
                cells: [
                  DataCell(
                    Align(
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.check_box,
                        color:
                            widget.dadosCreateEmbalagem.data[index].quantNota ==
                                    widget.dadosCreateEmbalagem.data[index]
                                        .quantEmbalado
                                ? Colors.green
                                : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                  DataCell(
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        widget.dadosCreateEmbalagem.data[index].quantNota
                            .toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        widget.dadosCreateEmbalagem.data[index].quantEmbalado
                            .toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      widget.dadosCreateEmbalagem.data[index].descProduto
                          .trim(),
                      style: TextStyle(
                        fontSize: 14,
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
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      _readCodesM(scanData.code!);
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
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => AlertDialog(
                    title: Text(
                      "Atenção",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    content: Text(
                        "A criação da embalagem será cancelada. Confirma?"),
                    actions: [
                      TextButton(
                        child: const Text('Não'),
                        onPressed: () async {
                          Navigator.pop(context);
                        },
                      ),
                      TextButton(
                        child: Text("Sim"),
                        onPressed: () async {
                          Navigator.pop(context);

                          await _getEmbalagemList(widget.idPedido);

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  SelecionarEmbalagem(
                                nfeDados: widget.pedido,
                                dadosEmbalagem: dadosNotaFiscal!.data,
                                IdPedidoRetiradaCarga: widget.IdPedidoRetiradaCarga
                              ),
                            ),
                            (route) => false,
                          );
                        },
                      ),
                    ],
                    elevation: 24.0,
                  ),
                );
              },
              child: Container(
                width: width * 0.43,
                height: 60,
                decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey),
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
              onTap: () async => {
                await finalizarEmbalagem(),
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

  bool validaQtd(ProdutoModel prod, String qtd) {
    bool qtdIsValid = int.tryParse(qtd) != null ? true : false;
    if (!qtdIsValid) {
      Dialogs.showToast(
          context, "A quantidade informada não é valida \n tente novamente",
          duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
    }

    List<DadosEmbalagem> listDados = widget.dadosCreateEmbalagem.data;
    DadosEmbalagem? dados =
        getProdutoIguais((prod.idproduto != null ? prod.idproduto! : prod.id!));

    if (dados != null) {
      if (dados.quantNota >= (dados.quantEmbalado + int.parse(qtd))) {
        return true;
      } else {
        Dialogs.showToast(context,
            "A quantidade não pode ser maior que a informada na nota fiscal.",
            duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
        return false;
      }
    } else {
      Dialogs.showToast(context, "Não foi encontrado o produto na nota fiscal.",
          duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
      return false;
    }
  }

  DadosEmbalagem? getDadosEmbalagembyId(String id) {
    List<DadosEmbalagem> listDados = widget.dadosCreateEmbalagem.data;
    DadosEmbalagem? dados = listDados
        .where((e) => e.idProduto.toUpperCase() == id.toUpperCase())
        .firstOrNull;

    return dados;
  }

  DadosEmbalagem? getProdutoIguais(String id) {
    List<DadosEmbalagem> ProdsIguais = widget.dadosCreateEmbalagem.data
        .where((e) => e.idProduto.toUpperCase() == id.toUpperCase())
        .toList();
    int? qtdProd = ProdsIguais != null ? ProdsIguais.length : 0;
    if (qtdProd > 1) {
      for (var i = 0; i < qtdProd; i++) {
        if (ProdsIguais[i].quantEmbalado < ProdsIguais[i].quantNota) {
          return ProdsIguais[i];
        } else {
          if (qtdProd == (i + 1)) {
            return ProdsIguais[i];
          }
        }
      }
    } else if (qtdProd == 1) {
      return ProdsIguais[0];
    } else {
      return null;
    }
  }

  ItensEmbalagem? getItemEmbalagem(String id) {
    return list
        .where((e) => e.idProduto!.toUpperCase() == id.toUpperCase())
        .firstOrNull;
  }

  addEmbalagem(ProdutoModel prodRead, int qtd) {
    String idProd =
        (prodRead.idproduto != null ? prodRead.idproduto! : prodRead.id!);

    DadosEmbalagem? dados = getProdutoIguais(idProd);

    if (dados != null) {
      dados.quantEmbalado = dados.quantEmbalado + 1;
    } else {
      Dialogs.showToast(
          context, "Não foi encontrado este produto para esta Nota fiscal",
          duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
      return;
    }

    ItensEmbalagem? item = getItemEmbalagem(idProd);

    if (item != null) {
      if (item.qtd != null && item.qtd! >= 1) {
        list.remove(item);
        item.qtd = item.qtd! + qtd;
        item.descProd =
            (prodRead.cod ?? " - ") + " - " + (prodRead.nome ?? " - ");
        list.add(item);
      } else {
        list.add(ItensEmbalagem(prodRead.idprodutoPedido, idProd, qtd,
            ((prodRead.cod ?? " - ") + " - " + (prodRead.nome ?? " - "))));
      }
    } else {
      list.add(ItensEmbalagem(prodRead.idprodutoPedido, idProd, qtd,
          ((prodRead.cod ?? " - ") + " - " + (prodRead.nome ?? " - "))));
    }
    setState(() {});
  }

  removeEmbalagem(String idProduto) {
    ItensEmbalagem? item =
        list.where((e) => e.idProduto == idProduto).firstOrNull;

    if (item != null) {
      if (item.qtd != null && item.qtd! > 1) {
        list.remove(item);
        item.qtd = item.qtd! - 1;
        list.add(item);
      } else {}
    }
  }

  finalizarEmbalagem() async {
    EmbalagemModel emb =
        EmbalagemModel(idOperador, widget.idEmbalagem, widget.idPedido, list);

    NotasFiscaisService nfservice = NotasFiscaisService(context);

    RetornoBaseModel? rtn = await nfservice.finalizarEmbalagem(emb);

    if (rtn != null) {
      if (!rtn.error!) {
        Dialogs.showToast(context, "Embalagem finalizada com sucesso.",
            duration: Duration(seconds: 5), bgColor: Colors.green.shade200);

        await _getEmbalagemList(widget.idPedido);

        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => SelecionarEmbalagem(
                nfeDados: widget.pedido,
                dadosEmbalagem: dadosNotaFiscal!.data,
                IdPedidoRetiradaCarga: widget.IdPedidoRetiradaCarga
              ),
            ),
            (route) => false);
      } else {
        Dialogs.showToast(
            context,
            rtn.message ??
                "Ocorreu um erro inesperado. Gentileza tentar novamente mais tarde.",
            duration: Duration(seconds: 5),
            bgColor: Colors.red.shade200);
      }
    } else {
      Dialogs.showToast(context,
          "Ocorreu um erro inesperado. Gentileza tentar novamente mais tarde.",
          duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
    }
  }

  Future<void> _getEmbalagemList(String idPedido) async {
    NotasFiscaisService notasFiscaisService = NotasFiscaisService(context);

    try {
      RetornoGetEmbalagemListModel? rtndadosNotaFiscal =
          await notasFiscaisService.getEmbalagemList(idPedido);
      if (rtndadosNotaFiscal != null) {
        setState(() {
          dadosNotaFiscal = rtndadosNotaFiscal;
        });
      }
    } catch (e) {
      print('Erro ao processar carga: $e');
    }
  }
}
