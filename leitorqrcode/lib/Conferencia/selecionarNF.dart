import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Conferencia/components/button_conferencia.dart';
import 'package:leitorqrcode/Conferencia/conferenciaExpedicao.dart';
import 'package:leitorqrcode/Infrastructure/AtualizarDados/atualizaOp.dart';
import 'package:leitorqrcode/Models/APIModels/NfEmbalagemResponse.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoConfItensPedidoModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoPedidoCargaModel.dart';
import 'package:leitorqrcode/Services/CargasService.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:leitorqrcode/notaFiscal/components/select_card_fiscal.dart';

class SelecionarNotaFiscalExpedicao extends StatefulWidget {
  final RetornoPedidoCargaModel retorno;
  const SelecionarNotaFiscalExpedicao({
    Key? key,
    required this.retorno,
  }) : super(key: key);

  @override
  State<SelecionarNotaFiscalExpedicao> createState() =>
      _SelecionarNotaFiscalExpedicaoState();
}

class _SelecionarNotaFiscalExpedicaoState
    extends State<SelecionarNotaFiscalExpedicao> {
  ContextoServices contextoServices = ContextoServices();
  int? selectedCardIndex;
  String idUser = "";

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
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getIdUser();
      // await _getCargas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: primaryColor,
        title: Text('Selecionar Nota Fiscal',
            style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.retorno.data?.length ?? 0,
              itemBuilder: (context, index) {
                var notaFiscal = widget.retorno.data![index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SelectCardFiscal(
                    isSelected: selectedCardIndex == index,
                    onTap: () {
                      setState(() {
                        selectedCardIndex = index;
                      });
                    },
                    numeroNota: notaFiscal.nro,
                    serieNota: notaFiscal.serie,
                    nomeNota: notaFiscal.cliente ?? "Cliente Desconhecido",
                  ),
                );
              },
            ),
          ),
          ButtonConference(
            label: 'Finalizar Expedição',
            onTap: () async {
              CargasServices cargasServices = CargasServices(context);

              RetornoConfItensPedidoModel? respostaConfItensPedido =
                  await cargasServices.getConfItensPedido(idUser,
                      widget.retorno.data![selectedCardIndex!].idPedido);

              if (respostaConfItensPedido != null &&
                  !respostaConfItensPedido.error) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConferenciaExpedicaoScreen(
                        retorno: respostaConfItensPedido),
                  ),
                );
              } else {
                Dialogs.showToast(context,
                    "Erro ao buscar pedidos de carga: ${respostaConfItensPedido?.message}",
                    duration: Duration(seconds: 5),
                    bgColor: Colors.red.shade200);
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(),
    );
  }
}
