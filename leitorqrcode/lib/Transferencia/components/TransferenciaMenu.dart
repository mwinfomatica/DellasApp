import 'package:flutter/material.dart';
import 'package:leitorqrcode/Apuracao/Apuracao.dart';
import 'package:leitorqrcode/ArmazenamentoTransferencia/armazenamentoTransf.dart';
import 'package:leitorqrcode/Components/GetTipoOperacao.dart';
import 'package:leitorqrcode/Components/armazenamento_app_icons.dart';
import 'package:leitorqrcode/Models/APIModels/MovimentacaoMOdel.dart';
import 'package:leitorqrcode/Models/APIModels/OperacaoModel.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:leitorqrcode/Models/armprodModel.dart';
import 'package:leitorqrcode/Models/pendenteArmazModel.dart';
import 'package:leitorqrcode/Models/retiradaprodModel.dart';
import 'package:leitorqrcode/Retirada/RetiradaTransf.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:leitorqrcode/Transferencia/components/Button.dart';
import 'package:uuid/uuid.dart';

class MenuTransferencia extends StatelessWidget {
  final OperacaoModel? op;
  const MenuTransferencia({Key? key, @required this.op}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    OperacaoModel opArm = new OperacaoModel();
    List<ProdutoModel> prods = [];
    List<ProdutoModel> prodsArm = [];
    List<retiradaprodModel> listRetirada = [];
    OperacaoModel opRetirada = new OperacaoModel();
    String idtransf = "";

    Future<void> getReitirada() async {
      listRetirada = await retiradaprodModel().getAll();

      if (listRetirada.isEmpty) {
        listRetirada = [];
      }
    }

    Future<void> delete() async {
      await retiradaprodModel().deleteAll();
      await pendenteArmazModel().deleteAll();
      await armprodModel().deleteAll();
      await MovimentacaoModel().deleteAll();
      await OperacaoModel().deleteAll();
      await ProdutoModel().deleteAll();
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
                  await getReitirada();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => RetiradaTransf(
                        titulo: getTipo("41"),
                        listRetirada: listRetirada,
                        idtransf:
                            listRetirada != null && listRetirada.length > 0
                                ? listRetirada.first.idtransfRetirado
                                : new Uuid().v4().toUpperCase(),
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
                onTap: () async {
                  List<pendenteArmazModel> list =
                      await pendenteArmazModel().getAllpendente();
                  List<armprodModel> armlist = await armprodModel().getAll();
                  if ((list != null && list.length > 0) ||
                      (armlist != null && armlist.length > 0)) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => ArmazenamentoTransf(
                          listPendente: list,
                          listarm: armlist,
                        ),
                      ),
                    );
                  } else {
                    Dialogs.showToast(
                        context, "Não há itens a serem armazenados.",
                        duration: Duration(seconds: 5),
                        bgColor: Colors.red.shade200);
                  }
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
                titulo: "Delete",
                descricao: "Descritivo da função armazenar",
                icone: ArmazenamentoApp.armazenamento,
                onTap: () async {
                  await delete();
                  Navigator.pop(context);
                },
              )
            ],
          ),
        ],
      ),
    );
  }
}
