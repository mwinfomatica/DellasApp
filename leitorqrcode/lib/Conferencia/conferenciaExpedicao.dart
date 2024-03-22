import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Components/DashedRect.dart';
import 'package:leitorqrcode/Conferencia/components/ModalForcaFinalizacaoConferencia.dart';
import 'package:leitorqrcode/Conferencia/components/button_conferencia.dart';
import 'package:leitorqrcode/Models/APIModels/BaixaConfModel.dart';
import 'package:leitorqrcode/Models/APIModels/ConfItensEmbalagem.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoConfBaixaModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoConfItensPedidoModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoGetEmbalagemListModel.dart';
import 'package:leitorqrcode/Models/ContextoModel.dart';
import 'package:leitorqrcode/Services/CargasService.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
import 'package:leitorqrcode/Services/NotasFiscaisService.dart';
import 'package:leitorqrcode/Services/ProdutosDBService.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ConferenciaExpedicaoScreen extends StatefulWidget {
  final RetornoConfItensPedidoModel retorno;
  final String idPeiddo;
  const ConferenciaExpedicaoScreen({
    Key? key,
    required this.retorno,
    required this.idPeiddo,
  }) : super(key: key);

  @override
  State<ConferenciaExpedicaoScreen> createState() =>
      _ConferenciaExpedicaoScreenState();
}

