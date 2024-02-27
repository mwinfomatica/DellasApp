import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class MontarEmbalagem extends StatefulWidget {
  const MontarEmbalagem({
    Key? key,
  }) : super(key: key);

  @override
  State<MontarEmbalagem> createState() => _MontarEmbalagemState();
}

class _MontarEmbalagemState extends State<MontarEmbalagem> {
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
          child: Column(
            children: [
              SizedBox(
                height: height * 0.15,
                child: _buildQrView(context),
              ),
              SizedBox(
                height: height * 0.02,
              ),
              _buildButtons(width),
              SizedBox(
                height: 20,
              ),
              Text(
                'Itens da Nota Fiscal',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              Container(
                width:
                    width * 0.9, // Define a largura para 90% da largura da tela
                child: _buildCustomTable(width),
              ),
              SizedBox(
                height: 40,
              ),
              Text(
                'Itens da Embalagem',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              Container(
                width:
                    width * 0.9, // Define a largura para 90% da largura da tela
                child: _buildItensEmbalagem(width),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomBar());
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

  Widget _buildButtons(double width) {
    return Center(
      child: SizedBox(
        width: width * 0.9,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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

  Widget _buildCustomTable(double width) {
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

    // Cria uma única linha de dados
    TableRow _buildRow(int index) {
      return TableRow(
        children: [
          TableCell(child: Center(child: Text('', style: cellStyle))),
          TableCell(
              child: Center(child: Text('${index + 1}', style: cellStyle))),
          TableCell(child: Center(child: Text('Em Aberto', style: cellStyle))),
          TableCell(
            child: Center(
              child: IconButton(
                icon: Icon(Icons.edit),
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
        0: FlexColumnWidth(0.5),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(2),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _buildHeader(),
        ...List.generate(3, (index) => _buildRow(index)).toList(),
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
