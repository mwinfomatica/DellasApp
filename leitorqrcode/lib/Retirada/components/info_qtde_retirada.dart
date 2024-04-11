import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:leitorqrcode/Models/pendenteArmazModel.dart';
import 'package:leitorqrcode/Models/retiradaprodModel.dart';
import 'package:leitorqrcode/Retirada/RetiradaTransf.dart';
import 'package:uuid/uuid.dart';

class infoQtdReti extends StatefulWidget {
  infoQtdReti({
    Key? key,
    required this.prodRead,
    required this.qtdeProdDialog,
    this.titulo,
    this.idtransf,
    required this.listRetirada,
    required this.endRead,
    required this.idOperador,
  }) : super(key: key);
  final TextEditingController qtdeProdDialog;
  final String? titulo;
  final String? idtransf;
  final String endRead;
  final String idOperador;
  final List<retiradaprodModel> listRetirada;
  final ProdutoModel prodRead;
  @override
  State<infoQtdReti> createState() => _infoQtdRetiState();
}

class _infoQtdRetiState extends State<infoQtdReti> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

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
                    text: "Saída de Transferência \n" +
                        (widget.prodRead.nome ?? ""),
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
                              builder: (BuildContext context) => RetiradaTransf(
                                idtransf: widget.idtransf,
                                listRetirada: widget.listRetirada,
                                titulo: widget.titulo,
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
                          await saveRetirada();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) => RetiradaTransf(
                                idtransf: widget.idtransf,
                                listRetirada: widget.listRetirada,
                                titulo: widget.titulo,
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

  Future<void> saveRetirada() async {
    retiradaprodModel? retirada = await retiradaprodModel()
        .getByIdProdIdTransfEnd(
            (widget.prodRead.idproduto == null
                ? widget.prodRead.id!.toUpperCase()
                : widget.prodRead.idproduto!.toUpperCase()),
            widget.idtransf!.toUpperCase(),
            widget.endRead.toUpperCase());
    if (retirada == null) {
      retirada = new retiradaprodModel(
        idRetirado: new Uuid().v4(),
        endRetirado: widget.endRead,
        idtransfRetirado: widget.idtransf!.toUpperCase(),
        idProdRetirado: (widget.prodRead.idproduto == null
            ? widget.prodRead.id!.toUpperCase()
            : widget.prodRead.idproduto!.toUpperCase()),
        nomeProdRetirado: widget.prodRead.nome!,
        barcodeRetirado: widget.prodRead.barcode!,
        qtdRetirado: widget.qtdeProdDialog.text,
        loteRetirado: widget.prodRead.lote!,
        validRetirado: widget.prodRead.vali ?? "",
        idoperadorRetirado: widget.idOperador,
      );
      await retirada.insert();
    } else {
      retirada.qtdRetirado = (int.parse(retirada.qtdRetirado!) +
              int.parse(widget.qtdeProdDialog.text))
          .toString();
      await retirada.update();
    }
    setState(() {});

    pendenteArmazModel? pendente = await pendenteArmazModel()
        .getByIdProdIdTransf(
            (widget.prodRead.idproduto == null
                ? widget.prodRead.id!.toUpperCase()
                : widget.prodRead.idproduto!.toUpperCase()),
            widget.idtransf!.toUpperCase());

    if (pendente == null) {
      pendente = new pendenteArmazModel(
          id: new Uuid().v4().toUpperCase(),
          end: "",
          idProd: (widget.prodRead.idproduto == null
              ? widget.prodRead.id!.toUpperCase()
              : widget.prodRead.idproduto!.toUpperCase()),
          idoperador: widget.idOperador,
          idtransf: widget.idtransf!,
          lote: widget.prodRead.lote!,
          qtd: widget.qtdeProdDialog.text,
          valid: widget.prodRead.vali ?? "",
          barcode: widget.prodRead.barcode!,
          nomeProd: widget.prodRead.nome!,
          situacao: "0");
      await pendente.insert();
    } else {
      pendente.qtd =
          (int.parse(pendente.qtd!) + int.parse(widget.qtdeProdDialog.text))
              .toString();
      await pendente.update();
    }
    setState(() {});

    if (widget.listRetirada.isEmpty || widget.listRetirada.length == 0) {
      widget.listRetirada.add(retirada);
    } else {
      retiradaprodModel? item = widget.listRetirada
          .where((element) =>
              element.idProdRetirado ==
                  (widget.prodRead.idproduto == null
                      ? widget.prodRead.id!.toUpperCase()
                      : widget.prodRead.idproduto!.toUpperCase()) &&
              element.endRetirado == widget.endRead)
          .firstOrNull;
      if (item != null) {
        item.qtdRetirado = retirada.qtdRetirado;
      } else {
        widget.listRetirada.add(retirada);
      }
    }
    setState(() {});
  }
}
