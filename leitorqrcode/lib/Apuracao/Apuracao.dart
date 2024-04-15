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
import 'package:leitorqrcode/Apuracao/components/ModalForcaFinalizacao.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Components/DashedRect.dart';
import 'package:leitorqrcode/Home/Home.dart';
import 'package:leitorqrcode/Infrastructure/AtualizarDados/atualizaOp.dart';
import 'package:leitorqrcode/Models/APIModels/Endereco.dart';
import 'package:leitorqrcode/Models/APIModels/EnderecoGrupo.dart';
import 'package:leitorqrcode/Models/APIModels/MovimentacaoMOdel.dart';
import 'package:leitorqrcode/Models/APIModels/OperacaoModel.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:leitorqrcode/Models/ContextoModel.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
import 'package:leitorqrcode/Services/ProdutoService.dart';
import 'package:leitorqrcode/Services/ProdutosDBService.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:leitorqrcode/notaFiscal/selecionarNotaFiscal.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class Apuracao extends StatefulWidget {
  final String titulo;
  final OperacaoModel operacaoModel;

  const Apuracao({
    Key? key,
    required this.titulo,
    required this.operacaoModel,
  }) : super(key: key);

  @override
  State<Apuracao> createState() => _ApuracaoState();
}

class _ApuracaoState extends State<Apuracao> {
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
  late QRViewController controller;
  Timer? temp;
  bool bluetoothDisconect = true;

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
  late BluetoothCharacteristic cNotify3;
  late StreamSubscription<List<int>> sub3;
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

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      _readCodes(scanData.code!);
    });
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
            ProdutoModel? prodDB = await new ProdutoModel().getByIdLoteIdPedido(
                prodRead.idloteunico!.toUpperCase(),
                widget.operacaoModel.id!.toUpperCase());

            List<ProdutoModel> lProdDB = await ProdutoModel()
                .getByIdProdIdOperacao(prodRead.idloteunico!.toUpperCase(),
                    widget.operacaoModel.id!.toUpperCase());

            if (lProdDB.length > 1) {
              var tqtd = 0;
              for (var i = 0; i < lProdDB.length; i++) {
                tqtd += int.parse(lProdDB[i].qtd ?? "0");
              }
            }

            if (prodDB != null) {
              var tqtd = int.parse(prodDB.qtd!);

              if (widget.operacaoModel.tipo == '21' ||
                  widget.operacaoModel.tipo == '31' ||
                  widget.operacaoModel.tipo == '72') {
                if (prodDB.end != endRead) {
                  Dialogs.showToast(context,
                      "O produto deve ser retirado do endereço " + prodDB.end!,
                      duration: Duration(seconds: 5),
                      bgColor: Colors.red.shade200);

                  isOK = false;
                } else if (prodRead.infVali!.trim() == 's' &&
                    (prodDB.lote != prodRead.lote ||
                        prodDB.vali != prodRead.vali)) {
                  Dialogs.showToast(context,
                      "O produto deve ter a validade e lote informado na nota fiscal.",
                      duration: Duration(seconds: 5),
                      bgColor: Colors.red.shade200);

                  isOK = false;
                }
              }

              if (widget.operacaoModel.tipo == '10' ||
                  widget.operacaoModel.tipo == '40') {
                ///conferir se o projeto trata grupo x endereço
                ///Tratar se o endereço atual pode amarzenar grupo do prodDB
                ///fazer selecrt na endereçogrupo
                if (contextoModel.enderecoGrupo == true &&
                    prodDB.codEndGrupo != null &&
                    prodDB.codEndGrupo!.isNotEmpty) {
                  EnderecoGrupoModel? enderecoGrupoModel =
                      await new EnderecoGrupoModel()
                          .getByGroupAndCod(endRead, prodDB.codEndGrupo);

                  if (enderecoGrupoModel == null) {
                    Dialogs.showToast(context,
                        "O produto deve ter a validade e lote informado na nota fiscal.",
                        duration: Duration(seconds: 5),
                        bgColor: Colors.red.shade200);
                    isOK = false;
                  }
                }
              }

              if (isOK) {
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
                            await calcQtdProduto(
                                prodRead, prodDB, qtdeProdDialog.text);
                            Navigator.pop(context);
                            setState(() {});
                          },
                        ),
                      ],
                      elevation: 24.0,
                    ),
                  );
                } else {
                  await calcQtdProduto(
                      prodRead,
                      prodDB,
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

  Future<void> calcQtdProduto(
      ProdutoModel prodRead, ProdutoModel prodDB, String qtdeprod) async {
    List<ProdutoModel> lProdDB = await ProdutoModel().getByIdProdIdOperacao(
        prodRead.idloteunico!.toUpperCase(),
        widget.operacaoModel.id!.toUpperCase());
    var tqtd = 0;
    if (lProdDB.length >= 1) {
      for (var i = 0; i < lProdDB.length; i++) {
        tqtd += int.parse(lProdDB[i].qtd ?? "0");
      }
    }

    bool qtdIsValid = int.tryParse(qtdeprod) != null ? true : false;
    if (!qtdIsValid) {
      Dialogs.showToast(
          context, "A quantidade informada não é valida \n tente novamente",
          duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
    } else if (tqtd < int.parse(qtdeprod)) {
      Dialogs.showToast(context,
          "A quantidade não pode ser maior que a informada na nota fiscal.",
          duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
    } else {
      if (lProdDB.length >= 1) {
        ProdutoModel? prodVirtual = await ProdutoModel()
            .getByIdProdIdOperacaoVirtual(prodRead.idloteunico!.toUpperCase(),
                widget.operacaoModel.id!.toUpperCase());

        String qtdtxt = qtdeprod;
        int qtdconsiderar = 0;
        int restante = 0;

        for (var i = 0; i < lProdDB.length; i++) {
          if (int.parse(qtdeprod) >= int.parse(lProdDB[i].qtd!) &&
              restante == 0) {
            restante = (int.parse(qtdeprod) - int.parse(lProdDB[i].qtd!));

            qtdconsiderar = int.parse(qtdtxt) - restante;
          } else if (restante > 0) {
            qtdconsiderar = restante;
            qtdeprod = restante.toString();

            if (restante <= int.parse(lProdDB[i].qtd!)) {
              restante = 0;
            }
          } else {
            qtdconsiderar = int.parse(qtdtxt);
          }

          if (int.parse(qtdeprod) <= 0) {
            break;
          }

          if (prodVirtual == null) {
            prodVirtual =
                await gerarProdVirtual(lProdDB[i], qtdconsiderar.toString());
            listProd.add(prodVirtual);
          } else {
            prodVirtual = listProd.firstWhere((e) =>
                e.idloteunico == prodVirtual!.idloteunico &&
                e.isVirtual == '1' &&
                e.idproduto == prodVirtual.idproduto);

            prodVirtual.qtd =
                (int.parse(prodVirtual.qtd!) + qtdconsiderar).toString();
            await prodVirtual.update();
          }

          if (int.parse(lProdDB[i].qtd!) <= qtdconsiderar) {
            qtdeprod = (qtdconsiderar - int.parse(lProdDB[i].qtd!)).toString();

            setState(() {
              listProd.removeWhere((e) =>
                  e.idloteunico == lProdDB[i].idloteunico &&
                  e.id == lProdDB[i].id);
            });
            await lProdDB[i].delete(lProdDB[i].id!);
          } else {
            qtdeprod = (qtdconsiderar - int.parse(lProdDB[i].qtd!)).toString();

            lProdDB[i].qtd =
                (int.parse(lProdDB[i].qtd!) - qtdconsiderar).toString();

            if (int.parse(lProdDB[i].qtd!) > 0) {
              await lProdDB[i].update();
              // if (int.parse(lProdDB[i].qtd) <=
              //     qtdconsiderar) {
              ProdutoModel prodlist = listProd.firstWhere((e) =>
                  e.idloteunico == lProdDB[i].idloteunico &&
                  e.id == lProdDB[i].id);
              prodlist.qtd = lProdDB[i].qtd;
              // }
            }
          }
          await saveMovimentacao(prodVirtual, prodRead,
              idProdutoPai: lProdDB[i].id);
        }
      } else {
        ProdutoModel? prodVirtual = await ProdutoModel()
            .getByIdProdIdOperacaoVirtual(prodRead.idloteunico!.toUpperCase(),
                widget.operacaoModel.id!.toUpperCase());

        if (prodVirtual == null) {
          prodVirtual = await gerarProdVirtual(prodDB, qtdeprod);
          listProd.add(prodVirtual);
        } else {
          prodVirtual = listProd.firstWhere((e) =>
              e.idloteunico == prodVirtual!.idloteunico &&
              e.isVirtual == '1' &&
              e.idproduto == prodVirtual.idproduto);

          prodVirtual.qtd =
              (int.parse(prodVirtual.qtd!) + int.parse(qtdeprod)).toString();
          await prodVirtual.update();
        }

        prodDB.qtd = (int.parse(prodDB.qtd!) - int.parse(qtdeprod)).toString();

        if (int.parse(prodDB.qtd!) > 0) {
          await prodDB.update();
          // if (int.parse(prodDB.qtd) <=
          //     int.parse(qtdeprod)) {
          ProdutoModel prodlist = listProd.firstWhere((e) =>
              e.idloteunico == prodDB.idloteunico &&
              e.idproduto == prodDB.idproduto);
          prodlist.qtd = prodDB.qtd;
          // }
        } else {
          await prodDB.delete(prodDB.id!);
          setState(() {
            listProd.removeWhere((e) =>
                e.idloteunico == prodDB.idloteunico &&
                e.idproduto == prodDB.idproduto);
          });
        }

        await saveMovimentacao(prodVirtual, prodRead,
            idProdutoPai: prodDB.idproduto);
      }
    }
  }

  Future<void> removeItem(ProdutoModel prod) async {
    MovimentacaoModel? moviDB = await new MovimentacaoModel()
        .getModelById(prod.idproduto!, prod.idOperacao!);

    if (moviDB != null) {
      if (moviDB.qtd != null) {
        moviDB.qtd = (int.parse(moviDB.qtd!) - 1).toString();

        if (int.parse(moviDB.qtd!) <= 0)
          await moviDB.deleteByIdOpIdProd(
              moviDB.idOperacao!, moviDB.idProduto!);
        else {
          await moviDB.updatebyId();
        }
      } else {
        await moviDB.deleteByIdOpIdProd(moviDB.idOperacao!, moviDB.idProduto!);
      }
    }

    ProdutoModel? itemList = listProd
        .where((e) =>
            e.idproduto == prod.idproduto &&
            e.idOperacao == prod.idOperacao &&
            (e.isVirtual == "0" || e.isVirtual == null))
        .firstOrNull;

    if (itemList != null) {
      itemList.qtd = (int.parse(itemList.qtd!) + 1).toString();
      itemList.end = prod.end ?? '';
      await itemList.update();
    } else {
      ProdutoModel newprod = ProdutoModel(
          id: new Uuid().v4().toUpperCase(),
          idproduto: prod.idproduto,
          barcode: prod.barcode,
          cod: prod.cod,
          codEndGrupo: prod.codEndGrupo,
          cx: prod.cx,
          desc: prod.desc,
          idOperacao: prod.idOperacao,
          idloteunico: prod.idloteunico,
          end: prod.end ?? '',
          qtd: "1",
          idprodutoPedido: prod.idprodutoPedido,
          isVirtual: '0',
          nome: prod.nome,
          lote: prod.lote,
          situacao: "0",
          vali: prod.vali,
          infVali: prod.infVali,
          infq: prod.infq,
          sl: prod.sl);

      newprod.qtd = "1";
      newprod.isVirtual = "0";
      await newprod.insert();
      listProd.add(newprod);
    }

    prod.qtd = (int.parse(prod.qtd!) - 1).toString();

    if (int.parse(prod.qtd!) <= 0) {
      await prod.deleteOnlyV(prod.id!);
      listProd.removeWhere((e) => e.id == prod.id && e.isVirtual == "1");
    } else {
      await prod.update();
      // listProd.removeWhere((e) => e.id == prod.id);
      // listProd.add(prod);
    }
    setState(() {});
  }

  Future<void> saveMovimentacao(ProdutoModel prodDB, ProdutoModel prodRead,
      {String? idProdutoPai}) async {
    prodDB.end = endRead;
    prodDB.situacao = "3";
    await prodDB.update();
    MovimentacaoModel? moviDB = await new MovimentacaoModel()
        .getModelById(prodDB.idproduto!, prodDB.idOperacao!);

    if (moviDB == null || moviDB.endereco != endRead) {
      MovimentacaoModel movi = new MovimentacaoModel();
      movi.id = new Uuid().v4().toUpperCase();
      movi.operacao = widget.operacaoModel.tipo;
      movi.idOperacao = widget.operacaoModel.id;
      movi.codMovi = widget.operacaoModel.nrdoc;
      movi.operador = idOperador;
      movi.endereco = endRead;
      movi.idProduto = prodDB.idproduto!;
      movi.qtd = prodRead.qtd ?? "1";
      DateTime today = new DateTime.now();
      String dateSlug =
          "${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year.toString()} ${today.hour}:${today.minute}:${today.second}";
      movi.dataMovimentacao = dateSlug;
      await movi.insert();
    } else {
      moviDB.qtd = prodDB.qtd!;
      await moviDB.updatebyIdOpProdEnd();
    }

    if (prodDB.isVirtual == '1') {
      setState(() {
        ProdutoModel itemList = listProd.firstWhere(
            (element) => element.id!.toUpperCase() == prodDB.id!.toUpperCase());

        itemList.end = endRead;
        itemList.situacao = "3";
      });

      if (listProd.where((element) => element.situacao != "3").length == 0) {
        await finalizarOp();
        if (widget.operacaoModel.tipo == '40') {
          OperacaoModel? opRetirada =
              await OperacaoModel().getPendenteAramazenamento();
          opRetirada!.situacao = "3";
          await opRetirada.update();
        }

        Dialogs.showToast(context, "Leitura concluída",
            duration: Duration(seconds: 5), bgColor: Colors.green.shade200);
        setState(() {
          this.hasAdress = false;
          this.prodReadSuccess = true;
        });
      }
    }

    countleituraProd++;
    setState(() {});
  }

  finalizarOp() async {
    widget.operacaoModel.situacao = "3";
    await widget.operacaoModel.update();
  }

  void getIdUser() async {
    SharedPreferences userlogged = await SharedPreferences.getInstance();
    this.idOperador = userlogged.getString('IdUser')!;
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
    listProd = widget.operacaoModel.prods!;

    listProd.sortBy((prod) => prod.end ?? "-");

    var count = listProd.where((element) => element.situacao == "3").length;
    getIdUser();
    getContexto();
    _loadPreferences();

    if (count == listProd.length) {
      Dialogs.showToast(context, "Leitura já realizada");
      this.prodReadSuccess = true;
      this.hasAdress = false;
    }

    if (widget.operacaoModel.tipo != null)
      widget.operacaoModel.tipo = widget.operacaoModel.tipo!.trim();
    else
      widget.operacaoModel.tipo = "";

    if (widget.operacaoModel.tipo == "10" || widget.operacaoModel.tipo == "40")
      titleBtn = "Iniciar Armazenamento";
    else if (widget.operacaoModel.tipo == "21" ||
        widget.operacaoModel.tipo == "31" ||
        widget.operacaoModel.tipo == "72")
      titleBtn = "Iniciar Retirada";
    else if (widget.operacaoModel.tipo == "41")
      titleBtn = "Iniciar Armazenamento";
    else if (widget.operacaoModel.tipo == "20" ||
        widget.operacaoModel.tipo == "30")
      titleBtn = "Iniciar Devolução";
    else if (widget.operacaoModel.tipo == "90") titleBtn = "Iniciar Contagem";

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
                    text: widget.titulo,
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
                      child: BarcodeKeyboardListener(
                        bufferDuration: Duration(milliseconds: 50),
                        onBarcodeScanned: (barcode) async {
                          print(barcode);
                          _readCodes(barcode);
                        },
                        child: TextField(
                            autofocus: true, keyboardType: TextInputType.none),
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
                              if (widget.operacaoModel.tipo == '10' &&
                                  listProd
                                      .where((a) => a.situacao == '3')
                                      .isNotEmpty)
                                Container(
                                  width: 100,
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: secondary,
                                          textStyle:
                                              const TextStyle(fontSize: 12)),
                                      onPressed: () {
                                        showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (_) =>
                                                modalForcaFinalizacao(
                                                    op: widget.operacaoModel,
                                                    psw: widget
                                                        .operacaoModel.id!
                                                        .split('-')[1]));
                                      },
                                      child: Text('Finalizar')),
                                ),
                              Container(
                                width: (widget.operacaoModel.tipo == '10' &&
                                        listProd
                                            .where((a) => a.situacao == '3')
                                            .isNotEmpty)
                                    ? MediaQuery.of(context).size.width - 120
                                    : MediaQuery.of(context).size.width - 10,
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
                                    color: listProd[index].situacao == "3"
                                        ? Colors.green
                                        : Colors.grey,
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
                                DataCell(
                                  listProd[index].situacao == "3" &&
                                          !prodReadSuccess
                                      ? Ink(
                                          child: InkWell(
                                            child: Icon(
                                              Icons.delete,
                                              size: 30,
                                              color: Colors.red,
                                            ),
                                            onTap: () async => {
                                              await removeItem(listProd[index])
                                            },
                                          ),
                                        )
                                      : Text(""),
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
            ),
            bottomSheet: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!prodReadSuccess)
                  Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          textStyle: const TextStyle(fontSize: 15)),
                      onPressed: () async {
                        await syncOp(context, false);

                        if (widget.operacaoModel.tipo == "72") {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => AlertDialog(
                              title: Text(
                                "Atenção",
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              content: Text("Deseja criar embalagem?"),
                              actions: [
                                TextButton(
                                  child: const Text('Não'),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (BuildContext context) =>
                                              HomeScreen(),
                                        ),
                                        ModalRoute.withName('/HomeScreen'));
                                  },
                                ),
                                TextButton(
                                  child: Text("Sim"),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (BuildContext context) =>
                                              SelecionarNotaFiscal(
                                                  idPedido:
                                                      widget.operacaoModel.id!),
                                        ),
                                        ModalRoute.withName('/HomeScreen'));
                                  },
                                ),
                              ],
                              elevation: 24.0,
                            ),
                          );
                        } else
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
                          backgroundColor: primaryColor,
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

  Future<ProdutoModel> gerarProdVirtual(ProdutoModel prod, String qtd) async {
    ProdutoModel prodVirtual = new ProdutoModel(
        id: new Uuid().v4().toUpperCase(),
        cod: prod.cod,
        idprodutoPedido: prod.idprodutoPedido,
        idproduto: prod.idproduto,
        desc: prod.desc,
        end: prod.end,
        idOperacao: prod.idOperacao,
        idloteunico: prod.idloteunico,
        infq: prod.infq,
        sl: prod.sl,
        lote: prod.lote,
        nome: prod.nome,
        qtd: qtd,
        situacao: prod.situacao,
        vali: prod.vali);

    prodVirtual.isVirtual = '1';
    await prodVirtual.insert();

    List<ProdutoModel> list =
        await ProdutoService().getProdutos(prod.idOperacao!);
    print(list);

    return prodVirtual;
  }
}
