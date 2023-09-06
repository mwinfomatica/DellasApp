import 'package:flutter/material.dart';
import 'package:dellas/Components/armazenamento_app_icons.dart';
import 'package:dellas/Components/eco_font_icons.dart';
import 'package:dellas/OrdemProducao/components/Button.dart';

import '../../QrCoderFirst.dart';

class MenuOrdemProducao extends StatelessWidget {
  const MenuOrdemProducao({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: (MediaQuery.of(context).size.height * 0.2) - 25,
      left: 30,
      right: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ButtonMenuOrdemProducao(
                titulo: "Retirada para Produção",
                descricao: "Descritivo da função armazenar",
                icone: ArmazenamentoApp.op,
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
              )
            ],
          ),
          SizedBox(
            height: 25,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ButtonMenuOrdemProducao(
                titulo: "Devolver de Insumos",
                descricao: "Descritivo da função armazenar",
                icone: ArmazenamentoApp.armazenamento,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => QrCoderFirst(
                        tipo: 2,
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ButtonMenuOrdemProducao(
                titulo: "Inserir Insumos",
                descricao: "Descritivo da função armazenar",
                icone: EcoFont.package,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => QrCoderFirst(
                        tipo: 3,
                      ),
                    ),
                  );
                },
              )
            ],
          ),
        ],
      ),
    );
  }
}
