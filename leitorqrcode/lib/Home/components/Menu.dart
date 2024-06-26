import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:leitorqrcode/Apuracao/Apuracao.dart';
import 'package:leitorqrcode/Conferencia/selecionarCargas.dart';
import 'package:leitorqrcode/Home/Home.dart';
import 'package:leitorqrcode/Home/components/Button.dart';
import 'package:leitorqrcode/Infrastructure/AtualizarDados/atualizaOp.dart';
import 'package:leitorqrcode/Inventario/Inventario.dart';
import 'package:leitorqrcode/Inventario/Inventario_2.dart';
import 'package:leitorqrcode/Models/APIModels/OperacaoModel.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoBase.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoGetEmbalagemListModel.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoNotasFiscaisModel.dart';
import 'package:leitorqrcode/QrCoderFirst.dart';
import 'package:leitorqrcode/Services/NotasFiscaisService.dart';
import 'package:leitorqrcode/Services/ProdutoService.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';
import 'package:leitorqrcode/Transferencia/Transferencias.dart';
import 'package:leitorqrcode/notaFiscal/selecionarEmbalagem.dart';
import 'package:leitorqrcode/printer/printer_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuHome extends StatelessWidget {
  final double? topPadding;
  // final BlueThermalPrinter bluetooth;
  final String adressBT;
  MenuHome(
      {Key? key,
      this.topPadding,
      // required this.bluetooth,
      required this.adressBT})
      : super(key: key);

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
                icone: Icons.all_inbox_outlined,
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
                icone: Icons.sync_alt,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ButtonHome(
                titulo: "Inventário",
                descricao: "Contagem de produtos \n no inventário",
                icone: Icons.inventory_outlined,
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => Inventario2(),
                    ),
                    (route) => true,
                  );
                },
              ),
              ButtonHome(
                titulo: "Carga",
                descricao: "Informe aqui as cargas \n a serem retiradas",
                icone: Icons.outbox_outlined,
                onTap: () async {
                  OperacaoModel? opRead =
                      await new OperacaoModel().getOpCarga();

                  if (opRead != null) {
                    opRead.prods =
                        await ProdutoModel().getByIdOperacao(opRead.id!);
                    if (opRead.prods == null || opRead.prods!.length == 0) {
                      opRead.prods = await _getProdutosInServer(opRead.id!);
                      for (int i = 0; i < opRead.prods!.length; i++) {
                        ProdutoModel? prodDB = await new ProdutoModel()
                            .getById(opRead.prods![i].id!);
                        if (prodDB == null || prodDB.id == null) {
                          opRead.prods![i].idOperacao = opRead.id;
                          await opRead.prods![i].insert();
                        } else {
                          opRead.prods![i] = prodDB;
                        }
                      }
                    }

                    Navigator.pop(context);
                    if (opRead.prods == null || opRead.prods!.length == 0) {
                      Dialogs.showToast(
                          context, "Nenhum produto encontrado para o pedido.",
                          duration: Duration(seconds: 5),
                          bgColor: Colors.red.shade200);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) => Apuracao(
                            titulo: "Retirada de Carga" +
                                (opRead.nrdoc != null
                                    ? "\n" + opRead.nrdoc!
                                    : ""),
                            operacaoModel: opRead,
                          ),
                        ),
                      );
                    }
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => QrCoderFirst(
                          tipo: 1,
                        ),
                      ),
                    );
                  }
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
                titulo: "Conferência",
                descricao: "Conferência de Retirada",
                icone: Icons.inventory_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => SelecionarCargas(),
                    ),
                  );
                },
              ),
              ButtonHome(
                titulo: "Sincronizar",
                descricao: "Clique aqui para enviar os dados para o servidor",
                icone: Icons.sync_sharp,
                onTap: () async {
                  await syncOp(context, true);
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
                titulo: "Teste Impressão",
                descricao: "teste impressão",
                icone: Icons.sync_sharp,
                onTap: () async {
                  List<EmbalagemPrinter>? listembprint = [];
                  String cmdZPL = "";

                  NotasFiscaisService notasFiscaisService =
                      NotasFiscaisService(context);

                  try {
                    List<String> idEmbalagens = [
                      '0F68C3EE-563A-4CF8-90E7-0D42DCBD343D',
                      '6F94A58A-712C-4E6C-9A37-182F7289610C',
                    ];

                    // for (var i = 0; i < widget.dadosEmbalagem.length; i++) {
                    //   idEmbalagens.add(widget.dadosEmbalagem[i].idEmbalagem);
                    // }

                    RetornoBaseModel? rtndadosEmbalagem =
                        await notasFiscaisService
                            .getDadosPrinterEmbalagem(idEmbalagens);

                    if (rtndadosEmbalagem != null) {
                      if (!rtndadosEmbalagem.error!) {
                        cmdZPL = rtndadosEmbalagem.data.toString();
                      }
                    } else {
                      return;
                    }
                  } catch (e) {
                    print('Erro ao processar carga: $e');
                  }

                  await PrinterController().PrintHeaderItensTeste(
                    // bluetooth: bluetooth,
                    context: context,
                    adressBT: adressBT,
                    cmdZPL: cmdZPL,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Future<RetornoGetEmbalagemListModel> _getEmbalagemList(
  //     BuildContext context, String idPedido) async {
  //   NotasFiscaisService notasFiscaisService = NotasFiscaisService(context);

  //   try {
  //     RetornoGetEmbalagemListModel? rtndadosNotaFiscal =
  //         await notasFiscaisService.getEmbalagemList(idPedido);
  //     if (rtndadosNotaFiscal != null) {
  //       return rtndadosNotaFiscal;
  //     }
  //   } catch (e) {
  //     print('Erro ao processar carga: $e');
  //   }
  // }

  Future<List<ProdutoModel>> _getProdutosInServer(String idOperacao) async {
    ProdutoService produtoService = new ProdutoService();

    if (idOperacao.isNotEmpty)
      return await produtoService.getProdutos(idOperacao);
    else
      return Future.value(<ProdutoModel>[]);
  }
}
