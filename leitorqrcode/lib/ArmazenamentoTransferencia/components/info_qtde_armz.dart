import 'package:flutter/material.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:leitorqrcode/ArmazenamentoTransferencia/armazenamentoTransf.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:leitorqrcode/Models/armprodModel.dart';
import 'package:leitorqrcode/Models/pendenteArmazModel.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:uuid/uuid.dart';

class infoQtdArmz extends StatefulWidget {
  const infoQtdArmz({
    Key? key,
    this.listPendente,
    required this.listarm,
    required this.prodRead,
    required this.endRead,
    required this.idOperador,
    required this.qtdeProdDialog,
  }) : super(key: key);
  final TextEditingController qtdeProdDialog;
  final List<pendenteArmazModel>? listPendente;
  final List<armprodModel> listarm;
  final ProdutoModel prodRead;
  final String endRead;
  final String idOperador;
  @override
  State<infoQtdArmz> createState() => _infoQtdArmzState();
}

class _infoQtdArmzState extends State<infoQtdArmz> {
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
                    text: "Armazenamento Transferência \n" +
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
                              builder: (BuildContext context) =>
                                  ArmazenamentoTransf(
                                listPendente: widget.listPendente,
                                listarm: widget.listarm,
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
                          await saveArmz();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  ArmazenamentoTransf(
                                listPendente: widget.listPendente,
                                listarm: widget.listarm,
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

  Future<void> saveArmz() async {
    armprodModel? arm = armprodModel();

    pendenteArmazModel? item = widget.listPendente!
        .where(
          (element) =>
              element.idProd ==
                  (widget.prodRead.idproduto == null
                      ? widget.prodRead.id!.toUpperCase()
                      : widget.prodRead.idproduto!.toUpperCase()) &&
              element.idtransf ==
                  widget.listPendente![0].idtransf!.toUpperCase() &&
              element.lote == widget.prodRead.lote &&
              element.valid == (widget.prodRead.vali ?? "") &&
              element.situacao == "0",
        )
        .firstOrNull;
    int qt = 0;
    if (item != null) {
      qt = int.parse(item.qtd!) - int.parse(widget.qtdeProdDialog.text);
      if (qt > 0) {
        item.qtd = qt.toString();
      }
    } else {
      FlutterBeep.beep(false);
      Dialogs.showToast(context,
          "Produto não listado para Armazenamento. \n Armazenamento deste produto já concluído.",
          duration: Duration(seconds: 5), bgColor: Colors.red.shade200);
      return;
    }

    setState(() {});
    if (widget.listarm.isNotEmpty) {
      arm = widget.listarm
          .where(
            (e) =>
                e.idProdArm ==
                    (widget.prodRead.idproduto == null
                        ? widget.prodRead.id!.toUpperCase()
                        : widget.prodRead.idproduto!.toUpperCase()) &&
                e.endArm == widget.endRead &&
                e.loteArm == widget.prodRead.lote &&
                e.validArm == (widget.prodRead.vali ?? ""),
          )
          .firstOrNull;
    }
    if (arm == null || arm.idProdArm == null) {
      arm = new armprodModel(
          idArm: new Uuid().v4().toUpperCase(),
          endArm: widget.endRead,
          idProdArm: widget.prodRead.idproduto!,
          idtransfArm: widget.listPendente![0].idtransf,
          loteArm: widget.prodRead.lote!,
          nomeProdArm: widget.prodRead.nome!,
          qtdArm: widget.qtdeProdDialog.text,
          validArm: widget.prodRead.vali ?? "",
          barcodeArm: widget.prodRead.barcode!);

      await arm.insert();
      widget.listarm.add(arm);
    } else {
      arm.qtdArm =
          (int.parse(arm.qtdArm!) + int.parse(widget.qtdeProdDialog.text))
              .toString();
      await arm.update();
    }

    if (qt == 0) {
      widget.listPendente!.removeWhere((e) => e.id == item.id);
      await item.delete(item.id!);
    }

    setState(() {});

    var Gitem = widget.listPendente!.where((element) =>
        element.idProd ==
            (widget.prodRead.idproduto == null
                ? widget.prodRead.id!.toUpperCase()
                : widget.prodRead.idproduto!.toUpperCase()) &&
        element.idtransf == arm!.idtransfArm!.toUpperCase() &&
        element.end == widget.endRead &&
        element.lote == arm.loteArm &&
        element.valid == (arm.validArm ?? "") &&
        element.situacao == "1");

    if (Gitem.isEmpty) {
      pendenteArmazModel pendenteOk = new pendenteArmazModel(
        id: new Uuid().v4().toUpperCase(),
        barcode: widget.prodRead.barcode!,
        end: widget.endRead,
        idProd: (widget.prodRead.idproduto == null
            ? widget.prodRead.id!.toUpperCase()
            : widget.prodRead.idproduto!.toUpperCase()),
        idoperador: widget.idOperador,
        idtransf: arm.idtransfArm!.toUpperCase(),
        situacao: "1",
        valid: widget.prodRead.vali ?? "",
        lote: widget.prodRead.lote!,
        nomeProd: widget.prodRead.nome!,
        qtd: widget.qtdeProdDialog.text,
      );
      widget.listPendente!.add(pendenteOk);
    } else {
      pendenteArmazModel itemOk = Gitem.first;
      itemOk.qtd =
          (int.parse(itemOk.qtd!) + int.parse(widget.qtdeProdDialog.text))
              .toString();
    }

    if (widget.listPendente!.where((e) => e.situacao == "0").length == 0) {
      Dialogs.showToast(context, "Leitura concluída",
          duration: Duration(seconds: 5), bgColor: Colors.green.shade200);
    }

    setState(() {});
  }
}
