import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Conferencia/components/button_conferencia.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoConfItensPedidoModel.dart';
import 'package:leitorqrcode/Services/CargasService.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

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
  ContextoServices contextoServices = ContextoServices();
  int? selectedCardIndex;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

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
            'Montagem de Embalagem',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: height * 0.15,
                  child: _buildQrView(context),
                ),
                SizedBox(
                  height: 20,
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
                  label: 'Finalizar',
                  onTap: () async {},
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomBar());
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
        _buildForceButton()
      ],
    );
  }

  Widget _buildForceButton() {
    return Positioned(
      right: 10,
      top: 15,
      child: GestureDetector(
        onTap: () async {
          await forcarConferencia();
        },
        child: Container(
          width: 40.0,
          height: 40.0,
          decoration: BoxDecoration(
              color: Colors.grey.shade300, border: Border.all(width: 0.5)),
          child: Center(
            child: Container(
              width: 25.0,
              height: 25.0,
              decoration: BoxDecoration(
                border: Border.all(width: 0.5),
                color: Colors.redAccent.shade100,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;

    return QRView(
      key: qrKey,
      overlay: QrScannerOverlayShape(
          borderColor: primaryColor,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
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
