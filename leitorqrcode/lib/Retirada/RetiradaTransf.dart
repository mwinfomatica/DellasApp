import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'package:flutter/material.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:leitorqrcode/ArmazenamentoTransferencia/armazenamentoTransf.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Components/DashedRect.dart';
import 'package:leitorqrcode/Home/Home.dart';
import 'package:leitorqrcode/Models/APIModels/Endereco.dart';
import 'package:leitorqrcode/Models/ContextoModel.dart';
import 'package:leitorqrcode/Models/armprodModel.dart';
import 'package:leitorqrcode/Models/pendenteArmazModel.dart';
import 'package:leitorqrcode/Models/retiradaprodModel.dart';
import 'package:leitorqrcode/Retirada/components/IniciarApuracao.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:leitorqrcode/Retirada/components/info_qtde_retirada.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
import 'package:leitorqrcode/Services/ProdutosDBService.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:leitorqrcode/Transferencia/components/TransferenciaMenu.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class RetiradaTransf extends StatefulWidget {
  final String? titulo;
  final String? idtransf;
  final List<retiradaprodModel>? listRetirada;
  final String? end;

  const RetiradaTransf({
    Key? key,
    @required this.titulo,
    @required this.listRetirada,
    @required this.idtransf,
    this.end,
  }) : super(key: key);

  @override
  State<RetiradaTransf> createState() => _RetiradaTransfState();
}

class _RetiradaTransfState extends State<RetiradaTransf> {
  // TextEditingController _invisibleTextController = TextEditingController();
  Barcode? result;
  FocusNode _focusNode = FocusNode();
  bool reading = false;
  bool showCamera = false;
  bool hasAdress = false;
  bool prodReadSuccess = false;
  bool isManual = false;
  // bool isExternalReadingEnabledApp = false;
  String? endRead = null;
  String? titleBtn = null;
  String idOperador = "";
  final animateListKey = GlobalKey<AnimatedListState>();
  final qtdeProdDialog = TextEditingController();
  final GlobalKey qrAKey = GlobalKey(debugLabel: 'QR');
  bool showLeituraExterna = false;
  bool leituraExterna = false;
  String tipoLeituraExterna = "endereco";
  QRViewController? controller;
  Timer? temp;

  int countleituraProd = 0;

  ContextoServices contextoServices = ContextoServices();
  ContextoModel contextoModel =
      ContextoModel(leituraExterna: false, descLeituraExterna: "");

  List<retiradaprodModel> list = [];

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
  BluetoothDevice? device;
  BluetoothCharacteristic? cNotify1;
  StreamSubscription<List<int>>? sub1;
  bool isExternalDeviceEnabled = false;
  bool isCollectModeEnabled = false;
  bool isCameraEnabled = false;

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

      List<BluetoothDevice> conectados = await flutterBlue.connectedDevices;
      if (conectados != null && conectados.length > 0) {
        device = conectados.firstWhere(
          (BluetoothDevice dev) => dev.id.id == contextoModel.uuidDevice,
          orElse: () => null as BluetoothDevice,
        );
      }
      if (device != null) {
        scanner();
      } else {
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
  }

