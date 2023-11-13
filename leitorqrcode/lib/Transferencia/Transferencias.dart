import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Models/APIModels/OperacaoModel.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';
import 'package:leitorqrcode/Models/retiradaprodModel.dart';
import 'package:leitorqrcode/Transferencia/components/TransferenciaMenu.dart';
import 'package:uuid/uuid.dart';

class TransferenciasScreen extends StatefulWidget {
  @override
  _TransferenciasScreenState createState() => _TransferenciasScreenState();
}

class _TransferenciasScreenState extends State<TransferenciasScreen> {
  OperacaoModel? op;

  @override
  void initState() {
    getOpPendentes().then(
      (value) => setState(() {
        op = value;
      }),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: primaryColor,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return SafeArea(
      child: Scaffold(
          body: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.2,
                    color: primaryColor,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(30),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(
                      width: 25,
                    ),
                    Text(
                      "Transferências",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              MenuTransferencia(
                op: op,
              ),
            ],
          ),
          bottomNavigationBar: BottomBar()),
    );
  }

  Future<OperacaoModel> getOpPendentes() async {
    op = await new OperacaoModel().getPendenteAramazenamento();
    List<retiradaprodModel> prodRetirada = [];
    if (op != null) {
      List<ProdutoModel> prods =
          await new ProdutoModel().getByIdOperacao(op!.id!);
      if (prods.length == 0)
        op!.prods = [];
      else
        op!.prods = prods;
    } else {
      op = new OperacaoModel(
        cnpj: "",
        id: new Uuid().v4().toUpperCase(),
        nrdoc: new Uuid().v4().toUpperCase(),
        situacao: "1",
        tipo: "41",
        prods: [],
      );
      await op!.insert();
    }
    setState(() {});
    return op!;
  }
}
