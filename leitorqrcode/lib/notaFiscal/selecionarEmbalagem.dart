import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Models/APIModels/EmbalagemListResponse.dart';
import 'package:leitorqrcode/Models/APIModels/EmbalagemModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoGetCreateEmbalagemModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoGetEmbalagemListModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoNotasFiscaisModel.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
import 'package:leitorqrcode/Services/NotasFiscaisService.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:leitorqrcode/notaFiscal/detailsEmbalagem.dart';
import 'package:leitorqrcode/notaFiscal/montarEmbalagem.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:leitorqrcode/notaFiscal/selecionarNotaFiscal.dart';
import 'package:leitorqrcode/printer/printer_controller.dart';

class SelecionarEmbalagem extends StatefulWidget {
  final List<EmbalagemData> dadosEmbalagem;
  final Pedido nfeDados;
  final String IdPedidoRetiradaCarga;
  const SelecionarEmbalagem({
    Key? key,
    required this.nfeDados,
    required this.dadosEmbalagem,
    required this.IdPedidoRetiradaCarga,
  }) : super(key: key);

  @override
  State<SelecionarEmbalagem> createState() => _SelecionarEmbalagemState();
}

class _SelecionarEmbalagemState extends State<SelecionarEmbalagem> {
  ContextoServices contextoServices = ContextoServices();
  int? selectedCardIndex;
  List<EmbalagemDados> listdadosEmbalagem = [];
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  bool bluetoothConnected = false;
  RetornoGetCreateEmbalagemModel? dadosRetornoCreateEmbalagem;

