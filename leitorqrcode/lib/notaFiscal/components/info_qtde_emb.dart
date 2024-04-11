import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Models/APIModels/EmbalagemModel.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoGetCreateEmbalagemModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoNotasFiscaisModel.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:leitorqrcode/notaFiscal/montarEmbalagem.dart';

class infoQtdEmb extends StatefulWidget {
  const infoQtdEmb({
    Key? key,
    required this.qtdeProdDialog,
    required this.dadosCreateEmbalagem,
    required this.idPedido,
    this.idEmbalagem,
    required this.pedido,
    required this.IdPedidoRetiradaCarga,
    required this.list,
    required this.prodRead,
  }) : super(key: key);
  final TextEditingController qtdeProdDialog;
  final RetornoGetCreateEmbalagemModel dadosCreateEmbalagem;
  final String idPedido;
  final String? idEmbalagem;
  final Pedido pedido;
  final String IdPedidoRetiradaCarga;
  final List<ItensEmbalagem> list;
  final ProdutoModel prodRead;
  @override
  State<infoQtdEmb> createState() => _infoQtdEmbState();
}

class _infoQtdEmbState extends State<infoQtdEmb> {
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
                    text: "Embalagem",
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
                                  MontarEmbalagem(
                                dadosCreateEmbalagem:
                                    widget.dadosCreateEmbalagem,
                                IdPedidoRetiradaCarga:
                                    widget.IdPedidoRetiradaCarga,
                                idPedido: widget.idPedido,
                                pedido: widget.pedido,
                                idEmbalagem: widget.idEmbalagem,
                                listrtn: widget.list,
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
                          await addEmbalagem();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  MontarEmbalagem(
                                dadosCreateEmbalagem:
                                    widget.dadosCreateEmbalagem,
                                IdPedidoRetiradaCarga:
                                    widget.IdPedidoRetiradaCarga,
                                idPedido: widget.idPedido,
                                pedido: widget.pedido,
                                idEmbalagem: widget.idEmbalagem,
                                listrtn: widget.list,
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

  DadosEmbalagem? getProdutoIguais(String id) {
    List<DadosEmbalagem> ProdsIguais = widget.dadosCreateEmbalagem.data
        .where((e) => e.idProduto.toUpperCase() == id.toUpperCase())
        .toList();
    int? qtdProd = ProdsIguais != null ? ProdsIguais.length : 0;
    if (qtdProd > 1) {
      for (var i = 0; i < qtdProd; i++) {
        if (ProdsIguais[i].quantEmbalado < ProdsIguais[i].quantNota) {
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

  ItensEmbalagem? getItemEmbalagem(String id) {
    return widget.list
        .where((e) => e.idProduto!.toUpperCase() == id.toUpperCase())
        .firstOrNull;
  }

  addEmbalagem() {
    String idProd = (widget.prodRead.idproduto != null
        ? widget.prodRead.idproduto!
        : widget.prodRead.id!);

    int qtd = int.parse(widget.qtdeProdDialog.text ?? "0");

    DadosEmbalagem? dados = getProdutoIguais(idProd);

    if (dados != null) {
      dados.quantEmbalado = dados.quantEmbalado + qtd;
    } else {
      Dialogs.showToast(
          context, "Não foi encontrado este produto para esta Nota fiscal",
          duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
      return;
    }

    ItensEmbalagem? item = getItemEmbalagem(idProd);

    if (item != null) {
      if (item.qtd != null && item.qtd! >= 1) {
        widget.list.remove(item);
        item.qtd = item.qtd! + qtd;
        item.descProd = (widget.prodRead.cod ?? " - ") +
            " - " +
            (widget.prodRead.nome ?? " - ");
        widget.list.add(item);
      } else {
        widget.list.add(ItensEmbalagem(
            widget.prodRead.idprodutoPedido,
            idProd,
            qtd,
            ((widget.prodRead.cod ?? " - ") +
                " - " +
                (widget.prodRead.nome ?? " - "))));
      }
    } else {
      widget.list.add(ItensEmbalagem(
          widget.prodRead.idprodutoPedido,
          idProd,
          qtd,
          ((widget.prodRead.cod ?? " - ") +
              " - " +
              (widget.prodRead.nome ?? " - "))));
    }
    setState(() {});
  }
}
