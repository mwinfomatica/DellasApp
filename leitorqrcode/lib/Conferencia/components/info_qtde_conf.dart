import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Conferencia/conferenciaExpedicao.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoConfItensPedidoModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoPedidoCargaModel.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';

class infoQtdConf extends StatefulWidget {
  const infoQtdConf({
    Key? key,
    required this.retorno,
    required this.idPeiddo,
    required this.listItens,
    required this.prodRead,
    required this.qtdeProdDialog,
    required this.rtnNF,
  }) : super(key: key);
  final TextEditingController qtdeProdDialog;
  final RetornoConfItensPedidoModel retorno;
  final String idPeiddo;
  final List<ItemConferenciaNfs> listItens;
  final ProdutoModel prodRead;
  final RetornoPedidoCargaModel rtnNF;
  @override
  State<infoQtdConf> createState() => _infoQtdConfState();
}

class _infoQtdConfState extends State<infoQtdConf> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: PopScope(
        canPop: true,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: primaryColor,
            title: ListTile(
                title: RichText(
                  maxLines: 2,
                  text: TextSpan(
                    text: "Conferência \n" + (widget.prodRead.nome ?? ""),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                trailing: Container(
                  height: 1,
                  width: 1,
                )),
          ),
          body: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Text("Informe a quantidade"),
                TextField(
                  controller: widget.qtdeProdDialog,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    labelText: 'Qtde',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  ConferenciaExpedicaoScreen(
                                idPeiddo: widget.idPeiddo,
                                retorno: widget.retorno,
                                rtnNF: widget.rtnNF,
                              ),
                            ),
                            (route) => false,
                          );
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.3,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.red,
                          ),
                          child: Center(
                            child: Text(
                              "Cancelar",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await addConferencia();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  ConferenciaExpedicaoScreen(
                                idPeiddo: widget.idPeiddo,
                                retorno: widget.retorno,
                                rtnNF: widget.rtnNF,
                              ),
                            ),
                            (route) => false,
                          );
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.3,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.green,
                          ),
                          child: Center(
                            child: Text(
                              "Salvar",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ItemConferenciaNfs? getProdutoIguais(String id) {
    List<ItemConferenciaNfs>? ProdsIguais = widget.listItens
        .where((e) => e.idProduto.toUpperCase() == id.toUpperCase())
        .toList();
    int? qtdProd = ProdsIguais != null ? ProdsIguais.length : 0;
    if (qtdProd > 1) {
      for (var i = 0; i < qtdProd; i++) {
        if ((ProdsIguais[i].qtdeConf ?? 0) < ProdsIguais[i].qtde) {
          return ProdsIguais[i];
        } else {
          if (qtdProd == (i + 1)) {
            return ProdsIguais[i];
          }
        }
      }
    } else if (qtdProd == 1) {
      return ProdsIguais[0];
    } else {
      return null;
    }
  }

  addConferencia() {
    String idProd = (widget.prodRead.idproduto != null
        ? widget.prodRead.idproduto!
        : widget.prodRead.id!);

    ItemConferenciaNfs? dados = getProdutoIguais(idProd);

    if (dados != null) {
      if (dados.qtdeConf == null) {
        dados.qtdeConf = 0;
      }

      dados.qtdeConf = dados.qtdeConf! + int.parse(widget.qtdeProdDialog.text);
    } else {
      Dialogs.showToast(
          context, "Não foi encontrado este produto para esta Nota fiscal",
          duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
      return;
    }

    setState(() {});
  }
}
