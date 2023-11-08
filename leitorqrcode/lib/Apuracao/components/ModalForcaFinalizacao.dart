import 'package:leitorqrcode/Components/Constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Models/APIModels/OperacaoModel.dart';
import 'package:leitorqrcode/Shared/Dialog.dart';

class modalForcaFinalizacao extends StatelessWidget {
  final String psw;
  final OperacaoModel op;

  modalForcaFinalizacao({Key key, @required this.psw, @required this.op})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final senhaDialog = TextEditingController();
    String alert = "";
    return AlertDialog(
      title: Text(
        "Informe a senha que consta na tela de detalhes do documento",
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      content: TextField(
        controller: senhaDialog,
        keyboardType: TextInputType.visiblePassword,
        maxLength: 4,
        decoration: InputDecoration(
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primaryColor),
            ),
            labelText: 'Senha'),
      ),
      actions: [
        Container(
          child: Row(children: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Fechar"),
            ),
            SizedBox(
              width: 10,
            ),
            TextButton(
              onPressed: () async => {
                if (senhaDialog.text != null &&
                    senhaDialog.text.length == 4 &&
                    senhaDialog.text.toUpperCase() == psw.toUpperCase())
                  {
                    op.situacao = "3",
                    await op.update(),
                    Navigator.pop(context),
                    Navigator.pop(context),
                     Dialogs.showToast(context, "Finalizado!")
                  }
                else
                  {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => AlertDialog(
                        title: Text(
                          "Senha incorreta",
                          style: TextStyle(
                              fontWeight: FontWeight.w500, color: Colors.red),
                        ),
                        elevation: 24.0,
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text("OK"),
                          ),
                        ],
                      ),
                    ),
                  }
              },
              child: Text("Finalizar"),
            ),
          ]),
        ),
      ],
      elevation: 24.0,
    );
  }
}
