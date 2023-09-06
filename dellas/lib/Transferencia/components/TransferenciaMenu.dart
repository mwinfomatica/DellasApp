import 'package:flutter/material.dart';
import 'package:dellas/Apuracao/Apuracao.dart';
import 'package:dellas/Components/GetTipoOperacao.dart';
import 'package:dellas/Components/armazenamento_app_icons.dart';
import 'package:dellas/Models/APIModels/OperacaoModel.dart';
import 'package:dellas/Models/APIModels/ProdutoModel.dart';
import 'package:dellas/Retirada/RetiradaTransf.dart';
import 'package:dellas/Shared/Dialog.dart';
import 'package:dellas/Transferencia/components/Button.dart';
import 'package:uuid/uuid.dart';

class MenuTransferencia extends StatelessWidget {
  final OperacaoModel op;
  const MenuTransferencia({Key? key, required this.op}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ProdutoModel prod = new ProdutoModel();
    OperacaoModel? opArm = new OperacaoModel();
    List<ProdutoModel> prods = [];
    List<ProdutoModel> prodsArm = [];

    OperacaoModel opRetirada = new OperacaoModel();

    List<ProdutoModel> getVirtualArm(String idlote, String id) {
      return opArm!.prods!
          .where((a) =>
              a.idproduto == id &&
              a.idloteunico == idlote &&
              a.isVirtual == "1")
          .toList();
    }

    int getQtdVirtual(String idlote, String id) {
      int qt = 0;
      List<ProdutoModel> listVirtual = getVirtualArm(idlote, id);
      if (listVirtual.length > 0) {
        for (var v = 0; v < listVirtual.length; v++) {
          qt = qt + int.parse(listVirtual[v].qtd);
        }
      }

      return qt;
    }

    Future<OperacaoModel> getOpPendentes() async {
      opRetirada = await new OperacaoModel().getPendenteAramazenamento();

      if (opRetirada != null) {
        List<ProdutoModel> prods =
            await new ProdutoModel().getByIdOperacao(op.id);
        opRetirada.prods = prods;
        opRetirada = opRetirada;
      }
      return opRetirada;
    }

    delete() async {
      await OperacaoModel().deleteAll();
      await ProdutoModel().deleteAll();
    }

    onTapMetodArmazenamento() async {
      opArm!.prods = [];
      opArm = await opArm!.getOpAramazenamento();

      if (opArm == null) {
        opArm = new OperacaoModel(
            cnpj: "",
            id: new Uuid().v4().toUpperCase(),
            nrdoc: op.nrdoc,
            situacao: "1",
            tipo: "40",
            prods: []);
        await opArm!.insert();
        prods = await ProdutoModel().getByIdOperacao(op.id);
        for (var i = 0; i < prods.length; i++) {
          prod = new ProdutoModel(
            cod: prods[i].cod,
            desc: prods[i].desc,
            end: "",
            id: new Uuid().v4().toUpperCase(),
            idOperacao: opArm!.id,
            idloteunico: prods[i].idloteunico,
            idproduto: prods[i].idproduto,
            idprodutoPedido: prods[i].idprodutoPedido,
            infq: prods[i].infq,
            isVirtual: prods[i].isVirtual,
            lote: prods[i].lote,
            nome: prods[i].nome,
            qtd: prods[i].qtd,
            situacao: prods[i].situacao,
            sl: prods[i].sl,
            vali: prods[i].vali,
          );
          prod.isVirtual = "0";
          await prod.insert();
          opArm!.prods!.add(prod);
        }
      } else {
        prodsArm = await new ProdutoModel().getByIdOperacao(opArm!.id);

        opArm!.prods = prodsArm;

        prods = await ProdutoModel().getByIdOperacao(op.id);

        for (var i = 0; i < prods.length; i++) {
          int qtVitual =
              getQtdVirtual(prods[i].idloteunico, prods[i].idproduto);

          List<ProdutoModel> lproduto = opArm!.prods!
              .where((a) =>
                  a.idproduto == prods[i].idproduto &&
                  (a.isVirtual == "" ||
                      a.isVirtual == "0" ||
                      a.isVirtual == null))
              .toList();

          ProdutoModel prod = new ProdutoModel();
          if (lproduto.length == 0) {
            prod = new ProdutoModel(
              cod: prods[i].cod,
              desc: prods[i].desc,
              end: "",
              id: new Uuid().v4().toUpperCase(),
              idOperacao: opArm!.id,
              idloteunico: prods[i].idloteunico,
              idproduto: prods[i].idproduto,
              idprodutoPedido: prods[i].idprodutoPedido,
              infq: prods[i].infq,
              isVirtual: prods[i].isVirtual,
              lote: prods[i].lote,
              nome: prods[i].nome,
              qtd: prods[i].qtd,
              situacao: prods[i].situacao,
              sl: prods[i].sl,
              vali: prods[i].vali,
            );
            prod.isVirtual = "0";
            await prod.insert();
            opArm!.prods!.add(prod);
          } else {
            for (var x = 0; x < lproduto.length; x++) {
              List<ProdutoModel> listVirtual =
                  getVirtualArm(lproduto[x].idloteunico, lproduto[x].idproduto);

              int qt = 0;

              if (listVirtual.length > 0) {
                var tqtd = getQtdVirtual(
                    lproduto[x].idloteunico, lproduto[x].idproduto);
                qt = int.parse(prods[i].qtd) - tqtd;
              }

              lproduto[x].qtd = qt.toString();

              ProdutoModel? prodDB = await lproduto[x]
                  .getByIdLoteIdPedido(lproduto[x].idloteunico, opArm!.id);

              prodDB!.qtd = lproduto[x].qtd;
              await prodDB.update();
            }
          }
        }
      }
    }

    return Positioned(
      top: (MediaQuery.of(context).size.height * 0.2) - 25,
      left: 30,
      right: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ButtonMenuTransferencia(
                titulo: "Retirar",
                descricao: "Descritivo da função armazenar",
                icone: ArmazenamentoApp.armazenamento,
                onTap: () async {
                  await getOpPendentes().then((value) => {
                        if (value != null)
                          {
                            opRetirada = value,
                            if (opRetirada.tipo == "")
                              {
                                opRetirada.tipo = "41",
                              },
                            if (opRetirada.id == "")
                              {opRetirada.id = new Uuid().v4().toUpperCase()}
                          }
                      });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => RetiradaTransf(
                        titulo: getTipo("41"),
                        operacaoModel: opRetirada,
                      ),
                    ),
                  );
                },
              )
            ],
          ),
          SizedBox(
            height: 25,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ButtonMenuTransferencia(
                titulo: "Armazenar",
                descricao: "Descritivo da função armazenar",
                icone: ArmazenamentoApp.op,
                onTap: () async => {
                  await onTapMetodArmazenamento(),
                  if (opArm != null)
                    {
                      if (opArm!.id != null && opArm!.prods!.length > 0)
                        {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) => Apuracao(
                                titulo: getTipo("40"),
                                operacaoModel: opArm!,
                              ),
                            ),
                          ),
                        }
                      else
                        {
                          Dialogs.showToast(context, "Nenhum produto retirado.",
                              duration: Duration(seconds: 5),
                              bgColor: Colors.red.shade200),
                        }
                    }
                  else
                    {
                      Dialogs.showToast(context, "Nenhum produto retirado.",
                          duration: Duration(seconds: 5),
                          bgColor: Colors.red.shade200),
                    }
                },
              )
            ],
          ),
          SizedBox(
            height: 25,
          ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceAround,
          //   children: [
          //     ButtonMenuTransferencia(
          //       titulo: "Delete",
          //       descricao: "Descritivo da função armazenar",
          //       icone: ArmazenamentoApp.armazenamento,
          //       onTap: () async {
          //         delete();
          //         Navigator.pop(context);
          //       },
          //     )
          //   ],
          // ),
        ],
      ),
    );
  }
}
