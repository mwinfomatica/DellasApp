import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:leitorqrcode/Conferencia/selecionarCargas.dart';
import 'package:leitorqrcode/Home/components/Button.dart';
import 'package:leitorqrcode/Infrastructure/AtualizarDados/atualizaOp.dart';
import 'package:leitorqrcode/Inventario/Inventario.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoGetEmbalagemListModel.dart';
import 'package:leitorqrcode/QrCoderFirst.dart';
import 'package:leitorqrcode/Services/NotasFiscaisService.dart';
import 'package:leitorqrcode/Transferencia/Transferencias.dart';
import 'package:leitorqrcode/printer/plugin_printer.dart';
import 'package:leitorqrcode/printer/printer_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuHome extends StatelessWidget {
  final double? topPadding;
  final BlueThermalPrinter bluetooth;
  MenuHome({Key? key, this.topPadding, required this.bluetooth})
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
                icone: Icons.outbox_outlined,
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
          // SizedBox(
          //   height: 25,
          // ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     ButtonHome(
          //       titulo: "Teste Impressão",
          //       descricao: "teste impressão",
          //       icone: Icons.sync_sharp,
          //       onTap: () async {
          //         List<EmbalagemPrinter>? listembprint = [];

          //         NotasFiscaisService notasFiscaisService =
          //             NotasFiscaisService(context);

          //         try {
          //           List<String> idEmbalagens = [
          //             '7088C7AE-C8C4-4FA6-9CA8-DF2095ED71F1',
          //             'DF785F1A-B2C8-439B-96E4-236ACEB16624'
          //           ];

          //           // for (var i = 0; i < widget.dadosEmbalagem.length; i++) {
          //           //   idEmbalagens.add(widget.dadosEmbalagem[i].idEmbalagem);
          //           // }

          //           RetornoGetDadosEmbalagemListModel? rtndadosEmbalagem =
          //               await notasFiscaisService
          //                   .getDadosPrinterEmbalagem(idEmbalagens);

          //           if (rtndadosEmbalagem != null) {
          //             if (!rtndadosEmbalagem.error) {
          //               listembprint = rtndadosEmbalagem.data;
          //             }
          //           } else {
          //             return;
          //           }
          //         } catch (e) {
          //           print('Erro ao processar carga: $e');
          //         }

          //         await PrinterController().printQrCodeEmbalagem(
          //           listemb: listembprint ?? [],
          //           bluetooth: bluetooth,
          //           context: context,
          //         );
          //       },
          //     ),
          //   ],
          // ),
    
        ],
      ),
    );
  }
}
