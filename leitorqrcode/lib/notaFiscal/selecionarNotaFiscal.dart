import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Models/APIModels/NfEmbalagemResponse.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
import 'package:leitorqrcode/notaFiscal/components/select_card_fiscal.dart';
import 'package:leitorqrcode/notaFiscal/selecionarEmbalagem.dart';

class SelecionarNotaFiscal extends StatefulWidget {
  final String idGrupo;
  final String idCarga;
  const SelecionarNotaFiscal({
    Key? key,
    required this.idGrupo,
    required this.idCarga,
  }) : super(key: key);

  @override
  State<SelecionarNotaFiscal> createState() => _SelecionarNotaFiscalState();
}

class _SelecionarNotaFiscalState extends State<SelecionarNotaFiscal> {
  ContextoServices contextoServices = ContextoServices();
  int? selectedCardIndex;

  // Método para simular os dados retornados pelo endpoint
  NfeEmbalagemResponse getSimulatedData() {
    return NfeEmbalagemResponse(
      error: false,
      message: "sucesso",
      data: [
        NfeDados(
          idPedido: "a9fb2fd1-eab8-4aec-bd15-0a403759d9d5",
          nrNfe: "059547",
          serieNfe: "1",
          nomeCliente: "Cliente A",
        ),
        NfeDados(
          idPedido: "a9fb2fd1-eab8-4aec-bd15-0a403759d9d5",
          nrNfe: "059548",
          serieNfe: "2",
          nomeCliente: "Cliente B",
        ),
        NfeDados(
          idPedido: "a9fb2fd1-eab8-4aec-bd15-0a403759d9d5",
          nrNfe: "059549",
          serieNfe: "3",
          nomeCliente: "Cliente C",
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    // Obtém os dados simulados
    NfeEmbalagemResponse dadosSimulados = getSimulatedData();

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
              itemCount: dadosSimulados.data.length,
              itemBuilder: (context, index) {
                var notaFiscal = dadosSimulados.data[index];
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
                    serieNota: notaFiscal.serieNfe,
                    nomeNota: notaFiscal.nomeCliente,
                  ),
                );
              },
            ),
          ),
          GestureDetector(
            onTap: () {
              if (selectedCardIndex != null) {
                // Assumindo que você tenha uma lista de NfeDados
                var selectedData = dadosSimulados.data[selectedCardIndex!];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) =>
                        SelecionarEmbalagem(nfeDados: selectedData),
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
}
