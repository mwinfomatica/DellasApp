import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Inventario/Inventario_2.dart';

class modalQtd extends StatefulWidget {
  const modalQtd({Key? key, required this.onclick}) : super(key: key);
  final Function onclick;

  @override
  State<modalQtd> createState() => _modalQtdState();
}

class _modalQtdState extends State<modalQtd> {
  TextEditingController qtdeProdDialog = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Informe a quantidade do produto scaneado",
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      content: TextField(
        controller: qtdeProdDialog,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primaryColor),
            ),
            labelText: 'Qtde'),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () async {
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: Text("Salvar"),
          onPressed: () async {
            await widget.onclick(qtd: qtdeProdDialog.text);
          },
        ),
      ],
      elevation: 24.0,
    );
  }
}
