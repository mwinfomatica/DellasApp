import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Inventario/Inventario_2.dart';
import 'package:leitorqrcode/Models/APIModels/MovimentacaoMOdel.dart';
import 'package:leitorqrcode/Models/APIModels/OperacaoModel.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:uuid/uuid.dart';

class infoQtd extends StatefulWidget {
  const infoQtd({
    Key? key,
    required this.qtdeProdDialog,
    required this.op,
    required this.nroContagem,
    required this.idOperador,
    required this.endRead,
    required this.listProd,
    this.produto,
    required this.prodRead,
  }) : super(key: key);
  final TextEditingController qtdeProdDialog;
  final OperacaoModel op;
  final String nroContagem;
  final String idOperador;
  final String endRead;
  final ProdutoModel? produto;
  final ProdutoModel prodRead;
  final List<ProdutoModel> listProd;
  @override
  State<infoQtd> createState() => _infoQtdState();
}

class _infoQtdState extends State<infoQtd> {
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
                    text: "Inventário \n" + (widget.prodRead.nome ?? ""),
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
                              builder: (BuildContext context) => Inventario2(
                                op: widget.op,
                                end: widget.endRead,
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
                          await geraMoviProd();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) => Inventario2(
                                op: widget.op,
                                end: widget.endRead,
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

  Future<void> geraMoviProd() async {
    if (widget.produto == null) {
      MovimentacaoModel movi = new MovimentacaoModel();
      movi.id = new Uuid().v4().toUpperCase();
      movi.operacao = widget.op.tipo;
      movi.idOperacao = widget.op.id;
      movi.codMovi = widget.op.nrdoc;
      movi.operador = widget.idOperador;
      movi.endereco = widget.endRead!;
      movi.idProduto = widget.prodRead.idproduto!;
      movi.qtd = widget.qtdeProdDialog.text;
      movi.nroContagem = widget.nroContagem;
      DateTime today = new DateTime.now();
      String dateSlug =
          "${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year.toString()} ${today.hour}:${today.minute}:${today.second}";
      movi.dataMovimentacao = dateSlug;
      await movi.insert();
      // animateListKey.currentState!.insertItem(0);
      widget.prodRead.idproduto = widget.prodRead.idproduto;
      widget.prodRead.id = new Uuid().v4().toUpperCase();
      widget.prodRead.idOperacao = widget.op.id;
      widget.prodRead.qtd = widget.qtdeProdDialog.text;
      widget.prodRead.end = widget.endRead;
      widget.listProd.add(widget.prodRead);
      widget.op.prods = widget.listProd;
      await widget.prodRead.insert();
      setState(() {});
    } else {
      ProdutoModel? prodsop = new ProdutoModel();
      List<MovimentacaoModel> listmovi = [];
      listmovi = await new MovimentacaoModel().getAllByoperacao(widget.op.id!);
      MovimentacaoModel? movi = new MovimentacaoModel();

      movi = listmovi
          .where((element) =>
              element.idOperacao == widget.op.id &&
              element.endereco == widget.endRead &&
              element.idProduto == widget.prodRead.idproduto)
          .firstOrNull;
      if (movi != null) {
        movi.qtd =
            (int.parse(movi.qtd!) + int.parse(widget.qtdeProdDialog.text))
                .toString();
        await movi.updatebyIdOpProdEnd();

        prodsop = widget.op.prods!
            .where((element) =>
                element.idproduto == widget.produto!.idproduto &&
                element.end != null &&
                element.end!.toUpperCase() == widget.endRead)
            .firstOrNull;

        if (prodsop != null) {
          setState(() {
            widget.prodRead.qtd =
                widget.prodRead.qtd == null ? "1" : widget.prodRead.qtd;
            widget.produto!.qtd = movi!.qtd;
            prodsop!.qtd = movi.qtd;
            prodsop.end = widget.endRead;
            widget.prodRead.end = widget.endRead;
            widget.prodRead.edit(widget.produto!);
          });
        }
      } else {
        return;
      }
    }
  }
}
