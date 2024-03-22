import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Models/APIModels/EmbalagemModel.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoBase.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoGetEmbalagemListModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoNotasFiscaisModel.dart';
import 'package:leitorqrcode/Models/ContextoModel.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
import 'package:leitorqrcode/Services/NotasFiscaisService.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:leitorqrcode/notaFiscal/selecionarEmbalagem.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailsEmbalagem extends StatefulWidget {
  final RetornoGetDetailsEmbalagemModel dadosCreateEmbalagem;
  final String idPedido;
  final String? idEmbalagem;
  final String sequencial;
  final String status;
  final Pedido pedido;
  final String IdPedidoRetiradaCarga;
  const DetailsEmbalagem({
    Key? key,
    required this.dadosCreateEmbalagem,
    required this.idPedido,
    this.idEmbalagem,
    required this.sequencial,
    required this.status,
    required this.pedido,
    required this.IdPedidoRetiradaCarga,
  }) : super(key: key);

  @override
  State<DetailsEmbalagem> createState() => _MontarEmbalagemState();
}

class _MontarEmbalagemState extends State<DetailsEmbalagem> {
  String idOperador = "";
  String titleBtn = '';
  final animateListKey = GlobalKey<AnimatedListState>();
  String textExterno = "";
  final FlutterBlue flutterBlue = FlutterBlue.instance;

  List<ProdutoModel> listProd = [];
  bool bluetoothDisconect = true;
  RetornoGetEmbalagemListModel? dadosNotaFiscal;
  List<ItensEmbalagem> list = [];

  ContextoServices contextoServices = ContextoServices();
  ContextoModel contextoModel =
      ContextoModel(leituraExterna: false, descLeituraExterna: "");

  void getIdUser() async {
    SharedPreferences userlogged = await SharedPreferences.getInstance();
    this.idOperador = userlogged.getString('IdUser')!;
  }

  @override
  void initState() {
    getIdUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: primaryColor,
            automaticallyImplyLeading: false,
            title: ListTile(
              title: RichText(
                maxLines: 2,
                text: TextSpan(
                  text: "Detalhes da Embalagem",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
              trailing: Container(
                height: 1,
                width: 1,
              ),
            ),
          ),
          body: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Embalagem: " + widget.sequencial,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            "Status: " + widget.status,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
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
                      child: Text(
                        widget.dadosCreateEmbalagem.data[index].qtd!.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      widget.dadosCreateEmbalagem.data[index].descProd != null
                          ? widget.dadosCreateEmbalagem.data[index].descProd!
                              .trim()
                          : " - ",
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

  Widget _buildButtons(double width) {
    return Center(
      child: SizedBox(
        width: width * 0.9,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () async {
                await _getEmbalagemList(widget.idPedido);

                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => SelecionarEmbalagem(
                        nfeDados: widget.pedido,
                        dadosEmbalagem: dadosNotaFiscal!.data,
                        IdPedidoRetiradaCarga: widget.IdPedidoRetiradaCarga,
                      ),
                    ),
                    (route) => false);
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
                    'Voltar',
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
                await ExcluirEmbalagem(),
              },
              child: Container(
                width: width * 0.43,
                height: 60,
                decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.red),
                child: Center(
                  child: Text(
                    'Excluir',
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

  ExcluirEmbalagem() async {
    EmbalagemModel emb =
        EmbalagemModel(idOperador, widget.idEmbalagem, widget.idPedido, list);

    NotasFiscaisService nfservice = NotasFiscaisService(context);

    RetornoBaseModel? rtn = await nfservice.DeleteEmbalagem(emb.idEmbalagem!);

    if (rtn != null) {
      if (!rtn.error!) {
        Dialogs.showToast(
            context, rtn.message ?? "Embalagem excluída com sucesso.",
            duration: Duration(seconds: 5), bgColor: Colors.green.shade200);

        await _getEmbalagemList(widget.idPedido);

        if (dadosNotaFiscal == null) {
          dadosNotaFiscal =
              RetornoGetEmbalagemListModel(error: false, message: "", data: []);
          setState(() {});
        }
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
}
