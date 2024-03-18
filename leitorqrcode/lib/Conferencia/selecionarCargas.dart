import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Conferencia/components/button_conferencia.dart';
import 'package:leitorqrcode/Conferencia/selecionarNF.dart';
import 'package:leitorqrcode/Conferencia/components/select_card_carga.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoCargaModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoPedidoCargaModel.dart';
import 'package:leitorqrcode/Services/CargasService.dart';
import 'package:leitorqrcode/Services/ContextoServices.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelecionarCargas extends StatefulWidget {
  const SelecionarCargas({
    Key? key,
  }) : super(key: key);

  @override
  State<SelecionarCargas> createState() => _SelecionarCargasState();
}

class _SelecionarCargasState extends State<SelecionarCargas> {
  ContextoServices contextoServices = ContextoServices();
  RetornoCargaModel? retornoCargaModel;
  final nroCargaController = TextEditingController();
  List<Pedido> selecionados = [];
  String idUser = "";

  int? selectedCardIndex;

  // Método para simular os dados retornados pelo endpoint
  // RetornoCargaModel getSimulatedData() {
  //   return RetornoCargaModel(
  //     error: false,
  //     message: "sucesso",
  //     data: [
  //       Pedido(
  //         idPedido: "7c3abf25-0984-4c3a-a2d8-b63c7aa9b397-1",
  //         carga: "091074",
  //       ),
  //       Pedido(
  //         idPedido: "7c3abf25-0984-4c3a-a2d8-b63c7aa9b397-2",
  //         carga: "091075",
  //       ),
  //       Pedido(
  //         idPedido: "7c3abf25-0984-4c3a-a2d8-b63c7aa9b397-3",
  //         carga: "091076",
  //       ),
  //     ],
  //   );
  // }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getIdUser();
      await _getCargas();
    });

    nroCargaController.addListener(_filtroCargas);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    // Obtém os dados simulados
    // RetornoCargaModel dadosSimulados = getSimulatedData();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: primaryColor,
        title: Text(
          'Selecione as Cargas',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SizedBox(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () async => await showDialogConfir(context),
                      child: Icon(
                        Icons.refresh,
                        size: 55,
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: TextField(
                        controller: nroCargaController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            suffixIcon: Icon(Icons.search),
                            labelText: 'Nro Carga'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: retornoCargaModel?.data?.length ?? 0,
                itemBuilder: (context, index) {
                  var carga = retornoCargaModel!.data![index];
                  return SelectCardCarga(
                    carga: carga,
                    isSelected: selecionados
                        .any((selected) => selected.idPedido == carga.idPedido),
                    onCheckboxChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selecionados.add(retornoCargaModel!.data![index]);
                        } else {
                          selecionados.removeWhere((item) =>
                              item.idPedido ==
                              retornoCargaModel!.data![index].idPedido);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            ButtonConference(
              titulo: 'Iniciar a Conferência',
              onPressed: () async => await enviarCargasSelecionadas(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(),
    );
  }

  Future<void> enviarCargasSelecionadas() async {
    print('entrou aqui');
    CargasServices cargasServices = CargasServices(context);
    print('entrou aqui 2');
    List<String> cargasSelecionadas =
        selecionados.map((carga) => carga.carga).toList();

    RetornoPedidoCargaModel? respostaPedidoCarga =
        await cargasServices.getPedidosDeCarga(idUser, cargasSelecionadas);

    if (respostaPedidoCarga != null && !respostaPedidoCarga.error) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SelecionarNotaFiscalExpedicao(retorno: respostaPedidoCarga),
        ),
      );
    } else {
      Dialogs.showToast(context,
          "Erro ao buscar pedidos de carga: ${respostaPedidoCarga?.message}",
          duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
    }
  }

  Future<void> _getCargas() async {
    CargasServices cargasServices = CargasServices(context);

    try {
      RetornoCargaModel? dadosCarga = await cargasServices.getCargas();
      if (dadosCarga != null &&
          dadosCarga.data != null &&
          dadosCarga.data!.isNotEmpty) {
        String filtro = nroCargaController.text.trim().toLowerCase();

        List<Pedido>? dadosFiltrados;
        if (filtro.isNotEmpty) {
          dadosFiltrados = dadosCarga.data!
              .where((carga) => carga.carga.toLowerCase().contains(filtro))
              .toList();
        } else {
          dadosFiltrados = dadosCarga.data;
        }

        setState(() {
          retornoCargaModel = RetornoCargaModel(
            error: dadosCarga.error,
            message: dadosCarga.message,
            data: dadosFiltrados,
          );
        });
      }
    } catch (e) {
      print('Erro ao processar carga: $e');
    }
  }

  void _filtroCargas() {
    String filtro = nroCargaController.text.trim().toLowerCase();

    if (filtro.isNotEmpty &&
        retornoCargaModel != null &&
        retornoCargaModel!.data != null) {
      List<Pedido> dadosFiltrados = retornoCargaModel!.data!
          .where((carga) => carga.carga.toLowerCase().contains(filtro))
          .toList();

      setState(() {
        retornoCargaModel = RetornoCargaModel(
          error: retornoCargaModel!.error,
          message: retornoCargaModel!.message,
          data: dadosFiltrados,
        );
      });
    } else {
      _getCargas();
    }
  }

  Future<void> showDialogConfir(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            "Confirmação",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          content: Text(
            'Ao atualizar a lista, os itens já marcados serão desmarcados e a lista será atualizada',
            style: TextStyle(fontSize: 16.0),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('Confirmar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                selecionados = [];
                _getCargas();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> getIdUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idUser = prefs.getString('IdUser') ?? "";
    });
  }
}
