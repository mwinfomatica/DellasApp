import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Models/APIModels/EmbalagemListResponse.dart';
import 'package:leitorqrcode/Models/APIModels/NfEmbalagemResponse.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
import 'package:leitorqrcode/notaFiscal/montarEmbalagem.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:leitorqrcode/printer/printer_controller.dart';

class SelecionarEmbalagem extends StatefulWidget {
  final NfeDados nfeDados;
  const SelecionarEmbalagem({
    Key? key,
    required this.nfeDados,
  }) : super(key: key);

  @override
  State<SelecionarEmbalagem> createState() => _SelecionarEmbalagemState();
}

class _SelecionarEmbalagemState extends State<SelecionarEmbalagem> {
  ContextoServices contextoServices = ContextoServices();
  int? selectedCardIndex;
  List<EmbalagemDados> dadosEmbalagem = [];
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  bool bluetoothConnected = false;

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

  @override
  void initState() {
    _initValidationPrinter();
    super.initState();
    // chamada de API para buscar os dados da embalagem
  }

  final List<EmbalagemDados> dadosEmbalagemSimulados = [
    EmbalagemDados(
      idPedido: "a9fb2fd1-eab8-4aec-bd15-0a403759d9d5",
      sequencial: "1",
      idEmbalagem: "e64f1c8a-7919-4383-b19b-47c199041f83",
      status: "Finalizada",
    ),
    EmbalagemDados(
      idPedido: "a9fb2fd1-eab8-4aec-bd15-0a403759d9d5",
      sequencial: "2",
      idEmbalagem: "59b58468-23d8-40ed-96cb-9eb543d625f6",
      status: "Em Aberto",
    ),
    // Adicione mais objetos EmbalagemDados conforme necessário para simulação
  ];

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
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
            SizedBox(
              height: height * 0.02,
            ),
            _buildButtons(width),
            SizedBox(
              height: 20,
            ),
            Container(
              width:
                  width * 0.9, // Define a largura para 90% da largura da tela
              child: _buildCustomTable(width, dadosEmbalagemSimulados),
            ),
          ],
        ),
        bottomNavigationBar: BottomBar());
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
                PrinterController().printCupomComandaIndividual(
                  username: "",
                  bluetooth: bluetooth,
                  context: context,
                )
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => MontarEmbalagem()),
                );
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

  Widget _buildCustomTable(double width, List<EmbalagemDados> dadosEmbalagem) {
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

    TableRow _buildRow(EmbalagemDados embalagem, int index) {
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
        ...List.generate(dadosEmbalagem.length,
            (index) => _buildRow(dadosEmbalagem[index], index)).toList(),
      ],
    );
  }
}
