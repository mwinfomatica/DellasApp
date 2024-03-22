import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Home/Home.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoGetEmbalagemListModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoNotasFiscaisModel.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
import 'package:leitorqrcode/Services/NotasFiscaisService.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:leitorqrcode/notaFiscal/components/select_card_fiscal.dart';
import 'package:leitorqrcode/notaFiscal/selecionarEmbalagem.dart';

class SelecionarNotaFiscal extends StatefulWidget {
  final String idPedido;
  const SelecionarNotaFiscal({
    Key? key,
    required this.idPedido,
  }) : super(key: key);

  @override
  State<SelecionarNotaFiscal> createState() => _SelecionarNotaFiscalState();
}

class _SelecionarNotaFiscalState extends State<SelecionarNotaFiscal> {
  ContextoServices contextoServices = ContextoServices();
  int? selectedCardIndex;
  RetornoNotasFiscaisModel? dadosNotasFiscais;
  RetornoGetEmbalagemListModel? dadosNotaFiscal;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getNotas();
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

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
            centerTitle: true,
            automaticallyImplyLeading: false,
            backgroundColor: primaryColor,
            title: Text(
              'Selecionar Nota Fiscal',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: dadosNotasFiscais?.data.length ?? 0,
                  itemBuilder: (context, index) {
                    var notaFiscal = dadosNotasFiscais!.data[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: SelectCardFiscal(
                        isSelected: selectedCardIndex == index,
                        onTap: () {
                          setState(() {
                            selectedCardIndex = index;
                          });
                        },
                        numeroNota: notaFiscal.nrNfe,
                        serieNota: notaFiscal.serieNfe.isEmpty
                            ? 'Sem Série'
                            : notaFiscal.serieNfe,
                        nomeNota: notaFiscal.nomeCliente.isEmpty
                            ? 'Sem nome'
                            : notaFiscal.nomeCliente,
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (BuildContext context) => HomeScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: width * 0.3,
                        height: 50,
                        decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(10),
                            color: primaryColor),
                        child: Center(
                          child: Text(
                            'Menu',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: GestureDetector(
                      onTap: () async {
                        if (selectedCardIndex != null &&
                            dadosNotasFiscais != null) {
                          var selectedData =
                              dadosNotasFiscais!.data[selectedCardIndex!];
                          await _getEmbalagemList(selectedData.idPedido);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  SelecionarEmbalagem(
                                nfeDados: selectedData,
                                dadosEmbalagem: dadosNotaFiscal != null
                                    ? dadosNotaFiscal!.data
                                    : [],
                                IdPedidoRetiradaCarga: widget.idPedido,
                              ),
                            ),
                          );
                        } else {
                          Dialogs.showToast(
                              context, "Gentileza selecionar uma nota fiscal.",
                              duration: Duration(seconds: 5),
                              bgColor: Colors.orange.shade200);
                        }
                      },
                      child: Container(
                        width: width * 0.5,
                        height: 50,
                        decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.green),
                        child: Center(
                          child: Text(
                            'Embalagens',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
          bottomNavigationBar: BottomBar(),
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

  Future<void> _getNotas() async {
    NotasFiscaisService notasFiscaisService = NotasFiscaisService(context);

    try {
      RetornoNotasFiscaisModel? dadosCarga =
          await notasFiscaisService.getNotasFiscais(widget.idPedido);
      if (dadosCarga != null) {
        setState(() {
          dadosNotasFiscais = dadosCarga;
        });
      }
    } catch (e) {
      print('Erro ao processar carga: $e');
    }
  }
}