  Future<void> _initValidationPrinter() async {
    List<BluetoothDevice> devices = [];

    try {
      devices = await bluetooth.getBondedDevices();
      // ignore: empty_catches
    } on PlatformException {}

    bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
          bluetoothConnected = true;
          setState(() {});
          break;
        case BlueThermalPrinter.DISCONNECTED:
          bluetoothConnected = false;
          setState(() {});
          break;
        default:
          break;
      }
    });

    for (var i = 0; i < devices.length; i++) {
      if (devices[i].name!.trim().toUpperCase().contains("4B-2044PA-43C8")) {
        _connect(devices[i]);
        break;
      }
    }

    if (!mounted) return;
    setState(() {});
  }

  void _connect(BluetoothDevice device) {
    if (device == null) {
      bluetoothConnected = false;
    } else {
      bluetooth.isConnected.then((isConnected) {
        bluetoothConnected = isConnected == true;
        if (!isConnected!) {
          bluetooth.connect(device).catchError((error) {});
        }
      });
    }
  }

  Future<void> _getEmbalagemList(String idPedido) async {
    NotasFiscaisService notasFiscaisService = NotasFiscaisService(context);

    try {
      RetornoGetEmbalagemListModel? dadosNotaFiscal =
          await notasFiscaisService.getEmbalagemList(idPedido);
      if (dadosNotaFiscal != null) {
        setState(() {
          dadosNotaFiscal = dadosNotaFiscal;
        });
      }
    } catch (e) {
      print('Erro ao processar carga: $e');
    }
  }

  @override
  void initState() {
    _initValidationPrinter();
    super.initState();
    // chamada de API para buscar os dados da embalagem
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return SafeArea(
      child: PopScope(
        canPop: false,
        onPopInvoked: (canPop) => {
          if (!canPop)
            {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => SelecionarNotaFiscal(
                    idPedido: widget.IdPedidoRetiradaCarga,
                  ),
                ),
                (route) => false,
              )
            }
        },
        child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              automaticallyImplyLeading: false,
              backgroundColor: primaryColor,
              title: Text(
                'Selecionar Embalagem',
                style: TextStyle(color: Colors.white),
              ),
            ),
            body: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Nota: " +
                                widget.nfeDados.nrNfe +
                                " / " +
                                (widget.nfeDados.serieNfe.isEmpty
                                    ? "-"
                                    : widget.nfeDados.serieNfe),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            "Cliente: " +
                                (widget.nfeDados.nomeCliente.isEmpty
                                    ? "-"
                                    : widget.nfeDados.nomeCliente),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                _buildButtons(width),
                SizedBox(
                  height: 10,
                ),
                widget.dadosEmbalagem.isNotEmpty
                    ? tableItensNotafiscal()
                    : Center(
                        child: Text(
                        'Sem embalagens',
                        style: TextStyle(fontSize: 18.0),
                      ))
              ],
            ),
            bottomNavigationBar: BottomBar()),
      ),
    );
  }

  Widget _buildButtons(double width) {
    return Center(
      child: SizedBox(
        width: width * 0.9,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () async => {
                await printEmbalagem(),
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
                    'Imprimir',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                await _createEmbalagem(widget.nfeDados.idPedido);
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
                    'Criar Embalagem',
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

  Future<void> printEmbalagem() async {
    List<EmbalagemPrinter>? listembprint = [];

    NotasFiscaisService notasFiscaisService = NotasFiscaisService(context);

    try {
      List<String> idEmbalagens = [];

      for (var i = 0; i < widget.dadosEmbalagem.length; i++) {
        idEmbalagens.add(widget.dadosEmbalagem[i].idEmbalagem);
      }

      RetornoGetDadosEmbalagemListModel? rtndadosEmbalagem =
          await notasFiscaisService.getDadosPrinterEmbalagem(idEmbalagens);

      if (rtndadosEmbalagem != null) {
        if (!rtndadosEmbalagem.error) {
          listembprint = rtndadosEmbalagem.data;
        }
      }
      else {
        return;
      }
    } catch (e) {
      print('Erro ao processar carga: $e');
    }

    await _initValidationPrinter();

    await PrinterController().printQrCodeEmbalagem(
      listemb: listembprint ?? [],
      bluetooth: bluetooth,
      context: context,
    );

    await _getEmbalagemList(widget.IdPedidoRetiradaCarga);
  }

  Future<void> _createEmbalagem(String idPedido) async {
    NotasFiscaisService notasFiscaisService = NotasFiscaisService(context);

    try {
      RetornoGetCreateEmbalagemModel? dadosNotaFiscal =
          await notasFiscaisService.getCreateEmbalagem(idPedido);
      if (dadosNotaFiscal != null) {
        setState(() {
          dadosRetornoCreateEmbalagem = dadosNotaFiscal;
        });

        if (dadosNotaFiscal.data
                .where((e) => e.quantNota > e.quantEmbalado)
                .length >
            0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => MontarEmbalagem(
                  idPedido: idPedido,
                  dadosCreateEmbalagem: dadosRetornoCreateEmbalagem!,
                  pedido: widget.nfeDados,
                  IdPedidoRetiradaCarga: widget.IdPedidoRetiradaCarga),
            ),
            (route) => false,
          );
        } else {
          Dialogs.showToast(context,
              "Não há mais Quantidade disponivel para criar uma embalagem",
              duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
          return;
        }
      }
    } catch (e) {
      print('Erro ao processar carga: $e');
    }
  }

  Widget tableItensNotafiscal() {
    return Center(
      child: SingleChildScrollView(
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
            dataRowHeight: 30,
            columnSpacing: 50,
            horizontalMargin: 20,
            columns: [
              DataColumn(
                label: Text(
                  "Seq",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  "Stauts",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
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
              widget.dadosEmbalagem.length,
              (index) {
                return DataRow(
                  color: MaterialStateColor.resolveWith(
                    (states) =>
                        index % 2 == 0 ? Colors.white : Colors.grey[200]!,
                  ),
                  cells: [
                    DataCell(
                      Text(
                        widget.dadosEmbalagem[index].sequencial,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        widget.dadosEmbalagem[index].status.toString(),
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
                            Icons.remove_red_eye_sharp,
                            size: 30,
                            color: Colors.orange.shade400,
                          ),
                          onTap: () async => {
                            await DetailsEmb(widget.dadosEmbalagem[index]),
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
      ),
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
                child: Center(child: Text('Seq', style: headerStyle)),
              ),
            ),
          ),
          TableCell(
            child: Center(
              child: SizedBox(
                height: cellHeight,
                child: Center(child: Text('Status', style: headerStyle)),
              ),
            ),
          ),
          TableCell(
            child: Center(
              child: SizedBox(
                height: cellHeight,
                child: Center(child: Text('Ação', style: headerStyle)),
              ),
            ),
          ),
        ],
      );
    }

    TableRow _buildRow(EmbalagemData embalagem, int index) {
      return TableRow(
        children: [
          TableCell(
            child: Center(
              child: Text('${index + 1}', style: cellStyle),
            ),
          ),
          TableCell(
            child: Center(
              child: Text(embalagem.status, style: cellStyle),
            ),
          ),
          TableCell(
            child: Center(
              child: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  // Aqui você pode implementar a lógica para editar a embalagem
                  // Por exemplo, abrir uma tela de edição com os dados da embalagem
                },
              ),
            ),
          ),
        ],
      );
    }

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
        ...List.generate(widget.dadosEmbalagem.length,
            (index) => _buildRow(widget.dadosEmbalagem[index], index)).toList(),
      ],
    );
  }

  DetailsEmb(EmbalagemData dadosemb) async {
    NotasFiscaisService notaservice = NotasFiscaisService(context);
    RetornoGetDetailsEmbalagemModel? dadosNotaFiscal =
        await notaservice.getDetailsItensEmbalagem(dadosemb.idEmbalagem);
    if (dadosNotaFiscal != null) {
      if (dadosNotaFiscal.data != null && dadosNotaFiscal.data.length > 0) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => DetailsEmbalagem(
                idPedido: dadosemb.idPedido,
                dadosCreateEmbalagem: dadosNotaFiscal,
                idEmbalagem: dadosemb.idEmbalagem,
                sequencial: dadosemb.sequencial,
                status: dadosemb.status,
                pedido: widget.nfeDados,
                IdPedidoRetiradaCarga: widget.IdPedidoRetiradaCarga),
          ),
          (route) => false,
        );
      }
    }
  }
}