  scanner() async {
    if (device != null) {
      flutterBlue.stopScan();
      try {
        await device!.connect();
      } catch (e) {
        if (e != 'already_connected') {
          throw e;
        }
      } finally {
        // final mtu = await device.mtu.first;
        // await device.requestMtu(512);
      }

      List<BluetoothService> _services = await device!.discoverServices();

      if (cNotify1 != null) {
        sub1!.cancel();
      }
      for (BluetoothService service in _services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.notify) {
            cNotify1 = characteristic;

            sub1 = cNotify1!.value.listen((value) {
              textExterno = String.fromCharCodes(value);
              if (textExterno != "") {
                setTimer(textExterno);
              }
            });
            await cNotify1!.setNotifyValue(true);

            setState(() {});
          }
        }
      }
    }
  }

  setTimer(String texto) async {
    // if (temp != null) {
    //   temp.cancel();
    //   temp = null;
    // }

    // temp = Timer.periodic(Duration(milliseconds: 500), (timer) async {
    await _readCodes(texto);
    //   timer.cancel();
    // });
  }

  Future<void> _readCodes(String code) async {
    try {
      if (!reading) {
        reading = true;
        print('tem endereço? $hasAdress');

        //Atualizar produto & Criar movimentação
        if (hasAdress) {
          bool isOK = true;

          ProdutosDBService produtosDBService = ProdutosDBService();
          bool leituraQR = await produtosDBService.isLeituraQRCodeProduto(code);
          ProdutoModel prodRead = ProdutoModel();
          SharedPreferences prefs = await SharedPreferences.getInstance();
          // Verifica se o método de leitura externa está habilitado

          // isExternalReadingEnabledApp = prefs.getBool('collectMode') ?? false;

          if (leituraQR) {
            prodRead = ProdutoModel.fromJson(jsonDecode(code));
            prodRead =
                await produtosDBService.getProdutoPedidoByProduto(prodRead);
          } else {
            prodRead = await produtosDBService
                .getProdutoPedidoByBarCodigo(code.trim());
          }

          FlutterBeep.beep();
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
                //           await saveRetirada(prodRead, qtdeProdDialog.text);
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
                    builder: (BuildContext context) => infoQtdReti(
                      idtransf: widget.idtransf,
                      listRetirada: list,
                      titulo: widget.titulo,
                      endRead: endRead ?? "",
                      idOperador: idOperador,
                      prodRead: prodRead,
                      qtdeProdDialog: qtdeProdDialog,
                    ),
                  ),
                  (route) => false,
                );

                return;
              } else {
                await saveRetirada(
                    prodRead,
                    prodRead.qtd != null &&
                            prodRead.qtd != "" &&
                            prodRead.qtd != "0"
                        ? prodRead.qtd!
                        : "1");
              }
            }
          } else
            Dialogs.showToast(context, "Produto não encontrado",
                duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
        } else {
          //Habilita camera
          if (code.isEmpty || code.length > 20) {
            FlutterBeep.beep(false);
            Dialogs.showToast(context, "Código de barras inválido");
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
        Timer(Duration(seconds: 1), () {
          reading = false;
        });
      }
    } catch (ex) {
      Timer(Duration(seconds: 1), () {
        reading = false;
      });
      FlutterBeep.beep(false);
      Dialogs.showToast(context,
          "Código não reconhecido \n favor realizar a leitura novamente",
          duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
    } finally {}
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      await _readCodes(scanData.code!);
    });
  }

  Future<void> saveRetirada(ProdutoModel prod, String qtde) async {
    retiradaprodModel? retirada = await retiradaprodModel()
        .getByIdProdIdTransfEnd(
            (prod.idproduto == null
                ? prod.id!.toUpperCase()
                : prod.idproduto!.toUpperCase()),
            widget.idtransf!.toUpperCase(),
            endRead!);
    if (retirada == null) {
      retirada = new retiradaprodModel(
          idRetirado: new Uuid().v4().toUpperCase(),
          endRetirado: endRead!,
          idtransfRetirado: widget.idtransf!.toUpperCase(),
          idProdRetirado: (prod.idproduto == null
              ? prod.id!.toUpperCase()
              : prod.idproduto!.toUpperCase()),
          nomeProdRetirado: prod.nome!,
          barcodeRetirado: prod.barcode!,
          qtdRetirado: qtde,
          loteRetirado: prod.lote!,
          validRetirado: prod.vali ?? "",
          idoperadorRetirado: idOperador);
      await retirada.insert();
    } else {
      retirada.qtdRetirado =
          (int.parse(retirada.qtdRetirado!) + int.parse(qtde)).toString();
      await retirada.update();
    }
    setState(() {});

    pendenteArmazModel? pendente = await pendenteArmazModel()
        .getByIdProdIdTransf(
            (prod.idproduto == null
                ? prod.id!.toUpperCase()
                : prod.idproduto!.toUpperCase()),
            widget.idtransf!.toUpperCase());

    if (pendente == null) {
      pendente = new pendenteArmazModel(
          id: new Uuid().v4().toUpperCase(),
          end: "",
          idProd: (prod.idproduto == null
              ? prod.id!.toUpperCase()
              : prod.idproduto!.toUpperCase()),
          idoperador: idOperador,
          idtransf: widget.idtransf!.toUpperCase(),
          lote: prod.lote!,
          qtd: qtde,
          valid: prod.vali ?? "",
          barcode: prod.barcode!,
          nomeProd: prod.nome!,
          situacao: "0");
      await pendente.insert();
    } else {
      pendente.qtd = (int.parse(pendente.qtd!) + int.parse(qtde)).toString();
      await pendente.update();
    }
    setState(() {});

    if (list.isEmpty || list.length == 0) {
      list = [];
      list.add(retirada);
    } else {
      retiradaprodModel? item = list
          .where(
            (element) =>
                element.idProdRetirado!.toLowerCase() ==
                    prod.idproduto!.toLowerCase() &&
                element.endRetirado == endRead,
          )
          .firstOrNull;

      if (item != null) {
        item.qtdRetirado = retirada.qtdRetirado;
      } else {
        list.add(retirada);
      }
    }
    countleituraProd++;
    setState(() {});
  }

  void getIdUser() async {
    SharedPreferences userlogged = await SharedPreferences.getInstance();
    this.idOperador = userlogged.getString('IdUser')!;
  }

  Future<void> removeItem(retiradaprodModel prodremove) async {
    list.removeWhere((e) =>
        e.idProdRetirado == prodremove.idProdRetirado &&
        e.idtransfRetirado == prodremove.idtransfRetirado);
    setState(() {});

    await prodremove.delete(prodremove.idRetirado!);
    new pendenteArmazModel()
        .deleteByProd(prodremove.idProdRetirado!, prodremove.idtransfRetirado!);

    setState(() {});
  }

  @override
  void dispose() {
    if (sub1 != null) {
      sub1!.cancel();
      //device.disconnect();
    }
    // _invisibleTextController.dispose();
    controller!.dispose();
    super.dispose();
  }

  @override
  void initState() {
    if (widget.listRetirada != null) {
      list = widget.listRetirada!;
      if (widget.end != null && widget.end != "") {
        endRead = widget.end ?? "";
        hasAdress = true;
      }
    }

    getIdUser();
    getContexto();
    _loadPreferences(); // Carrega as preferências para o estado do widget

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
              (route) => true,
            );
          }
        },
        child: Scaffold(
            appBar: AppBar(
                backgroundColor: primaryColor,
                title: Text(
                  widget.titulo!,
                  style: TextStyle(color: Colors.white),
                ),
                automaticallyImplyLeading: countleituraProd == 0),
            body: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                if (isCollectModeEnabled)
                  Offstage(
                    offstage: true,
                    child: BarcodeKeyboardListener(
                      bufferDuration: Duration(milliseconds: 50),
                      onBarcodeScanned: (barcode) async {
                        print(barcode);
                        await _readCodes(barcode);
                      },
                      child: TextField(
                        autofocus: true,
                        keyboardType: TextInputType.none,
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
                              await _readCodes(value);
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
                          : leituraExterna
                              ? showLeituraExterna == false
                                  ? BotaoIniciarApuracao(
                                      titulo: titleBtn == null ? "" : titleBtn!,
                                      onPressed: () {
                                        if (isCollectModeEnabled) {
                                          null;
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
                                      titulo: titleBtn == null ? "" : titleBtn!,
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
                Container(
                  padding: EdgeInsets.all(10),
                  color: !hasAdress ? Colors.grey[300] : Colors.yellow[300],
                  child: Container(
                    width: MediaQuery.of(context).size.width - 10,
                    child: endRead == null
                        ? Text(
                            "Nenhum endereço lido",
                            style: TextStyle(
                              fontSize: 25,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : Text(
                            endRead!,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
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
                      list.length,
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
                                list[index].qtdRetirado == null
                                    ? ""
                                    : list[index].qtdRetirado!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                list[index].nomeProdRetirado!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                list[index].endRetirado != null
                                    ? list[index].endRetirado!
                                    : "-",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                list[index].loteRetirado == null
                                    ? ""
                                    : list[index].loteRetirado!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Ink(
                                child: InkWell(
                                  child: Icon(
                                    Icons.delete,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onTap: () => {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Text("Atenção"),
                                        content: Text(
                                            "Deseja confimar a remoção do item?"),
                                        actions: [
                                          TextButton(
                                            child: Text("Não"),
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                          ),
                                          TextButton(
                                            child: Text("Sim"),
                                            onPressed: () async {
                                              await removeItem(list[index]);
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
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
              ],
            ),
            bottomSheet: SizedBox(
              height: MediaQuery.of(context).size.height * .2,
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 190,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          textStyle: const TextStyle(fontSize: 15)),
                      onPressed: () async {
                        setState(() {
                          isManual = !isManual;
                          showCamera = false;
                          showLeituraExterna = false;
                        });
                      },
                      child: Text(
                        isManual ? 'Cancelar digitação' : 'Digitar código',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        // padding: EdgeInsets.fromLTRB(10, 0, 10, ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              textStyle: const TextStyle(fontSize: 15)),
                          onPressed: () async {
                            Navigator.pop(context);
                            List<pendenteArmazModel> list =
                                await pendenteArmazModel().getAllpendente();
                            List<armprodModel> armlist =
                                await armprodModel().getAll();
                            if ((list != null && list.length > 0) ||
                                (armlist != null && armlist.length > 0)) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      ArmazenamentoTransf(
                                    listPendente: list,
                                    listarm: armlist,
                                  ),
                                ),
                                (route) => false,
                              );
                            } else {
                              Dialogs.showToast(
                                  context, "Não há itens a serem armazenados.",
                                  duration: Duration(seconds: 5),
                                  bgColor: Colors.red.shade200);
                            }
                          },
                          child: Center(
                            child: Text(
                              'Iniciar Armazenamento',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      if (hasAdress)
                        Container(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                textStyle: const TextStyle(fontSize: 15)),
                            onPressed: () {
                              setState(() {
                                endRead = null;
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
                ],
              ),
            ),
            bottomNavigationBar: BottomBar()),
      ),
    );
  }
}
