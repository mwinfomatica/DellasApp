import 'package:flutter/cupertino.dart';
import 'package:leitorqrcode/Models/APIModels/Endereco.dart';
import 'package:leitorqrcode/Models/APIModels/MovimentacaoMOdel.dart';
import 'package:leitorqrcode/Models/APIModels/OperacaoModel.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoLoginModel.dart';
import 'package:leitorqrcode/Models/APIModels/TransferenciaModel.dart';
import 'package:leitorqrcode/Models/armprodModel.dart';
import 'package:leitorqrcode/Models/retiradaprodModel.dart';
import 'package:leitorqrcode/Services/MovimentacaoService.dart';
import 'package:leitorqrcode/Services/ProdutoService.dart';
import 'package:leitorqrcode/Services/TransferenciaService.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> getIdUser() async {
  SharedPreferences userlogged = await SharedPreferences.getInstance();
  return userlogged.getString('IdUser');
}

Future<void> syncOp(BuildContext context, bool Transferencia) async {
  getIdUser();
  List<retiradaprodModel> listRetirado = [];
  List<armprodModel> listArm = [];
  List<OperacaoModel> ops = await OperacaoModel().getListFinalizado();

  if (Transferencia) {
    listRetirado = await retiradaprodModel().getAll();

    listArm = await armprodModel().getAll();
  }

  if (ops.length == 0 && listRetirado.length == 0 && listArm.length == 0) {
    Dialogs.showToast(context, "Nenhum item para sincronizar");
  } else {
    if (ops.length != 0) {
      for (int i = 0; i < ops.length; i++) {
        List<MovimentacaoModel> list =
            await MovimentacaoModel().getAllByoperacao(ops[i].id);

        MovimentacaoService movimentacaoService =
            MovimentacaoService(contexto: context);
        bool ok = await movimentacaoService.insertMovimentacoes(list);

        if (ok) {
          MovimentacaoModel().deleteByIdOperacao(ops[i].id);
          ProdutoModel().deleteByIdOperacao(ops[i].id);
          OperacaoModel().delete(ops[i].id);
        }
      }

      if (Transferencia) {
        OperacaoModel opTransf =
            await new OperacaoModel().getOpAramazenamento();

        if (opTransf != null) {
          Dialogs.showToast(
              context, "Exitem transferências pendentes para finalizar.");
        }
      }
    }
    if (Transferencia) {
      if (listRetirado.length != 0 && listArm.length != 0) {
        List<armprodModel> listArmOK = [];
        List<retiradaprodModel> listRetiradoOk = [];

        for (var retirado in listRetirado) {
          for (var arm in listArm
              .where((e) => e.idtransfArm == retirado.idtransfRetirado)) {
            if (retirado.idProdRetirado == arm.idProdArm &&
                // arm.qtdArm == retirado.qtdRetirado &&
                (arm.endArm != null && arm.endArm != "") &&
                (retirado.endRetirado != null && retirado.endRetirado != "")) {
              listArmOK.add(arm);
              listRetiradoOk.add(retirado);
            }
          }
        }

        if (listArmOK.length > 0 && listRetiradoOk.length > 0) {
          TransferenciaModel model = new TransferenciaModel(
              ListArmz: listArmOK,
              ListRetirada: listRetiradoOk,
              cnpj: "03316661000119",
              iduser: await getIdUser(),
              id: "");

          bool ok = await TransferenciaService(contexto: context)
              .InsertTransferencia(model);
          if (ok) {
            for (var i = 0; i < listRetiradoOk.length; i++) {
              await retiradaprodModel().delete(listRetiradoOk[i].idRetirado);
            }
            for (var i = 0; i < listArmOK.length; i++) {
              await armprodModel().delete(listArmOK[i].idArm);
            }
          }
        }
      }
    }
  }
}
