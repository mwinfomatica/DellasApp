import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Conferencia/components/button_conferencia.dart';
import 'package:leitorqrcode/Conferencia/conferenciaExpedicao.dart';
import 'package:leitorqrcode/Conferencia/selecionarCargas.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoConfItensPedidoModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoPedidoCargaModel.dart';
import 'package:leitorqrcode/Services/CargasService.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:leitorqrcode/notaFiscal/components/select_card_fiscal.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getIdUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: PopScope(
        canPop: false,
        onPopInvoked: (isPop) {
          if (!isPop) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => SelecionarCargas(),
              ),
              (route) => false,
            );
          }
        },
        child: Scaffold(
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
                titulo: 'Iniciar Conferência',
                onPressed: () async {
                  CargasServices cargasServices = CargasServices(context);

                  RetornoConfItensPedidoModel? respostaConfItensPedido =
                      await cargasServices.getConfItensPedido(
                    idUser,
                    widget.retorno.data![selectedCardIndex!].idPedido,
                  );

                  if (respostaConfItensPedido != null &&
                      !respostaConfItensPedido.error) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConferenciaExpedicaoScreen(
                            retorno: respostaConfItensPedido,
                            rtnNF: widget.retorno,
                            idPeiddo: widget
                                .retorno.data![selectedCardIndex!].idPedido),
                      ),
                    );
                  } else {
                    Dialogs.showToast(context,
                        "Erro ao buscar pedidos de carga: ${respostaConfItensPedido?.message}",
                        duration: Duration(seconds: 5),
                        bgColor: Colors.red.shade200);
                  }
                },
                backcolors: selectedCardIndex == null
                    ? [Colors.grey, const Color.fromARGB(255, 66, 66, 66)]
                    : null,
              ),
            ],
          ),
          bottomNavigationBar: BottomBar(),
        ),
      ),
    );
  }

  Future<void> getIdUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idUser = prefs.getString('IdUser') ?? "";
    });
  }
}
