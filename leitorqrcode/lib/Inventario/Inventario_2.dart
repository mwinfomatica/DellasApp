import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'package:flutter/material.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:leitorqrcode/Apuracao/components/IniciarApuracao.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Components/DashedRect.dart';
import 'package:leitorqrcode/Home/Home.dart';
import 'package:leitorqrcode/Infrastructure/AtualizarDados/atualizaOp.dart';
import 'package:leitorqrcode/Models/APIModels/Endereco.dart';
import 'package:leitorqrcode/Models/APIModels/MovimentacaoMOdel.dart';
import 'package:leitorqrcode/Models/APIModels/OperacaoModel.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:leitorqrcode/Models/ContextoModel.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
import 'package:leitorqrcode/Services/ProdutosDBService.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:visibility_detector/visibility_detector.dart';

class Inventario2 extends StatefulWidget {
  const Inventario2({
    Key? key,
  }) : super(key: key);

  @override
  State<Inventario2> createState() => _Inventario2State();
}

class _Inventario2State extends State<Inventario2> {
  late Barcode result;
  bool reading = false;
  bool showCamera = false;
  bool showLeituraExterna = false;
  bool hasAdress = false;
  bool prodReadSuccess = false;
  bool isManual = false;
  bool leituraExterna = false;
  Random r = new Random();
  String endRead = '';
  String titleBtn = '';
  String tipoLeituraExterna = "endereco";
  String idOperador = "";
  final animateListKey = GlobalKey<AnimatedListState>();
  final qtdeProdDialog = TextEditingController();
  final GlobalKey qrAKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  Timer? temp;
  bool bluetoothDisconect = true;

  OperacaoModel? op = null;
  String nroContagem = "01";
  List<String> Contagens = [
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
  ];

  int countleituraProd = 0;

  ContextoServices contextoServices = ContextoServices();
  ContextoModel contextoModel =
      ContextoModel(leituraExterna: false, descLeituraExterna: "");

  List<ProdutoModel> listProd = [];

