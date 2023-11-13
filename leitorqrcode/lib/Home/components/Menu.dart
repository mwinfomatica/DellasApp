import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/armazenamento_app_icons.dart';
import 'package:leitorqrcode/Components/eco_font_icons.dart';
import 'package:leitorqrcode/Home/components/Button.dart';
import 'package:leitorqrcode/Infrastructure/AtualizarDados/atualizaOp.dart';
import 'package:leitorqrcode/Inventario/Inventario.dart';
import 'package:leitorqrcode/QrCoderFirst.dart';
import 'package:leitorqrcode/Transferencia/Transferencias.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuHome extends StatelessWidget {
  final double? topPadding;
  MenuHome({Key? key, this.topPadding}) : super(key: key);

  Future<String> getIdUser() async {
    SharedPreferences userlogged = await SharedPreferences.getInstance();
    return userlogged.getString('IdUser')!;
  }

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
              ButtonHome(
                titulo: "Armazenamento",
                descricao: "Informe aqui o local \n de armazenamento",
                icone: ArmazenamentoApp.armazenamento,
                onTap: () {
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
              ButtonHome(
                titulo: "Transferência",
                descricao: "Para tranferir produtos \n entre locais",
                icone: ArmazenamentoApp.transferencia,
                onTap: () {
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
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     ButtonHome(
          //       titulo: "Ordem Produção",
          //       descricao: "Retire produtos \n para montagem",
          //       icone: ArmazenamentoApp.op,
          //       onTap: () {
          //         Navigator.push(
          //           context,
          //           MaterialPageRoute(
          //             builder: (BuildContext context) => OrdemProducaoScreen(),
          //           ),
          //         );
          //       },
          //     ),
          //     ButtonHome(
          //       titulo: "Vendas",
          //       descricao: "Informe aqui vendas \n de produtos",
          //       icone: ArmazenamentoApp.vendas,
          //       onTap: () {
          //         Navigator.push(
          //           context,
          //           MaterialPageRoute(
          //             builder: (BuildContext context) => QrCoderFirst(
          //               tipo: 1,
          //             ),
          //           ),
          //         );
          //       },
          //     ),
          //   ],
          // ),
          // SizedBox(
          //   height: 25,
          // ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ButtonHome(
                titulo: "Inventário",
                descricao: "Contagem de produtos \n no inventário",
                icone: EcoFont.inventory,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => Inventario(),
                    ),
                  );
                },
              ),
              ButtonHome(
                titulo: "Carga",
                descricao: "Informe aqui as cargas \n a serem retiradas",
                icone: ArmazenamentoApp.armazenamento,
                onTap: () {
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
              ButtonHome(
                titulo: "Sincronizar",
                descricao: "Clique aqui para enviar os dados para o servidor",
                icone: EcoFont.sync_icon,
                onTap: () async {
                  await syncOp(context, true);
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}
