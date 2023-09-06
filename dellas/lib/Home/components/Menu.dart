import 'package:dellas/Home/components/ButtonAux.dart';
import 'package:flutter/material.dart';
import 'package:dellas/Components/armazenamento_app_icons.dart';
import 'package:dellas/Components/eco_font_icons.dart';
import 'package:dellas/Home/components/Button.dart';
import 'package:dellas/Inventario/Inventario.dart';
import 'package:dellas/Models/APIModels/Endereco.dart';
import 'package:dellas/Models/APIModels/MovimentacaoMOdel.dart';
import 'package:dellas/Models/APIModels/OperacaoModel.dart';
import 'package:dellas/Models/APIModels/ProdutoModel.dart';
import 'package:dellas/Models/APIModels/RetornoLoginModel.dart';
import 'package:dellas/OrdemProducao/OrdemProducao.dart';
import 'package:dellas/QrCoderFirst.dart';
import 'package:dellas/Services/MovimentacaoService.dart';
import 'package:dellas/Services/ProdutoService.dart';
import 'package:dellas/Shared/Dialog.dart';
import 'package:dellas/Transferencia/Transferencias.dart';

class MenuHome extends StatelessWidget {
  final double? topPadding;

  const MenuHome({Key? key, this.topPadding}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: topPadding!,
        left: 30,
        right: 30,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ButtonAux(
                titulo: "Armazenamento",
                descricao: "Informe aqui o local \n de armazenamento",
                icone: ArmazenamentoApp.armazenamento,
                func: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => QrCoderFirst(
                        tipo: 1,
                      ),
                    ),
                  );
                },
              ),
              ButtonAux(
                titulo: "Transferência",
                descricao: "Para tranferir produtos \n entre locais",
                icone: ArmazenamentoApp.transferencia,
                func: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => TransferenciasScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(
            height: 25,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ButtonAux(
                titulo: "Ordem Produção",
                descricao: "Retire produtos \n para montagem",
                icone: ArmazenamentoApp.op,
                func: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => OrdemProducaoScreen(),
                    ),
                  );
                },
              ),
              ButtonAux(
                titulo: "Vendas",
                descricao: "Informe aqui vendas \n de produtos",
                icone: ArmazenamentoApp.vendas,
                func: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => QrCoderFirst(
                        tipo: 1,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(
            height: 25,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ButtonAux(
                titulo: "Inventário",
                descricao: "Contagem de produtos \n no inventário",
                icone: EcoFont.inventory,
                func: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => Inventario(),
                    ),
                  );
                },
              ),
              ButtonAux(
                titulo: "Carga",
                descricao: "Informe aqui as cargas \n a serem retiradas",
                icone: ArmazenamentoApp.armazenamento,
                func: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => QrCoderFirst(
                        tipo: 1,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
           SizedBox(
            height: 25,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ButtonAux(
                titulo: "Sincronizar",
                descricao: "Clique aqui para enviar os dados para o servidor",
                icone: EcoFont.sync_icon,
                func: () async {
                  List<OperacaoModel> ops =
                      await OperacaoModel().getListFinalizado();

                  if (ops.length != 0) {
                    for (int i = 0; i < ops.length; i++) {
                      List<MovimentacaoModel> list =
                          await MovimentacaoModel().getAllByoperacao(ops[i].id);

                      MovimentacaoService movimentacaoService =
                          MovimentacaoService(context);
                      bool ok =
                          await movimentacaoService.insertMovimentacoes(list);

                      if (ok) {
                        MovimentacaoModel().deleteByIdOperacao(ops[i].id);
                        ProdutoModel().deleteByIdOperacao(ops[i].id);
                        OperacaoModel().delete(ops[i].id);
                      }
                    }

                    OperacaoModel? opTransf =
                        await new OperacaoModel().getOpAramazenamento();

                    if (opTransf != null) {
                      Dialogs.showToast(context,
                          "Exitem transferências pendentes para finalizar.");
                    }
                  } else {
                    Dialogs.showToast(context, "Nenhum item para sincronizar");
                  }

                  RetornoLoginModel rtn = await ProdutoService().getEndereco();
                  await new EnderecoModel().deleteAll();

                  for (var i = 0; i < rtn.endereco.length; i++) {
                    EnderecoModel end = new EnderecoModel();
                    end = rtn.endereco[i];
                    await end.insert();
                  }
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}