  Widget _buildQrView(BuildContext context) {
    return QRView(
      key: qrAKey,
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

  String textExterno = "";
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  late BluetoothDevice device;
  late BluetoothCharacteristic cNotify4;
  StreamSubscription<List<int>>? sub4;
  bool isExternalDeviceEnabled = false;
  bool isCollectModeEnabled = false;
  bool isCameraEnabled = false;

  FocusNode focusDropDown = FocusNode();

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

      if (cNotify4 != null) {
        await sub4!.cancel();
      }
      for (BluetoothService service in _services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.notify) {
            cNotify4 = characteristic;

            sub4 = cNotify4.value.listen(
              (value) {
                textExterno += String.fromCharCodes(value);
                if (textExterno != "") {
                  setTimer(textExterno);
                }
              },
            );
            await cNotify4.setNotifyValue(true);

            setState(() {});
          }
        }
      }
    } else {
      bluetoothDisconect = true;
      setState(() {});
    }
  }

  setTimer(String texto) {
    if (temp != null) {
      temp!.cancel();
      temp = null;
    }

    temp = Timer.periodic(Duration(milliseconds: 500), (timer) {
      _readCodesInv(texto);
      timer.cancel();
    });
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      _readCodesInv(scanData.code!);
    });
  }

  void getIdUser() async {
    SharedPreferences userlogged = await SharedPreferences.getInstance();
    this.idOperador = userlogged.getString('IdUser')!;
  }

  void createEditOP() async {
    op = await OperacaoModel().getOpInventario();

    if (op == null) {
      op = new OperacaoModel(
        id: new Uuid().v4().toUpperCase(),
        cnpj: '03316661000119',
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
    }
  }

  @override
  void dispose() {
    if (sub4 != null) {
      sub4!.cancel();
      // device.disconnect();
    }
    if (controller != null) controller!.dispose();
    super.dispose();
  }

  @override
  void initState() {
    getIdUser();
    getContexto();
    _loadPreferences();
    createEditOP();

    titleBtn = "Iniciar Inventário";
    super.initState();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      if (Platform.isAndroid) {
        if (controller != null) controller!.pauseCamera();
      }
      if (controller != null) controller!.resumeCamera();
    }
  }

  void _readCodesInv(String code) async {
    textExterno = "";
    if (temp != null) {
      temp!.cancel();
      temp = null;
    }
    if (code == null || code == "") {
      FlutterBeep.beep(false);
      setState(() {
        reading = false;
      });

      Dialogs.showToast(context, "Nenhum código scaneado.",
          duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
      return;
    }

    try {
      if (!reading) {
        reading = true;
        bool showDialogQtd = false;
        //Atualizar produto & Criar movimentação
        if (hasAdress) {
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

          if (prodRead != null && prodRead.cod!.isNotEmpty) {
            FlutterBeep.beep();

            if (listProd == null) {
              listProd = [];
            }
            ProdutoModel? produto = listProd
                .where(
                  (element) =>
                      element.idproduto == prodRead.idproduto &&
                      element.barcode == prodRead.barcode &&
                      element.coddum == prodRead.coddum &&
                      element.idloteunico == prodRead.idloteunico &&
                      element.lote == prodRead.lote,
                )
                .firstOrNull;

            if (isOK) {
              qtdeProdDialog.text = "";
              showDialog(
                context: context,
                useSafeArea: true,
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
                        await geraMoviProd(
                            produto, prodRead, qtdeProdDialog.text);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                  elevation: 24.0,
                ),
              );
            }
          } else {
            FlutterBeep.beep(false);
            Dialogs.showToast(context,
                "Produto não foi localizado favor ir até as configurações e atualizá-los.",
                duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
          }
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
                hasAdress = true;
              });
            }
          }
        }
        Timer(Duration(milliseconds: 200), () {
          reading = false;
        });
      }
    } catch (ex) {
      Timer(Duration(milliseconds: 200), () {
        reading = false;
      });
      FlutterBeep.beep(false);
      Dialogs.showToast(context,
          "Código não reconhecido \n favor realizar a leitura novamente",
          duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
    }
  }

  @override
  Widget build(BuildContext context) {
    late bool visible;

    return SafeArea(
      child: PopScope(
        canPop: false,
        onPopInvoked: (isPop) => {
          if (!isPop)
            {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => HomeScreen(),
                ),
                (route) => false,
              )
            }
        },
        child: Scaffold(
            appBar: AppBar(
              backgroundColor: primaryColor,
              automaticallyImplyLeading: countleituraProd == 0,
              title: ListTile(
                title: RichText(
                  maxLines: 2,
                  text: TextSpan(
                    text: "Inventário",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
                  DropdownButton<String>(
                    iconSize: 40,
                    onTap: () {
                      if (op!.prods != null && op!.prods!.length > 0) {
                        Navigator.pop(context);
                        return;
                      }
                    },
                    alignment: Alignment.center,
                    focusNode: focusDropDown,
                    enableFeedback: op!.prods != null && op!.prods!.length > 0
                        ? false
                        : true,
                    isExpanded:
                        true, // Adicione esta linha para garantir que o DropdownButton se expanda para preencher o Container.
                    value: nroContagem,
                    onChanged: (String? Value) {
                      setState(() {
                        focusDropDown.canRequestFocus = false;
                        nroContagem = Value ?? "01";
                      });
                    },
                    items: Contagens.map<DropdownMenuItem<String>>(
                        (String? value) {
                      return DropdownMenuItem<String>(
                        alignment: Alignment.center,
                        value: value,
                        enabled: op!.prods != null && op!.prods!.length > 0
                            ? false
                            : true,
                        child: Text(
                          value!,
                          style: TextStyle(fontSize: 35),
                        ),
                      );
                    }).toList(),
                  ),
                  if (isCollectModeEnabled)
                    Offstage(
                      offstage: true,
                      child: VisibilityDetector(
                        onVisibilityChanged: (VisibilityInfo info) {
                          visible = info.visibleFraction > 0;
                        },
                        key: Key('visible-detector-key-inv'),
                        child: BarcodeKeyboardListener(
                          bufferDuration: Duration(milliseconds: 200),
                          onBarcodeScanned: (barcode) async {
                            print(barcode);
                            _readCodesInv(barcode);
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
                                _readCodesInv(value);
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
                                        color: !hasAdress
                                            ? Colors.grey[400]
                                            : Colors.yellow[400],
                                        child: Center(
                                          child: Text(
                                            !hasAdress
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
                                        color: !hasAdress
                                            ? Colors.grey[400]
                                            : Colors.yellow[400],
                                        child: Center(
                                          child: Text(
                                            !hasAdress
                                                ? "Aguardando leitura do Endereço"
                                                : "Aguardando leitura dos Produtos",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                            : showCamera == false
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
                                            vertical: !hasAdress
                                                ? (MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.05)
                                                : (MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.01),
                                            horizontal: !hasAdress
                                                ? 25
                                                : (MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.3),
                                          ),
                                          height: !hasAdress
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
                                            gap: !hasAdress ? 10 : 25,
                                            strokeWidth: !hasAdress ? 2 : 5,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 10,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  hasAdress
                                                      ? "Leia o QRCode \n do produto"
                                                      : "Realize a leitura do \n Endereço",
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
                    height: 1,
                  ),
                  prodReadSuccess
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
                          padding: EdgeInsets.fromLTRB(2, 10, 2, 10),
                          color: !hasAdress
                              ? Colors.grey[300]
                              : Colors.yellow[300],
                          child: Row(
                            children: [
                              Container(
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
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                              ),
                            ],
                          ),
                        ),
                  SizedBox(
                    height: 3,
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
                        dataRowHeight: 30,
                        columnSpacing: 5,
                        horizontalMargin: 10,
                        columns: [
                          DataColumn(
                            label: Text(""),
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
                              "Endereço",
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
                              "",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        rows: List.generate(
                          listProd.length,
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
                                    listProd[index].qtd == null
                                        ? ""
                                        : listProd[index].qtd!,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    listProd[index].nome == null &&
                                            listProd[index].cod == null
                                        ? ""
                                        : listProd[index].cod == null &&
                                                listProd[index].nome != null
                                            ? listProd[index].nome!
                                            : listProd[index].cod != null &&
                                                    listProd[index].nome == null
                                                ? listProd[index].cod!
                                                : listProd[index].cod!.trim() +
                                                    " - " +
                                                    listProd[index].nome!,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                    listProd[index].sl == null
                                        ? ""
                                        : listProd[index].sl!,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    listProd[index].qtd == null
                                        ? ""
                                        : listProd[index].qtd!,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(Ink(
                                  child: InkWell(
                                    child: Icon(
                                      Icons.delete,
                                      size: 30,
                                      color: Colors.red,
                                    ),
                                    onTap: () async => {
                                      _removeItem(listProd[index], index),
                                    },
                                  ),
                                )),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottomSheet: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        primary: primaryColor,
                        textStyle: const TextStyle(fontSize: 20)),
                    onPressed: () async {
                      op!.situacao = "3";
                      await op!.update();
                      await syncOp(context, false);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Finalizar',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (hasAdress)
                  Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          primary: primaryColor,
                          textStyle: const TextStyle(fontSize: 15)),
                      onPressed: () {
                        setState(() {
                          endRead = '';
                          hasAdress = false;
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

  Future<void> geraMoviProd(
      ProdutoModel? produto, ProdutoModel prod, String qtd) async {
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
      // animateListKey.currentState!.insertItem(0);
      prod.idproduto = prod.idproduto;
      prod.id = new Uuid().v4().toUpperCase();
      prod.idOperacao = op!.id;
      prod.qtd = qtd;
      // listProd.add(prod);
      op!.prods!.add(prod);
      await prod.insert();
      setState(() {});
    } else {
      ProdutoModel? prodsop = new ProdutoModel();
      List<MovimentacaoModel> listmovi = [];
      listmovi = await new MovimentacaoModel().getAllByoperacao(op!.id!);
      MovimentacaoModel? movi = new MovimentacaoModel();

      movi =
          listmovi.where((element) => element.idOperacao == op!.id).firstOrNull;
      if (movi != null) {
        movi.qtd = (int.parse(movi.qtd!) + int.parse(qtd)).toString();
        await movi.updatebyId();

        prodsop = op!.prods!
            .where((element) => element.idproduto == produto.idproduto)
            .firstOrNull;

        if (prodsop != null) {
          setState(() {
            prod.qtd = prod.qtd == null ? "1" : prod.qtd;
            produto.qtd = movi!.qtd;
            prodsop!.qtd = movi!.qtd;
            produto.edit(produto);
          });
        }
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
      setState(() {});
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
}
