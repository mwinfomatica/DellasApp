import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoGetEmbalagemListModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoNotasFiscaisModel.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
import 'package:leitorqrcode/Services/NotasFiscaisService.dart';
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

    return Scaffold(
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
          GestureDetector(
            onTap: () async {
              if (selectedCardIndex != null && dadosNotasFiscais != null) {
                var selectedData = dadosNotasFiscais!.data[selectedCardIndex!];
                await _getEmbalagemList(selectedData.idPedido);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => SelecionarEmbalagem(
                      nfeDados: selectedData,
                      dadosEmbalagem: dadosNotaFiscal!.data,
                    ),
                  ),
                );
              }
            },
            child: Container(
              width: width * 0.9,
              height: 60,
              decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.green),
              child: Center(
                child: Text(
                  'Liberar para Expedição',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: BottomBar(),
    );
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