class _ConferenciaExpedicaoScreenState
    extends State<ConferenciaExpedicaoScreen> {
  int? selectedCardIndex;
  late QRViewController controller;

  bool reading = false;
  bool isManual = false;
  bool leituraExterna = false;

  bool showCamera = false;
  bool showLeituraExterna = false;
  String idOperador = "";
  String titleBtn = '';
  final GlobalKey qrKeyConf = GlobalKey(debugLabel: 'QR');
  final animateListKey = GlobalKey<AnimatedListState>();
  String textExterno = "";
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  late BluetoothDevice device;
  late BluetoothCharacteristic cNotify6;
  late StreamSubscription<List<int>> sub6;
  bool isExternalDeviceEnabled = false;
  bool isCollectModeEnabled = false;
  bool isCameraEnabled = false;

  bool conferenciaOk = false;

  List<ItemConferenciaNfs> listItens = [];
  List<String> listEmb = [];

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
      key: qrKeyConf,
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
    reading = false;
    try {
      if (!reading) {
        reading = true;
        bool showDialogQtd = false;
        //Atualizar produto & Criar movimentação
        bool isOK = true;
        bool qtdOk = false;
        List<ConfItensEmbalagem> list = [];

        if (code.indexOf("Embalagem") > 0) {
          EmbalagemPrinter? emb = EmbalagemPrinter.fromJson(jsonDecode(code));

          if (emb == null) {
            return;
          }

          NotasFiscaisService notasFiscaisService =
              NotasFiscaisService(context);
          RetornoGetConfItensEmbalagemModel? rtn =
              await notasFiscaisService.getConfItensEmbalagem(emb.id);

          if (rtn != null) {
            if (!rtn.error) {
              list = rtn.data;

              for (int i = 0; i < list.length; i++) {
                int qtd = list[i].qtde ?? 1;

                for (var q = 0; q < qtd; q++) {
                  ProdutoModel prod = ProdutoModel(
                    id: list[i].idProduto,
                    barcode: "",
                    cod: "",
                    codEndGrupo: "",
                    coddum: "",
                    cx: "",
                    desc: "",
                    end: "",
                    idOperacao: widget.idPeiddo,
                    idloteunico: "",
                    idproduto: list[i].idProduto,
                    idprodutoPedido: list[i].idPedidoProduto,
                    infVali: "n",
                    infq: "n",
                    isVirtual: '0',
                    lote: "",
                    nome: "",
                    qtd: "1",
                    situacao: "1",
                    sl: "",
                    vali: "",
                  );

                  qtdOk = validaQtd(prod, prod.qtd != null ? prod.qtd! : "0");
                  addConferencia(
                      prod,
                      int.parse(prod.qtd != null ? prod.qtd! : "0"),
                      true,
                      emb.id);
                }
                Dialogs.showToast(context, "Leitura da Embalegm concluida.",
                    duration: Duration(seconds: 5),
                    bgColor: Colors.green.shade200);
                return;
              }
            }
          }
        }

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
              prodRead.qtd != null && prodRead.qtd != "" && prodRead.qtd != "0"
                  ? prodRead.qtd!
                  : "1",
            );
          }

          if (qtdOk) {
            addConferencia(
                prodRead,
                int.parse(prodRead.qtd != null &&
                        prodRead.qtd != "" &&
                        prodRead.qtd != "0"
                    ? prodRead.qtd!
                    : "1"),
                false,
                null);
          }
        }
        reading = false;
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
    listItens = widget.retorno.data.itensConferenciaNfs;
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
                        'visible-detector-key-Conf',
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
                if (!conferenciaOk)
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
                                  titulo: titleBtn,
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
                  height: 1,
                ),
                conferenciaOk
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
                    : Container(),
                SizedBox(
                  height: 3,
                ),
                _buildHeaderNF(height),
                SizedBox(
                  height: 10,
                ),
                tableNotafiscal(),
                SizedBox(
                  height: 40,
                ),
              ],
            ),
          ),
          bottomSheet: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!conferenciaOk)
                Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        primary: primaryColor,
                        textStyle: const TextStyle(fontSize: 15)),
                    onPressed: () async {
                      RetornoConfBaixaModel? retorno =
                          await finalizaConferencia('N');
                      if (retorno != null && !retorno.error) {
                        Dialogs.showToast(context, retorno.message,
                            duration: Duration(seconds: 5),
                            bgColor: Colors.green.shade200);
                        Navigator.pop(context);
                      } else {
                        Dialogs.showToast(context, retorno!.message,
                            duration: Duration(seconds: 5),
                            bgColor: Colors.red.shade200);
                        return;
                      }
                    },
                    child: Text(
                      'Finalizar',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: BottomBar()),
    );
  }

  Widget _buildHeaderNF(double height) {
    return Stack(
      children: [
        Container(
          height: height * 0.17,
          color: Colors.yellow.shade300,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.32,
                      height: height * 0.1,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            primary: primaryColor,
                            textStyle: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => modalForcaFinalizacaoConferencia(
                              idPedido: widget.idPeiddo,
                              psw: widget.idPeiddo.split('-')[1],
                              ontap: () => {
                                finalizaConferencia('F'),
                              },
                            ),
                          );
                        },
                        child: Text(
                          'Forçar Finalização',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Nota: ${widget.retorno.data.nroNFE}/${widget.retorno.data.serieNfe.isEmpty ? 'SN' : widget.retorno.data.serieNfe}',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '<${widget.retorno.data.cliente ?? 'Cliente não identificado'}>',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget tableNotafiscal() {
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
          dataRowHeight: 50,
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
                "Qtd",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                "Qtd Conf.",
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
            listItens.length,
            (index) {
              return DataRow(
                color: MaterialStateColor.resolveWith(
                  (states) =>
                      listItens[index].qtde < (listItens[index].qtdeConf ?? 0)
                          ? Colors.red
                          : index % 2 == 0
                              ? Colors.white
                              : Colors.grey[200]!,
                ),
                cells: [
                  DataCell(
                    Align(
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.check_box,
                        color:
                            listItens[index].qtde == listItens[index].qtdeConf
                                ? Colors.green
                                : listItens[index].qtde <
                                        (listItens[index].qtdeConf ?? 0)
                                    ? Colors.orange[200]
                                    : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                  DataCell(
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        listItens[index].qtde.toString(),
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
                        listItens[index].qtdeConf == null
                            ? "0"
                            : listItens[index].qtdeConf.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      (listItens[index].codigo.trim() +
                          " - " +
                          listItens[index].descricao.trim()),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(
                    Ink(
                      child: InkWell(
                        child: Icon(
                          Icons.delete_outline,
                          color: listItens[index].qtde <
                                  (listItens[index].qtdeConf ?? 0)
                              ? Colors.black
                              : Colors.red,
                          size: 40,
                        ),
                        onTap: () async => {
                          showDialogConfir(context, listItens[index].idItem),
                        },
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

  Future<void> showDialogConfir(BuildContext context, String id) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            "Atenção",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Ao confirmar será necessário realizar a conferência do item novamente.\nDeseja prosseguir?',
            style: TextStyle(fontSize: 16.0),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('Confirmar'),
              onPressed: () {
                ItemConferenciaNfs? dados = getItembyId(id);
                if (dados != null) {
                  dados.qtdeConf = 0;
                }
                setState(() {});

                validaConferencia();
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<RetornoConfBaixaModel?> finalizaConferencia(String tipoBaixa) async {
    CargasServices cargasServices = CargasServices(context);
    BaixaConfModel model = BaixaConfModel(
      idEmbalagem: listEmb,
      idPedidos: [widget.idPeiddo],
      tipoBaixa: tipoBaixa,
      idUsuario: idOperador,
    );
    RetornoConfBaixaModel? respostaForcarCarga =
        await cargasServices.baixaPedido(model);

    return respostaForcarCarga;
  }

  bool validaQtd(ProdutoModel prod, String qtd) {
    bool qtdIsValid = int.tryParse(qtd) != null ? true : false;
    if (!qtdIsValid) {
      Dialogs.showToast(
          context, "A quantidade informada não é valida \n tente novamente",
          duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
    }

    ItemConferenciaNfs? dados =
        getProdutoIguais((prod.idproduto != null ? prod.idproduto! : prod.id!));

    if (dados != null) {
      return true;
      // if (dados.qtde >= ((dados.qtdeConf ?? 0) + int.parse(qtd))) {
      //   return true;
      // } else {
      //   dados = getProdutoIguais(
      //       (prod.idproduto != null ? prod.idproduto! : prod.id!));

      //   if (dados != null) {

      // }
      // }

      // else {
      //   Dialogs.showToast(context,
      //       "A quantidade não pode ser maior que a informada na nota fiscal.",
      //       duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
      //   return false;
      // }
    } else {
      Dialogs.showToast(context, "Não foi encontrado o produto na nota fiscal.",
          duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
      return false;
    }
  }

  ItemConferenciaNfs? getItembyIdproduto(String id) {
    ItemConferenciaNfs? dados = listItens
        .where((e) => e.idProduto.toUpperCase() == id.toUpperCase())
        .firstOrNull;

    return dados;
  }

  ItemConferenciaNfs? getItembyId(String id) {
    ItemConferenciaNfs? dados = listItens
        .where((e) => e.idItem.toUpperCase() == id.toUpperCase())
        .firstOrNull;

    return dados;
  }

  ItemConferenciaNfs? getProdutoIguais(String id) {
    List<ItemConferenciaNfs>? ProdsIguais = listItens
        .where((e) => e.idProduto.toUpperCase() == id.toUpperCase())
        .toList();
    int? qtdProd = ProdsIguais != null ? ProdsIguais.length : 0;
    if (qtdProd > 1) {
      for (var i = 0; i < qtdProd; i++) {
        if ((ProdsIguais[i].qtdeConf ?? 0) < ProdsIguais[i].qtde) {
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

  addConferencia(
      ProdutoModel prodRead, int qtd, bool isEmbalagem, String? idEmbalagem) {
    String idProd =
        (prodRead.idproduto != null ? prodRead.idproduto! : prodRead.id!);

    ItemConferenciaNfs? dados = getProdutoIguais(idProd);

    if (dados != null) {
      if (dados.qtdeConf == null) {
        dados.qtdeConf = 0;
      }

      dados.qtdeConf = dados.qtdeConf! + qtd;

      if (isEmbalagem && idEmbalagem != null) listEmb.add(idEmbalagem);
    } else {
      Dialogs.showToast(
          context, "Não foi encontrado este produto para esta Nota fiscal",
          duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
      return;
    }

    setState(() {});

    validaConferencia();
  }

  validaConferencia() {
    int? qdtItensConf = listItens.where((e) => e.qtde == e.qtdeConf).length;

    if (qdtItensConf == listItens.length) {
      conferenciaOk = true;
    } else {
      conferenciaOk = false;
    }
  }
}
